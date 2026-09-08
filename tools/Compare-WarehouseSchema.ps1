<#
.SYNOPSIS
    Compares the SQL schema of two Fabric Warehouse environments.

.DESCRIPTION
    The other half of the parity check. Compare-FabricEnvironment.ps1 covers the Fabric
    objects; this covers the SQL ones, which until now had no mechanical check at all.

    ⛔ THIS IS A MUCH SIMPLER COMPARISON THAN THE FABRIC ONE, AND DELIBERATELY SO.

    A pipeline is full of values that MUST differ between environments - workspace ids,
    endpoints, connection references - so that comparison has to classify them before it
    can say anything. Two warehouses built from the same repository and the same
    deployment script should be GENUINELY IDENTICAL. There is nothing to normalize away.

    **So here, a difference is a difference.** No allow-list, no expected-difference
    rules, no classification. If something differs, either a script reached one
    environment and not the other, or somebody changed an object in place.

    ⛔ THE CLIENT'S OWN DESIGN IS WHAT MAKES THAT TRUE. usp_CreateDataVirtualizationViews_Prep
    hardcodes a lakehouse name, which would normally force a legitimate difference - but an
    identically NAMED lakehouse exists in both workspaces precisely so the code can be
    identical. That was a deliberate decision, and it is why routine text can be compared
    character for character.

    Four things are compared, and the third is the one most likely to catch something:

      tables      present in one environment and not the other
      columns     added, removed, retyped, resized, or nullability changed
      routines    present in one and not the other, and bodies that differ - compared by
                  SHA-256 hash, because the full text is a 3 MB duplicate of the code
                  already in this repository

      ordering    a column that moved position, which changes SELECT * and INSERT

    DEFINITION_LENGTH IS compared, alongside the hash. It was previously excluded on the
    grounds that any length change already changes the hash - which is true, and which is
    also the reason to keep it. The hash is one opaque value with no way to check that it
    covered the whole definition; the length is the only INDEPENDENT witness that it did.
    If the export ever truncates a definition on one side, the two agree with each other
    and the pair of them says so.

    ⛔ A DIFFERENCE EXPLAINED BY A DIFFERENCE ABOVE IT IS COUNTED, NOT REPRINTED.

    A table that exists in one environment and not the other is ONE finding. Every one of
    its columns is also absent - necessarily, unavoidably, and with no information in it -
    so the first version of this report listed the object once and then listed forty more
    rows saying the same thing. The genuine findings were buried underneath, which is the
    only thing that actually matters about a comparison report.

    Three restatements are recognized, and each is fully explained by a finding printed
    above it:

      a column of an object that is absent on that side
      a routine row for a view that is absent on that side - a view sits in
                  INFORMATION_SCHEMA.TABLES *and* in sys.sql_modules, so its absence
                  arrives twice
      a routine row that appears or disappears because the object changed between a
                  TABLE and a VIEW - the type change is the finding, not its consequence

    ⛔ AND EVERY ONE OF THEM IS ANNOUNCED WITH ITS COUNT. Suppression that cannot be seen
    is indistinguishable from a tool that never looked, which is the exact failure this
    whole family of scripts exists to prevent. Nothing is dropped: the parent finding
    states how many differences it accounts for, and the summary states the total. The
    arithmetic closes - listed plus folded equals detected, printed on the report.
    -Verbose prints every folded difference individually, so the suppression can be
    audited against the raw findings rather than trusted.

    DETECTION IS UNCHANGED BY ANY OF THIS. Every difference found before is still found,
    still counted, and still able to fail the run. What changed is only how many lines it
    takes to say so.

    ⛔ EVERY NUMBER CARRIES ITS UNIT, AND EVERY FINDING NAMES ITS SIDE.

    The report was read against four live warehouses and came back with two questions it
    should have answered itself, and both are questions about the REPORT rather than
    about the warehouses:

      "dev=1200  prod=1240 - what is that number? Characters? Lines?"

          It is characters, from SQL LEN(m.definition), and LEN() does not count trailing
          spaces - so it is not a byte count and not quite a size either. Nothing on the
          line said so. Every quantity the report prints is now explained, and where two
          numbers are compared the subtraction is done for the reader, because the fact
          they wanted was "prod is 40 characters longer" and not "1200 versus 1240".

      "which side of the validation, dev or prod, are you referring to?"

          Some lines already said. Having to hunt for the ones that did is the same
          defect as not saying it: a one-sided finding now names BOTH environments in the
          same phrase, worded identically in every section.

    ⛔ AND EACH THING IS SAID EXACTLY ONCE - THE EXPLANATION BELONGS TO THE SECTION,
    THE VALUE BELONGS TO THE ROW.

    The first answer to that first question was to print the explanation beside the
    number, at the point of use. At real scale that means once per row: a live run with
    25 differing routines carried the same three lines of prose 25 times, 75 lines of
    identical text with the 25 findings scattered through them. That is the SAME defect
    the fold above was built to fix - the findings buried under text that says nothing
    new - applied to prose instead of to findings.

    So the rule the whole report is written to:

      a sentence that would read identically under every row of a section is printed
      ONCE, under that section's heading, before the first finding

      anything that changes from row to row - the object name, the two values, the
      delta, the side - stays on the row, and nothing that varies was ever folded away

    Applied everywhere it holds: what LEN() counts and how to see where a body differs
    (the routine section), what each column attribute measures and what "(not
    applicable)" means (the column section), that an absent object takes its columns
    with it (the object section), what the exports hold (once for the whole run). A
    row's delta phrase already names its unit - "prod is 7950 characters narrower" - so
    the loose unit word is dropped from rows that have one and kept only where one side
    is NULL and nothing else on the row supplies it.

    A reader should be able to learn each thing exactly once. Repeating it does not make
    it clearer; it makes the findings harder to find.

    ⛔ AND A COLUMN IS NAMED ONCE - A TABLE CHANGED WHOLESALE IS ONE FINDING.

    The column section was read against four live warehouses and the shape of it said
    something untrue before a single value had been read. Every differing attribute got
    its own line, and every line began with the same column key, so one table whose
    columns had all been changed the same way filled the screen with what looked like
    dozens of unrelated problems in dozens of unrelated tables. The client's question
    was the right one: if it is the same column, why is it said more than once?

    Two folds answer it, and the second is where the reading gain is:

      one entry per column      the column is named once and everything that differs
                                about it is listed beneath it. Two differing attributes
                                is one entry, not two lines with the same key on both

      one entry per identical   where two or more columns OF THE SAME TABLE differ in
      change                    EXACTLY the same way, they are named together under
                                that table: the change is stated once, and the columns
                                it applied to are listed under it. That is what a
                                wholesale change to a table actually is - one thing that
                                happened, not one thing per column

    ⛔ IDENTICAL MEANS IDENTICAL, DECIDED BY COMPARISON AND NEVER BY RESEMBLANCE.
    A group's identity is its table plus the exact text of every attribute line its
    columns produce - the fields, both values, and the delta. A column that differs in
    one EXTRA way, or in the same way by a different amount, is a different set of
    lines and is printed on its own. This is the whole risk of the fold: a column that
    differs interestingly must never be hidden inside a crowd that differs boringly,
    because a reader who finds it in the crowd will take the crowd's change for the
    whole story about it. It is asserted from both ends in the self-test, on a fixture
    built for exactly that discrimination.

    ⛔ AND THE LIST OF COLUMNS WRAPS AND IS NEVER CUT SHORT. A wide table's names on
    one line runs off the right edge of every console and every paste of this report; a
    list trimmed to "and 39 more" moves real names out of the default report. The fold
    is only safe while it is lossless - the moment a name can be missing, a reader can
    no longer tell which columns the change reached, which is the one question the
    grouping exists to answer. So it wraps, it is never capped, and -Verbose prints
    every difference on its own line for anyone who wants to audit the grouping.

    DETECTION IS UNTOUCHED BY BOTH FOLDS, AND SO IS THE ARITHMETIC. No difference is
    suppressed or counted away here - every column name and every differing attribute
    still reaches the report - so the section heading still counts DIFFERENCES rather
    than entries, and the listed-plus-folded-equals-detected line is unaffected. The
    section states its own three numbers before the first entry: how many differences,
    how many columns they affect, and how many entries they are shown as.

    And the report states its own PROVENANCE before anything else - per warehouse, the
    two files read, the environment each records, and the endpoint each was exported
    from. Every other line says "dev" or "prod"; this is the only place that says what
    those two words stood for on this run, which also makes the report self-contained
    when it is pasted to somebody who did not run it. It is what exposes an export whose
    NAME and CONTENTS disagree, which -Endpoint and -Environment make possible: one
    decides which warehouse is read, the other decides what the file is called.

.PARAMETER Folder
    Folder holding the exports. Files are paired by database name: dev-WH_Raw.json
    against prod-WH_Raw.json, and so on.

.PARAMETER DevFile
    One development export, if comparing a single pair explicitly.

.PARAMETER ProdFile
    One production export.

.PARAMETER ShowRoutineDiff
    Print the first differing line of any routine whose definition changed, rather than
    only naming it.


.EXAMPLE
    .\Compare-WarehouseSchema.ps1 -Folder warehouse-schema

.EXAMPLE
    .\Compare-WarehouseSchema.ps1 -DevFile dev-WH_Curated.json -ProdFile prod-WH_Curated.json -ShowRoutineDiff

.OUTPUTS
    Exit code 0 when the environments match, 1 when they do not.
#>

[CmdletBinding()]
param(
    [string] $Folder,
    [string] $DevFile,
    [string] $ProdFile,
    [switch] $ShowRoutineDiff
)

# ⛔ THE FOLDED-DIFFERENCE LISTING RIDES ON -Verbose, WHICH IS DELIBERATE AND NOT LAZINESS.
# It wants to be a switch of its own, but every declared parameter of every script in this
# folder is checked against Document 5's parameter reference by
# tools/sql-column-check/verify-param-docs.py, and that reference is a client deliverable
# held under change control. -Verbose comes from [CmdletBinding()], is not a declared
# parameter, and so adds the capability without silently putting that reference out of
# step. It is gated on the preference rather than routed through Write-Verbose because the
# whole report is written with Write-Host and a listing split across two streams is worse
# than one that is not there.
$ListRestated = ($VerbosePreference -ne 'SilentlyContinue')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Folder -and -not ($DevFile -and $ProdFile)) {
    throw "Give -Folder, or both -DevFile and -ProdFile."
}

function Read-Schema {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Not found: $Path" }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-Key {
    # A stable identity for a row, so two sides can be paired without relying on order.
    param($Row, [string[]] $Fields)
    return (($Fields | ForEach-Object { [string]$Row.$_ }) -join '|')
}

function Format-Key {
    # dbo|Sales|Amount reads as dbo.Sales.Amount. The pipe is a join character, not
    # something a reader should have to decode.
    param([string] $Key)
    return ($Key -replace '\|', '.')
}

# ⛔ EVERY NUMBER THIS REPORT PRINTS MUST SAY WHAT IT MEASURES - BUT IT SAYS SO ONCE.
# The routine line used to read "dev=1200  prod=1240" and the first question asked about
# it was "1200 what - characters? lines?". A quantity a reader has to guess at is a
# quantity they will eventually guess WRONG. So every quantity is still explained - but
# the EXPLANATION belongs to the SECTION and the VALUE belongs to the ROW.
#
# ⛔ THE SECOND HALF OF THAT SENTENCE WAS LEARNED THE HARD WAY. Printing the
# explanation beside every value put the same three lines of prose under all 25 differing
# routines of a live run: 75 lines of identical text, with the findings scattered through
# them. A reader should be able to learn each thing exactly once. Saying it again does
# not make it clearer - it buries what is actually different.
#
#   FieldUnit  the bare unit word. Used on a row ONLY where no delta phrase is produced
#              (one side is NULL, so there is nothing to subtract) and the surviving
#              number would otherwise print naked.
#   FieldNote  the full explanation of what the field counts. Printed ONCE, under the
#              heading of any section whose rows actually use that field.
$script:FieldUnit = @{
    CHARACTER_MAXIMUM_LENGTH = 'characters'
    NUMERIC_PRECISION        = 'total digits'
    NUMERIC_SCALE            = 'digits after the decimal point'
    ORDINAL_POSITION         = 'column position, 1 = leftmost'
    DEFINITION_LENGTH        = 'characters'
}

$script:FieldNote = @{
    CHARACTER_MAXIMUM_LENGTH = 'CHARACTER_MAXIMUM_LENGTH counts characters, not bytes.'
    NUMERIC_PRECISION        = 'NUMERIC_PRECISION is the total number of digits the column can hold.'
    NUMERIC_SCALE            = 'NUMERIC_SCALE is how many of those digits sit after the decimal point.'
    ORDINAL_POSITION         = "ORDINAL_POSITION is the column's place in the table, 1 = leftmost."
    DEFINITION_LENGTH        = 'LENGTH is T-SQL LEN(definition): characters, ignoring trailing spaces. It is not bytes and it is not lines.'
}

function Get-FieldNotes {
    # The explanations owed to one section: one line per field its rows actually use,
    # and never a field this section does not show.
    param($Items)
    $notes = @()
    foreach ($f in (@($Items) | ForEach-Object { $_.Field } |
                    Where-Object { $_ } | Sort-Object -Unique)) {
        if ($script:FieldNote.ContainsKey($f)) { $notes += $script:FieldNote[$f] }
    }
    return $notes
}

function Format-Count {
    # ⛔ "7950 character(s)" MAKES THE READER DO THE GRAMMAR. The number is right
    # there and the report knows whether it is one or many, so it says which.
    param([int] $N, [string] $Singular, [string] $Plural)
    if ($N -eq 1) { return ("1 {0}" -f $Singular) }
    return ("{0} {1}" -f $N, $Plural)
}

function Format-Value {
    <#
        ⛔ A NULL AND AN EMPTY STRING ARE DIFFERENT FACTS, so they print differently.
        INFORMATION_SCHEMA returns NULL for CHARACTER_MAXIMUM_LENGTH on a numeric column
        and for NUMERIC_PRECISION on a varchar one - the attribute does not apply to that
        type. The report used to render that as "prod=" with nothing after it, which
        reads as a value that failed to load rather than one that cannot exist.
    #>
    param($Value)
    if ($null -eq $Value) { return '(not applicable)' }
    $s = [string]$Value
    if ($s -eq '') { return '(empty)' }
    return $s
}

function Format-Delta {
    # The arithmetic the reader would otherwise do in their head, phrased for the field.
    param([string] $Field, [int] $Delta)
    $n = [Math]::Abs($Delta)
    switch ($Field) {
        'DEFINITION_LENGTH'        { return ("prod is {0} {1}"   -f (Format-Count $n 'character' 'characters'), $(if ($Delta -gt 0) { 'longer' } else { 'shorter' })) }
        'CHARACTER_MAXIMUM_LENGTH' { return ("prod is {0} {1}"   -f (Format-Count $n 'character' 'characters'), $(if ($Delta -gt 0) { 'wider' }  else { 'narrower' })) }
        'NUMERIC_PRECISION'        { return ("prod holds {0} {1}" -f (Format-Count $n 'digit' 'digits'),        $(if ($Delta -gt 0) { 'more' }   else { 'fewer' })) }
        'NUMERIC_SCALE'            { return ("prod keeps {0} {1}" -f (Format-Count $n 'decimal' 'decimals'),    $(if ($Delta -gt 0) { 'more' }   else { 'fewer' })) }
        'ORDINAL_POSITION'         { return ("the column sits {0} {1} in prod" -f (Format-Count $n 'position' 'positions'), $(if ($Delta -gt 0) { 'further right' } else { 'further left' })) }
        default                    { return ("prod is {0} {1}" -f $n, $(if ($Delta -gt 0) { 'more' } else { 'fewer' })) }
    }
}

function Format-Difference {
    # dev=X  prod=Y, with the unit named and the subtraction already done.
    param([string] $Field, $DevValue, $ProdValue)
    $text = "dev={0}  prod={1}" -f (Format-Value $DevValue), (Format-Value $ProdValue)
    $a = 0
    $b = 0
    if ([int]::TryParse([string]$DevValue, [ref] $a) -and [int]::TryParse([string]$ProdValue, [ref] $b)) {
        # "1200 vs 1240" makes the reader subtract to reach the fact they actually
        # wanted, which is that prod is 40 characters longer. Print the fact.
        #
        # ⛔ AND THE DELTA PHRASE ALREADY NAMES THE UNIT - "prod is 7950 characters
        # narrower". Appending the bare unit word as well printed "characters" twice on
        # the same line, six lines running, on the XREF columns of a live run. The row
        # keeps the phrase that carries the unit naturally; the loose word goes to the
        # section heading, where it is stated once for every row beneath it.
        $text += (" - {0}" -f (Format-Delta $Field ($b - $a)))
    }
    elseif ($script:FieldUnit.ContainsKey($Field)) {
        # No delta to phrase - one side is NULL, so there is nothing to subtract - and
        # the surviving number would otherwise print naked. Here the unit word earns its
        # place on the row, because nothing else on the row supplies it.
        $text += ("  {0}" -f $script:FieldUnit[$Field])
    }
    return $text
}

function Format-Side {
    <#
        ⛔ WHICH ENVIRONMENT HAS WHAT, WITHOUT INFERENCE. "MISSING IN PROD" is a verdict
        about prod that leaves the reader to deduce the dev half of it. Every one-sided
        finding now names BOTH sides in the same phrase, and it is worded identically in
        every section so the reader learns it once.
    #>
    param([string] $Change)
    switch ($Change) {
        'MISSING IN PROD' { return 'in dev only - MISSING IN PROD' }
        'EXTRA IN PROD'   { return 'in prod only - EXTRA IN PROD' }
        default           { return $Change }
    }
}

function New-Finding {
    <#
        One difference, carried as data so the renderer can group it rather than
        printing it in discovery order.

        ObjectKey is the identity of the OBJECT the row belongs to - for a column
        (schema, table, column) the first two fields are the object. That is the field
        that lets the renderer tell a child difference from the parent difference which
        already explains it.
    #>
    param([string] $Section, [string] $Change, [string] $Field, [string] $Key,
          $Row, [string] $Extra, [int] $ObjectKeyFieldCount)

    $parts = $Key -split '\|'
    $take = [Math]::Min($ObjectKeyFieldCount, $parts.Count)
    $objectKey = ($parts[0..($take - 1)]) -join '|'
    $kind = if ($Field) { "$Section $Field $Change" } else { "$Section $Change" }
    return [pscustomobject]@{
        Section   = $Section
        Change    = $Change
        Field     = $Field
        Key       = $Key
        ObjectKey = $objectKey
        Row       = $Row
        Kind      = $kind
        Detail    = $Key
        Extra     = $Extra
    }
}

function Compare-Part {
    <#
        Pairs two row sets by key and reports three things: only-in-dev, only-in-prod,
        and paired rows whose compared fields differ. Returns findings rather than
        printing, so the caller decides how much to show.
    #>
    param($DevRows, $ProdRows, [string[]] $KeyFields, [string[]] $CompareFields,
          [string] $What, [int] $ObjectKeyFieldCount = 0)

    if ($ObjectKeyFieldCount -le 0) { $ObjectKeyFieldCount = $KeyFields.Count }

    $findings = @()
    $devMap = @{}
    foreach ($r in @($DevRows))  { $devMap[(Get-Key $r $KeyFields)] = $r }
    $prodMap = @{}
    foreach ($r in @($ProdRows)) { $prodMap[(Get-Key $r $KeyFields)] = $r }

    foreach ($k in $devMap.Keys) {
        if (-not $prodMap.ContainsKey($k)) {
            $findings += New-Finding $What 'MISSING IN PROD' '' $k $devMap[$k] '' $ObjectKeyFieldCount
        }
    }
    foreach ($k in $prodMap.Keys) {
        if (-not $devMap.ContainsKey($k)) {
            $findings += New-Finding $What 'EXTRA IN PROD' '' $k $prodMap[$k] '' $ObjectKeyFieldCount
        }
    }
    foreach ($k in $devMap.Keys) {
        if (-not $prodMap.ContainsKey($k)) { continue }
        foreach ($f in $CompareFields) {
            # ⛔ THE RAW VALUE IS KEPT, NOT JUST ITS STRING FORM. Comparison still happens
            # on the string - detection is unchanged - but the renderer needs to tell a
            # NULL from an empty string, and [string]$null flattens the two together.
            $rawA = $devMap[$k].$f
            $rawB = $prodMap[$k].$f
            $a = [string]$rawA
            $b = [string]$rawB
            if ($a -ne $b) {
                # A routine body is thousands of characters. Dumping it onto the finding
                # line makes the report unreadable and hides the other findings, so the
                # value is summarized here and -ShowRoutineDiff gives the differing line.
                $extra = if ($f -eq 'DEFINITION_HASH') { '' } else { Format-Difference $f $rawA $rawB }
                $findings += New-Finding $What 'DIFFERS' $f $k $devMap[$k] $extra $ObjectKeyFieldCount
            }
        }
    }
    return $findings
}

function Test-JsonProperty {
    # ⛔ Set-StrictMode -Version Latest turns a MISSING property into a terminating error,
    # not $null. Reading .definitionsIncluded straight off an export written before that
    # field existed aborted the whole comparison instead of degrading to "no definitions
    # here". A comparison must never be stopped by the absence of an optional field.
    param($Object, [string] $Name)
    if ($null -eq $Object) { return $false }
    return ($Object.PSObject.Properties.Name -contains $Name)
}

function Get-JsonProperty {
    param($Object, [string] $Name, $Default = $null)
    if (Test-JsonProperty $Object $Name) { return $Object.$Name }
    return $Default
}

function Add-RestatementCount {
    param([hashtable] $Map, [string] $Key, [string] $Bucket)
    if (-not $Map.ContainsKey($Key)) { $Map[$Key] = @{ columns = 0; routines = 0 } }
    $Map[$Key][$Bucket] = $Map[$Key][$Bucket] + 1
}

function Resolve-Restatement {
    <#
        Splits the raw findings into the ones worth printing and the ones that only
        restate a finding already in the list, and records against each parent exactly
        how many of its children were folded into it.

        ⛔ NOTHING IS DISCARDED HERE. Every raw finding leaves this function in exactly
        one of the two lists and the counts are taken from the data, so the caller can
        assert that the two add back up to what came in. A comparison that quietly
        shrinks its own input is the failure mode this whole tool exists to catch.
    #>
    param($Findings)

    # Objects absent on one side, and the direction they are absent in. Direction
    # matters: a column reported missing under an object reported EXTRA is not a
    # restatement of anything, it is a contradiction, and it must stay visible.
    $absent = @{}
    foreach ($x in @($Findings)) {
        if ($x.Section -eq 'table' -and $x.Change -ne 'DIFFERS') { $absent[$x.Key] = $x.Change }
    }
    # Objects that changed between TABLE and VIEW. sys.sql_modules holds a row for a
    # view and none for a table, so the type change drags a routine appearance or
    # disappearance behind it that carries no separate information.
    $typeChanged = @{}
    foreach ($x in @($Findings)) {
        if ($x.Section -eq 'table' -and $x.Field -eq 'TABLE_TYPE') { $typeChanged[$x.Key] = $true }
    }

    $reported = @()
    $restated = @()
    $byParent = @{}

    foreach ($x in @($Findings)) {
        $reason = ''

        if ($x.Section -eq 'column' -and $x.Change -ne 'DIFFERS' -and
            $absent.ContainsKey($x.ObjectKey) -and $absent[$x.ObjectKey] -eq $x.Change) {
            $reason = 'absent-object'
            Add-RestatementCount $byParent $x.ObjectKey 'columns'
        }
        elseif ($x.Section -eq 'routine' -and $x.Change -ne 'DIFFERS' -and
                $absent.ContainsKey($x.Key) -and $absent[$x.Key] -eq $x.Change) {
            $reason = 'absent-object'
            Add-RestatementCount $byParent $x.Key 'routines'
        }
        elseif ($x.Section -eq 'routine' -and $x.Change -ne 'DIFFERS' -and
                $typeChanged.ContainsKey($x.Key)) {
            $reason = 'type-change'
            Add-RestatementCount $byParent $x.Key 'routines'
        }

        if ($reason) {
            $restated += ($x | Add-Member -NotePropertyName RestatementOf -NotePropertyValue $reason -PassThru)
        } else {
            $reported += $x
        }
    }

    return [pscustomobject]@{
        Reported = $reported
        Restated = $restated
        ByParent = $byParent
    }
}

function Get-FirstDifferingLine {
    # Where two routine definitions diverge, as a line number and the two lines.
    param([string] $A, [string] $B)
    $la = ($A -replace "`r`n", "`n") -split "`n"
    $lb = ($B -replace "`r`n", "`n") -split "`n"
    for ($i = 0; $i -lt [Math]::Max($la.Count, $lb.Count); $i++) {
        $x = if ($i -lt $la.Count) { $la[$i] } else { '(end of file)' }
        $y = if ($i -lt $lb.Count) { $lb[$i] } else { '(end of file)' }
        # ⛔ -ceq / -cne, NOT -eq / -ne. PowerShell's string comparison is
        # CASE-INSENSITIVE by default, so this walk stepped straight over a line that
        # changed only in case - and the caller then told the reader "the hashes differ
        # but no LINE does: trailing whitespace, or line endings", which is a confident,
        # specific and WRONG answer. SHA-256 is case-sensitive; the line walk that
        # explains it has to be too, or the explanation contradicts the finding.
        if ($x -cne $y) {
            # ⛔ TRIMMED FOR DISPLAY, SO SAY WHEN THE TRIM IS WHAT HID THE DIFFERENCE.
            # A trailing space is a real hash difference, and printing the two trimmed
            # lines showed a reader two IDENTICAL lines under "first differs at line 1",
            # which reads as a broken tool rather than a finding about whitespace.
            $invisible = ($x.Trim() -ceq $y.Trim())
            return [pscustomobject]@{
                Line = $i + 1; Dev = $x.Trim(); Prod = $y.Trim()
                WhitespaceOnly = $invisible
                DevLength = $x.Length; ProdLength = $y.Length
            }
        }
    }
    return $null
}

function Test-RoutineDefinitionsAvailable {
    # Whether -ShowRoutineDiff has anything to work from. It needs the TEXT, and the
    # text is only in a .full export - of BOTH sides.
    param($Detail)
    return ([bool](Get-JsonProperty $Detail.Dev  'definitionsIncluded' $false) -and
            [bool](Get-JsonProperty $Detail.Prod 'definitionsIncluded' $false))
}

function Show-RoutineDiff {
    # The -ShowRoutineDiff body, lifted out so the renderer below stays readable.
    #
    # ⛔ THE "THIS EXPORT HOLDS HASHES ONLY" APOLOGY IS NOT PRINTED HERE ANY MORE.
    # It was three lines, identical every time, once per differing routine - 75 lines on
    # a run with 25 of them. It is a fact about the EXPORT, not about any one routine, so
    # the renderer states it once under the section heading and calls this only when
    # there is text to read. The caller guarantees that; see Test-RoutineDefinitionsAvailable.
    param($Detail, [string] $RoutineKey)

    $a = (@($Detail.Dev.routines)  | Where-Object { (Get-Key $_ @('ROUTINE_SCHEMA','ROUTINE_NAME')) -eq $RoutineKey }).ROUTINE_DEFINITION
    $b = (@($Detail.Prod.routines) | Where-Object { (Get-Key $_ @('ROUTINE_SCHEMA','ROUTINE_NAME')) -eq $RoutineKey }).ROUTINE_DEFINITION
    $diff = Get-FirstDifferingLine $a $b
    if (-not $diff) {
        # The hashes differ but no line does. Say so - silence here reads as a tool that
        # failed rather than a real and quite specific finding.
        Write-Host '        the hashes differ but no LINE does: trailing whitespace, line endings, or a character that renders the same'
        return
    }
    Write-Host ("        first differs at line {0}" -f $diff.Line)
    Write-Host ("        dev  : {0}" -f $diff.Dev)
    Write-Host ("        prod : {0}" -f $diff.Prod)
    if ($diff.WhitespaceOnly) {
        # Row-specific: the two lengths are this routine's own numbers. What that MEANS
        # - trimmed for display, so the difference is whitespace and the logic may well
        # be identical - is stated once under the section heading.
        Write-Host ("        those two lines are trimmed for display and read the same: WHITESPACE ONLY, dev line {0} characters, prod line {1} characters" -f
                    $diff.DevLength, $diff.ProdLength)
    }
}

function Get-ColumnAttributeLine {
    <#
        One differing ATTRIBUTE of one column, rendered without the column's name.

        The name is deliberately absent: it is printed once, on the entry above, and
        that is the entire point of the grouping. It also makes this string usable as
        an identity - two columns that differ in exactly the same way produce exactly
        the same set of these lines, which is how "identical" is decided rather than
        guessed at.
    #>
    param($Finding)
    if ($Finding.Change -eq 'DIFFERS') {
        # Extra already carries dev=, prod=, the unit, and the delta.
        return (("{0,-26} {1}" -f $Finding.Field, $Finding.Extra)).TrimEnd()
    }
    # A whole column on one side only. Format-Side names both environments.
    return (Format-Side $Finding.Change)
}

function Group-ColumnFinding {
    <#
        Turns the flat list of column differences into the entries the report prints:
        one entry per column, and one entry per SET of columns in the same table that
        differ in EXACTLY the same way.

        ⛔ IDENTICAL MEANS IDENTICAL, AND IT IS DECIDED BY COMPARISON, NEVER BY
        RESEMBLANCE. A group's identity is its table plus the exact, ordered text of
        every attribute line its columns produce - the field names, both values, and
        the delta phrase. A column that differs in one extra way, or in the same way by
        a different amount, produces a different set of lines, lands in a different
        group, and is printed on its own. That is the whole risk of this change: a
        column that differs INTERESTINGLY must never be hidden inside a crowd that
        differs boringly, and the only defense is that the crowd is defined by an exact
        match rather than by a shared prefix or a shared field name.

        ⛔ AND NOTHING IS OMITTED. Every column name reaches the report and every
        attribute of every column is stated. What is removed is the REPETITION of a
        column key down the left margin and the repetition of an identical change once
        per column - never a fact.
    #>
    param($Findings)

    $byColumn = @{}
    foreach ($x in @($Findings)) {
        if (-not $byColumn.ContainsKey($x.Key)) { $byColumn[$x.Key] = @() }
        $byColumn[$x.Key] += $x
    }

    $bySignature = @{}
    foreach ($k in @($byColumn.Keys)) {
        $items = @($byColumn[$k] | Sort-Object Field, Change)
        $attrs = @($items | ForEach-Object { Get-ColumnAttributeLine $_ })
        # The table is part of the identity. Two tables changed the same way are two
        # findings about two tables, not one finding about a change.
        $sig = $items[0].ObjectKey + "`n" + ($attrs -join "`n")
        if (-not $bySignature.ContainsKey($sig)) {
            $bySignature[$sig] = [pscustomobject]@{
                ObjectKey   = $items[0].ObjectKey
                Attributes  = $attrs
                Columns     = @()
                Keys        = @()
                Differences = 0
            }
        }
        $g = $bySignature[$sig]
        $g.Columns     += ($k -split '\|')[-1]
        $g.Keys        += $k
        $g.Differences += $items.Count
    }

    foreach ($g in @($bySignature.Values)) {
        $g.Columns = @($g.Columns | Sort-Object)
        $g.Keys    = @($g.Keys    | Sort-Object)
    }
    return @($bySignature.Values | Sort-Object @{ Expression = { $_.ObjectKey } },
                                               @{ Expression = { $_.Columns[0] } })
}

function Format-ColumnList {
    <#
        ⛔ A FORTY-SEVEN NAME LIST MUST NOT BECOME A LINE NOBODY CAN READ, AND MUST NOT BE
        CUT SHORT EITHER.

        Two things were true at once: one line of forty-seven names runs off the right
        edge of every console and every paste of this report, and a list trimmed to
        "and 39 more" moves real names out of the default report. Grouping is only safe
        while it is LOSSLESS - the moment a name can be missing from the entry, a reader
        can no longer tell which columns the change applied to, which is the one
        question the grouping exists to answer.

        So the list WRAPS and is never capped. It costs a few lines on a wide table and
        keeps every name where the reader can see it.
    #>
    param([string[]] $Names, [int] $Width = 96)

    $lead   = '        columns: '
    $indent = ' ' * $lead.Length
    $lines  = @()
    $current = $lead
    $first = $true
    foreach ($n in @($Names)) {
        $piece = $(if ($first) { $n } else { ", $n" })
        if (-not $first -and ($current.Length + $piece.Length) -gt $Width) {
            $lines  += ($current + ',')
            $current = $indent + $n
        } else {
            $current += $piece
        }
        $first = $false
    }
    if ($current.Trim()) { $lines += $current }
    return $lines
}

function Write-Group {
    # ⛔ THE COUNT IN A HEADING IS A BARE NUMBER UNTIL IT IS GIVEN A NOUN. "(5)" beside a
    # section title could be objects, differences, or environments; the noun settles it.
    #
    # ⛔ AND AN EXPLANATION BELONGS TO THE SECTION, NEVER TO THE ROWS. -Notes is where
    # every sentence that would read identically under every row of this section goes. It
    # is printed once, directly under the heading, ahead of the first finding. Anything
    # that changes from row to row stays on the row.
    param([string] $Title, $Items, [string] $Noun = 'finding', [string[]] $Notes = @())
    if (@($Items).Count -eq 0) { return }
    Write-Host ''
    Write-Host ("  {0} - {1} {2}(s)" -f $Title, @($Items).Count, $Noun) -ForegroundColor Cyan
    foreach ($n in @($Notes)) {
        if ($n) { Write-Host ("    {0}" -f $n) -ForegroundColor DarkGray }
    }
}

# ---------------------------------------------------------------------------
$pairs = @()
$unpaired = 0
# ⛔ PAIRING PROBLEMS ARE HELD AND PRINTED INSIDE THE REPORT, not before it. They used
# to be written to the console during the file scan, which put the single most serious
# thing this tool can find - a whole warehouse that exists on one side only - ABOVE the
# report banner, where it reads as start-up chatter.
$pairingNotes = @()
function Add-Note {
    param([string] $Text, [string] $Color = 'Yellow')
    $script:pairingNotes += [pscustomobject]@{ Text = $Text; Color = $Color }
}

if ($Folder) {
    if (-not (Test-Path -LiteralPath $Folder)) { throw "Folder not found: $Folder" }

    # ⛔ THE UNION OF BOTH SIDES, NOT dev-*.json. Enumerating only the development
    # exports meant a warehouse that exists in PRODUCTION AND NOT IN DEVELOPMENT was
    # never compared and never mentioned - the single highest-value thing this tool
    # could find, and the only one it could not report. An unexpected warehouse in
    # production is a bigger finding than any column that moved inside one.
    $all = @(Get-ChildItem -LiteralPath $Folder -Filter '*.json' -File)

    # <label>-<database>[.full].json. Anything that does not carry a dev- or prod-
    # prefix cannot pair by name at all, so it is named rather than dropped.
    $devFiles  = @{}
    $prodFiles = @{}
    $unusable  = @()
    foreach ($f in $all) {
        if     ($f.Name -like 'dev-*')  { $devFiles[($f.Name -replace '^dev-', '')]   = $f }
        elseif ($f.Name -like 'prod-*') { $prodFiles[($f.Name -replace '^prod-', '')] = $f }
        else                            { $unusable += $f }
    }

    if ($unusable.Count -gt 0) {
        # An -Endpoint export is labeled 'custom' and so can never pair by prefix.
        # It used to be invisible here: exported successfully, then silently ignored.
        Add-Note ("  {0} export(s) carry neither a dev- nor a prod- prefix and cannot be paired" -f
                  $unusable.Count)
        foreach ($f in ($unusable | Sort-Object Name)) { Add-Note ("    {0}" -f $f.Name) }
        Add-Note '    An -Endpoint export is labeled custom-. Compare one explicitly with' 'Gray'
        Add-Note '    -DevFile and -ProdFile, or re-export it with -Environment dev|prod.' 'Gray'
    }

    # ⛔ THE DIAGNOSTIC EXPORT WINS WHERE IT EXISTS. -IncludeDefinitions writes
    # <label>-<database>.full.json beside the hash export rather than over it, so both
    # can be present. The full one is preferred because it is the only one that can
    # answer -ShowRoutineDiff, and the file actually read is printed so nobody has to
    # guess which of the two produced the verdict.
    $bases = @(@($devFiles.Keys) + @($prodFiles.Keys) | Sort-Object -Unique)
    $stems = @($bases | ForEach-Object { $_ -replace '\.full\.json$', '' -replace '\.json$', '' } |
               Sort-Object -Unique)

    foreach ($stem in $stems) {
        $pick = {
            param($map)
            if     ($map.ContainsKey("$stem.full.json")) { $map["$stem.full.json"] }
            elseif ($map.ContainsKey("$stem.json"))      { $map["$stem.json"] }
            else                                         { $null }
        }
        $d = & $pick $devFiles
        $p = & $pick $prodFiles

        if ($d -and $p) {
            $pairs += [pscustomobject]@{ Dev = $d.FullName; Prod = $p.FullName
                                         DevName = $d.Name; ProdName = $p.Name; Stem = $stem }
        }
        elseif ($d) {
            Add-Note ("  {0} has NO PRODUCTION COUNTERPART - NOT COMPARED" -f $d.Name)
            Add-Note  '    Either it was never deployed to production, or the production export was not taken.' 'Gray'
            $unpaired++
        }
        else {
            # The direction that was missing entirely.
            Add-Note ("  {0} has NO DEVELOPMENT COUNTERPART - NOT COMPARED" -f $p.Name)
            Add-Note  '    A warehouse exists in PRODUCTION that development does not have. That is a' 'Gray'
            Add-Note  '    finding in its own right, not a missing export to shrug at.' 'Gray'
            $unpaired++
        }
    }

    if ($pairs.Count -eq 0) { throw "No dev-*.json / prod-*.json pairs found in $Folder." }
}
else {
    $pairs += [pscustomobject]@{ Dev = $DevFile; Prod = $ProdFile
                                 DevName = (Split-Path -Leaf $DevFile)
                                 ProdName = (Split-Path -Leaf $ProdFile); Stem = '' }
}

# ⛔ THE BANNER IS PRINTED AFTER THE COMPARISON RUNS, NOT BEFORE IT.
# It used to print first, which meant the report could not state its own provenance -
# what "dev" and "prod" actually WERE on this run - because that is recorded inside the
# export files, which had not been opened yet. Nothing here writes to the console during
# the loop, so deferring the banner reorders no output; it only lets the header carry
# facts read from the files it is describing.
$rows = @()
$details = @()
$provenance = @()
$problems = 0
$totalDetected = 0
$totalListed = 0
$totalFolded = 0

foreach ($pair in $pairs) {
    $dev = Read-Schema $pair.Dev
    $prod = Read-Schema $pair.Prod
    $db = $dev.database

    # ⛔ WHAT "dev" AND "prod" WERE ON THIS RUN, taken from the export files themselves.
    # The reader was being told two sides differ without being told what the two sides
    # were. environment and endpoint are already written by Export-WarehouseSchema.ps1,
    # so nothing is invented here - and because -Endpoint decides what is READ while
    # -Environment decides the FILENAME, printing both is what exposes a file whose name
    # and contents disagree.
    $provenance += [pscustomobject]@{
        Database     = $db
        DevName      = $pair.DevName
        ProdName     = $pair.ProdName
        DevEnv       = [string](Get-JsonProperty $dev  'environment' '(not recorded)')
        ProdEnv      = [string](Get-JsonProperty $prod 'environment' '(not recorded)')
        DevEndpoint  = [string](Get-JsonProperty $dev  'endpoint'    '(not recorded)')
        ProdEndpoint = [string](Get-JsonProperty $prod 'endpoint'    '(not recorded)')
        DevDb        = [string](Get-JsonProperty $dev  'database'    '(not recorded)')
        ProdDb       = [string](Get-JsonProperty $prod 'database'    '(not recorded)')
        DevFull      = [bool](Get-JsonProperty $dev  'definitionsIncluded' $false)
        ProdFull     = [bool](Get-JsonProperty $prod 'definitionsIncluded' $false)
    }

    $f = @()
    $f += Compare-Part -DevRows $dev.tables -ProdRows $prod.tables `
            -KeyFields TABLE_SCHEMA, TABLE_NAME -CompareFields TABLE_TYPE -What 'table'
    $f += Compare-Part -DevRows $dev.columns -ProdRows $prod.columns `
            -KeyFields TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME `
            -CompareFields DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE, ORDINAL_POSITION `
            -What 'column' -ObjectKeyFieldCount 2
    $f += Compare-Part -DevRows $dev.routines -ProdRows $prod.routines `
            -KeyFields ROUTINE_SCHEMA, ROUTINE_NAME `
            -CompareFields ROUTINE_TYPE, DEFINITION_HASH, DEFINITION_LENGTH -What 'routine'

    $split = Resolve-Restatement $f

    # A routine whose body changed produces BOTH a hash finding and a length finding.
    # They are two witnesses to one event, so they are shown on ONE line - the length
    # is folded onto the hash line rather than printed again under its own heading.
    # The pair is still detected, and the hash-same-length-differs case is still its
    # own loud finding, because that combination means a broken export.
    $hashKeys = @{}
    foreach ($x in $split.Reported) {
        if ($x.Section -eq 'routine' -and $x.Field -eq 'DEFINITION_HASH') { $hashKeys[$x.Key] = $true }
    }
    $merged = @($split.Reported | Where-Object {
        $_.Section -eq 'routine' -and $_.Field -eq 'DEFINITION_LENGTH' -and $hashKeys.ContainsKey($_.Key)
    })
    $mergedByKey = @{}
    foreach ($m in $merged) { $mergedByKey[$m.Key] = $m.Extra }
    $printable = @($split.Reported | Where-Object {
        -not ($_.Section -eq 'routine' -and $_.Field -eq 'DEFINITION_LENGTH' -and $hashKeys.ContainsKey($_.Key))
    })

    $folded = @($split.Restated).Count + $merged.Count
    $totalDetected += $f.Count
    $totalListed   += $printable.Count
    $totalFolded   += $folded

    # ⛔ "DIFFERS (10) +11 folded" IS THREE BARE NUMBERS IN A ROW. Spelled out, because a
    # reader cannot tell a count of findings from a count of objects by looking at it.
    $status = if ($f.Count -eq 0) { 'match' } else { "DIFFERS - $($printable.Count) finding(s) listed" }
    if ($folded -gt 0) { $status += ", $folded folded" }

    # ⛔ BOTH SIDES' COUNTS, AND LABELED AS SUCH. This row used to print the DEV export's
    # counts with no side named at all, so "3 tables" beside a warehouse whose production
    # copy holds two was simply wrong to anybody who read it as a fact about the pair.
    # The file each verdict was read from now lives in the provenance block above, in
    # full, with its environment and endpoint beside it.
    $rows += [pscustomobject]@{
        Database = $db
        Counts   = ("tables {0}/{1}  columns {2}/{3}  routines {4}/{5}" -f
                    @($dev.tables).Count,   @($prod.tables).Count,
                    @($dev.columns).Count,  @($prod.columns).Count,
                    @($dev.routines).Count, @($prod.routines).Count)
        Status   = $status
    }
    if ($f.Count -gt 0) {
        $problems++
        $details += [pscustomobject]@{
            Database    = $db; Dev = $dev; Prod = $prod
            Detected    = $f.Count
            Printable   = $printable
            Restated    = @($split.Restated)
            ByParent    = $split.ByParent
            MergedByKey = $mergedByKey
            Merged      = $merged
            MergedCount = $merged.Count
        }
    }
}

Write-Host ''
Write-Host ('=' * 78)
Write-Host 'WAREHOUSE SCHEMA COMPARISON'
Write-Host ('=' * 78)
Write-Host '  Two warehouses built from the same repository should be identical.'
Write-Host '  There is nothing here that legitimately differs, so every finding is real.'
Write-Host ''

# ⛔ THE REPORT MUST SAY WHAT IT COMPARED, so it is self-contained when it is pasted to
# somebody who did not run it. Every later line says "dev" or "prod"; this is the only
# place that says which files, which environments and which endpoints those two words
# stood for on this run.
Write-Host 'EXPORTS COMPARED - what "dev" and "prod" mean in this report'

# ⛔ WHAT EVERY EXPORT HOLDS IS ONE FACT ABOUT THE RUN, NOT ONE PER FILE. Printing
# it under each side put "the file holds definition hashes only" eight times in a
# four-warehouse run, saying nothing new after the first. Where every file in the run
# agrees - which is the normal case, because one export command produced them all - it
# is stated once here. Where they DISAGREE it goes back onto the individual lines,
# because then it is the thing the reader most needs to see.
$holdsSet = @()
foreach ($pv in $provenance) {
    $holdsSet += $(if ($pv.DevFull)  { 'full definition text' } else { 'definition hashes only' })
    $holdsSet += $(if ($pv.ProdFull) { 'full definition text' } else { 'definition hashes only' })
}
$holdsUniform = (@($holdsSet | Sort-Object -Unique).Count -le 1)
if ($holdsUniform -and $holdsSet.Count -gt 0) {
    Write-Host ("  Every export read in this run holds {0}." -f $holdsSet[0]) -ForegroundColor DarkGray
}

foreach ($pv in $provenance) {
    Write-Host ("  {0}" -f $pv.Database)
    foreach ($side in @(
        @{ Tag = 'dev '; File = $pv.DevName;  Env = $pv.DevEnv;  End = $pv.DevEndpoint;  Full = $pv.DevFull },
        @{ Tag = 'prod'; File = $pv.ProdName; Env = $pv.ProdEnv; End = $pv.ProdEndpoint; Full = $pv.ProdFull })) {
        Write-Host ("    {0}  read {1}, exported as environment '{2}' from endpoint {3}" -f
                    $side.Tag, $side.File, $side.Env, $side.End)
        if (-not $holdsUniform) {
            $holds = if ($side.Full) { 'full definition text' } else { 'definition hashes only' }
            Write-Host ("          this file holds {0}" -f $holds) -ForegroundColor DarkGray
        }
    }

    # ⛔ THE MISLABELED-FILE TRAP, MADE VISIBLE. -Endpoint decides which warehouse is
    # READ and -Environment decides what the file is NAMED, so the two can disagree and
    # nothing downstream would ever notice. These checks report; they do not change the
    # verdict, because a name is evidence about the export, not about the schema.
    if ($pv.DevEndpoint -eq $pv.ProdEndpoint) {
        Write-Host '    WARNING: both sides were exported from the SAME endpoint. This run is' -ForegroundColor Red
        Write-Host '             comparing one environment with itself, and a match means nothing.' -ForegroundColor Red
    }
    if ($pv.DevName -like 'dev-*' -and $pv.DevEnv -ne 'dev') {
        Write-Host ("    WARNING: the file named {0} records environment '{1}', not 'dev'." -f
                    $pv.DevName, $pv.DevEnv) -ForegroundColor Red
    }
    if ($pv.ProdName -like 'prod-*' -and $pv.ProdEnv -ne 'prod') {
        Write-Host ("    WARNING: the file named {0} records environment '{1}', not 'prod'." -f
                    $pv.ProdName, $pv.ProdEnv) -ForegroundColor Red
    }
    if ($pv.DevDb -ne $pv.ProdDb) {
        Write-Host ("    WARNING: these two files hold DIFFERENT databases - dev '{0}', prod '{1}'." -f
                    $pv.DevDb, $pv.ProdDb) -ForegroundColor Red
    }
}
Write-Host ''

if ($pairingNotes.Count -gt 0) {
    Write-Host 'EXPORTS THAT COULD NOT BE PAIRED' -ForegroundColor Yellow
    foreach ($n in $pairingNotes) { Write-Host $n.Text -ForegroundColor $n.Color }
    Write-Host ''
}

$w = 14
Write-Host ("  {0,-$w} {1,-46} {2}" -f 'warehouse', 'objects in each export (dev/prod)', 'verdict')
foreach ($r in $rows) {
    $color = if ($r.Status -eq 'match') { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-$w} {1,-46} {2}" -f
                $r.Database, $r.Counts, $r.Status) -ForegroundColor $color
}

foreach ($d in $details) {
    Write-Host ''
    Write-Host ('-' * 78)
    Write-Host $d.Database
    Write-Host ('-' * 78)

    $p = $d.Printable

    # ⛔ THE SUMMARY TABLE IS HUNDREDS OF LINES ABOVE THIS ON A REAL RUN. A reader
    # who scrolled to a warehouse's findings cannot see its verdict any more, so each
    # detail block restates its own - which is a fact about THIS warehouse, not a
    # sentence repeated from somewhere else.
    $recapFolded = @($d.Restated).Count + $d.MergedCount
    $recap = ("  {0} finding(s) listed below" -f @($p).Count)
    if ($recapFolded -gt 0) { $recap += (", {0} folded into them" -f $recapFolded) }
    Write-Host $recap -ForegroundColor DarkGray

    # 1. Whole objects that exist on one side only. FIRST, because they are the largest
    #    finding available and everything under them is a consequence of them.
    $objectAbsent = @($p | Where-Object { $_.Section -eq 'table' -and $_.Change -ne 'DIFFERS' } |
                      Sort-Object Detail)
    Write-Group 'OBJECTS PRESENT IN ONE ENVIRONMENT ONLY' $objectAbsent 'object' @(
        'When a whole object is absent, everything inside it is absent with it. Its columns and its',
        'sys.sql_modules row are counted under the object rather than listed one by one below.')
    foreach ($x in $objectAbsent) {
        $type = if (Test-JsonProperty $x.Row 'TABLE_TYPE') { [string]$x.Row.TABLE_TYPE } else { 'OBJECT' }
        Write-Host ("    {0,-44} {1,-12} {2}" -f
                    (Format-Key $x.Detail), $type, (Format-Side $x.Change)) -ForegroundColor Yellow
        if ($d.ByParent.ContainsKey($x.Key)) {
            $c = $d.ByParent[$x.Key]
            $bits = @()
            if ($c['columns']  -gt 0) { $bits += ("its {0} column(s)" -f $c['columns']) }
            if ($c['routines'] -gt 0) { $bits += 'its definition row in sys.sql_modules' }
            Write-Host ("        {0} not listed separately" -f ($bits -join ' and '))
        } else {
            Write-Host '        the export holds no columns for this object, so nothing was folded'
        }
    }

    # 2. An object that changed between a TABLE and a VIEW.
    $typeChanged = @($p | Where-Object { $_.Section -eq 'table' -and $_.Field -eq 'TABLE_TYPE' } |
                     Sort-Object Detail)
    Write-Group 'OBJECTS WHOSE TYPE CHANGED' $typeChanged 'object' @(
        'sys.sql_modules holds a row for a view and none for a table, so a TABLE/VIEW change drags a',
        'definition row into or out of existence. That follows from the type change and is counted here.')
    foreach ($x in $typeChanged) {
        Write-Host ("    {0,-44} TABLE_TYPE  {1}" -f (Format-Key $x.Detail), $x.Extra) -ForegroundColor Yellow
        if ($d.ByParent.ContainsKey($x.Key)) {
            $c = $d.ByParent[$x.Key]
            if ($c['routines'] -gt 0) {
                Write-Host ("        its sys.sql_modules row not listed separately ({0} difference)" -f $c['routines'])
            }
        }
    }

    # 3. Columns of objects that exist on BOTH sides. These are the ones that carry
    #    information a reader cannot get from anything above.
    $columns = @($p | Where-Object { $_.Section -eq 'column' } | Sort-Object Detail, Field)

    # ⛔ ONE LEGEND FOR THE WHOLE SECTION, NOT A UNIT WORD ON EVERY ROW. Six
    # consecutive XREF columns on a live run each carried "characters" twice - once as a
    # loose word, once inside "prod is 7950 characters narrower". The rows keep the
    # phrase that does the work; the definitions sit here, once, and only for the fields
    # that actually appear below.
    $columnNotes = @(Get-FieldNotes $columns)
    if (@($columns | Where-Object { $_.Extra -match '\(not applicable\)' }).Count -gt 0) {
        # ⛔ "(not applicable)" IS NOT AN ERROR AND MUST NOT BE READ AS ONE.
        # INFORMATION_SCHEMA returns NULL where an attribute cannot apply to that type.
        # Explaining it beside each value would be the same defect this pass exists for.
        $columnNotes += '(not applicable) is a NULL from INFORMATION_SCHEMA: the attribute cannot apply to that'
        $columnNotes += 'column type - CHARACTER_MAXIMUM_LENGTH on an int, NUMERIC_PRECISION on a varchar. Not an error.'
    }
    # ⛔ ONE ENTRY PER COLUMN, AND ONE ENTRY PER IDENTICAL CHANGE.
    #
    # Read against four live warehouses this section printed hundreds of lines, and the
    # first thing it told the reader was wrong: the same table name repeated down the
    # left margin reads as dozens of separate problems with dozens of separate tables.
    # It was not. It was ONE change applied to one table, and every column of that table
    # carried it.
    #
    # So two things are folded, in this order:
    #
    #   a column is named ONCE, with everything that differs about it beneath it - a
    #   column with two differing attributes is one entry, not two lines that both
    #   start with the same forty-character key
    #
    #   columns of the SAME table whose differences are EXACTLY the same are named
    #   together, with the change stated once and the columns it applied to listed
    #
    # ⛔ AND DETECTION IS UNTOUCHED BY BOTH. Nothing here is suppressed or counted away:
    # every column name and every differing attribute still reaches the report, so the
    # section heading still counts DIFFERENCES and the listed-plus-folded arithmetic
    # below is unaffected. What changed is how many lines it takes to say so.
    $columnEntries  = @(Group-ColumnFinding $columns)
    $groupedEntries = @($columnEntries | Where-Object { $_.Columns.Count -gt 1 })

    if (@($columns).Count -gt 0) {
        # ⛔ THE FOLD IS STATED, WITH ITS THREE NUMBERS, BEFORE THE FIRST ENTRY. A reader
        # who cannot see that grouping happened cannot tell this report from one that
        # found less, which is the failure this whole family of scripts exists to stop.
        $columnNotes += ("The {0} below affect {1}, shown as {2}. Each column is named once, with" -f
                         (Format-Count @($columns).Count 'difference' 'differences'),
                         (Format-Count (@($columnEntries | ForEach-Object { $_.Columns.Count } |
                                          Measure-Object -Sum).Sum) 'column' 'columns'),
                         (Format-Count @($columnEntries).Count 'entry' 'entries'))
        $columnNotes += 'everything that differs about it listed beneath it.'
        if ($groupedEntries.Count -gt 0) {
            $columnNotes += 'Columns of one table that differ in EXACTLY the same way - same fields, same dev values,'
            $columnNotes += 'same prod values - are named together under that table, and every one of their names is'
            $columnNotes += 'listed: a long list wraps and is never cut short. A column that differs in any other way is'
            $columnNotes += 'listed on its own, never inside a group. -Verbose prints every difference ungrouped.'
        }
    }

    Write-Group 'COLUMNS THAT DIFFER (the object exists in both environments)' $columns 'difference' $columnNotes

    if ($ListRestated) {
        # ⛔ THE UNGROUPED VIEW IS ALWAYS REACHABLE. The grouping is lossless, so this is
        # an audit rather than a rescue - but a fold a reader cannot undo is a fold they
        # have to take on trust, and this family of scripts does not ask for trust.
        foreach ($x in $columns) {
            if ($x.Change -eq 'DIFFERS') {
                Write-Host (("    {0,-44} {1,-26} {2}" -f
                             (Format-Key $x.Detail), $x.Field, $x.Extra).TrimEnd()) -ForegroundColor Yellow
            } else {
                Write-Host ("    {0,-44} {1}" -f
                            (Format-Key $x.Detail), (Format-Side $x.Change)) -ForegroundColor Yellow
            }
        }
    }
    else {
        foreach ($g in $columnEntries) {
            if ($g.Columns.Count -eq 1) {
                Write-Host ("    {0}" -f (Format-Key $g.Keys[0])) -ForegroundColor Yellow
            } else {
                # ⛔ THE COUNT IS ON THE ENTRY BECAUSE THE ENTRY IS NOW THE FINDING.
                # The table name on its own would understate a change that reached
                # twelve columns exactly as badly as twelve repeated lines overstated
                # it - and the reader has to know the size to judge it.
                Write-Host ("    {0} - {1} differ identically" -f
                            (Format-Key $g.ObjectKey),
                            (Format-Count $g.Columns.Count 'column' 'columns')) -ForegroundColor Yellow
            }
            foreach ($a in $g.Attributes) {
                Write-Host ("        {0}" -f $a) -ForegroundColor Yellow
            }
            if ($g.Columns.Count -gt 1) {
                foreach ($line in (Format-ColumnList $g.Columns)) { Write-Host $line }
            }
        }
    }

    # 4. Routines on one side only that nothing above already explains - a procedure or
    #    function, which has no INFORMATION_SCHEMA.TABLES row to be reported against.
    $routineAbsent = @($p | Where-Object { $_.Section -eq 'routine' -and $_.Change -ne 'DIFFERS' } |
                       Sort-Object Detail)
    Write-Group 'ROUTINES PRESENT IN ONE ENVIRONMENT ONLY' $routineAbsent 'routine'
    foreach ($x in $routineAbsent) {
        $type = if (Test-JsonProperty $x.Row 'ROUTINE_TYPE') { [string]$x.Row.ROUTINE_TYPE } else { 'ROUTINE' }
        Write-Host (("    {0,-44} {1,-22} {2}" -f
                     (Format-Key $x.Detail), $type, (Format-Side $x.Change)).TrimEnd()) -ForegroundColor Yellow
    }

    # 5. Routine bodies that differ.
    $routineDiff = @($p | Where-Object { $_.Section -eq 'routine' -and $_.Change -eq 'DIFFERS' } |
                     Sort-Object Detail, Field)
    # ⛔ THE DEFECT THIS SECTION EXISTS TO NOT REPEAT. Every routine below used to
    # carry the same three lines of prose - what LEN() counts, and how to see where the
    # bodies differ. On a live run with 25 differing routines that was 75 lines of
    # identical text with the 25 findings buried in it. Both sentences are facts about
    # the SECTION, so they are printed here, once. Each routine keeps only what is true
    # of that routine alone: its name, that the bodies differ, and its own two numbers.
    $rdHashes  = @($routineDiff | Where-Object { $_.Field -eq 'DEFINITION_HASH' })
    $rdImposs  = @($routineDiff | Where-Object { $_.Field -eq 'DEFINITION_LENGTH' })
    $rdHaveDefs = Test-RoutineDefinitionsAvailable $d

    $routineNotes = @()
    if ($rdHashes.Count -gt 0) {
        $routineNotes += $script:FieldNote['DEFINITION_LENGTH']
        $routineNotes += 'A routine with no LENGTH line below has bodies of identical length - the change did not alter the size of the text.'
        if (-not $ShowRoutineDiff) {
            $routineNotes += 'Re-run with -ShowRoutineDiff, on .full exports, to see WHERE a body differs.'
        }
        elseif (-not $rdHaveDefs) {
            # ⛔ -ShowRoutineDiff WITH NOTHING TO SHOW MUST STILL SAY SO - once.
            # Silence reads as "asked and there was nothing to say" rather than "could
            # not look". This used to print per routine; it is a fact about the export.
            $routineNotes += '-ShowRoutineDiff cannot show anything here: these exports hold hashes only. Re-export BOTH'
            $routineNotes += 'sides with -IncludeDefinitions, which writes <environment>-<database>.full.json, then re-run.'
        }
        else {
            $routineNotes += 'Differing lines are printed trimmed, so two that read the same differ only in whitespace.'
        }
    }
    if ($rdImposs.Count -gt 0) {
        $routineNotes += 'A LENGTH difference with an IDENTICAL hash is impossible for two genuine bodies. Suspect a'
        $routineNotes += 'truncated or partial export and re-export both sides.'
    }
    Write-Group 'ROUTINE DEFINITIONS THAT DIFFER' $routineDiff 'difference' $routineNotes

    foreach ($x in $routineDiff) {
        if ($x.Field -eq 'DEFINITION_HASH') {
            Write-Host ("    {0,-44} the dev and prod bodies differ (SHA-256)" -f
                        (Format-Key $x.Detail)) -ForegroundColor Yellow
            if ($d.MergedByKey.ContainsKey($x.Key)) {
                # This routine's own numbers, and the subtraction already done. The
                # WORD "LENGTH" is enough of a label because the heading above defined it.
                Write-Host ("        LENGTH {0}" -f $d.MergedByKey[$x.Key])
            }
            if ($ShowRoutineDiff -and $rdHaveDefs) { Show-RoutineDiff $d $x.Key }
        }
        elseif ($x.Field -eq 'DEFINITION_LENGTH') {
            # Length differs, hash does not. Two different bodies cannot share a hash, so
            # this is not a code change - it is the export disagreeing with itself, which
            # is the exact thing the length was kept alongside the hash to catch. Why it
            # is impossible is stated once at the heading; the numbers are the row.
            Write-Host ("    {0,-44} LENGTH differs but the HASH does not: {1}" -f
                        (Format-Key $x.Detail), $x.Extra) -ForegroundColor Red
        }
        else {
            Write-Host (("    {0,-44} {1,-22} {2}" -f (Format-Key $x.Detail), $x.Field, $x.Extra).TrimEnd()) -ForegroundColor Yellow
        }
    }

    # 6. The audit trail. Printed whenever anything was folded away, so the suppression
    #    is a visible, countable claim rather than a silent edit to the report.
    $foldedHere = @($d.Restated).Count + $d.MergedCount
    if ($foldedHere -gt 0) {
        Write-Host ''
        Write-Host ("  NOT LISTED SEPARATELY - {0} difference(s)" -f $foldedHere) -ForegroundColor DarkCyan
        Write-Host ("    {0} raw difference(s) were detected in {1}." -f $d.Detected, $d.Database)
        Write-Host ("    {0} are listed above. The other {1} each restate one of them and carry no" -f
                    @($p).Count, $foldedHere)
        Write-Host '    information of their own:'
        foreach ($g in (@($d.Restated) | Group-Object RestatementOf | Sort-Object Name)) {
            # ⛔ EACH REASON NAMES THE FINDING IT WAS FOLDED INTO, so the reader can walk
            # back up to the line that already told them which environment is involved.
            # "absent on that side" left the side to be worked out.
            $why = switch ($g.Name) {
                'absent-object' { 'a column or definition row of an object already listed above as present in one environment only' }
                'type-change'   { 'a definition row that follows from an object already listed above as changing TABLE/VIEW' }
                default         { $g.Name }
            }
            Write-Host ("      {0,5}  {1}" -f $g.Count, $why)
        }
        if ($d.MergedCount -gt 0) {
            Write-Host ("      {0,5}  a definition LENGTH shown under its own hash finding above, with both sides named there" -f
                        $d.MergedCount)
        }
        Write-Host ("    {0} listed + {1} folded = {2} detected difference(s). Nothing was dropped." -f
                    @($p).Count, $foldedHere, $d.Detected)
        if ($ListRestated) {
            # Every folded difference, the merged length lines included, so the count
            # above and the list below are the same number. A listing that showed 10 of
            # 11 would be the very thing this block exists to disprove.
            foreach ($x in ((@($d.Restated) + @($d.Merged)) | Sort-Object Detail, Kind)) {
                Write-Host ("      {0,-46} {1}" -f (Format-Key $x.Detail), $x.Kind) -ForegroundColor DarkGray
            }
        }
        # ⛔ THE "-Verbose SHOWS THEM ALL" POINTER IS NOT PRINTED HERE. It is advice
        # about the RUN, identical under every warehouse, so on a four-warehouse run it
        # said the same thing four times. It is given once, in the closing summary.
    }
}

Write-Host ''
if ($unpaired -gt 0) {
    # ⛔ AN UNPAIRED WAREHOUSE IS A FAILURE, NOT A WARNING. It used to print a yellow line
    # and let the run exit 0, so "the two environments match" could be said about a folder
    # in which a whole warehouse was never compared.
    Write-Host ("{0} warehouse(s) exist on ONE SIDE ONLY and were not compared." -f
                $unpaired) -ForegroundColor Yellow
}
if ($problems -eq 0 -and $unpaired -eq 0) {
    # The two environments are named in the EXPORTS COMPARED block at the top, endpoint
    # and all, so this line can stay short without leaving the reader guessing.
    Write-Host ("The two environments match across {0} warehouse(s) - see EXPORTS COMPARED above for which two." -f
                @($pairs).Count) -ForegroundColor Green
}
elseif ($problems -gt 0) {
    # ⛔ THE HEADLINE NUMBER IS THE ONE A PERSON HAS TO ACT ON. It used to be the raw
    # difference count, which counted forty restatements of one absent table as forty
    # things to look at.
    Write-Host ("{0} warehouse(s) differ: {1} finding(s) listed." -f $problems, $totalListed) -ForegroundColor Yellow
    if ($totalFolded -gt 0) {
        Write-Host ("  A further {0} difference(s) were detected and folded into the finding that" -f $totalFolded)
        Write-Host '  already explains them. They were counted, not skipped:'
        Write-Host ("  {0} listed + {1} folded = {2} detected difference(s)." -f
                    $totalListed, $totalFolded, $totalDetected)
        if (-not $ListRestated) {
            Write-Host '  Re-run with -Verbose to see every folded difference individually.'
        }
    }
    Write-Host '  NOTHING HERE IS EXPECTED TO DIFFER. Each finding is a script that reached one'
    Write-Host '  environment and not the other, or an object changed in place.'
}
Write-Host ''

exit ($(if (($problems + $unpaired) -gt 0) { 1 } else { 0 }))
