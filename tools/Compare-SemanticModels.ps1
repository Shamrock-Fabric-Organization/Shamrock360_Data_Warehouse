<#
.SYNOPSIS
    Compares exported Fabric semantic models between development and production.

.DESCRIPTION
    A SEPARATE script from Compare-FabricEnvironment.ps1 on purpose. That one walks a
    pipeline's activities; a semantic model has no activities at all. It has tables,
    columns, measures, relationships, hierarchies, roles and M expressions, held as TMDL
    under definition\. The two share the export format and nothing else, so they share
    the transport (Export-FabricItemDefinition.ps1) and not the comparison.

    Expects the layout Export-FabricItemDefinition.ps1 -AllParts writes:

        fabric/semantic-models/
          dev/   Supply Chain and Manufacturing Model - DEV.json
                 Supply Chain and Manufacturing Model - DEV.parts/
                     .platform
                     definition/
                         database.tmdl  model.tmdl  relationships.tmdl
                         expressions.tmdl
                         tables/*.tmdl
                         roles/*.tmdl
          prod/  Finance Model.json
                 Finance Model.parts/ ...

    MOST MODELS EXIST ON ONE SIDE ONLY, AND THAT IS NOT A FINDING. Development
    typically holds a handful of models under active work while production holds the
    whole estate. Reporting each unpaired model as a problem buries the one comparison
    that matters underneath a page of noise. They are COUNTED AND NAMED in a block of
    their own, and they do not touch the verdict or the exit code.

    AND PAIRING IS NEVER GUESSED. A model may carry an environment suffix in its
    name, so the two sides often cannot pair on name alone. Pairing comes from an
    explicit list - compare-config.json or -Pair - or from a suffix rule the caller
    opts into with -DevSuffix. It is never inferred from a partial or fuzzy match: a
    wrong pairing produces a full diff of two unrelated models, which is worse than
    reporting both as unpaired. Whichever rule paired two models is printed beside the
    pair, so a pairing is never silent.

    A PROPERTY THAT CHANGES THE SAME WAY ON MANY OBJECTS IS ONE LINE, NOT MANY. On the
    Shamrock pair, sourceProviderType accounts for 231 of 300 column differences, because
    development reads OneLake and production reads the SQL analytics endpoint, and only the
    endpoint reports a provider type. That binding is intentional and the differences are
    REAL - they are counted, they reach the verdict, and they set the exit code exactly as
    every other finding does. What changes is only how they are printed: where the same
    property changes from the same value to the same value on ten or more objects, the
    names give way to a count and the span of tables they sit in. Fewer than that and the
    names are printed, because turning two into a count hides more than it saves. This is
    generic - it is the repetition that collapses, never a named property - and -Verbose
    restores every name.

    lineageTag IS NOT COMPARED. It is a GUID minted per object per deployment and
    carries no meaning: on a real Shamrock pair it differs on all 524 objects that
    otherwise match exactly. The same is true of the GUID that names a relationship, so
    relationships are keyed by the columns they join rather than by their name. This is
    identity plumbing, not a tolerated difference - nothing a reader could act on is set
    aside by it. The run states how many it skipped.

.PARAMETER Root
    The folder holding the dev and prod subfolders. Defaults to 'fabric\semantic-models'.

.PARAMETER DevName
    Name of the development subfolder under -Root. Defaults to 'dev'.

.PARAMETER ProdName
    Name of the production subfolder under -Root. Defaults to 'prod'.

.PARAMETER ConfigPath
    A compare-config.json holding explicit pairs, in the same shape and the same file
    Compare-FabricEnvironment.ps1 already reads, so the toolchain has ONE pairing
    convention rather than a second one invented here. Entries carrying a "type" are
    honored only when it is 'semantic-models'. Defaults to compare-config.json in the
    parent of -Root, and is optional.

        { "pairs": [ { "type": "semantic-models",
                       "dev": "Sales Model - DEV", "prod": "Sales Model",
                       "reason": "..." } ] }

.PARAMETER Pair
    One or more explicit pairs given on the command line as 'dev=prod', for a one-off
    run without editing the config. Takes precedence over -DevSuffix.

.PARAMETER DevSuffix
    A suffix the development copy carries and production does not, for example ' - DEV'.
    A dev model whose name ends with it pairs with the production model of the same name
    without it. OFF unless given, and every pairing it makes is labeled in the report as
    made by this rule, so it is never mistaken for a name that genuinely matched.

.PARAMETER Preview
    Print the pairing this run would use - which models pair, by which rule, and which
    are left on one side only - then stop without comparing anything. Pairing is the part
    that has to be right before any diff means anything.

.PARAMETER Detail
    Also print every differing property individually underneath its grouped finding. The
    default groups them, which is what keeps the report readable.

.PARAMETER CountsOnly
    Print the count of each finding without the name list underneath it. The names are
    printed by default and are never truncated, because a grouped finding is only safe
    while it stays lossless. Use this when a model is mid-build, the two sides differ by
    hundreds of objects, and the shape of the report is all you are after.

.EXAMPLE
    .\Compare-SemanticModels.ps1 -Root ..\fabric\semantic-models -DevSuffix ' - DEV' -Preview

.EXAMPLE
    .\Compare-SemanticModels.ps1 -Root ..\fabric\semantic-models -DevSuffix ' - DEV'

.EXAMPLE
    .\Compare-SemanticModels.ps1 -Pair 'Sales Model - DEV=Sales Model'

.OUTPUTS
    Exit code 0 when no PAIRED model differs, 1 otherwise. Models on one side only never
    set the exit code - on this estate they are the normal condition, and a script that
    always exits 1 stops being consulted.

.NOTES
    Requires PowerShell 7. Reads exports only; it never contacts Fabric and never writes.

    -Verbose prints the names behind every collapsed finding, so the summary can always be
    taken apart. It rides on the common parameter rather than a switch of its own: the
    parameter block of every script in this folder is checked against the client's
    parameter reference, and a capability that needs no new parameter does not put that
    reference out of step.
#>

[CmdletBinding()]
param(
    [string]   $Root = 'fabric\semantic-models',
    [string]   $DevName = 'dev',
    [string]   $ProdName = 'prod',
    [string]   $ConfigPath,
    [string[]] $Pair,
    [string]   $DevSuffix,
    [switch]   $Preview,
    [switch]   $Detail,
    [switch]   $CountsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# HOW MANY OBJECTS CHANGING IN EXACTLY THE SAME WAY COLLAPSE TO A COUNT.
# Ten is where a name list stops being scannable. The names here are table-qualified and
# run around thirty characters, so about three fit on a wrapped line: nine names is three
# lines, roughly the height of the finding they belong to, and past that the list is taller
# than everything around it and the findings that differ are pushed off the screen. Below
# the threshold the names are printed, because collapsing two into a count costs the reader
# more than it saves them.
#
# A CONSTANT RATHER THAN A PARAMETER, deliberately. The number is a decision about how this
# report reads, not something a run needs to vary, and nothing is lost by fixing it: the
# names never leave the report, they move to -Verbose.
$script:CollapseAt = 10

# The restated listing rides on -Verbose, matching Compare-WarehouseSchema.ps1. It is read
# from the preference rather than written through Write-Verbose because this whole report
# is Write-Host, and a listing split across two streams is worse than one that is not there.
$script:ListRestated = ($VerbosePreference -ne 'SilentlyContinue')

$script:SkippedIdentityTags = 0
$script:CollapsedGroups = 0
$script:CollapsedNames  = 0

# ===========================================================================
# TMDL PARSER
#
# TMDL is tab-indented. Structure indents one tab per level; the BODY of an
# expression (DAX or M) is indented one further level again, which is what lets a
# measure's multi-line DAX and its formatString sit under the same parent without
# ambiguity:
#
#     measure 'X' =
#             VAR a = 1          <- body, two levels below the measure
#             RETURN a
#
#         formatString: 0        <- property, one level below the measure
#
# So a header ending at '=' with nothing after it takes every following line
# indented at least two levels deeper as its body, and parsing resumes after it.
# ===========================================================================

function Get-TabDepth {
    param([string] $Line)
    $n = 0
    while ($n -lt $Line.Length -and $Line[$n] -eq "`t") { $n++ }
    return $n
}

function New-TmdlNode {
    param([string] $Keyword, [string] $Name, [string] $Value, [int] $Depth, [string] $Raw)
    return [pscustomobject]@{
        Keyword  = $Keyword
        Name     = $Name
        Value    = $Value
        Depth    = $Depth
        Raw      = $Raw
        Body     = $null
        Children = [System.Collections.ArrayList]::new()
    }
}

function ConvertFrom-TmdlHeader {
    # The ORDER of these patterns matters. 'dataType: int64' must be read as a
    # property before 'measure X = ...' is tried, or any value containing a colon
    # is misread as an object declaration.
    param([string] $Text, [int] $Depth)

    if ($Text -match '^([A-Za-z_][\w]*):\s*(.*)$') {
        return New-TmdlNode 'property' $Matches[1] $Matches[2].Trim() $Depth $Text
    }
    if ($Text -match "^([A-Za-z_][\w]*)\s+('[^']*'|[^\s=]+)\s*=\s*(.*)$") {
        return New-TmdlNode $Matches[1] ($Matches[2].Trim("'")) $Matches[3].Trim() $Depth $Text
    }
    if ($Text -match "^([A-Za-z_][\w]*)\s+('[^']*'|\S+)\s*$") {
        return New-TmdlNode $Matches[1] ($Matches[2].Trim("'")) '' $Depth $Text
    }
    if ($Text -match '^([A-Za-z_][\w]*)\s*=\s*(.*)$') {
        # changedProperty = Name : an assignment carrying no object name of its own.
        return New-TmdlNode 'property' $Matches[1] $Matches[2].Trim() $Depth $Text
    }
    if ($Text -match '^([A-Za-z_][\w]*)\s*$') {
        # A bare flag such as isHidden, or a container such as 'source'.
        return New-TmdlNode 'property' $Matches[1] 'true' $Depth $Text
    }
    return New-TmdlNode 'raw' $Text '' $Depth $Text
}

function Format-TmdlBody {
    # ONLY EXPORT ARTEFACTS MAY BE NORMALIZED, because the body is compared as text.
    # Both sides come out of the same exporter, so removing the common leading
    # indentation, trailing spaces and the fence markers is safe. Nothing INSIDE the
    # expression is touched: a DAX change that is only whitespace is still a DAX
    # change, and the client's standing rule is that project code is preserved as
    # written rather than tidied to suit us.
    param([string[]] $Lines)
    $fence = [string][char]96 + [char]96 + [char]96
    $out = @($Lines | ForEach-Object { $_.TrimEnd() })
    while ($out.Count -gt 0 -and $out[0].Trim() -eq '')  { $out = @($out[1..($out.Count - 1)]) }
    while ($out.Count -gt 0 -and $out[-1].Trim() -eq '') { $out = @($out[0..($out.Count - 2)]) }
    if ($out.Count -gt 0 -and $out[0].Trim()  -eq $fence) { $out = @($out[1..($out.Count - 1)]) }
    if ($out.Count -gt 0 -and $out[-1].Trim() -eq $fence) { $out = @($out[0..($out.Count - 2)]) }
    $filled = @($out | Where-Object { $_.Trim() -ne '' })
    if ($filled.Count -eq 0) { return '' }
    $minTabs = (@($filled | ForEach-Object { Get-TabDepth $_ }) | Measure-Object -Minimum).Minimum
    return (@($out | ForEach-Object {
        if ($_.Trim() -eq '') { '' } else { $_.Substring([Math]::Min($minTabs, (Get-TabDepth $_))) }
    }) -join "`n")
}

function ConvertFrom-Tmdl {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $lines = @(Get-Content -LiteralPath $Path)
    $fence = [string][char]96 + [char]96 + [char]96
    $top = [System.Collections.ArrayList]::new()
    $byDepth = @{}
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line.Trim() -eq '') { $i++; continue }
        $depth = Get-TabDepth $line
        $text  = $line.Substring($depth).TrimEnd()
        $node  = ConvertFrom-TmdlHeader $text $depth
        $i++

        # A header that ENDS at '=', with nothing after it but an optional fence, is
        # introducing a body rather than assigning a value on the line.
        if ($node.Raw -match ('=\s*(' + [regex]::Escape($fence) + ')?\s*$')) {
            $body = @()
            while ($i -lt $lines.Count) {
                $l = $lines[$i]
                if ($l.Trim() -eq '') {
                    $k = $i
                    while ($k -lt $lines.Count -and $lines[$k].Trim() -eq '') { $k++ }
                    if ($k -lt $lines.Count -and (Get-TabDepth $lines[$k]) -ge ($depth + 2)) {
                        $body += ''; $i++; continue
                    }
                    break
                }
                if ((Get-TabDepth $l) -lt ($depth + 2)) { break }
                $body += $l
                $i++
            }
            $node.Body = Format-TmdlBody $body
        }
        elseif ($node.Value -ne '' -and $node.Raw -match '=') {
            $node.Body = $node.Value
        }

        if ($depth -eq 0) { [void]$top.Add($node) }
        elseif ($byDepth.ContainsKey($depth - 1)) { [void]$byDepth[$depth - 1].Children.Add($node) }
        else { [void]$top.Add($node) }
        $byDepth[$depth] = $node
        foreach ($d in @($byDepth.Keys | Where-Object { $_ -gt $depth })) { $byDepth.Remove($d) }
    }
    return @($top)
}

function Get-TmdlChild {
    param($Node, [string] $Keyword, [string] $Name)
    foreach ($c in @($Node.Children)) {
        if ($c.Keyword -eq $Keyword -and (-not $Name -or $c.Name -eq $Name)) { return $c }
    }
    return $null
}

function Get-TmdlChildren {
    param($Node, [string] $Keyword)
    return @(@($Node.Children) | Where-Object { $_.Keyword -eq $Keyword })
}

function Get-TmdlValue {
    param($Node, [string] $Name)
    $c = Get-TmdlChild $Node 'property' $Name
    if ($c) { return $c.Value }
    return $null
}

# Properties that are identity plumbing rather than meaning. Excluded from every
# comparison and COUNTED so the exclusion is visible rather than assumed.
$script:IdentityProperties = @('lineageTag')

function Get-PropertyMap {
    # Every property of one object as a flat name -> value map, so no attribute can be
    # forgotten by the comparison simply because nobody thought to name it. Annotations
    # are prefixed so they group separately in the report; identity tags are counted out.
    param($Node, [string] $Prefix = '')
    $map = [ordered]@{}
    foreach ($c in @($Node.Children)) {
        if ($c.Keyword -eq 'property') {
            if ($script:IdentityProperties -contains $c.Name) { $script:SkippedIdentityTags++; continue }
            # A bare word carrying children is a CONTAINER, not a flag - 'source' under a
            # partition is where entityName and expressionSource live, and reading it as
            # the flag 'source = true' would drop the binding this report exists to check.
            if (@($c.Children).Count -gt 0) {
                $inner = Get-PropertyMap $c ($Prefix + $c.Name + '.')
                foreach ($k in $inner.Keys) { $map[$k] = $inner[$k] }
            }
            else { $map[$Prefix + $c.Name] = $c.Value }
        }
        elseif ($c.Keyword -eq 'annotation') {
            $map[$Prefix + 'annotation ' + $c.Name] = $c.Value
        }
    }
    return $map
}

# ===========================================================================
# READING ONE MODEL
# ===========================================================================

function Read-SemanticModel {
    param([string] $PartsDir, [string] $DisplayName)

    $def = Join-Path $PartsDir 'definition'
    if (-not (Test-Path -LiteralPath $def)) {
        throw ("No definition folder under {0}. Re-export with -AllParts." -f $PartsDir)
    }

    $model = [pscustomobject]@{
        Name          = $DisplayName
        Path          = $PartsDir
        Model         = [ordered]@{}
        Tables        = [ordered]@{}
        Relationships = [ordered]@{}
        Expressions   = [ordered]@{}
        Roles         = [ordered]@{}
    }

    # --- model.tmdl and database.tmdl -------------------------------------
    # Model-level annotations are kept WITH the model properties rather than sent to
    # the bookkeeping block: __PBI_TimeIntelligenceEnabled and PBI_QueryOrder are real
    # settings, and there are only a handful of them. Annotations further down, on a
    # column or a measure, are editor bookkeeping and are grouped as such.
    foreach ($n in @(ConvertFrom-Tmdl (Join-Path $def 'model.tmdl'))) {
        if ($n.Keyword -eq 'model') {
            $m = Get-PropertyMap $n
            foreach ($k in $m.Keys) { $model.Model[$k] = $m[$k] }
        }
        elseif ($n.Keyword -eq 'annotation') { $model.Model['annotation ' + $n.Name] = $n.Value }
    }
    foreach ($n in @(ConvertFrom-Tmdl (Join-Path $def 'database.tmdl'))) {
        if ($n.Keyword -eq 'database') {
            $m = Get-PropertyMap $n
            foreach ($k in $m.Keys) { $model.Model[$k] = $m[$k] }
        }
    }

    # --- expressions.tmdl -------------------------------------------------
    foreach ($n in @(ConvertFrom-Tmdl (Join-Path $def 'expressions.tmdl'))) {
        if ($n.Keyword -ne 'expression') { continue }
        $model.Expressions[$n.Name] = [pscustomobject]@{
            Name = $n.Name; Body = $n.Body; Props = (Get-PropertyMap $n)
        }
    }

    # --- relationships.tmdl -----------------------------------------------
    # KEYED BY THE COLUMNS THEY JOIN, NEVER BY NAME. The name is a GUID minted per
    # deployment, so keying on it would report every relationship as missing on one
    # side and extra on the other - a hundred findings describing nothing.
    foreach ($n in @(ConvertFrom-Tmdl (Join-Path $def 'relationships.tmdl'))) {
        if ($n.Keyword -ne 'relationship') { continue }
        $props = Get-PropertyMap $n
        $from = $(if ($props.Contains('fromColumn')) { $props['fromColumn'] } else { '?' })
        $to   = $(if ($props.Contains('toColumn'))   { $props['toColumn'] }   else { '?' })
        $key  = "$from -> $to"
        # A model may legitimately hold two relationships on the same columns, one of
        # them inactive. Numbering the duplicate keeps both instead of losing one.
        if ($model.Relationships.Contains($key)) {
            $seq = 2
            while ($model.Relationships.Contains("$key #$seq")) { $seq++ }
            $key = "$key #$seq"
        }
        $model.Relationships[$key] = [pscustomobject]@{ Name = $key; Props = $props }
    }

    # --- roles ------------------------------------------------------------
    $rolesDir = Join-Path $def 'roles'
    if (Test-Path -LiteralPath $rolesDir) {
        foreach ($f in @(Get-ChildItem -LiteralPath $rolesDir -Filter '*.tmdl' -File)) {
            foreach ($n in @(ConvertFrom-Tmdl $f.FullName)) {
                if ($n.Keyword -ne 'role') { continue }
                $perms = [ordered]@{}
                foreach ($p in (Get-TmdlChildren $n 'tablePermission')) { $perms[$p.Name] = $p.Body }
                $model.Roles[$n.Name] = [pscustomobject]@{
                    Name = $n.Name; Props = (Get-PropertyMap $n); Permissions = $perms
                }
            }
        }
    }

    # --- tables -----------------------------------------------------------
    $tablesDir = Join-Path $def 'tables'
    if (Test-Path -LiteralPath $tablesDir) {
        foreach ($f in @(Get-ChildItem -LiteralPath $tablesDir -Filter '*.tmdl' -File)) {
            foreach ($n in @(ConvertFrom-Tmdl $f.FullName)) {
                if ($n.Keyword -ne 'table') { continue }

                $cols = [ordered]@{}
                foreach ($c in (Get-TmdlChildren $n 'column')) {
                    $cols[$c.Name] = [pscustomobject]@{
                        Name = $c.Name; Body = $c.Body; Props = (Get-PropertyMap $c)
                    }
                }
                $meas = [ordered]@{}
                foreach ($c in (Get-TmdlChildren $n 'measure')) {
                    $meas[$c.Name] = [pscustomobject]@{
                        Name = $c.Name; Body = $c.Body; Props = (Get-PropertyMap $c)
                    }
                }
                $hier = [ordered]@{}
                foreach ($c in (Get-TmdlChildren $n 'hierarchy')) {
                    # LEVEL ORDER IS THE HIERARCHY. Year above Quarter above Month is the
                    # whole meaning of the object, so the levels are compared as an ordered
                    # sequence rather than as a set.
                    $levels = @(@(Get-TmdlChildren $c 'level') | ForEach-Object {
                        '{0}({1})' -f $_.Name, (Get-TmdlValue $_ 'column')
                    })
                    $hier[$c.Name] = [pscustomobject]@{
                        Name = $c.Name; Props = (Get-PropertyMap $c); Levels = ($levels -join ' > ')
                    }
                }
                $parts = [ordered]@{}
                foreach ($c in (Get-TmdlChildren $n 'partition')) {
                    $parts[$c.Name] = [pscustomobject]@{
                        Name = $c.Name; Kind = $c.Value; Props = (Get-PropertyMap $c)
                    }
                }

                $model.Tables[$n.Name] = [pscustomobject]@{
                    Name = $n.Name; Props = (Get-PropertyMap $n)
                    Columns = $cols; Measures = $meas; Hierarchies = $hier; Partitions = $parts
                }
            }
        }
    }

    return $model
}

# ===========================================================================
# COMPARISON
#
# Findings carry a GROUP (which section of the report they belong to), a KIND, the
# object they are about, and the two values. Nothing is decided at the point a
# finding is made - grouping and aggregation happen once, at render time, so every
# section aggregates the same way.
# ===========================================================================

$script:Findings = [System.Collections.ArrayList]::new()

function Add-Finding {
    param([string] $Group, [string] $Kind, [string] $Object,
          [string] $Attribute = '', $Dev = $null, $Prod = $null)
    [void]$script:Findings.Add([pscustomobject]@{
        Group = $Group; Kind = $Kind; Object = $Object
        Attribute = $Attribute; Dev = $Dev; Prod = $Prod
    })
}

function Get-MapValue {
    param($Map, [string] $Key)
    if ($Map -and $Map.Contains($Key)) { return [string]$Map[$Key] }
    return $null
}

function Compare-PropertyMaps {
    # Compares EVERY property either side carries, rather than a list of attributes
    # someone remembered to name. A property added to TMDL by a future Fabric release
    # is then compared automatically instead of being silently ignored.
    param($DevMap, $ProdMap, [string] $Group, [string] $Object, [string] $BookkeepingGroup)
    $keys = @(@($DevMap.Keys) + @($ProdMap.Keys) | Sort-Object -Unique)
    foreach ($k in $keys) {
        $d = Get-MapValue $DevMap $k
        $p = Get-MapValue $ProdMap $k
        if ($d -eq $p) { continue }
        # An annotation or a changedProperty below model level records what the Power BI
        # editor did, not what the model means. It is still compared and still counted;
        # it is only rendered in its own block so it cannot bury the rest.
        $g = $Group
        if ($BookkeepingGroup -and ($k -eq 'changedProperty' -or $k -like 'annotation *')) {
            $g = $BookkeepingGroup
        }
        Add-Finding $g 'DIFFERS' $Object $k $d $p
    }
}

function Compare-Collection {
    # The presence half of every comparison: what is on one side only. Returns the keys
    # present on BOTH, for the caller to compare in detail.
    # -Prefix qualifies the name a presence finding is reported under. Without it a
    # column reported as PROD ONLY carries its bare name, and 'Amount' says nothing
    # about which of thirty tables gained it.
    param($Dev, $Prod, [string] $Group, [string] $Prefix = '')
    foreach ($k in @($Dev.Keys)) {
        if (-not $Prod.Contains($k)) { Add-Finding $Group 'DEV ONLY' ($Prefix + $k) }
    }
    foreach ($k in @($Prod.Keys)) {
        if (-not $Dev.Contains($k)) { Add-Finding $Group 'PROD ONLY' ($Prefix + $k) }
    }
    return @(@($Dev.Keys) | Where-Object { $Prod.Contains($_) })
}

function Compare-SemanticModel {
    param($Dev, $Prod)

    # --- model level ------------------------------------------------------
    Compare-PropertyMaps $Dev.Model $Prod.Model 'MODEL PROPERTIES' '(model)' ''

    # --- source binding ---------------------------------------------------
    # THE HIGHEST-VALUE CHECK IN THIS SCRIPT. The expression is what decides which
    # warehouse the model reads. Two models can match table for table and still be
    # wrong if production is pointed at development.
    $common = Compare-Collection $Dev.Expressions $Prod.Expressions 'SOURCE BINDING' 'expression '
    foreach ($k in $common) {
        if ($Dev.Expressions[$k].Body -ne $Prod.Expressions[$k].Body) {
            Add-Finding 'SOURCE BINDING' 'DIFFERS' ("expression " + $k) 'M script' `
                $Dev.Expressions[$k].Body $Prod.Expressions[$k].Body
        }
        Compare-PropertyMaps $Dev.Expressions[$k].Props $Prod.Expressions[$k].Props `
            'SOURCE BINDING' ("expression " + $k) ''
    }

    # --- relationships ----------------------------------------------------
    $common = Compare-Collection $Dev.Relationships $Prod.Relationships 'RELATIONSHIPS'
    foreach ($k in $common) {
        Compare-PropertyMaps $Dev.Relationships[$k].Props $Prod.Relationships[$k].Props `
            'RELATIONSHIPS' $k 'EDITOR BOOKKEEPING'
    }

    # --- roles ------------------------------------------------------------
    $common = Compare-Collection $Dev.Roles $Prod.Roles 'ROLES'
    foreach ($k in $common) {
        Compare-PropertyMaps $Dev.Roles[$k].Props $Prod.Roles[$k].Props 'ROLES' $k 'EDITOR BOOKKEEPING'
        $dp = $Dev.Roles[$k].Permissions
        $pp = $Prod.Roles[$k].Permissions
        foreach ($t in @(@($dp.Keys) + @($pp.Keys) | Sort-Object -Unique)) {
            $d = Get-MapValue $dp $t
            $p = Get-MapValue $pp $t
            if ($d -ne $p) { Add-Finding 'ROLES' 'DIFFERS' ("$k / $t") 'row filter' $d $p }
        }
    }

    # --- tables, and everything inside them -------------------------------
    $commonTables = Compare-Collection $Dev.Tables $Prod.Tables 'TABLES'
    foreach ($t in $commonTables) {
        $dt = $Dev.Tables[$t]
        $pt = $Prod.Tables[$t]
        Compare-PropertyMaps $dt.Props $pt.Props 'TABLES' $t 'EDITOR BOOKKEEPING'

        foreach ($c in (Compare-Collection $dt.Columns $pt.Columns 'COLUMNS' "$t.")) {
            Compare-PropertyMaps $dt.Columns[$c].Props $pt.Columns[$c].Props `
                'COLUMNS' "$t.$c" 'EDITOR BOOKKEEPING'
            if ($dt.Columns[$c].Body -ne $pt.Columns[$c].Body) {
                Add-Finding 'COLUMNS' 'DIFFERS' "$t.$c" 'DAX expression' `
                    $dt.Columns[$c].Body $pt.Columns[$c].Body
            }
        }
        foreach ($m in (Compare-Collection $dt.Measures $pt.Measures 'MEASURES' "$t.")) {
            Compare-PropertyMaps $dt.Measures[$m].Props $pt.Measures[$m].Props `
                'MEASURES' "$t.$m" 'EDITOR BOOKKEEPING'
            if ($dt.Measures[$m].Body -ne $pt.Measures[$m].Body) {
                Add-Finding 'MEASURES' 'DIFFERS' "$t.$m" 'DAX expression' `
                    $dt.Measures[$m].Body $pt.Measures[$m].Body
            }
        }
        foreach ($h in (Compare-Collection $dt.Hierarchies $pt.Hierarchies 'HIERARCHIES' "$t.")) {
            if ($dt.Hierarchies[$h].Levels -ne $pt.Hierarchies[$h].Levels) {
                Add-Finding 'HIERARCHIES' 'DIFFERS' "$t.$h" 'levels' `
                    $dt.Hierarchies[$h].Levels $pt.Hierarchies[$h].Levels
            }
            Compare-PropertyMaps $dt.Hierarchies[$h].Props $pt.Hierarchies[$h].Props `
                'HIERARCHIES' "$t.$h" 'EDITOR BOOKKEEPING'
        }
        # A partition's source is the per-table half of the source binding, so it is
        # reported in that section rather than under the table it happens to sit on.
        foreach ($p in (Compare-Collection $dt.Partitions $pt.Partitions 'SOURCE BINDING' "$t partition ")) {
            Compare-PropertyMaps $dt.Partitions[$p].Props $pt.Partitions[$p].Props `
                'SOURCE BINDING' "$t partition" 'EDITOR BOOKKEEPING'
        }
    }
}

# ===========================================================================
# REPORT
#
# EVERY LINE EARNS ITS PLACE. Findings are aggregated by KIND, never listed one per
# occurrence, because two hundred rows that each say the same thing hide the three
# that do not. Name lists WRAP and are never capped: grouping is only safe while it
# stays lossless, and a list cut short at "and 39 more" moves real names out of the
# report. Nothing scrolls sideways.
# ===========================================================================

function Format-Count {
    param([int] $N, [string] $Singular, [string] $Plural)
    return ('{0} {1}' -f $N, $(if ($N -eq 1) { $Singular } else { $Plural }))
}

function Format-NameList {
    param([string[]] $Names, [string] $Lead = '      ', [int] $Width = 92)
    $indent = ' ' * $Lead.Length
    $lines = @()
    $current = $Lead
    $first = $true
    foreach ($n in @($Names)) {
        $piece = $(if ($first) { $n } else { ", $n" })
        if (-not $first -and ($current.Length + $piece.Length) -gt $Width) {
            $lines += ($current + ',')
            $current = $indent + $n
        }
        else { $current += $piece }
        $first = $false
    }
    if ($current.Trim()) { $lines += $current }
    return $lines
}

function Format-Wrap {
    # Prose, wrapped on WORD boundaries. Distinct from Format-NameList, which joins its
    # items with commas - running a sentence through that one puts a comma between every
    # word, which is how a note explaining the report became the least readable line in it.
    param([string] $Text, [string] $Lead = '    ', [int] $Width = 94)
    $lines = @()
    $current = $Lead
    foreach ($w in @($Text -split '\s+' | Where-Object { $_ })) {
        if ($current.Trim() -and ($current.Length + 1 + $w.Length) -gt $Width) {
            $lines += $current
            $current = $Lead + $w
        }
        else { $current = $(if ($current.Trim()) { $current + ' ' + $w } else { $current + $w }) }
    }
    if ($current.Trim()) { $lines += $current }
    return $lines
}

function Format-Short {
    # A value shown inline. A multi-line DAX or M script is NEVER printed inline - the
    # whole body goes under -Detail, where it has the room to be read.
    param($Value)
    if ($null -eq $Value) { return '(absent)' }
    $s = [string]$Value
    if ($s -eq '') { return '(empty)' }
    if ($s.Contains("`n")) { return ('({0} lines)' -f (@($s -split "`n").Count)) }
    return $s
}

# The noun a section counts in. A section name is a heading, not a word that survives
# being singularized by rule - HIERARCHIES does not, and a report that says '14 hierarchys'
# has stopped being worth reading. Sections whose objects are of mixed kinds count
# 'objects', which is true rather than convenient.
$script:SectionNoun = @{
    'COLUMNS'       = @('column', 'columns')
    'MEASURES'      = @('measure', 'measures')
    'TABLES'        = @('table', 'tables')
    'RELATIONSHIPS' = @('relationship', 'relationships')
    'HIERARCHIES'   = @('hierarchy', 'hierarchies')
    'ROLES'         = @('role', 'roles')
}

function Format-Repetition {
    # ONE LINE STANDING IN FOR A LIST OF NAMES THAT ALL SAY THE SAME THING. It prints the
    # two facts a reader can act on when the alternative is fifty-eight names: how many
    # objects changed, and how many tables they are spread across. A count confined to one
    # table is a different situation from the same count spread over nine, and that is the
    # distinction the names were being read for.
    #
    # GENERIC BY CONSTRUCTION - it is handed the names of a group that already shares one
    # property and one before-and-after, and it never asks which property that was. The
    # property that buries the next report will not be the one that buried this one.
    param([string[]] $Names, [string] $Section, [string] $Lead = '      ')
    $names = @($Names)
    $pair = $(if ($script:SectionNoun.ContainsKey($Section)) { $script:SectionNoun[$Section] }
              else { @('object', 'objects') })
    $text = Format-Count $names.Count $pair[0] $pair[1]
    # A table-qualified name carries its parent before the last dot. The span is stated only
    # where EVERY name in the group is qualified; inferring a parent for a name that has none
    # would be a guess, and the count on its own is still true.
    $unqualified = @($names | Where-Object { -not $_.Contains('.') })
    if ($names.Count -gt 0 -and $unqualified.Count -eq 0) {
        $parents = @($names | ForEach-Object { $_.Substring(0, $_.LastIndexOf('.')) } |
                     Sort-Object -Unique)
        $text += ' across ' + (Format-Count $parents.Count 'table' 'tables')
    }
    return ($Lead + $text)
}

function Write-Body {
    param([string] $Label, $Value)
    Write-Host ("        {0}:" -f $Label) -ForegroundColor DarkGray
    if ($null -eq $Value) { Write-Host '          (absent)' -ForegroundColor DarkGray; return }
    foreach ($l in @(([string]$Value) -split "`n")) {
        Write-Host ('          ' + $l) -ForegroundColor DarkGray
    }
}

function Write-Section {
    param([string] $Title, $Items, [string] $Note = '')

    $these = @($Items)
    if ($these.Count -eq 0) { return }

    Write-Host ''
    Write-Host ("  {0} - {1}" -f $Title, (Format-Count $these.Count 'difference' 'differences')) `
        -ForegroundColor Cyan
    if ($Note) {
        foreach ($l in (Format-Wrap $Note '    ' 94)) { Write-Host $l -ForegroundColor DarkGray }
    }

    # --- on one side only -------------------------------------------------
    # One line per side, then the names. Twenty-six tables that exist only in
    # production is ONE fact about the model, not twenty-six findings to read.
    foreach ($kind in @('DEV ONLY', 'PROD ONLY')) {
        $side = @($these | Where-Object { $_.Kind -eq $kind })
        if ($side.Count -eq 0) { continue }
        $where = $(if ($kind -eq 'DEV ONLY') { $script:DevLabel } else { $script:ProdLabel })
        Write-Host ("    in {0} only - {1}" -f $where, (Format-Count $side.Count 'object' 'objects'))
        if ($script:ShowLists) {
            foreach ($l in (Format-NameList @($side | ForEach-Object { $_.Object } | Sort-Object))) {
                Write-Host $l -ForegroundColor DarkGray
            }
        }
    }

    # --- differing attributes, grouped ------------------------------------
    # Grouped by the ATTRIBUTE and the two VALUES, so one line describes every object
    # that changed in the same way. Bodies group on the attribute and object instead,
    # because two DAX scripts are never the same change twice.
    $diffs = @($these | Where-Object { $_.Kind -eq 'DIFFERS' })
    if ($diffs.Count -eq 0) { return }

    $sep = [string][char]1
    $groups = @($diffs | Group-Object {
        $dv = [string]$_.Dev; $pv = [string]$_.Prod
        if ($dv.Contains("`n") -or $pv.Contains("`n")) { $_.Attribute + $sep + $_.Object }
        else { $_.Attribute + $sep + $dv + $sep + $pv }
    } | Sort-Object @{ Expression = { $_.Count }; Descending = $true }, Name)

    foreach ($g in $groups) {
        $f = $g.Group[0]
        $dv = Format-Short $f.Dev
        $pv = Format-Short $f.Prod
        $tally = $(if ($g.Count -gt 1) { 'x' + $g.Count } else { '' })

        # ONE LINE WHERE IT FITS, TWO WHERE IT DOES NOT - and NEVER a truncated value.
        # A collation or an annotation cut off at the column width reads as a difference
        # nobody can act on, which is the clutter this report is written against. The
        # attribute and the count stay on the first line so the shape of the section is
        # still scannable down the left edge; only the values move.
        $oneLine = "    {0,-26} {1,-24} -> {2,-24} {3}" -f $f.Attribute, $dv, $pv, $tally
        if ($oneLine.TrimEnd().Length -le 94) {
            Write-Host $oneLine.TrimEnd()
        }
        else {
            Write-Host ("    {0} {1}" -f $f.Attribute, $tally).TrimEnd()
            foreach ($l in (Format-Wrap ("{0}  ->  {1}" -f $dv, $pv) '      ' 94)) {
                Write-Host $l
            }
        }
        # Not under -Detail: that block names every object as it prints its two values,
        # and printing the list as well says each name twice.
        if ($script:ShowLists -and -not $Detail) {
            $names = @($g.Group | ForEach-Object { $_.Object } | Sort-Object)
            # REPETITION COLLAPSES, THE FINDING DOES NOT. Every one of these objects is
            # still counted in the section total, in the run total and in the exit code.
            # Only the name list gives way, and only to a line that says how much it stood
            # for - so the arithmetic still closes on the page.
            if ($names.Count -ge $script:CollapseAt) {
                Write-Host (Format-Repetition $names $Title) -ForegroundColor DarkGray
                $script:CollapsedGroups++
                $script:CollapsedNames += $names.Count
                if ($script:ListRestated) {
                    foreach ($l in (Format-NameList $names)) { Write-Host $l -ForegroundColor DarkGray }
                }
            }
            else {
                foreach ($l in (Format-NameList $names)) { Write-Host $l -ForegroundColor DarkGray }
            }
        }
        if ($Detail) {
            foreach ($item in @($g.Group)) {
                Write-Host ("      {0}" -f $item.Object) -ForegroundColor DarkGray
                Write-Body $script:DevLabel  $item.Dev
                Write-Body $script:ProdLabel $item.Prod
            }
        }
    }
}

# ===========================================================================
# PAIRING, THEN THE RUN
# ===========================================================================

$script:DevLabel  = $DevName
$script:ProdLabel = $ProdName
$script:ShowLists = -not $CountsOnly

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Root folder not found: $Root. Run this from the repository root, or pass -Root."
}
$rootFull = (Resolve-Path -LiteralPath $Root).Path
$devDir   = Join-Path $rootFull $DevName
$prodDir  = Join-Path $rootFull $ProdName
foreach ($d in @($devDir, $prodDir)) {
    if (-not (Test-Path -LiteralPath $d)) { throw "Environment folder not found: $d" }
}

function Get-ModelFolders {
    # One entry per exported model: display name -> the .parts folder holding its
    # definition. The folder name already carries the display name, but .platform is
    # the authority on it and is read wherever it is present.
    param([string] $Dir)
    $out = [ordered]@{}
    foreach ($p in @(Get-ChildItem -LiteralPath $Dir -Directory -Filter '*.parts' | Sort-Object Name)) {
        $name = $p.Name -replace '\.parts$', ''
        $plat = Join-Path $p.FullName '.platform'
        if (Test-Path -LiteralPath $plat) {
            try {
                $j = Get-Content -LiteralPath $plat -Raw | ConvertFrom-Json
                if ($j.metadata -and $j.metadata.displayName) { $name = [string]$j.metadata.displayName }
            }
            catch { }
        }
        $out[$name] = $p.FullName
    }
    return $out
}

$devModels  = Get-ModelFolders $devDir
$prodModels = Get-ModelFolders $prodDir

# --- build the pairing ------------------------------------------------------
# Explicit list first, then the opt-in suffix rule, then identical names. Never a
# partial or fuzzy match: a wrong pairing produces a full diff of two unrelated
# models, which is worse than reporting both as unpaired.
$pairs = [ordered]@{}

if (-not $ConfigPath) { $ConfigPath = Join-Path (Split-Path -Parent $rootFull) 'compare-config.json' }
$configUsed = $null
if (Test-Path -LiteralPath $ConfigPath) {
    try { $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json }
    catch { throw "compare-config.json is not valid JSON ($ConfigPath): $($_.Exception.Message)" }
    if ($config -and $config.PSObject.Properties.Name -contains 'pairs') {
        foreach ($p in @($config.pairs)) {
            if ($p.PSObject.Properties.Name -contains 'type' -and $p.type -and
                $p.type -ne 'semantic-models') { continue }
            if (-not ($p.PSObject.Properties.Name -contains 'dev' -and
                      $p.PSObject.Properties.Name -contains 'prod')) { continue }
            $configUsed = $ConfigPath
            $pairs[[string]$p.dev] = [pscustomobject]@{
                Prod = [string]$p.prod
                Rule = 'compare-config.json'
                Reason = $(if ($p.PSObject.Properties.Name -contains 'reason') { [string]$p.reason } else { '' })
            }
        }
    }
}

foreach ($spec in @($Pair)) {
    if (-not $spec) { continue }
    $i = $spec.IndexOf('=')
    if ($i -lt 1) { throw "-Pair expects 'dev=prod'. Received: $spec" }
    $pairs[$spec.Substring(0, $i).Trim()] = [pscustomobject]@{
        Prod = $spec.Substring($i + 1).Trim(); Rule = '-Pair'; Reason = ''
    }
}

if ($DevSuffix) {
    foreach ($d in @($devModels.Keys)) {
        if ($pairs.Contains($d)) { continue }
        if (-not $d.EndsWith($DevSuffix)) { continue }
        $candidate = $d.Substring(0, $d.Length - $DevSuffix.Length)
        # Only where the stripped name is a model that ACTUALLY EXISTS in production. A
        # suffix rule that invented a counterpart would be a guess wearing a rule's hat.
        if ($prodModels.Contains($candidate)) {
            $pairs[$d] = [pscustomobject]@{
                Prod = $candidate; Rule = ("-DevSuffix '{0}'" -f $DevSuffix); Reason = ''
            }
        }
    }
}

foreach ($d in @($devModels.Keys)) {
    if ($pairs.Contains($d)) { continue }
    if ($prodModels.Contains($d)) {
        $pairs[$d] = [pscustomobject]@{ Prod = $d; Rule = 'same name'; Reason = '' }
    }
}

# A configured pair naming a model that was never exported is STATED, not silently
# dropped - a pair that quietly does nothing is how a model stops being checked.
$brokenPairs = @()
foreach ($d in @($pairs.Keys)) {
    $missing = @()
    if (-not $devModels.Contains($d))               { $missing += "$DevName '$d'" }
    if (-not $prodModels.Contains($pairs[$d].Prod)) { $missing += "$ProdName '$($pairs[$d].Prod)'" }
    if ($missing.Count -gt 0) {
        $brokenPairs += [pscustomobject]@{
            Dev = $d
            Text = ('{0} -> {1} : no export for {2}' -f $d, $pairs[$d].Prod, ($missing -join ' and '))
        }
    }
}
foreach ($b in $brokenPairs) { $pairs.Remove($b.Dev) }

$pairedProd = @(@($pairs.Values) | ForEach-Object { $_.Prod })
$devOnly  = @(@($devModels.Keys)  | Where-Object { -not $pairs.Contains($_) } | Sort-Object)
$prodOnly = @(@($prodModels.Keys) | Where-Object { $pairedProd -notcontains $_ } | Sort-Object)

Write-Host ''
Write-Host ('=' * 94)
Write-Host ("SEMANTIC MODEL COMPARISON - {0} against {1}" -f $DevName, $ProdName)
Write-Host ('=' * 94)
Write-Host ("  {0}" -f $rootFull)
Write-Host ("  {0} model(s) in {1}, {2} in {3}, {4} paired" -f
    $devModels.Count, $DevName, $prodModels.Count, $ProdName, $pairs.Count)
if ($configUsed) { Write-Host ("  pairs read from {0}" -f $configUsed) }

foreach ($d in @($pairs.Keys)) {
    Write-Host ("    {0}  ->  {1}" -f $d, $pairs[$d].Prod) -ForegroundColor Green
    Write-Host ("        paired by {0}" -f $pairs[$d].Rule) -ForegroundColor DarkGray
    if ($pairs[$d].Reason) {
        foreach ($l in (Format-Wrap $pairs[$d].Reason '        ' 94)) {
            Write-Host $l -ForegroundColor DarkGray
        }
    }
}

if ($brokenPairs.Count -gt 0) {
    Write-Host ''
    Write-Host ("  {0} configured pair(s) name a model with no export:" -f $brokenPairs.Count) `
        -ForegroundColor Yellow
    foreach ($b in $brokenPairs) { Write-Host ("    {0}" -f $b.Text) -ForegroundColor Yellow }
}

if ($pairs.Count -eq 0) {
    Write-Host ''
    Write-Host '  NOTHING PAIRED, so nothing was compared.' -ForegroundColor Yellow
    # A SUGGESTION, NEVER AN ACTION. Naming the pairing that WOULD be made leaves the
    # decision with the reader; making it silently is the mistake this script exists to
    # avoid, and a suffix that looks obvious is still a guess until somebody confirms it.
    if (-not $DevSuffix) {
        $hint = @()
        foreach ($d in @($devModels.Keys)) {
            foreach ($p in @($prodModels.Keys)) {
                if ($d.StartsWith($p) -and $d.Length -gt $p.Length) {
                    $hint += ("    -DevSuffix '{0}' would pair '{1}' with '{2}'" -f
                              $d.Substring($p.Length), $d, $p)
                }
            }
        }
        if ($hint.Count -gt 0) {
            Write-Host '  A suffix rule would pair these. Nothing pairs until you pass it:' `
                -ForegroundColor Yellow
            foreach ($h in @($hint | Sort-Object -Unique)) { Write-Host $h -ForegroundColor Yellow }
        }
    }
}

if ($Preview) {
    Write-Host ''
    Write-Host ("  {0} in {1} only, {2} in {3} only." -f
        $devOnly.Count, $DevName, $prodOnly.Count, $ProdName)
    Write-Host '  Preview only - nothing compared.' -ForegroundColor Yellow
    Write-Host ''
    exit 0
}

# --- compare each pair ------------------------------------------------------
$sectionOrder = @(
    @{ Title = 'SOURCE BINDING'
       Note  = 'Which warehouse the model reads. The most consequential thing here: two models can match table for table and still be wrong if production is pointed at development.' }
    @{ Title = 'MODEL PROPERTIES'; Note = '' }
    @{ Title = 'TABLES'; Note = '' }
    @{ Title = 'COLUMNS'; Note = '' }
    @{ Title = 'MEASURES'; Note = '' }
    @{ Title = 'RELATIONSHIPS'
       Note  = 'Keyed by the columns joined, because the name of a relationship is a per-deployment GUID.' }
    @{ Title = 'HIERARCHIES'; Note = '' }
    @{ Title = 'ROLES'; Note = '' }
    @{ Title = 'EDITOR BOOKKEEPING'
       Note  = 'Annotations and changedProperty below model level - what the Power BI editor recorded about its own session, not what the model means. Counted and shown, never hidden.' }
)

$modelsWithDifferences = 0
$totalDifferences = 0

foreach ($d in @($pairs.Keys)) {
    $script:Findings = [System.Collections.ArrayList]::new()
    $script:CollapsedGroups = 0
    $script:CollapsedNames  = 0
    $devModel  = Read-SemanticModel $devModels[$d] $d
    $prodModel = Read-SemanticModel $prodModels[$pairs[$d].Prod] $pairs[$d].Prod
    Compare-SemanticModel $devModel $prodModel

    Write-Host ''
    Write-Host ('-' * 94)
    Write-Host ("{0}  ->  {1}" -f $d, $pairs[$d].Prod)
    Write-Host ('-' * 94)
    Write-Host ("  {0}: {1} table(s), {2} relationship(s), {3} measure(s)" -f $DevName,
        $devModel.Tables.Count, $devModel.Relationships.Count,
        (@(@($devModel.Tables.Values) | ForEach-Object { $_.Measures.Count } |
           Measure-Object -Sum).Sum)) -ForegroundColor DarkGray
    Write-Host ("  {0}: {1} table(s), {2} relationship(s), {3} measure(s)" -f $ProdName,
        $prodModel.Tables.Count, $prodModel.Relationships.Count,
        (@(@($prodModel.Tables.Values) | ForEach-Object { $_.Measures.Count } |
           Measure-Object -Sum).Sum)) -ForegroundColor DarkGray

    $all = @($script:Findings)
    if ($all.Count -eq 0) {
        Write-Host '  No differences.' -ForegroundColor Green
    }
    else {
        foreach ($s in $sectionOrder) {
            Write-Section $s.Title @($all | Where-Object { $_.Group -eq $s.Title }) $s.Note
        }
        # WHAT WAS COLLAPSED IS STATED, ONCE. A summary nobody is told about is a summary
        # nobody can check, and the pointer belongs here rather than on each collapsed line,
        # where eleven copies of the same advice would be the clutter this is undoing.
        if ($script:CollapsedGroups -gt 0) {
            Write-Host ''
            $tail = $(if ($script:ListRestated) { 'Every name is listed under each of them above.' }
                      else { 'Re-run with -Verbose to see every name.' })
            $note = ('{0} above each stood for a group of objects changing in exactly the same way - {1} objects in all, printed as a count rather than a name list. They are counted in every total and in the exit code. {2}' -f
                (Format-Count $script:CollapsedGroups 'finding' 'findings'), $script:CollapsedNames, $tail)
            foreach ($l in (Format-Wrap $note '  ' 94)) { Write-Host $l -ForegroundColor DarkGray }
        }
        $modelsWithDifferences++
    }
    $totalDifferences += $all.Count
}

# --- models on one side only -------------------------------------------------
# LAST, AND OUT OF THE WAY. Development holds a handful of models under active work
# while production holds the whole estate, so this block is the normal condition and
# not a finding. It is stated once, with every name, and it never reaches the verdict.
Write-Host ''
Write-Host ('=' * 94)
Write-Host ("MODELS ON ONE SIDE ONLY - {0}" -f
    (Format-Count ($devOnly.Count + $prodOnly.Count) 'model' 'models')) -ForegroundColor DarkCyan
Write-Host ('=' * 94)
Write-Host '  Not compared, and they do not affect the verdict or the exit code. What to look'
Write-Host '  for here is a model you expected to be promoted and do not see, or one in'
Write-Host '  production that nobody remembers deploying.'
foreach ($side in @(
    @{ Names = $devOnly;  Label = "$DevName only" }
    @{ Names = $prodOnly; Label = "$ProdName only" })) {
    Write-Host ''
    Write-Host ("  {0} - {1}" -f $side.Label, (Format-Count @($side.Names).Count 'model' 'models'))
    if (@($side.Names).Count -gt 0) {
        foreach ($l in (Format-NameList $side.Names '    ' 92)) { Write-Host $l -ForegroundColor DarkGray }
    }
}

# --- verdict -----------------------------------------------------------------
Write-Host ''
Write-Host ('=' * 94)
if ($pairs.Count -eq 0) {
    Write-Host 'NO PAIRED MODELS - nothing was compared.' -ForegroundColor Yellow
    Write-Host ('=' * 94)
    Write-Host '  Pair them in compare-config.json, with -Pair, or with -DevSuffix, then run again.'
    Write-Host ''
    exit 1
}
elseif ($modelsWithDifferences -eq 0) {
    Write-Host ("EVERY PAIRED MODEL MATCHES - {0} compared." -f
        (Format-Count $pairs.Count 'model' 'models')) -ForegroundColor Green
    Write-Host ('=' * 94)
}
else {
    Write-Host ("{0} of {1} paired model(s) differ - {2}." -f
        $modelsWithDifferences, $pairs.Count,
        (Format-Count $totalDifferences 'difference' 'differences')) -ForegroundColor Yellow
    Write-Host ('=' * 94)
}
if ($script:SkippedIdentityTags -gt 0) {
    Write-Host ("  {0} lineageTag value(s) were not compared - per-deployment GUIDs that differ" -f
        $script:SkippedIdentityTags) -ForegroundColor DarkGray
    Write-Host '  on every object in every export and mean nothing on either side.' -ForegroundColor DarkGray
}
Write-Host ''

exit $(if ($modelsWithDifferences -gt 0) { 1 } else { 0 })
