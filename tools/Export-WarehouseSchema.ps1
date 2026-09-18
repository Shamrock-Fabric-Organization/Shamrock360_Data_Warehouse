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
    they produced. Two paths carry no evidence either way and are still unexercised:

      -IncludeDefinitions   the .full.json export, and -ShowRoutineDiff reading it
      the failure branch    reached only when ONE warehouse cannot be read while the
                            others can, which no reported run has hit

    Neither is on the routine path. Neither should be called tested until somebody says
    it ran.
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
    # Hashing happens here in SQL rather than in PowerShell so the definition text
    # never leaves the server unless -IncludeDefinitions asks for it.
    routines = @"
SELECT s.name AS ROUTINE_SCHEMA, o.name AS ROUTINE_NAME, o.type_desc AS ROUTINE_TYPE,
       LEN(m.definition) AS DEFINITION_LENGTH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', m.definition), 2) AS DEFINITION_HASH
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
ORDER BY s.name, o.name;
"@
    routinesFull = @"
SELECT s.name AS ROUTINE_SCHEMA, o.name AS ROUTINE_NAME, o.type_desc AS ROUTINE_TYPE,
       LEN(m.definition) AS DEFINITION_LENGTH,
       CONVERT(varchar(64), HASHBYTES('SHA2_256', m.definition), 2) AS DEFINITION_HASH,
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
