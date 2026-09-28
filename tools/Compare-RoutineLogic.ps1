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

    ⛔ KEYWORD CASE IS FOLDED BY DEFAULT. SELECT, Select and select are one word in T-SQL -
    the case of a keyword cannot change what a routine does, so reporting it as a
    difference buries the differences that matter. This is the baseline, not a switch.

    ⛔ STRING LITERALS ARE NEVER FOLDED, IN ANY MODE. 'East' against 'east' is data that
    reaches a column somebody reads, so it stays a difference however the script is run.
    The same goes for anything inside a quoted identifier: if the author wrote [Order Date]
    in brackets they meant those characters literally, so [Order Date] against [ORDER DATE]
    also stays a difference.

    IDENTIFIER CASE IS A SEPARATE, OPTIONAL FOLD (-IgnoreIdentifierCase). A Fabric
    warehouse is case-insensitive, so dbo.Orders and dbo.ORDERS are the same object and
    could fairly be folded too - but that is a different claim from the keyword one, and
    the run prints how many routines it moved so the size of it is visible before it is
    dismissed as noise.

    ⛔ WHAT COUNTS AS A KEYWORD IS THE TOKENIZER'S ANSWER, NEVER A WORD LIST WE MAINTAIN.
    Microsoft's lexer answers IsKeyword() per token. A hand-kept list would be wrong the
    week somebody used a construct it had never heard of, and it could not tell a keyword
    from a column that happens to be spelled like one.

    WHERE THAT LINE FALLS, AND THE ONE SURPRISE IN IT. The lexer's keyword table covers the
    language's reserved words - SELECT, FROM, WHERE, JOIN, AS, AND. It does NOT cover
    built-in function and type names: CAST, INT, VARCHAR, GETDATE and ISNULL all come back
    as ordinary identifiers, so Cast against CAST is still a difference on a default run.
    -IgnoreIdentifierCase is what covers those. The run header says so rather than leaving
    it to be discovered.

    ⛔ IT NEEDS THE FULL EXPORTS. Run Export-WarehouseSchema.ps1 with -IncludeDefinitions
    on both environments first. That writes <environment>-<database>.full.json BESIDE the
    ordinary hash export rather than over it, so the small committed-safe file survives.
    A hash-only export carries no text and this script will say so rather than guess.
    Those .full.json files hold the complete SQL of every routine - use them, then delete
    them.

    ⛔ AND IT CHECKS THAT THEY ARE COMPLETE, ROUTINE BY ROUTINE. The export records each
    body's true length from the server; this script compares the text it was given against
    that number and REFUSES any routine that arrived short rather than comparing an excerpt.
    Exports taken before Export-WarehouseSchema.ps1 passed -MaxCharLength cut every body
    over 4,000 characters, and the dangerous half of that was silent: a cut landing on a
    token boundary reads as valid SQL, so two routines agreeing for 4,000 characters and
    diverging at 4,001 came back identical. A truncated run is announced at the top of the
    warehouse, repeated at the end, and exits 2 - it is never reported as agreement.

    WHAT THE LINE NUMBERS MEAN. A reported line number is a line of the STRIPPED AND
    NORMALIZED body, not of the source. Comments and blank lines are gone by then, so it
    will not match the line number in a .sql file. It identifies the differing statement,
    which is what the cleanup needs; the repository remains the authority on the code.

    ⛔ THE TWO LINES PRINTED UNDER "LOGIC DIFFERS" ARE THE CODE AS WRITTEN, NOT AS FOLDED.
    Case folding decides WHETHER a routine is reported; it never decides WHAT is shown. A
    reader looking at a difference needs the text he would find in the repository, not a
    lowercased rendering he would then have to translate back. Folding only ever rewrites a
    token in place, so the folded and unfolded bodies break into lines identically and the
    line the comparison found is the line that gets printed.

.PARAMETER Folder
    A folder of exports. Pairs dev-<database>.full.json with prod-<database>.full.json
    and compares every pair it finds. Use this for all four warehouses at once.

.PARAMETER DevFile
    One development-side .full.json export, when you would rather name the two files.

.PARAMETER ProdFile
    The production-side .full.json export to compare it against.

.PARAMETER IgnoreIdentifierCase
    Also treat identifiers as case-insensitive, so dbo.Orders and dbo.ORDERS are the same
    object and CustNo and CUSTNO are the same column. A Fabric warehouse is case-insensitive,
    so this matches how the two environments actually behave. It is off by default because
    it is a bigger claim than the keyword fold, and the run prints how many routines it moved
    out of "logic differs" so its size is visible rather than assumed.

    It also picks up the built-in function and type names - CAST, INT, VARCHAR, GETDATE -
    which the lexer classes as identifiers rather than keywords.

    ⛔ It does NOT reach string literals or bracketed names. 'East' against 'east', and
    [Order Date] against [ORDER DATE], remain differences with this switch on.

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

.EXAMPLE
    # Treat object and column names as case-insensitive too, the way the warehouse does.
    # The run reports how many routines that moved, which is the number worth seeing before
    # deciding identifier casing is noise.
    .\Compare-RoutineLogic.ps1 -Folder warehouse-schema -IgnoreIdentifierCase

.NOTES
    Exit code 0  nothing differs in logic
              1  at least one routine differs in logic
              2  the comparison could not be run on what was asked for - no tokenizer, no
                 definitions, no pair of files, OR the export truncated at least one body,
                 which makes every other count in the run provisional

    NOT YET RUN AGAINST A LIVE EXPORT. The classification and the tokenizer behavior are
    proved on a constructed fixture covering all three classes, the string-literal trap,
    an absent body, and each case rule: keyword case in three spellings, an object name
    differing only in case, a string literal differing only in case, a bracketed name
    differing only in case, and a column actually named after a reserved word. The
    .full.json shape it reads is the shape Export-WarehouseSchema.ps1 writes, read from
    that script rather than assumed.
#>

#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'Folder')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Folder')] [string] $Folder,
    [Parameter(Mandatory, ParameterSetName = 'Files')]  [string] $DevFile,
    [Parameter(Mandatory, ParameterSetName = 'Files')]  [string] $ProdFile,
    [switch] $IgnoreIdentifierCase,
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

# ⛔ THE TOKEN TYPES WHOSE TEXT IS NEVER TOUCHED, IN ANY MODE. Each one is either data or a
# name the author deliberately wrote in quotes:
#   AsciiStringLiteral / UnicodeStringLiteral      'East' and N'East' - values, not syntax
#   QuotedIdentifier                               [Order Date] - bracketed, so meant literally
#   AsciiStringOrQuotedIdentifier                  "Order Date" - the lexer cannot yet tell
#                                                  which of the two it is, and both are on
#                                                  this list, so it does not need to
# The last one is why this is a list of token types rather than a single test: with
# QUOTED_IDENTIFIER unresolved, a double-quoted run is reported as the ambiguous type, and
# folding it would risk rewriting a string value.
$script:NeverFoldTokenTypes = @(
    'AsciiStringLiteral'
    'UnicodeStringLiteral'
    'QuotedIdentifier'
    'AsciiStringOrQuotedIdentifier'
)

function Split-Routine {
    <#
        One routine body, taken apart by the lexer: the code with every comment removed,
        and the comments on their own.

        A comment is replaced by a SINGLE SPACE, not by nothing, so that /*x*/ between two
        tokens cannot weld them into one word. Any line breaks the comment contained are
        kept with it, so removing a block comment does not pull the following statement up
        onto the previous line.

        THREE RENDERINGS OF THE SAME BODY COME BACK, BUILT IN ONE PASS.
          Code          exactly as written, comments gone. This is what gets PRINTED.
          CodeKeyword   keyword case folded. This is the DEFAULT comparison basis.
          CodeFull      keyword and identifier case folded, for -IgnoreIdentifierCase.
        Having all three is what lets the run say how many routines the identifier fold
        moved: the same body is classified both ways and the two answers are compared.

        ⛔ FOLDING LOWERCASES A TOKEN IN PLACE AND NEVER MOVES ONE. No token is added,
        dropped, or split, and no line break lives inside a keyword or an identifier, so the
        three renderings break into lines identically. That is what makes it safe to find a
        difference in CodeKeyword and then print the corresponding line of Code.
    #>
    param([string] $Text)

    $parser = [Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
    $errors = $null
    $tokens = $parser.GetTokenStream([System.IO.StringReader]::new($Text), [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        # The lexer could not read the text. Saying "identical" about a body nobody could
        # read is the false pass this whole tool exists to avoid.
        return [pscustomobject]@{
            Ok = $false; Reason = $errors[0].Message
            Code = ''; CodeKeyword = ''; CodeFull = ''; Comments = @()
        }
    }

    $code     = [System.Text.StringBuilder]::new()   # as written
    $kwFold   = [System.Text.StringBuilder]::new()   # keywords lowercased
    $fullFold = [System.Text.StringBuilder]::new()   # keywords and identifiers lowercased
    $comments = [System.Collections.Generic.List[string]]::new()

    foreach ($t in $tokens) {
        $type = $t.TokenType.ToString()

        if ($type -eq 'SingleLineComment' -or $type -eq 'MultilineComment') {
            $comments.Add($t.Text)
            $blanked = ' ' + ($t.Text -replace "[^`r`n]", '')
            [void]$code.Append($blanked)
            [void]$kwFold.Append($blanked)
            [void]$fullFold.Append($blanked)
            continue
        }
        if ($type -eq 'EndOfFile') { continue }

        $asWritten = $t.Text
        [void]$code.Append($asWritten)

        if ($script:NeverFoldTokenTypes -contains $type) {
            # ⛔ A VALUE, OR A NAME SOMEBODY QUOTED ON PURPOSE. Untouched in both modes.
            [void]$kwFold.Append($asWritten)
            [void]$fullFold.Append($asWritten)
        }
        elseif ($t.IsKeyword()) {
            # ⛔ THE LEXER'S OWN ANSWER, NOT A LIST OF OURS. It also answers true for a bare
            # column spelled like a reserved word - a column actually named Key comes back as
            # the Key keyword. Folding that one is harmless: it is an identifier, and a
            # warehouse compares identifiers without regard to case anyway.
            $lower = $asWritten.ToLowerInvariant()
            [void]$kwFold.Append($lower)
            [void]$fullFold.Append($lower)
        }
        elseif ($type -eq 'Identifier' -or $type -eq 'Variable') {
            # Object, column and variable names as the lexer sees them - which also means the
            # built-in function and type names, since CAST, INT and GETDATE are not in its
            # keyword table. Folded only when the caller asked for it.
            [void]$kwFold.Append($asWritten)
            [void]$fullFold.Append($asWritten.ToLowerInvariant())
        }
        else {
            # Punctuation, operators, numbers, hex and whitespace. Either case cannot arise
            # or it is part of a literal value; nothing here is folded in either mode.
            [void]$kwFold.Append($asWritten)
            [void]$fullFold.Append($asWritten)
        }
    }

    return [pscustomobject]@{
        Ok = $true; Reason = ''
        Code        = $code.ToString()
        CodeKeyword = $kwFold.ToString()
        CodeFull    = $fullFold.ToString()
        Comments    = $comments.ToArray()
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

        THIS FUNCTION TOUCHES WHITESPACE AND NOTHING ELSE, which is precisely why it can
        still be copied from the export. Case folding happens earlier, in the tokenizer,
        where the lexer can say which run of characters is a keyword and which is a string.
        The export has no tokenizer and folds nothing, so on layout the two remain in step
        and on case this script is deliberately the more forgiving of the two - that is the
        difference the run header announces.
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

        ⛔ FOUND ON THE FOLDED BODIES, REPORTED FROM THE UNFOLDED ONES. $A and $B are the
        comparison basis, so the line it stops on is the line the classification actually
        objected to; $ShowA and $ShowB are the same bodies as the author wrote them, and
        those are what the reader is given. Printing a lowercased line would hand him text
        he could not find in the repository.

        Folding rewrites tokens in place, so the two pairs are line-for-line aligned. The
        bounds check below is a belt on those braces, not an expected path.

        ⛔ -cne, NOT -ne. PowerShell compares strings case-INSENSITIVELY by default, and a
        walk that steps over a line differing only in case would report "no line differs"
        about two bodies this script has just classified as different.
    #>
    param([string] $A, [string] $B, [string] $ShowA, [string] $ShowB)
    $la = $A -split "`n"
    $lb = $B -split "`n"
    $sa = $ShowA -split "`n"
    $sb = $ShowB -split "`n"
    for ($i = 0; $i -lt [Math]::Max($la.Count, $lb.Count); $i++) {
        $x = if ($i -lt $la.Count) { $la[$i] } else { '(no more lines)' }
        $y = if ($i -lt $lb.Count) { $lb[$i] } else { '(no more lines)' }
        if ($x -cne $y) {
            # The line as written wins the printing; the folded line stands in only if the
            # two renderings somehow did not line up.
            $showX = if ($i -lt $sa.Count) { $sa[$i] } else { $x }
            $showY = if ($i -lt $sb.Count) { $sb[$i] } else { $y }
            # ⛔ SAY WHEN THE DIFFERENCE IS ONE THE DISPLAY CANNOT SHOW. The normalization
            # copied from the export collapses a RUN of spaces to one but does not delete
            # a line's indentation, so a body moved in or out by one level still differs -
            # on this tool and on Compare-WarehouseSchema.ps1 alike. Printing the two
            # lines trimmed then showed a reader two identical lines under "line 2", which
            # reads as a broken tool rather than as the finding it is.
            return [pscustomobject]@{
                Line = $i + 1; Dev = $showX; Prod = $showY
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

function Test-DefinitionTruncated {
    <#
        ⛔ DID THE EXPORT DELIVER THE WHOLE BODY, OR THE FIRST PAGE OF IT?

        The export records DEFINITION_LENGTH from LEN(m.definition), computed ON THE SERVER
        before any text crosses the wire. The text beside it made the journey. If the text is
        SHORTER than the length the server reported, what is in the file is an excerpt, and
        every comparison built on it is an excerpt comparison.

        This is not hypothetical. Invoke-Sqlcmd caps character columns at 4,000 characters by
        default, and an export written without -MaxCharLength cut 298 of 928 Shamrock routine
        bodies at exactly 4,000 - the largest of them at 4,000 of 146,190. 120 of those cuts
        landed mid-token and the lexer refused them, which is the visible half. The other 178
        landed on a token boundary, tokenized perfectly, and were compared page-against-page:
        two routines that agree for 4,000 characters and diverge at 4,001 come back IDENTICAL.
        That silent half is why this test exists and why it runs BEFORE the tokenizer.

        ⛔ SHORTER THAN, NEVER NOT EQUAL TO. T-SQL's LEN() does not count trailing whitespace,
        so a body ending in one space or newline reports one character short of its true size
        and the text is legitimately LONGER than DEFINITION_LENGTH - that happened on 175 of
        the same 928 routines. An equality test would condemn every one of them.

        An export with no DEFINITION_LENGTH column cannot be checked, and says so by returning
        $false rather than by guessing: the caller then proceeds exactly as it did before.
    #>
    param($Row, [string] $Text)
    if (-not (Test-HasProperty $Row 'DEFINITION_LENGTH')) { return $false }
    $reported = $Row.DEFINITION_LENGTH
    if ($null -eq $reported -or $reported -is [System.DBNull]) { return $false }
    return ([int]$reported -gt $Text.Length)
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
        return [pscustomobject]@{ Ran = $false; Different = 0; Moved = 0 }
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
    # Bodies the export delivered only part of. Kept apart from $unreadable because the cause
    # and the cure are different: nothing is wrong with these routines, and no amount of
    # reading them will help - the export has to be run again.
    $truncated   = [System.Collections.Generic.List[object]]::new()

    # Routines that -IgnoreIdentifierCase pulled out of "logic differs" - the number that
    # says whether identifier casing was worth folding or was never the problem.
    $movedByIdentifierFold = [System.Collections.Generic.List[string]]::new()

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

        # ⛔ BEFORE THE TOKENIZER, NOT AFTER IT. A truncated body that happens to end on a
        # token boundary tokenizes cleanly and would be compared as though it were whole -
        # the silent false pass. Checking first catches both halves with one test.
        $ta = Test-DefinitionTruncated $devRt[$key]  $a
        $tb = Test-DefinitionTruncated $prodRt[$key] $b
        if ($ta -or $tb) {
            $side = if ($ta -and $tb) { 'both exports' }
                    elseif ($ta)      { 'the development export' }
                    else              { 'the production export' }
            $got  = if ($ta) { $a.Length } else { $b.Length }
            $want = if ($ta) { [int]$devRt[$key].DEFINITION_LENGTH } else { [int]$prodRt[$key].DEFINITION_LENGTH }
            $truncated.Add([pscustomobject]@{
                Key = $key; Side = $side; Got = $got; Want = $want })
            continue
        }

        $sa = Split-Routine $a
        $sb = Split-Routine $b
        if (-not $sa.Ok -or -not $sb.Ok) {
            $why = if (-not $sa.Ok) { $sa.Reason } else { $sb.Reason }
            # The body arrived COMPLETE - the truncation test above already cleared it - and
            # the lexer still could not read it. So this one really is about the text, and
            # saying so is what stops the reader re-exporting to no effect.
            $unreadable.Add([pscustomobject]@{ Key = $key
                Why = ("the export carried the whole body and the tokenizer still could not read it: {0}" -f $why) })
            continue
        }

        # As written, for display. Never the comparison basis - keyword case would come
        # straight back as a difference.
        $rawA = ConvertTo-NormalizedWhitespace $sa.Code
        $rawB = ConvertTo-NormalizedWhitespace $sb.Code

        # Keywords folded: the default basis, and also the "what would this run have said
        # without the switch" baseline that the moved count is measured against.
        $kwA = ConvertTo-NormalizedWhitespace $sa.CodeKeyword
        $kwB = ConvertTo-NormalizedWhitespace $sb.CodeKeyword

        if ($IgnoreIdentifierCase) {
            $cmpA = ConvertTo-NormalizedWhitespace $sa.CodeFull
            $cmpB = ConvertTo-NormalizedWhitespace $sb.CodeFull
            # Folding more can only ever merge two bodies, never split them, so a routine
            # can only move OUT of "logic differs" - which is the one direction worth counting.
            if (($kwA -cne $kwB) -and ($cmpA -ceq $cmpB)) { $movedByIdentifierFold.Add($key) }
        }
        else {
            $cmpA = $kwA
            $cmpB = $kwB
        }

        if ($cmpA -cne $cmpB) {
            $different.Add([pscustomobject]@{
                Key = $key; Diff = (Get-FirstDifferingLine $cmpA $cmpB $rawA $rawB) })
        }
        elseif ((Get-CommentSignature $sa.Comments) -cne (Get-CommentSignature $sb.Comments)) {
            $commentOnly.Add($key)
        }
        else {
            $identical++
        }
    }

    # -- is this run trustworthy at all ------------------------------------
    # ⛔ FIRST, LOUD, AND ON ITS OWN. Every other number below is computed from the routines
    # that were left, so if this one is above zero the reader must know before he reads them
    # and not after. It is printed even for a single routine: one truncated body means the
    # export was taken with the old script, which means every body over 4,000 characters in
    # the folder is an excerpt, which means this whole run is provisional.
    if ($truncated.Count -gt 0) {
        Write-Host ''
        Write-Host ('  ' + ('*' * 74))
        Write-Host ("  ** TRUNCATED EXPORT: {0} NOT COMPARED" -f
                    (Format-Count $truncated.Count 'routine was' 'routines were'))
        Write-Host ('  ' + ('*' * 74))
        Write-Host '    THIS IS NOT A PROBLEM WITH THE SQL, and it is not a tokenizer failure. The'
        Write-Host '    export file holds only the first part of these bodies, so there is nothing'
        Write-Host '    here to compare. The routines themselves are fine.'
        Write-Host ''
        Write-Host '    Cause. Invoke-Sqlcmd returns at most 4,000 characters of a text column'
        Write-Host '    unless it is told otherwise, and an export taken before that was fixed cut'
        Write-Host '    every longer routine at exactly 4,000 - mid-word, mid-string, mid-comment.'
        Write-Host '    The export records the true length from the server, which is how this is'
        Write-Host '    known rather than guessed: the text is shorter than the length beside it.'
        Write-Host ''
        Write-Host '    Fix. Re-export BOTH environments with the current Export-WarehouseSchema.ps1,'
        Write-Host '    which passes -MaxCharLength, then run this again:'
        Write-Host '        .\Export-WarehouseSchema.ps1 -Environment dev  -OutFolder <folder> -IncludeDefinitions'
        Write-Host '        .\Export-WarehouseSchema.ps1 -Environment prod -OutFolder <folder> -IncludeDefinitions'
        Write-Host ''
        Write-Host '    Until then the counts below are provisional. They describe the routines'
        Write-Host '    that survived, not this warehouse.'
        foreach ($t in ($truncated | Sort-Object Key)) {
            Write-Host ("      {0} - {1} carried {2} of {3} characters" -f $t.Key, $t.Side, $t.Got, $t.Want)
        }
    }

    # -- the worklist ------------------------------------------------------
    Write-Host ''
    Write-Host ("  Nothing to do: {0} the same" -f (Format-Count $identical 'routine is' 'routines are'))
    # The subtext names the rules that produced this count, because the count changes with
    # them and a reader arriving mid-output should not have to scroll back for the header.
    if ($IgnoreIdentifierCase) {
        Write-Host '    Same logic and same comments, once layout, keyword case and identifier case'
        Write-Host '    are set aside.'
    }
    else {
        Write-Host '    Same logic and same comments, once layout and keyword case are set aside.'
    }

    # ⛔ THE SWITCH REPORTS ITS OWN EFFECT. He turned identifier folding on to find out what
    # it is worth; a run that quietly swallowed the routines it moved would answer a
    # question he did not ask. Zero is an answer too, and the most useful one.
    if ($IgnoreIdentifierCase) {
        Write-Host ''
        if ($movedByIdentifierFold.Count -eq 0) {
            Write-Host '  Identifier case folding changed nothing on this warehouse.'
            Write-Host '    No routine differed only in the case of an object or column name, so the'
            Write-Host '    list below is the same one a default run would have printed.'
        }
        else {
            Write-Host ("  Identifier case folding moved {0} out of ""logic differs""" -f
                        (Format-Count $movedByIdentifierFold.Count 'routine' 'routines'))
            Write-Host '    Each of these differed ONLY in the case of an object, column or variable'
            Write-Host '    name - or of a built-in like CAST or INT, which the lexer counts as a name.'
            Write-Host '    A default run reports them as differences; the warehouse would not.'
            foreach ($k in ($movedByIdentifierFold | Sort-Object)) { Write-Host ("      {0}" -f $k) }
        }
    }

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
        Write-Host '    The two lines are the code as written - case folding decided whether a routine'
        Write-Host '    is listed here, never how it is printed.'
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
        if ($unreadable.Count -gt 0) {
            Write-Host '    Re-exporting will not change these. Either the body genuinely did not come'
            Write-Host '    back, or it is T-SQL the SQL Server grammar rejects - read the routine.'
        }
    }

    return [pscustomobject]@{
        Ran = $true; Different = $different.Count; Moved = $movedByIdentifierFold.Count
        Truncated = $truncated.Count
    }
}

# ---------------------------------------------------------------------------
# Run.
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host 'Routine logic comparison'

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

# ⛔ SAY WHAT WAS SET ASIDE, ONCE, BEFORE ANY FINDING. Two of these rules make differences
# disappear, and one of them is on whether or not anybody asked. A reader who has to guess
# which rules were in force cannot trust either the list or its length.
Write-Host ''
Write-Host '  Set aside on this run'
Write-Host '    comments          stripped, and counted separately as their own class'
Write-Host '    layout            line endings, tabs, repeated spaces, blank lines'
Write-Host '    keyword case      folded - SELECT, Select and select are one word'
Write-Host '                      the lexer decides what a keyword is; built-ins it calls'
Write-Host '                      names - CAST, INT, VARCHAR, GETDATE - fall under the next line'
if ($IgnoreIdentifierCase) {
    Write-Host '    identifier case   folded - dbo.Orders and dbo.ORDERS are the same object,'
    Write-Host '                      which is how the warehouse itself compares them'
}
else {
    Write-Host '    identifier case   NOT folded - dbo.Orders and dbo.ORDERS are two objects here'
    Write-Host '                      pass -IgnoreIdentifierCase to fold them and see the count'
}
Write-Host '  Never set aside'
Write-Host "    string literals   'East' and 'east' differ in every mode - that is data"
Write-Host '    quoted names      [Order Date] and [ORDER DATE] differ too: brackets mean literal'

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
$totalMoved = 0
$totalTruncated = 0
$ranAny = $false
foreach ($pair in $pairs) {
    $result = Compare-Pair -DevPath $pair.Dev -ProdPath $pair.Prod
    if ($result.Ran) {
        $ranAny = $true
        $totalDifferent += $result.Different
        $totalMoved += $result.Moved
        $totalTruncated += $result.Truncated
    }
}

# Across every warehouse in the folder, since he ran the switch to size one effect and the
# per-pair counts do not add themselves up.
if ($ranAny -and $IgnoreIdentifierCase -and $pairs.Count -gt 1) {
    Write-Host ''
    Write-Host ("  Across all {0} warehouses, identifier case folding moved {1} out of ""logic differs""." -f
                $pairs.Count, (Format-Count $totalMoved 'routine' 'routines'))
}

# ⛔ THE LAST THING ON THE SCREEN, SO IT CANNOT BE SCROLLED PAST. The per-warehouse banners
# are already loud, but a four-warehouse run buries the first of them thousands of lines up.
if ($ranAny -and $totalTruncated -gt 0) {
    Write-Host ''
    Write-Host ("  ** {0} not compared because the export truncated {1} - re-export and run again." -f
                (Format-Count $totalTruncated 'routine was' 'routines were'),
                $(if ($totalTruncated -eq 1) { 'it' } else { 'them' }))
    Write-Host '     Nothing above describes this environment until that is done.'
}

Write-Host ''
if (-not $ranAny) { exit 2 }
# ⛔ A TRUNCATED EXPORT EXITS 2, NEVER 0. "Nothing differs" computed from the first 4,000
# characters of each body is the exact false pass this tool exists to prevent, and a caller
# reading the exit code would bank it. The comparison could not be run on what was asked for,
# which is what 2 has always meant.
if ($totalTruncated -gt 0) { exit 2 }
exit $(if ($totalDifferent -gt 0) { 1 } else { 0 })
