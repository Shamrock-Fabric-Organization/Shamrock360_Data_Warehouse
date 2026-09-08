<#
.SYNOPSIS
    Compares every Fabric object between development and production in one run.

.DESCRIPTION
    Walks a folder tree laid out by object type, then environment:

        fabric/
          pipelines/
            dev/   pl_dimension_logic.json
            prod/  pl_dimension_logic.json
          notebooks/
            dev/
            prod/
          semantic-models/
            dev/
            prod/

    Files are paired by name, so the same object in both environments must have the
    same filename. Anything present on one side only is reported rather than skipped
    quietly - a file that exists in development and not in production usually means an
    export was forgotten, which is worth knowing.

    Prints one line per object, then the detail for whatever differed. When everything
    matches the output is short enough to read at a glance, which is what makes it
    realistic to run after every promotion.

.PARAMETER Root
    The folder containing the object-type folders. Defaults to 'fabric'.

.PARAMETER DevName
    Name of the development subfolder. Defaults to 'dev'.

.PARAMETER ProdName
    Name of the production subfolder. Defaults to 'prod'.

.PARAMETER Brief
    Compare only activity name, type and state - not the activity bodies.

.PARAMETER Detail
    Print the full CHECK 2 reference list for every object, not just those that differ.

.PARAMETER ConfigPath
    A JSON file recording two kinds of decision. Defaults to compare-config.json in the
    root folder, and is optional - without it everything still works, objects just pair
    by filename alone.

        pairs                 objects whose name differs between environments, so they
                              can still be compared to each other
        expectedDifferences   differences confirmed as deliberate, which are set aside
                              and counted rather than reported as problems

    Accepted differences are SEPARATED, never hidden. The run says how many were set
    aside and prints the recorded reason, so a decision stays visible instead of
    becoming an invisible rule nobody remembers agreeing to.

.EXAMPLE
    .\Compare-FabricEnvironment.ps1

.EXAMPLE
    .\Compare-FabricEnvironment.ps1 -Root ..\fabric -Brief

.OUTPUTS
    Exit code 0 when nothing differs and nothing is unpaired, 1 otherwise.

.NOTES
    A dataflow CAN be exported, but its definition is Power Query (mashup.pq) rather than
    a pipeline with activities, so CHECK 1 has nothing to walk and it is reported as an
    ERROR rather than compared. Only Scorecard has no definition API at all.
#>

[CmdletBinding()]
param(
    [string] $Root = 'fabric',
    [string] $DevName = 'dev',
    [string] $ProdName = 'prod',
    [switch] $Brief,
    [switch] $Detail,
    [string] $ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'FabricDefinition.psm1') -Force

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Root folder not found: $Root. Run this from the repository root, or pass -Root."
}

$rootFull = (Resolve-Path -LiteralPath $Root).Path
Write-Host ''
Write-Host "Comparing $DevName against $ProdName under $rootFull"

if (-not $ConfigPath) { $ConfigPath = Join-Path $rootFull 'compare-config.json' }
$config = $null
if (Test-Path -LiteralPath $ConfigPath) {
    try { $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json }
    catch { throw "compare-config.json is not valid JSON ($ConfigPath): $($_.Exception.Message)" }
    Write-Host "Using $ConfigPath"
}

$expectedRules = @()
if ($config -and $config.PSObject.Properties.Name -contains 'expectedDifferences') {
    $expectedRules = @($config.expectedDifferences)
}

$typeFolders = @(Get-ChildItem -LiteralPath $rootFull -Directory | Sort-Object Name)
if ($typeFolders.Count -eq 0) {
    throw "No object-type folders found under $Root. Expected something like $Root\pipelines\$DevName."
}

# Files that live alongside a definition in a Fabric export but are not definitions.
$script:IgnoredNames = @('manifest.json', '.platform')

# ---------------------------------------------------------------------------
# Anything set aside gets a NUMBERED NOTE, and the summary row it affected carries
# the number. Without that link the reader sees "7 allowed" on one line and three
# separate explanations at the bottom, and has to work out which belongs to which -
# or worse, a reason truncated to "...disabled in..." that says nothing at all. The
# number is what makes the summary readable in six months, and readable to someone
# who was never told any of this.
# ---------------------------------------------------------------------------
$noteText    = [ordered]@{}   # id -> explanation
$noteCount   = @{}            # id -> how many findings or objects it covered
$noteKeyToId = @{}            # dedupe key -> id

function Get-NoteId {
    param([string] $Key, [string] $Text)
    if (-not $noteKeyToId.ContainsKey($Key)) {
        $id = 'N' + ($noteKeyToId.Count + 1)
        $noteKeyToId[$Key] = $id
        $noteText[$id]  = $Text
        $noteCount[$id] = 0
    }
    return $noteKeyToId[$Key]
}

$rows = @()          # one per object, for the summary table
$details = @()       # findings to print underneath
$problems = 0
$ignoredTotal = 0
$expectedTotal = 0
$embeddedTotal = 0

# ⛔ CHECK 2 USED TO PRINT ONLY WHEN IT FOUND SOMETHING. On a clean run nothing
# appeared at all, so "Everything matched" rested on silence - and silence reads
# the same whether the check passed or never ran. A verdict is now printed every
# time, pass or fail.
$check2Examined = 0
$check2SharedTarget = 0
$check2Unclassified = 0
$expectedObjectReasons = @{}

foreach ($typeFolder in $typeFolders) {
    $devDir  = Join-Path $typeFolder.FullName $DevName
    $prodDir = Join-Path $typeFolder.FullName $ProdName

    $haveDev  = Test-Path -LiteralPath $devDir
    $haveProd = Test-Path -LiteralPath $prodDir

    if (-not $haveDev -and -not $haveProd) {
        # Not an environment-paired folder. Say so rather than silently ignoring it,
        # because a typo in a folder name would otherwise look like "nothing to check".
        $rows += [pscustomobject]@{
            Type = $typeFolder.Name; Object = '(no dev/prod folders)'; Status = 'SKIPPED'; Note = ''
        }
        continue
    }

    $devFiles  = if ($haveDev)  { @(Get-ChildItem -LiteralPath $devDir  -Filter *.json -File) } else { @() }
    $prodFiles = if ($haveProd) { @(Get-ChildItem -LiteralPath $prodDir -Filter *.json -File) } else { @() }

    # A Fabric export downloads as a zip containing the definition AND a manifest.json,
    # which holds the item name and a thumbnail image rather than any logic. Someone
    # will eventually extract a whole zip into these folders, and every export carries
    # a manifest by that same name - so they would collide with each other as well as
    # failing to parse as pipelines. Ignore them by name, and say so rather than
    # silently dropping a file somebody deliberately put there.
    $ignored = @($devFiles + $prodFiles | Where-Object { $_.Name -in $script:IgnoredNames })
    $devFiles  = @($devFiles  | Where-Object { $_.Name -notin $script:IgnoredNames })
    $prodFiles = @($prodFiles | Where-Object { $_.Name -notin $script:IgnoredNames })
    if ($ignored.Count -gt 0) { $ignoredTotal += $ignored.Count }

    # ForEach-Object rather than $devFiles.Name: under Set-StrictMode -Version Latest,
    # member access on an EMPTY collection is an error, not an empty result. An empty
    # notebooks folder would otherwise abort the whole run.
    $devNames  = @($devFiles  | ForEach-Object { $_.Name })
    $prodNames = @($prodFiles | ForEach-Object { $_.Name })

    # Objects whose NAME differs between environments cannot pair on filename. The
    # config records those pairs explicitly rather than the tool guessing from a
    # DEV/PROD token in the name - a guess would eventually pair two objects that
    # merely look related, and quietly report them as matching.
    $devToProd = @{}
    $expectDifferent = @{}
    if ($config -and $config.PSObject.Properties.Name -contains 'pairs') {
        foreach ($p in @($config.pairs)) {
            if ($p.PSObject.Properties.Name -contains 'type' -and $p.type -and
                $p.type -ne $typeFolder.Name) { continue }
            $devToProd[$p.dev] = $p.prod

            # Some objects are KNOWN to differ in content, not just in name. Marking the
            # pair is deliberately narrower than an expectedDifferences rule: a rule that
            # ignored missing PBISemanticModelRefresh activities everywhere would also
            # hide a refresh genuinely dropped from production one day. This exempts one
            # named object and nothing else.
            if ($p.PSObject.Properties.Name -contains 'expectDifferent' -and $p.expectDifferent) {
                $expectDifferent[$p.dev] = if ($p.PSObject.Properties.Name -contains 'reason') {
                    $p.reason } else { 'marked as expected to differ in compare-config.json' }
            }
        }
    }
    $prodToDev = @{}
    foreach ($k in $devToProd.Keys) { $prodToDev[$devToProd[$k]] = $k }

    $allNames  = @($devNames + $prodNames | Sort-Object -Unique)

    if ($allNames.Count -eq 0) {
        $rows += [pscustomobject]@{
            Type = $typeFolder.Name; Object = '(empty)'; Status = 'SKIPPED'; Note = 'no .json files'
        }
        continue
    }

    foreach ($name in $allNames) {
        # A prod file that is the mapped counterpart of a dev file is handled when the
        # dev file comes round, so skip it here rather than reporting it twice.
        if ($prodToDev.ContainsKey($name) -and $devNames -contains $prodToDev[$name]) { continue }

        $inDev  = $devNames  -contains $name
        # NOT $prodName. PowerShell variable names are CASE-INSENSITIVE, so a local
        # named $prodName IS the -ProdName parameter, and assigning a FILENAME to it
        # here rewrote $prodDir on the next type folder to a path that cannot exist.
        # Every object type sorting after the first was then reported DEV ONLY on a
        # healthy platform. Keep this name distinct from every parameter above.
        $prodFileName = if ($devToProd.ContainsKey($name)) { $devToProd[$name] } else { $name }
        $inProd = $prodNames -contains $prodFileName

        $label = if ($prodFileName -ne $name) { "$name -> $prodFileName" } else { $name }

        if (-not $inProd) {
            $rows += [pscustomobject]@{
                Type = $typeFolder.Name; Object = $label; Status = 'DEV ONLY'
                Note = 'not exported from production, or never promoted'
            }
            $problems++
            continue
        }
        if (-not $inDev) {
            $rows += [pscustomobject]@{
                Type = $typeFolder.Name; Object = $label; Status = 'PROD ONLY'
                Note = 'exists in production with no development counterpart'
            }
            $problems++
            continue
        }

        $devPath  = Join-Path $devDir  $name
        $prodPath = Join-Path $prodDir $prodFileName

        try {
            $r = Compare-FabricDefinitionPair -DevPath $devPath -ProdPath $prodPath `
                     -Brief:$Brief -Expected $expectedRules
        }
        catch {
            $rows += [pscustomobject]@{
                Type = $typeFolder.Name; Object = $label; Status = 'ERROR'; Note = $_.Exception.Message
            }
            $problems++
            continue
        }

        $rowRefs = @()

        if ($r.FormatMismatch) {
            $nid = Get-NoteId 'formatmismatch' ('The two sides were exported DIFFERENT WAYS. A manual ' +
                'export from the Fabric interface writes artifactId as a template parameter; the API ' +
                'writes the real GUID. Every activity touching a warehouse will report a difference ' +
                'that is not real. Re-export both sides the same way.')
            $noteCount[$nid] += 1
            $rowRefs += $nid
        }

        # An embedded child that has no standalone export of its own would go
        # completely unchecked, so say so rather than let it disappear.
        foreach ($emb in @($r.EmbeddedResources)) {
            $embFile = Join-Path $devDir ($emb + '.json')
            if (-not (Test-Path -LiteralPath $embFile)) {
                $rows += [pscustomobject]@{
                    Type = $typeFolder.Name; Object = "$label -> $emb"; Status = 'NOT CHECKED'
                    Note = 'embedded in the orchestrator with no export of its own'
                }
                $problems++
            }
        }
        if (@($r.EmbeddedResources).Count -gt 0) {
            $embeddedTotal += @($r.EmbeddedResources).Count
            $nid = Get-NoteId 'embedded' ('An orchestrator export freezes a copy of every pipeline it invokes, ' +
                'and that copy goes stale as soon as the child is edited. Those copies are NOT compared here - ' +
                'each child is compared from its own export, which is current.')
            $noteCount[$nid] += @($r.EmbeddedResources).Count
            $rowRefs += $nid
        }

        $check2Examined++
        if (@($r.SharedTargeting).Count -gt 0)     { $check2SharedTarget++ }
        if (@($r.SharedUnclassified).Count -gt 0)  { $check2Unclassified++ }

        $shared   = $r.SharedTargeting.Count
        $diffs    = $r.Findings.Count
        $accepted = @($r.ExpectedFindings).Count
        $expectedTotal += $accepted

        $isExpectedDiff = $expectDifferent.ContainsKey($name)
        $status =
            if ($diffs -gt 0 -and $isExpectedDiff) { "differs ($diffs), by design" }
            elseif ($diffs -gt 0)                  { "DIFFERS ($diffs)" }
            else                                   { 'match' }

        $notes = @()
        if ($accepted -gt 0) {
            foreach ($grp in ($r.ExpectedFindings | Group-Object { $_.Label })) {
                $reason = @($grp.Group)[0].Rule.reason
                if (-not $reason) { $reason = $grp.Name }
                $nid = Get-NoteId ('rule:' + $grp.Name) $reason
                $noteCount[$nid] += $grp.Count
                $rowRefs += $nid
            }
            $notes += ("{0} exception(s)" -f $accepted)
        }
        if ($isExpectedDiff) {
            $nid = Get-NoteId ('object:' + $name) $expectDifferent[$name]
            $noteCount[$nid] += 1
            $rowRefs += $nid
        }
        if ($shared -gt 0) { $notes += "$shared SHARED TARGET(S)" }
        $note = ($notes -join ', ')

        $rows += [pscustomobject]@{
            Type = $typeFolder.Name; Object = $label; Status = $status; Note = $note
            Refs = (@($rowRefs | Sort-Object -Unique) -join ' ')
        }
        if ($diffs -gt 0 -and -not $isExpectedDiff) { $problems++ }
        if ($isExpectedDiff) { $expectedObjectReasons[$name] = $expectDifferent[$name] }

        if (($diffs -gt 0 -and -not $isExpectedDiff) -or $shared -gt 0 -or
            @($r.SharedUnclassified).Count -gt 0 -or $Detail) {
            $details += [pscustomobject]@{ Type = $typeFolder.Name; Object = $label; Result = $r }
        }
    }
}

# ------------------------------------------------------------------ summary
Write-Host ''
Write-Host ('=' * 78)
Write-Host 'SUMMARY'
Write-Host ('=' * 78)

$rows = @($rows | ForEach-Object {
    if ($_.PSObject.Properties.Name -notcontains 'Refs') {
        $_ | Add-Member -NotePropertyName Refs -NotePropertyValue '' -PassThru
    } else { $_ }
})

$w = 20
if ($rows.Count -gt 0) {
    $longest = ($rows | ForEach-Object { $_.Object.Length } | Measure-Object -Maximum).Maximum
    if ($longest -gt $w) { $w = $longest }
}

foreach ($row in $rows) {
    $color = switch -Wildcard ($row.Status) {
        'match'     { 'Green' }
        'differs*'  { 'DarkGray' }
        'SKIPPED'   { 'DarkGray' }
        default     { 'Yellow' }
    }
    Write-Host ("  {0,-12} {1,-$w}  {2,-23} {3,-6} {4}" -f
                $row.Type, $row.Object, $row.Status, $row.Refs, $row.Note) -ForegroundColor $color
}

# ------------------------------------------------------------------ check 2
Write-Host ''
Write-Host ('=' * 78)
Write-Host 'CHECK 2 - IS PRODUCTION POINTING AT PRODUCTION?'
Write-Host ('=' * 78)
if ($check2Examined -eq 0) {
    Write-Host '  Nothing was compared, so this check did not run.' -ForegroundColor Yellow
}
else {
    Write-Host ("  {0} object(s) examined for workspaceId, endpoint and artifactId." -f $check2Examined)
    if ($check2SharedTarget -eq 0) {
        Write-Host '  PASS - no targeting value appears in both environments.' -ForegroundColor Green
    }
    else {
        Write-Host ("  FAIL - {0} object(s) share a targeting value. Listed below." -f
                    $check2SharedTarget) -ForegroundColor Red
        Write-Host '  These decide which warehouse is read, so production may be reading development.'
    }
    if ($check2Unclassified -gt 0) {
        Write-Host ("  {0} object(s) also share a value this script cannot classify - judge those yourself." -f
                    $check2Unclassified) -ForegroundColor Yellow
    }
    Write-Host '  A shared CONNECTION is expected and is not counted: the same connection object'
    Write-Host '  legitimately serves both workspaces on a shared capacity.'
}

# ------------------------------------------------------------------ notes
if ($noteText.Count -gt 0) {
    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host 'NOTES  - each is referenced by number in the table above'
    Write-Host ('=' * 78)
    foreach ($id in $noteText.Keys) {
        Write-Host ("  [{0}]  applied {1} time(s)" -f $id, $noteCount[$id]) -ForegroundColor Cyan
        $words = $noteText[$id] -split '\s+'
        $line = '       '
        foreach ($word in $words) {
            if (($line.Length + $word.Length + 1) -gt 78) { Write-Host $line; $line = '       ' }
            $line = $line + ' ' + $word
        }
        if ($line.Trim()) { Write-Host $line }
        Write-Host ''
    }
}

# ------------------------------------------------------------------ detail
foreach ($d in $details) {
    Write-Host ''
    Write-Host ('-' * 78)
    Write-Host ("{0} / {1}" -f $d.Type, $d.Object)
    Write-Host ('-' * 78)
    $r = $d.Result

    if ($r.Findings.Count -gt 0) {
        Write-Host ("  CHECK 1 - {0} activities in dev, {1} in prod" -f
                    $r.DevActivityCount, $r.ProdActivityCount)
        foreach ($f in $r.Findings) {
            Write-Host ("    {0,-20} {1,-26} {2}" -f $f.Kind, $f.Type, $f.Detail)
        }
    }
    else {
        Write-Host '  CHECK 1 - no differences.'
    }

    if ($r.SharedTargeting.Count -gt 0) {
        Write-Host ''
        Write-Host '  CHECK 2 - these TARGETING values appear in BOTH environments:'
        foreach ($s in $r.SharedTargeting) {
            Write-Host ("    {0}   {1}" -f $s.Value, $s.Label) -ForegroundColor Red
        }
        Write-Host '    These decide which warehouse is read. Production may be reading development.'
    }
    elseif ($Detail) {
        Write-Host ''
        Write-Host '  CHECK 2 - no targeting value shared. Production points at production.'
    }
}

Write-Host ''
if ($problems -eq 0) {
    Write-Host 'Everything matched.' -ForegroundColor Green
}
else {
    Write-Host ("{0} object(s) need attention." -f $problems) -ForegroundColor Yellow
}
Write-Host ''

exit ($(if ($problems -gt 0) { 1 } else { 0 }))
