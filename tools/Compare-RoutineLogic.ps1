<#
.SYNOPSIS
    Sorts the routines two warehouse environments share into three classes: the same,
    the same apart from their comments, and genuinely different.

.DESCRIPTION
    Compare-WarehouseSchema.ps1 already tolerates a difference that is only layout - two
    bodies that differ in line endings, tabs, repeated spaces, trailing spaces or blank
    lines are reported as logically identical. It does NOT tolerate a difference that is
    only a comment, and during a cleanup pass that is most of the noise: a reworded header
    block or a dropped TODO reads as a changed routine.

    This script answers the cleanup question instead: which routines can I stop worrying
    about, and what is actually left. It strips the comments out of both bodies, applies
    the same whitespace normalization the export applies, and classifies what remains.

    ⛔ THIS IS A TEMPORARY DIAGNOSTIC, DELIBERATELY SEPARATE FROM THE COMPARER. It is not
    a switch on Compare-WarehouseSchema.ps1 because that comparer is permanent and this
    question is not. A switch there would put a tokenizer on the routine path forever and
    change what a default run reports. When the cleanup is finished this file can be
    deleted and nothing else moves.

    ⛔ COMMENTS ARE FOUND WITH A REAL T-SQL TOKENIZER, NOT A REGEX. Microsoft's ScriptDom
    lexer (TSql160Parser) reports comment tokens directly, so '-- not a comment' inside a
    string literal stays in the body and a /* inside quotes does not open a comment. A
    regex gets both of those wrong, and gets them wrong SILENTLY - it would delete real
    code and then report the routine as identical, which is the one outcome worse than no
    tool at all. If the tokenizer cannot be loaded this script stops rather than falling
    back. The assembly already lives in the repository, under tools/qa-validator.

    ⛔ A COMMENT DIFFERENCE IS ITS OWN CLASS, LISTED BY NAME, NEVER FOLDED INTO
    "IDENTICAL". A commented-out WHERE clause or JOIN is a real behavioral difference
    wearing a comment's clothes, and that class is exactly where it hides. The count is
    not enough; the names are printed.

    ⛔ IT NEEDS THE FULL EXPORTS. Run Export-WarehouseSchema.ps1 with -IncludeDefinitions
    on both environments first. That writes <environment>-<database>.full.json BESIDE the
    ordinary hash export rather than over it, so the small committed-safe file survives.
    A hash-only export carries no text and this script will say so rather than guess.
    Those .full.json files hold the complete SQL of every routine - use them, then delete
    them.

    WHAT THE LINE NUMBERS MEAN. A reported line number is a line of the STRIPPED AND
    NORMALIZED body, not of the source. Comments and blank lines are gone by then, so it
    will not match the line number in a .sql file. It identifies the differing statement,
    which is what the cleanup needs; the repository remains the authority on the code.

.PARAMETER Folder
    A folder of exports. Pairs dev-<database>.full.json with prod-<database>.full.json
    and compares every pair it finds. Use this for all four warehouses at once.

.PARAMETER DevFile
    One development-side .full.json export, when you would rather name the two files.

.PARAMETER ProdFile
    The production-side .full.json export to compare it against.

.PARAMETER ScriptDomPath
    Path to Microsoft.SqlServer.TransactSql.ScriptDom.dll, if the copies under
    tools/qa-validator and the NuGet cache are both absent. Normally unnecessary.

.EXAMPLE
    # Both environments, all four warehouses, then the cleanup worklist.
    .\Export-WarehouseSchema.ps1 -Environment dev  -OutFolder warehouse-schema -IncludeDefinitions
    .\Export-WarehouseSchema.ps1 -Environment prod -OutFolder warehouse-schema -IncludeDefinitions
    .\Compare-RoutineLogic.ps1 -Folder warehouse-schema

.EXAMPLE
    # One warehouse, files named explicitly.
    .\Compare-RoutineLogic.ps1 -DevFile dev-WH_Curated.full.json -ProdFile prod-WH_Curated.full.json

.NOTES
    Exit code 0  nothing differs in logic
              1  at least one routine differs in logic
              2  the comparison could not be run at all (no tokenizer, no definitions,
                 no pair of files)

    NOT YET RUN AGAINST A LIVE EXPORT. The classification and the tokenizer behavior are
    proved on a constructed fixture covering all three classes, the string-literal trap
    and an absent body. The .full.json shape it reads is the shape
    Export-WarehouseSchema.ps1 writes, read from that script rather than assumed.
#>

#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'Folder')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Folder')] [string] $Folder,
    [Parameter(Mandatory, ParameterSetName = 'Files')]  [string] $DevFile,
    [Parameter(Mandatory, ParameterSetName = 'Files')]  [string] $ProdFile,
    [string] $ScriptDomPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# The tokenizer.
# ---------------------------------------------------------------------------

function Import-ScriptDom {
    <#
        Loads Microsoft's T-SQL lexer, or stops. There is no regex fallback by design -
        see the header. The search order is: an explicit path, the qa-validator build
        output, then the NuGet cache that build restores into.
    #>
    param([string] $Explicit)

    if ('Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser' -as [type]) { return 'already loaded' }

    $candidates = @()
    if ($Explicit) { $candidates += $Explicit }

    $qa = Join-Path (Split-Path -Parent $PSScriptRoot) 'qa-validator'
    foreach ($cfg in 'Release', 'Debug') {
        $candidates += Get-ChildItem -Path (Join-Path $qa "bin/$cfg") -Recurse -ErrorAction SilentlyContinue `
                            -Filter 'Microsoft.SqlServer.TransactSql.ScriptDom.dll' |
                       Where-Object { $_.Directory.Name -notmatch '^[a-z]{2}(-[A-Za-z]+)?$' } |
                       Select-Object -ExpandProperty FullName
    }

    # The NuGet cache. net6.0 first: this script requires PowerShell 7, which is .NET 6
    # or later, and the netstandard build is only there for older hosts.
    $cache = Join-Path $HOME '.nuget/packages/microsoft.sqlserver.transactsql.scriptdom'
    foreach ($tfm in 'net6.0', 'netstandard2.1', 'netstandard2.0') {
        $candidates += Get-ChildItem -Path $cache -Recurse -ErrorAction SilentlyContinue `
                            -Filter 'Microsoft.SqlServer.TransactSql.ScriptDom.dll' |
                       Where-Object { $_.Directory.Name -eq $tfm } |
                       Select-Object -ExpandProperty FullName
    }

    foreach ($dll in ($candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) })) {
        try {
            Add-Type -LiteralPath $dll
            if ('Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser' -as [type]) { return $dll }
        }
        catch {
            Write-Verbose ("could not load {0}: {1}" -f $dll, $_.Exception.Message)
        }
    }
    return $null
}

function Split-Routine {
    <#
        One routine body, taken apart by the lexer: the code with every comment removed,
        and the comments on their own.

        A comment is replaced by a SINGLE SPACE, not by nothing, so that /*x*/ between two
        tokens cannot weld them into one word. Any line breaks the comment contained are
        kept with it, so removing a block comment does not pull the following statement up
        onto the previous line.
    #>
    param([string] $Text)

    $parser = [Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
    $errors = $null
    $tokens = $parser.GetTokenStream([System.IO.StringReader]::new($Text), [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        # The lexer could not read the text. Saying "identical" about a body nobody could
        # read is the false pass this whole tool exists to avoid.
        return [pscustomobject]@{ Ok = $false; Reason = $errors[0].Message; Code = ''; Comments = @() }
    }

    $code = [System.Text.StringBuilder]::new()
    $comments = [System.Collections.Generic.List[string]]::new()

    foreach ($t in $tokens) {
        switch ($t.TokenType) {
            { $_ -eq [Microsoft.SqlServer.TransactSql.ScriptDom.TSqlTokenType]::SingleLineComment -or
              $_ -eq [Microsoft.SqlServer.TransactSql.ScriptDom.TSqlTokenType]::MultilineComment } {
                $comments.Add($t.Text)
                [void]$code.Append(' ')
                [void]$code.Append((($t.Text -replace "[^`r`n]", '')))
            }
            ([Microsoft.SqlServer.TransactSql.ScriptDom.TSqlTokenType]::EndOfFile) { }
            default { [void]$code.Append($t.Text) }
        }
    }

    return [pscustomobject]@{
        Ok = $true; Reason = ''
        Code = $code.ToString()
        Comments = $comments.ToArray()
    }
}

# ---------------------------------------------------------------------------
# Whitespace, normalized the way the export normalizes it.
# ---------------------------------------------------------------------------

function ConvertTo-NormalizedWhitespace {
    <#
        ⛔ THE SAME RULES AS DEFINITION_NORMALIZED_HASH IN Export-WarehouseSchema.ps1, IN
        THE SAME ORDER. This script must agree with the comparer about what "layout only"
        means; a second, slightly different standard would put a routine in one class here
        and another class there, and the reader would have no way to tell which was right.
        The export builds these steps out of REPLACE because T-SQL has no regex - the
        steps themselves are what is being copied, not the implementation.

        CASE IS NOT NORMALIZED, there as here. Select against SELECT stays a difference.
    #>
    param([string] $Text)

    if ($null -eq $Text) { return '' }
    $s = $Text -replace "`r`n", "`n" -replace "`r", "`n"   # line endings
    $s = $s -replace "`t", ' '                              # tab -> space
    $s = $s -replace ' +', ' '                              # runs of spaces -> one
    $s = $s -replace " `n", "`n"                            # trailing space on a line
    $s = $s -replace "`n+", "`n"                            # blank lines
    return $s.Trim(" `n")                                   # and trim the whole body
}

function Get-CommentSignature {
    # The comments as one comparable string. Each is whitespace-normalized on its own so
    # that re-wrapping a header block does not register as a comment change, and they are
    # joined in source order so that MOVING a comment does.
    param([string[]] $Comments)
    if (-not $Comments -or $Comments.Count -eq 0) { return '' }
    return (($Comments | ForEach-Object { ConvertTo-NormalizedWhitespace $_ }) -join "`n~`n")
}

function Get-FirstDifferingLine {
    <#
        Where two normalized bodies diverge, as a line number and the two lines.

        ⛔ -cne, NOT -ne. PowerShell compares strings case-INSENSITIVELY by default, and a
        walk that steps over a line differing only in case would report "no line differs"
        about two bodies this script has just classified as different.
    #>
    param([string] $A, [string] $B)
    $la = $A -split "`n"
    $lb = $B -split "`n"
    for ($i = 0; $i -lt [Math]::Max($la.Count, $lb.Count); $i++) {
        $x = if ($i -lt $la.Count) { $la[$i] } else { '(no more lines)' }
        $y = if ($i -lt $lb.Count) { $lb[$i] } else { '(no more lines)' }
        if ($x -cne $y) {
            # ⛔ SAY WHEN THE DIFFERENCE IS ONE THE DISPLAY CANNOT SHOW. The normalization
            # copied from the export collapses a RUN of spaces to one but does not delete
            # a line's indentation, so a body moved in or out by one level still differs -
            # on this tool and on Compare-WarehouseSchema.ps1 alike. Printing the two
            # lines trimmed then showed a reader two identical lines under "line 2", which
            # reads as a broken tool rather than as the finding it is.
            return [pscustomobject]@{
                Line = $i + 1; Dev = $x; Prod = $y
                IndentOnly = ($x.Trim() -ceq $y.Trim())
            }
        }
    }
    return $null
}

function Format-Line {
    # Kept inside the width of a terminal. A differing line identifies the statement; the
    # repository holds the code, and a wrapped or scrolling line helps nobody read either.
    param([string] $Text, [int] $Width = 96)
    $t = $Text.Trim()
    if ($t.Length -le $Width) { return $t }
    return ($t.Substring(0, $Width - 3) + '...')
}

function Format-Count {
    param([int] $N, [string] $Singular, [string] $Plural)
    return ("{0} {1}" -f $N, $(if ($N -eq 1) { $Singular } else { $Plural }))
}

# ---------------------------------------------------------------------------
# Reading the exports.
# ---------------------------------------------------------------------------

function Get-Export {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Export not found: $Path" }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Test-HasProperty {
    param($Object, [string] $Name)
    if ($null -eq $Object) { return $false }
    return [bool]($Object.PSObject.Properties.Name -contains $Name)
}

function Get-RoutineMap {
    # schema.name -> the routine row. Ordinal keys: two routines differing only in case
    # are two routines.
    param($Export)
    $map = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    if (-not (Test-HasProperty $Export 'routines')) { return $map }
    foreach ($r in @($Export.routines)) {
        $map[("{0}.{1}" -f $r.ROUTINE_SCHEMA, $r.ROUTINE_NAME)] = $r
    }
    return $map
}

function Get-Definition {
    # The body text, or $null when the export carries the row but no text for it.
    param($Row)
    if (-not (Test-HasProperty $Row 'ROUTINE_DEFINITION')) { return $null }
    $d = $Row.ROUTINE_DEFINITION
    if ($null -eq $d -or $d -is [System.DBNull]) { return $null }
    $s = [string]$d
    if ($s.Trim().Length -eq 0) { return $null }
    return $s
}

# ---------------------------------------------------------------------------
# One pair.
# ---------------------------------------------------------------------------

function Compare-Pair {
    param([string] $DevPath, [string] $ProdPath)

    $dev  = Get-Export $DevPath
    $prod = Get-Export $ProdPath

    Write-Host ''
    Write-Host ('-' * 78)
    $dbName = if (Test-HasProperty $dev 'database') { $dev.database } else { (Split-Path -Leaf $DevPath) }
    Write-Host ("{0}" -f $dbName)
    Write-Host ('-' * 78)
    Write-Host ("  dev  {0}" -f (Split-Path -Leaf $DevPath))
    Write-Host ("  prod {0}" -f (Split-Path -Leaf $ProdPath))

    # Definitions, or nothing to do. Stated per pair because one warehouse can be exported
    # with -IncludeDefinitions and another without.
    $devFull  = (Test-HasProperty $dev  'definitionsIncluded') -and [bool]$dev.definitionsIncluded
    $prodFull = (Test-HasProperty $prod 'definitionsIncluded') -and [bool]$prod.definitionsIncluded
    if (-not ($devFull -and $prodFull)) {
        $which = if (-not $devFull -and -not $prodFull) { 'Neither export carries' }
                 elseif (-not $devFull)                 { 'The development export does not carry' }
                 else                                   { 'The production export does not carry' }
        Write-Host ''
        Write-Host ("  {0} routine text, so there is nothing to strip comments out of." -f $which)
        Write-Host '  Re-export with -IncludeDefinitions. It writes a .full.json beside the hash'
        Write-Host '  export rather than over it, so nothing already in the folder is lost.'
        return [pscustomobject]@{ Ran = $false; Different = 0 }
    }

    $devRt  = Get-RoutineMap $dev
    $prodRt = Get-RoutineMap $prod

    $shared   = @($devRt.Keys | Where-Object { $prodRt.ContainsKey($_) } | Sort-Object)
    $devOnly  = @($devRt.Keys  | Where-Object { -not $prodRt.ContainsKey($_) })
    $prodOnly = @($prodRt.Keys | Where-Object { -not $devRt.ContainsKey($_) })

    $identical   = 0
    $commentOnly = [System.Collections.Generic.List[string]]::new()
    $different   = [System.Collections.Generic.List[object]]::new()
    $unreadable  = [System.Collections.Generic.List[object]]::new()

    foreach ($key in $shared) {
        $a = Get-Definition $devRt[$key]
        $b = Get-Definition $prodRt[$key]

        # ⛔ AN ABSENT BODY IS NOT AN IDENTICAL ONE. Two empty strings compare equal, and
        # a routine whose text failed to come back would otherwise land silently in the
        # "nothing to do" pile - the one class nobody re-reads.
        if ($null -eq $a -or $null -eq $b) {
            $side = if ($null -eq $a -and $null -eq $b) { 'neither export' }
                    elseif ($null -eq $a)               { 'the development export' }
                    else                                { 'the production export' }
            $unreadable.Add([pscustomobject]@{ Key = $key; Why = ("no body in {0}" -f $side) })
            continue
        }

        $sa = Split-Routine $a
        $sb = Split-Routine $b
        if (-not $sa.Ok -or -not $sb.Ok) {
            $why = if (-not $sa.Ok) { $sa.Reason } else { $sb.Reason }
            $unreadable.Add([pscustomobject]@{ Key = $key; Why = ("the tokenizer could not read it: {0}" -f $why) })
            continue
        }

        $na = ConvertTo-NormalizedWhitespace $sa.Code
        $nb = ConvertTo-NormalizedWhitespace $sb.Code

        if ($na -cne $nb) {
            $different.Add([pscustomobject]@{ Key = $key; Diff = (Get-FirstDifferingLine $na $nb) })
        }
        elseif ((Get-CommentSignature $sa.Comments) -cne (Get-CommentSignature $sb.Comments)) {
            $commentOnly.Add($key)
        }
        else {
            $identical++
        }
    }

    # -- the worklist ------------------------------------------------------
    Write-Host ''
    Write-Host ("  Nothing to do: {0} the same" -f (Format-Count $identical 'routine is' 'routines are'))
    Write-Host '    Same logic and same comments, once layout is set aside.'

    Write-Host ''
    if ($commentOnly.Count -eq 0) {
        Write-Host '  Comments differ, logic does not: none'
    }
    else {
        Write-Host ("  Comments differ, logic does not: {0}" -f (Format-Count $commentOnly.Count 'routine' 'routines'))
        Write-Host '    Read these before dismissing them. A commented-out WHERE clause or join is a'
        Write-Host '    real difference in behavior that this class - and only this class - hides.'
        foreach ($k in ($commentOnly | Sort-Object)) { Write-Host ("      {0}" -f $k) }
    }

    Write-Host ''
    if ($different.Count -eq 0) {
        Write-Host '  Logic differs: none'
    }
    else {
        Write-Host ("  Logic differs: {0}" -f (Format-Count $different.Count 'routine' 'routines'))
        Write-Host '    Line numbers are lines of the stripped body, not of the source file.'
        foreach ($d in ($different | Sort-Object Key)) {
            Write-Host ''
            Write-Host ("      {0}" -f $d.Key)
            if ($null -eq $d.Diff) {
                # The bodies differ but no line does: only reachable if one ends where the
                # other continues with nothing but line breaks, which normalization should
                # already have removed. Say so rather than print nothing.
                Write-Host '        the two bodies differ but no single line does'
            }
            else {
                Write-Host ("        line {0}" -f $d.Diff.Line)
                Write-Host ("          dev  {0}" -f (Format-Line $d.Diff.Dev))
                Write-Host ("          prod {0}" -f (Format-Line $d.Diff.Prod))
                if ($d.Diff.IndentOnly) {
                    Write-Host '          those two lines read the same: the difference is the indentation in'
                    Write-Host '          front of them, which Compare-WarehouseSchema.ps1 also counts'
                }
            }
        }
    }

    # -- what was not compared, and why ------------------------------------
    if ($unreadable.Count -gt 0 -or $devOnly.Count -gt 0 -or $prodOnly.Count -gt 0) {
        Write-Host ''
        Write-Host '  Not compared'
        if ($devOnly.Count -gt 0 -or $prodOnly.Count -gt 0) {
            # Summarized, not enumerated: a routine on one side only is a finding for
            # Compare-WarehouseSchema.ps1, which already reports it by name. This tool is
            # about the ones that exist on both sides.
            $parts = @()
            if ($devOnly.Count -gt 0)  { $parts += ("{0} only in dev"  -f (Format-Count $devOnly.Count  'routine' 'routines')) }
            if ($prodOnly.Count -gt 0) { $parts += ("{0} only in prod" -f (Format-Count $prodOnly.Count 'routine' 'routines')) }
            Write-Host ("    {0}. Compare-WarehouseSchema.ps1 names them." -f ($parts -join ', '))
        }
        foreach ($u in ($unreadable | Sort-Object Key)) {
            Write-Host ("    {0} - {1}" -f $u.Key, $u.Why)
        }
    }

    return [pscustomobject]@{ Ran = $true; Different = $different.Count }
}

# ---------------------------------------------------------------------------
# Run.
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host 'Routine logic comparison - comments stripped, layout normalized'

$loaded = Import-ScriptDom -Explicit $ScriptDomPath
if (-not $loaded) {
    Write-Host ''
    Write-Host 'The T-SQL tokenizer could not be loaded, and this script will not fall back to a'
    Write-Host 'regex. A regex cannot tell a comment from the text ''-- not a comment'' inside a'
    Write-Host 'string literal, so it would delete real code and then call the routine identical.'
    Write-Host ''
    Write-Host 'Build the validator once, which restores the assembly:'
    Write-Host '    dotnet build tools/qa-validator/QaValidator.csproj'
    Write-Host 'or pass -ScriptDomPath <Microsoft.SqlServer.TransactSql.ScriptDom.dll>.'
    exit 2
}
Write-Host ("  tokenizer {0}" -f $(if ($loaded -eq 'already loaded') { 'already loaded in this session' } else { Split-Path -Leaf $loaded }))

$pairs = @()
if ($PSCmdlet.ParameterSetName -eq 'Files') {
    $pairs += [pscustomobject]@{ Dev = $DevFile; Prod = $ProdFile }
}
else {
    if (-not (Test-Path -LiteralPath $Folder)) { Write-Host ''; Write-Host "Folder not found: $Folder"; exit 2 }
    $files = Get-ChildItem -LiteralPath $Folder -Filter '*.full.json' -File
    $stems = @($files | ForEach-Object { $_.Name -replace '^(dev|prod)-', '' } | Sort-Object -Unique)
    foreach ($stem in $stems) {
        $d = $files | Where-Object { $_.Name -eq "dev-$stem" }  | Select-Object -First 1
        $p = $files | Where-Object { $_.Name -eq "prod-$stem" } | Select-Object -First 1
        if ($d -and $p) { $pairs += [pscustomobject]@{ Dev = $d.FullName; Prod = $p.FullName } }
    }
    if ($pairs.Count -eq 0) {
        Write-Host ''
        Write-Host ("No dev-*.full.json / prod-*.full.json pair found in {0}." -f $Folder)
        Write-Host 'Export both environments with -IncludeDefinitions first. The .full.json files sit'
        Write-Host 'beside the ordinary exports; this script reads only the .full ones.'
        exit 2
    }
}

$totalDifferent = 0
$ranAny = $false
foreach ($pair in $pairs) {
    $result = Compare-Pair -DevPath $pair.Dev -ProdPath $pair.Prod
    if ($result.Ran) { $ranAny = $true; $totalDifferent += $result.Different }
}

Write-Host ''
if (-not $ranAny) { exit 2 }
exit $(if ($totalDifferent -gt 0) { 1 } else { 0 })
