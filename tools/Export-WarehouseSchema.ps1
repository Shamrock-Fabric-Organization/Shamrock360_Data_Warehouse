<#
.SYNOPSIS
    Exports a Fabric Warehouse's schema to a JSON file, so two environments can be compared.

.DESCRIPTION
    The Fabric objects are checked by Compare-FabricEnvironment.ps1. This is the other
    half: the SQL objects. Both are needed, and until now only one existed.

    **The exposure here is narrower than the Fabric side and it is not zero.** SQL comes
    from one repository and one script, so drift takes effort. But the promotion sequence
    executes statements against production BY HAND from VS Code, and nothing guarantees
    both environments received the same ones. "Narrower" is not "checked".

    Captures four things per warehouse:

      tables      name, schema and type of every table and view
      columns     name, position, type, length, precision, scale, nullability
      routines    every procedure, function and view - by default as a HASH of its
                  definition, not the definition itself

    ⛔ TWO HASHES PER ROUTINE, AND THE SECOND ONE IS THE ONE THAT DECIDES.

    DEFINITION_HASH is SHA-256 of the definition exactly as the server holds it. Every
    space, tab, blank line and CRLF goes into it, and SHA-256 is case-sensitive - so a
    tab-for-spaces reindent, or a file saved with LF where the other side has CRLF,
    changes it. These warehouses are rebuilt BY HAND, so that happens, and it raised a
    full "the bodies differ" finding for a change that could not alter what the code does.

    DEFINITION_NORMALIZED_HASH is SHA-256 of the same definition with whitespace
    normalized first: CRLF and lone CR become LF, tabs become spaces, runs of spaces
    collapse to one, trailing whitespace comes off each line, blank lines go, and the
    whole body is trimmed at both ends. Compare-WarehouseSchema.ps1 takes its VERDICT
    from this one, and reports a raw-hash difference under an identical normalized hash
    as whitespace only - counted and named, never a finding.

    ⛔ CASE IS NOT NORMALIZED, DELIBERATELY. Select against SELECT, or dbo.Orders against
    dbo.ORDERS, is a real difference between two hand-rebuilt environments and nobody
    asked for it to be hidden. Lower-casing the body would hide it.

    ⛔ AND ONE THING THE NORMALIZATION DOES HIDE: WHITESPACE INSIDE A STRING LITERAL.
    'a  b' and 'a b' in an error message or a delimiter are DIFFERENT behavior, and
    collapsing runs of spaces makes their normalized hashes identical. Nothing vanishes -
    the raw hash still differs and the comparison still names the routine - but
    "logically identical" is exactly that strong and no stronger. A routine that builds
    text out of spaces has to be read, not accepted on the strength of this hash.

    ⛔ BOTH ARE KEPT. The raw hash is the witness: it is what proves a normalized match
    was a whitespace match and not a hash that stopped covering the whole body.

    ⛔ ROUTINE DEFINITIONS ARE HASHED, NOT STORED. THIS MATTERS.

    The full text of every procedure and view is roughly 3 MB per environment, and it
    is a WORD-FOR-WORD DUPLICATE of database_projects/ in this same repository. Keeping
    it would create exactly the failure this tooling exists to prevent: a second copy of
    the code that drifts the moment anything is deployed, sitting beside the authoritative
    one, waiting for somebody to read the wrong file.

    So a SHA-256 of each definition is stored instead. The comparison detects a changed
    routine exactly as reliably - two different bodies cannot produce the same hash - and
    the export drops from megabytes to kilobytes with no duplication at all.

    ⛔ THE REPOSITORY REMAINS THE AUTHORITY ON THE CODE. This file only ever answers
    "are these two environments the same", never "what does this procedure do".

    -IncludeDefinitions stores the text as well, for the one case that needs it: a
    routine has been reported as differing and you want to see WHERE. Use it for that,
    on the affected warehouse, then delete the file.

    It writes to <environment>-<database>.full.json, NOT over the hash export, so the
    small safe file survives the diagnostic. Compare-WarehouseSchema.ps1 prefers a .full
    export when one is present and says which file it read. The .full files are ignored
    by git - they duplicate database_projects/ and must never be committed.

    ⛔ ROUTINE DEFINITIONS COME FROM sys.sql_modules, NOT INFORMATION_SCHEMA.
    INFORMATION_SCHEMA.ROUTINES.ROUTINE_DEFINITION is nvarchar(4000) and SILENTLY
    TRUNCATES anything longer. usp_CreateDataVirtualizationViews_Prep is several thousand
    lines, so a comparison built on INFORMATION_SCHEMA would compare its first page and
    call the rest identical - the exact class of false pass this tooling exists to prevent.

.PARAMETER Environment
    'dev' or 'prod'. Fills in the endpoint from the values below.

.PARAMETER Endpoint
    A warehouse SQL endpoint, if you would rather give it explicitly.

.PARAMETER Database
    Which warehouse. Omit to export all four.

.PARAMETER OutFolder
    Folder to write into. One file per warehouse, named <environment>-<database>.json,
    or <environment>-<database>.full.json under -IncludeDefinitions.

.PARAMETER TenantId
    Which tenant to get the token for. Needed when you hold accounts in more than one.

.EXAMPLE
    # Both environments, all four warehouses, then compare them.
    .\Export-WarehouseSchema.ps1 -Environment dev  -OutFolder warehouse-schema
    .\Export-WarehouseSchema.ps1 -Environment prod -OutFolder warehouse-schema
    .\Compare-WarehouseSchema.ps1 -Folder warehouse-schema

.NOTES
    Requires two modules:
        Install-Module Az.Accounts -Scope CurrentUser
        Install-Module SqlServer   -Scope CurrentUser

    RUN AGAINST LIVE WAREHOUSES. This note used to read "NOT YET RUN AGAINST A LIVE
    WAREHOUSE", and that is no longer true. As of 2026-09-04 the client reports having
    run this export and Compare-WarehouseSchema.ps1 against all four warehouses in a
    live environment, several times. Sign-in, the SQL token audience below, the two
    endpoints and all three queries therefore work as written against a real Fabric
    Warehouse SQL endpoint - they are no longer inferences from the documentation.

    ⛔ THAT IS WHAT WAS REPORTED, NOT WHAT WAS WATCHED. Nobody maintaining this file was
    at the keyboard for those runs; the evidence is the client's own runs and the output
    they produced. Three things carry no evidence from a live run and are still
    unexercised there:

      -IncludeDefinitions   the .full.json export, and -ShowRoutineDiff reading it
      the failure branch    reached only when ONE warehouse cannot be read while the
                            others can, which no reported run has hit
      DEFINITION_NORMALIZED_HASH
                            added 2026-09-18 and NOT YET RUN AGAINST A LIVE WAREHOUSE.
                            The expression was proved on SQL Server 2022 under
                            Latin1_General_100_BIN2 - the binary collation Fabric
                            Warehouse uses, so REPLACE matches byte for byte the same
                            way - over constructed definitions covering CRLF, tabs,
                            trailing spaces, blank lines, leading and trailing
                            whitespace, a string literal holding a double space, a
                            case-only change and a real logic change. REPLACE, CHAR and
                            HASHBYTES are the only functions it uses and all three are
                            already exercised live by the raw hash beside it. That is
                            strong evidence, and it is not a live run.

    The first two are not on the routine path. The third IS - every export now computes
    it - which is why its evidence is spelled out rather than left as an inference. None
    of the three should be called tested against Fabric until somebody says it ran.
#>

[CmdletBinding()]
param(
    [ValidateSet('dev', 'prod')] [string] $Environment,
    [string]   $Endpoint,
    [string[]] $Database = @('WH_Raw', 'WH_Transform', 'WH_Curated', 'WH_Metadata'),
    [Parameter(Mandatory)] [string] $OutFolder,
    [string]   $TenantId = '80726221-f16a-4d23-87e7-7e389dde5a25',

    # ⛔ OFF BY DEFAULT, AND THAT IS THE POINT. See the header.
    [switch]   $IncludeDefinitions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Read out of the client's own pipeline exports, where each warehouse activity carries
# the endpoint of the workspace it belongs to. Not typed from a portal screen.
$ENDPOINTS = @{
    dev  = 'efrhfadk6eru3b7hpy4j3xs2eu-uqz36rnpmmsetmasru36rmwxsu.datawarehouse.fabric.microsoft.com'
    prod = 'efrhfadk6eru3b7hpy4j3xs2eu-qg2ask2keqhepf4xm5b72jokau.datawarehouse.fabric.microsoft.com'
}

if (-not $Environment -and -not $Endpoint) {
    throw "Give -Environment dev|prod, or -Endpoint explicitly."
}
if (-not $Endpoint) { $Endpoint = $ENDPOINTS[$Environment] }
$label = if ($Environment) { $Environment } else { 'custom' }

foreach ($m in 'Az.Accounts', 'SqlServer') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        throw "$m is not installed. Run: Install-Module $m -Scope CurrentUser"
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module SqlServer   -ErrorAction Stop

$ctx = Get-AzContext
if (-not $ctx) {
    throw "Not signed in. Run: Connect-AzAccount -TenantId $TenantId -AccountId <you@...>"
}
Write-Host ("Signed in as : {0}" -f $ctx.Account.Id)
Write-Host ("Tenant       : {0}" -f $ctx.Tenant.Id)
Write-Host ("Endpoint     : {0}" -f $Endpoint)
Write-Host ''

# ⛔ The warehouse endpoint is a SQL resource, so the token audience is the SQL one -
# NOT the Fabric API audience the other scripts use. Getting this wrong produces a
# login failure that reads like a permissions problem.
$tokenArgs = @{ ResourceUrl = 'https://database.windows.net/' }
if ($TenantId) { $tokenArgs.TenantId = $TenantId }
$token = if ((Get-Command Get-AzAccessToken).Parameters.ContainsKey('AsPlainText')) {
    Get-AzAccessToken @tokenArgs -AsPlainText
} else {
    $t = (Get-AzAccessToken @tokenArgs).Token
    if ($t -is [System.Security.SecureString]) {
        [System.Net.NetworkCredential]::new('', $t).Password
    } else { $t }
}

# ---------------------------------------------------------------------------
# ⛔ THE WHITESPACE NORMALIZATION, BUILT ONE STEP AT A TIME BECAUSE THE FINISHED
# EXPRESSION IS SIXTEEN NESTED REPLACE CALLS AND NOBODY CAN READ, CHECK OR SAFELY EDIT
# THAT. Each line below wraps the one above it, so the file shows the STEPS and the
# server receives ONE expression. Read it top to bottom: that is the order it applies in.
#
# Two collapse markers do the work that a regex would do if T-SQL had one. CHAR(2) and
# CHAR(3) are STX and ETX - control characters that cannot occur in T-SQL source - and
# every one of them is consumed by the step that introduced it. CHAR(1) is the same idea
# used as an anchor: REPLACE cannot say "at the start of the string", so the body is
# bracketed with a character that appears nowhere else and the ends are matched against
# THAT. The bracket comes off on the last line.
#
# ⛔ NO LOWER() AND NO UPPER(). Case is a real difference between two hand-rebuilt
# environments; see the header.
$norm = 'm.definition'
# Line endings first: everything downstream matches on a bare LF.
$norm = "REPLACE($norm, CHAR(13)+CHAR(10), CHAR(10))"   # CRLF -> LF
$norm = "REPLACE($norm, CHAR(13), CHAR(10))"            # a lone CR -> LF
$norm = "REPLACE($norm, CHAR(9), ' ')"                  # tab -> space, so a reindent collapses below
# A run of spaces collapses to one: mark every space as <2><3>, delete every <3><2>
# that a neighbouring pair creates, then unmark. One space marks and unmarks unchanged.
$norm = "REPLACE($norm, ' ', CHAR(2)+CHAR(3))"
$norm = "REPLACE($norm, CHAR(3)+CHAR(2), '')"
$norm = "REPLACE($norm, CHAR(2)+CHAR(3), ' ')"
# Trailing whitespace on a line is now exactly one space before the LF. A line of nothing
# but spaces becomes an empty line here, which the next step then removes.
$norm = "REPLACE($norm, ' '+CHAR(10), CHAR(10))"
# Blank lines: the same collapse, applied to runs of LF.
$norm = "REPLACE($norm, CHAR(10), CHAR(2)+CHAR(3))"
$norm = "REPLACE($norm, CHAR(3)+CHAR(2), '')"
$norm = "REPLACE($norm, CHAR(2)+CHAR(3), CHAR(10))"
# Trim the whole body. After the steps above each end carries at most one LF and one
# space, in that order, so one removal each is enough - and the order below is the order
# they can occur in.
$norm = "CHAR(1)+$norm+CHAR(1)"
$norm = "REPLACE($norm, CHAR(1)+CHAR(10), CHAR(1))"     # leading LF
$norm = "REPLACE($norm, CHAR(1)+' ', CHAR(1))"          # leading space
$norm = "REPLACE($norm, ' '+CHAR(1), CHAR(1))"          # trailing space
$norm = "REPLACE($norm, CHAR(10)+CHAR(1), CHAR(1))"     # trailing LF
$norm = "REPLACE($norm, CHAR(1), '')"                   # the anchor comes off

$QUERIES = @{
    tables = @"
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;
"@
    columns = @"
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
"@
    # sys.sql_modules, not INFORMATION_SCHEMA - see the header. definition is
    # nvarchar(max) here and nvarchar(4000) there.
    # BOTH hashes are computed here in SQL rather than in PowerShell so the definition
    # text never leaves the server unless -IncludeDefinitions asks for it. That is also
    # why the normalization is T-SQL: normalizing in PowerShell would mean shipping every
    # body back to do it.
    routines = @"
SELECT s.name AS ROUTINE_SCHEMA, o.name AS ROUTINE_NAME, o.type_desc AS ROUTINE_TYPE,
       LEN(m.definition) AS DEFINITION_LENGTH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', m.definition), 2) AS DEFINITION_HASH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', $norm), 2) AS DEFINITION_NORMALIZED_HASH
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;
"@
    routinesFull = @"
SELECT s.name AS ROUTINE_SCHEMA, o.name AS ROUTINE_NAME, o.type_desc AS ROUTINE_TYPE,
       LEN(m.definition) AS DEFINITION_LENGTH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', m.definition), 2) AS DEFINITION_HASH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', $norm), 2) AS DEFINITION_NORMALIZED_HASH,
       m.definition AS ROUTINE_DEFINITION
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;
"@
}

if (-not (Test-Path -LiteralPath $OutFolder)) {
    New-Item -ItemType Directory -Force -Path $OutFolder | Out-Null
}

$written = 0
$failed = @()

foreach ($db in $Database) {
    Write-Host ("  {0}" -f $db)
    try {
        $captured = @{}
        foreach ($part in 'tables', 'columns', 'routines') {
            $q = if ($part -eq 'routines' -and $IncludeDefinitions) {
                $QUERIES['routinesFull']
            } else {
                $QUERIES[$part]
            }
            $rows = Invoke-Sqlcmd -ServerInstance $Endpoint -Database $db `
                                  -AccessToken $token -Query $q `
                                  -TrustServerCertificate -ErrorAction Stop
            $captured[$part] = @($rows | Select-Object -Property * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors)
            Write-Host ("      {0,-10} {1,6} row(s)" -f $part, @($rows).Count)
        }

        $out = [pscustomobject]@{
            environment = $label
            definitionsIncluded = [bool]$IncludeDefinitions
            endpoint    = $Endpoint
            database    = $db
            tables      = $captured['tables']
            columns     = $captured['columns']
            routines    = $captured['routines']
        }
        # ⛔ -IncludeDefinitions WRITES A DIFFERENT FILE, and it must. Both modes used to
        # write <label>-<database>.json, so running the documented diagnostic flow replaced
        # the ~1 KB hash export with a ~3 MB full-text one under the same name. The
        # comparison then consumed the full file without remarking on it, and the safe
        # export the folder was supposed to hold was simply gone.
        $suffix = if ($IncludeDefinitions) { '.full' } else { '' }
        $target = Join-Path $OutFolder ("{0}-{1}{2}.json" -f $label, $db, $suffix)
        $out | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $target -Encoding UTF8
        Write-Host ("      wrote {0}" -f (Split-Path -Leaf $target))
        $written++
    }
    catch {
        # One warehouse that cannot be read must not abandon the other three.
        Write-Host ("      FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $failed += $db
    }
}

Write-Host ''
Write-Host ("{0} exported, {1} failed." -f $written, $failed.Count)
if ($failed.Count -gt 0) { Write-Host ("  failed: " + ($failed -join ', ')) -ForegroundColor Red }
Write-Host ''
if ($IncludeDefinitions) {
    Write-Host '⛔ These files carry the FULL SQL TEXT and duplicate database_projects/.'
    Write-Host '   They are named <environment>-<database>.full.json so they do not overwrite'
    Write-Host '   the small hash exports. Use them to locate a difference, then DELETE them.'
    Write-Host '   .gitignore refuses them, but delete them anyway - they go stale immediately.'
    Write-Host ''
}
Write-Host 'Export the other environment, then compare with:'
Write-Host ("  .\Compare-WarehouseSchema.ps1 -Folder {0}" -f $OutFolder)

exit ($(if ($failed.Count -gt 0) { 1 } else { 0 }))
