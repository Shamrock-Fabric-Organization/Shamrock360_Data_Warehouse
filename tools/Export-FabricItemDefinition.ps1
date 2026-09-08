<#
.SYNOPSIS
    Exports Fabric item definitions to disk, so two environments can be compared.

.DESCRIPTION
    Pulls item definitions from a Fabric workspace via the REST API and writes them to
    files. Run it once per environment, then hand the folders to
    Compare-FabricEnvironment.ps1.

    ⛔ PICK ONE EXPORT METHOD AND STAY WITH IT. A manual export from the Fabric
    interface is ARM-shaped and writes artifactId as "[parameters('WH_Curated')]".
    This API writes the real GUID. Nothing else differs, but that field sits on every
    activity that touches a warehouse, so comparing a manual export against an API
    export reports differences that are not real. The comparison scripts detect the
    mismatch and warn; the fix is to export both environments the same way.

    The API export is the better of the two: repeatable, identical in shape on both
    sides, and it carries the REAL artifactId - one of the three values that decide
    which warehouse an activity reads. A manual export writes the same placeholder text
    in every environment, so that value can never be checked.

.PARAMETER WorkspaceName
    The workspace to read from, resolved to an id via the API.

.PARAMETER WorkspaceId
    The workspace GUID, if you already know it. Skips the name lookup.

.PARAMETER ItemName
    One or more item display names. Omit to export everything of -ItemType.

.PARAMETER ItemType
    Restrict to one Fabric item type, for example DataPipeline, Notebook,
    SemanticModel, Report, Dataflow. Required when -ItemName is omitted, so that
    "export everything" is always a deliberate choice about what.

    -ItemName and -ItemType COMBINE, and that is deliberate rather than an oversight.
    Given both, the export is the intersection: the named items, restricted to that
    type. Fabric allows two items of different types to carry the same display name,
    so a name alone can be ambiguous - naming the type alongside it is the only way to
    say which one you meant. Do not "fix" this into a mutually exclusive choice.

.PARAMETER OutFolder
    Folder to write into. Each item is written as <display name>.json. Created if it
    does not exist. Use this for one item or many.

.PARAMETER OutFile
    Exact path for a single item. Only valid with exactly one -ItemName.

.PARAMETER AllParts
    Write every part of the definition, not just the main content file.

    ⛔ REQUIRED FOR ANYTHING THAT IS NOT A PIPELINE. A pipeline is a single content
    part, but a dataflow is mashup.pq PLUS queryMetadata.json, and a semantic model is
    a set of TMDL files. Without this only the first part is written, which for those
    types is a silently incomplete export. The script warns when it sees more than one
    part and -AllParts was not given.

    NOT NEEDED FOR PIPELINES, however many you export at once. This is about how many
    parts ONE item has, not how many items are being exported.

    The main part stays at <OutFolder>\<item name>.json, which is the file the
    comparison pairs on. Additional parts go in <OutFolder>\<item name>.parts\ - one
    folder per item, because every item's extras share the same names and writing them
    side by side would have each item overwrite the last.

.PARAMETER TenantId
    Which tenant to get the token for. Needed when you hold accounts in more than one -
    a consultant signing in to a customer's Fabric environment always does.

.PARAMETER Preview
    List what would be exported without writing anything.

.EXAMPLE
    # Every pipeline in the development workspace, in one command.
    .\Export-FabricItemDefinition.ps1 -TenantId <guid> -WorkspaceName 'Shamrock360 DEV EDW' -ItemType DataPipeline -OutFolder fabric\pipelines\dev

.EXAMPLE
    # The same for production, then compare the two.
    .\Export-FabricItemDefinition.ps1 -TenantId <guid> -WorkspaceName 'Shamrock360 EDW' -ItemType DataPipeline -OutFolder fabric\pipelines\prod
    .\Compare-FabricEnvironment.ps1

.EXAMPLE
    # Just two named pipelines.
    .\Export-FabricItemDefinition.ps1 -WorkspaceName 'Shamrock360 EDW' -ItemName pl_dimension_logic, pl_fact_table_data -OutFolder fabric\pipelines\prod

.EXAMPLE
    # See what is there without writing anything.
    .\Export-FabricItemDefinition.ps1 -WorkspaceName 'Shamrock360 EDW' -ItemType DataPipeline -OutFolder . -Preview

.NOTES
    Requires the Az.Accounts module for the access token:
        Install-Module Az.Accounts -Scope CurrentUser
        Connect-AzAccount -TenantId <tenant> -AccountId <you@customer.com>

    ⛔ SIGNING IN AS SOMEBODY ELSE. A cached context is reused silently, so
    Connect-AzAccount can appear to succeed while leaving you on the previous account.
    Clear it with Disconnect-AzAccount first, then connect naming both the tenant and
    the account. This script prints the identity it ends up with, because a
    wrong-tenant sign-in fails as "no workspace named X" - which reads as a missing
    object rather than a wrong login.

    Works for any item type with a definition API: DataPipeline, Notebook,
    SemanticModel, Report, PaginatedReport, Lakehouse, SparkJobDefinition, Environment,
    VariableLibrary, Eventstream, the KQL types, and Dataflow. Only Scorecard has none.

    A bulk export API exists that would pull a whole workspace in one call. It entered
    public preview in March 2026 and still requires a ?beta=true query string, so this
    uses the per-item endpoint, which is generally available.
#>

[CmdletBinding()]
param(
    [string]   $WorkspaceName,
    [string]   $WorkspaceId,
    [string[]] $ItemName,
    [string]   $ItemType,
    [string]   $OutFolder,
    [string]   $OutFile,
    [switch]   $AllParts,
    [string]   $TenantId,
    [switch]   $Preview
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$FabricApi = 'https://api.fabric.microsoft.com'

# ------------------------------------------------------------------ validation
# Checked up front and in plain language. A PowerShell parameter-set error is accurate
# and unreadable, and this script is meant to be handed to somebody who did not write it.
if (-not $WorkspaceName -and -not $WorkspaceId) {
    throw "Give either -WorkspaceName or -WorkspaceId."
}
# ⛔ ENFORCED, not resolved silently. These are two ways of naming ONE workspace, so
# supplying both means the caller holds two beliefs about where the export is coming
# from. The id used to win without a word, which exports the wrong workspace and looks
# like a successful run. There is no useful combination of the two to preserve.
if ($WorkspaceName -and $WorkspaceId) {
    throw "Give -WorkspaceName or -WorkspaceId, not both. They name the same thing, and " +
          "if they disagree the export would silently come from the id."
}
if (-not $OutFolder -and -not $OutFile) {
    throw "Give either -OutFolder (one or many items) or -OutFile (exactly one item)."
}
if ($OutFile -and $OutFolder) {
    throw "Give -OutFolder or -OutFile, not both."
}
if ($OutFile -and @($ItemName).Count -ne 1) {
    throw "-OutFile names one exact file, so it needs exactly one -ItemName. Use -OutFolder for several."
}
if (-not $ItemName -and -not $ItemType) {
    throw "Give -ItemName, or -ItemType to export everything of one type. Exporting a whole " +
          "workspace unfiltered is never what anyone means."
}


function Get-FabricToken {
    <#
        Az.Accounts changed the return shape: older versions hand back a plain string in
        .Token, version 5 and later return a SecureString unless -AsPlainText is passed.
        Both are handled, because a handed-over script should not break on a module
        upgrade nobody connected to it.
    #>
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        throw "Az.Accounts is not installed. Run: Install-Module Az.Accounts -Scope CurrentUser"
    }
    Import-Module Az.Accounts -ErrorAction Stop

    $ctx = Get-AzContext
    if (-not $ctx) {
        throw "Not signed in. Run: Connect-AzAccount -TenantId <tenant> -AccountId <you@customer.com>"
    }

    Write-Host ("Signed in as : {0}" -f $ctx.Account.Id)
    Write-Host ("Tenant       : {0}" -f $ctx.Tenant.Id)
    if ($TenantId -and $ctx.Tenant.Id -ne $TenantId) {
        Write-Host ("  requesting a token for {0} instead" -f $TenantId) -ForegroundColor Yellow
    }
    Write-Host ''

    $tokenArgs = @{ ResourceUrl = $FabricApi }
    if ($TenantId) { $tokenArgs.TenantId = $TenantId }

    if ((Get-Command Get-AzAccessToken).Parameters.ContainsKey('AsPlainText')) {
        return (Get-AzAccessToken @tokenArgs -AsPlainText)
    }
    $t = (Get-AzAccessToken @tokenArgs).Token
    if ($t -is [System.Security.SecureString]) {
        return [System.Net.NetworkCredential]::new('', $t).Password
    }
    return $t
}


function Invoke-Fabric {
    param([string] $Method, [string] $Path, [hashtable] $Headers, $Body)

    $uri = "$FabricApi/v1$Path"
    $callArgs = @{ Method = $Method; Uri = $uri; Headers = $Headers; ErrorAction = 'Stop' }
    if ($null -ne $Body) {
        $callArgs.Body = ($Body | ConvertTo-Json -Depth 20)
        $callArgs.ContentType = 'application/json'
    }
    try { return Invoke-RestMethod @callArgs }
    catch { throw "Fabric API call failed ($Method $uri): $($_.Exception.Message)" }
}


function Get-SafeFileName {
    # A Fabric display name may contain characters Windows will not accept in a path.
    param([string] $Name)
    $out = $Name
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) { $out = $out.Replace($c, '_') }
    return $out
}


function Write-Part {
    param($Part, [string] $Destination)
    $bytes = [Convert]::FromBase64String($Part.payload)
    Set-Content -LiteralPath $Destination -Encoding UTF8 `
                -Value ([System.Text.Encoding]::UTF8.GetString($bytes))
    Write-Host ("      {0}  ({1:N0} bytes)" -f (Split-Path -Leaf $Destination), $bytes.Length)
}

# ---------------------------------------------------------------------------

$headers = @{ Authorization = "Bearer $(Get-FabricToken)" }

if (-not $WorkspaceId) {
    Write-Host "Resolving workspace '$WorkspaceName'..."
    $workspaces = (Invoke-Fabric -Method GET -Path '/workspaces' -Headers $headers).value
    $ws = @($workspaces | Where-Object { $_.displayName -eq $WorkspaceName })

    if ($ws.Count -eq 0) {
        # An empty list is almost always the wrong tenant rather than a wrong name.
        $visible = @($workspaces | ForEach-Object { $_.displayName } | Sort-Object)
        if ($visible.Count -eq 0) {
            throw "No workspace named '$WorkspaceName', and NO workspaces are visible at all. " +
                  "That usually means the token is for the wrong tenant. Check the identity " +
                  "printed above, and pass -TenantId for the customer's tenant."
        }
        throw "No workspace named '$WorkspaceName'. Visible workspaces: " + ($visible -join ', ')
    }
    if ($ws.Count -gt 1) { throw "More than one workspace is named '$WorkspaceName'. Use -WorkspaceId." }
    $WorkspaceId = $ws[0].id
}
Write-Host "Workspace id : $WorkspaceId"
Write-Host ''

$allItems = @((Invoke-Fabric -Method GET -Path "/workspaces/$WorkspaceId/items" -Headers $headers).value)

$targets = $allItems
if ($ItemType) { $targets = @($targets | Where-Object { $_.type -eq $ItemType }) }
if ($ItemName) { $targets = @($targets | Where-Object { $ItemName -contains $_.displayName }) }
$targets = @($targets | Sort-Object displayName)

if ($targets.Count -eq 0) {
    $types = @($allItems | ForEach-Object { $_.type } | Sort-Object -Unique)
    throw "Nothing matched. The workspace holds $($allItems.Count) item(s) of type(s): " +
          ($types -join ', ') + ". Check the -ItemType spelling and -ItemName."
}

# Every name asked for should have been found. Silently exporting four of five requested
# pipelines is exactly the quiet shortfall this whole tool exists to prevent.
if ($ItemName) {
    $found = @($targets | ForEach-Object { $_.displayName })
    $missing = @($ItemName | Where-Object { $found -notcontains $_ })
    if ($missing.Count -gt 0) { throw "Not found in that workspace: " + ($missing -join ', ') }
}

Write-Host ("Exporting {0} item(s):" -f $targets.Count)
foreach ($t in $targets) { Write-Host ("  {0,-22} {1}" -f $t.type, $t.displayName) }
Write-Host ''

if ($Preview) {
    Write-Host 'Preview only - nothing written.' -ForegroundColor Yellow
    return
}

if ($OutFolder -and -not (Test-Path -LiteralPath $OutFolder)) {
    New-Item -ItemType Directory -Force -Path $OutFolder | Out-Null
}

$written = 0
$failed = @()

foreach ($item in $targets) {
    Write-Host ("  {0}" -f $item.displayName)
    try {
        $definition = Invoke-Fabric -Method POST `
            -Path "/workspaces/$WorkspaceId/items/$($item.id)/getDefinition" `
            -Headers $headers -Body @{}

        if (-not $definition.definition -or -not $definition.definition.parts) {
            throw "the API returned no definition parts. Of the item types in normal use only " +
                  "Scorecard has no definition API, so check the item type and your permissions."
        }

        $parts = @($definition.definition.parts)
        $main = @($parts | Where-Object { $_.path -notlike '.platform*' })
        if ($main.Count -eq 0) { throw "the definition contains only metadata parts." }

        if (-not $AllParts -and $main.Count -gt 1) {
            # ⛔ NAME WHAT IS BEING SKIPPED. "2 content parts" tells the reader a decision
            # is needed without giving them anything to decide with - they cannot tell
            # whether the second part is something they need. The path is the answer, and
            # it costs one line.
            Write-Host ("      NOTE: {0} content parts, only the first is written:" -f
                        $main.Count) -ForegroundColor Yellow
            for ($i = 0; $i -lt $main.Count; $i++) {
                $mark = if ($i -eq 0) { 'written ' } else { 'SKIPPED ' }
                Write-Host ("        {0} {1}" -f $mark, $main[$i].path) -ForegroundColor Yellow
            }
            Write-Host '      Re-run with -AllParts to keep them all.' -ForegroundColor Yellow
        }

        $target = if ($OutFile) { $OutFile }
                  else { Join-Path $OutFolder ((Get-SafeFileName $item.displayName) + '.json') }

        Write-Part -Part $main[0] -Destination $target

        if ($AllParts -and $parts.Count -gt 1) {
            # ⛔ EVERY ITEM'S EXTRA PARTS HAVE THE SAME NAMES. A dataflow's second part is
            # always queryMetadata.json and every item carries a .platform, so writing
            # them beside each other means the second item silently overwrites the first,
            # and the third overwrites the second. Exporting seven items would leave one
            # set of extras with no indication that six were destroyed.
            #
            # Each item's extras therefore go in their own folder, named after the item.
            # The MAIN part stays where it was, because that is the file the comparison
            # pairs on and it must remain <item name>.json in the export folder itself.
            $dir = Split-Path -Parent (Resolve-Path -LiteralPath $target)
            $partDir = Join-Path $dir ((Get-SafeFileName $item.displayName) + '.parts')
            if (-not (Test-Path -LiteralPath $partDir)) {
                New-Item -ItemType Directory -Force -Path $partDir | Out-Null
            }
            foreach ($p in $parts) {
                if ($p.path -eq $main[0].path) { continue }
                # A part path can itself contain folders, for a semantic model's TMDL set.
                $rel = $p.path -replace '/', [System.IO.Path]::DirectorySeparatorChar
                $dest = Join-Path $partDir $rel
                $destDir = Split-Path -Parent $dest
                if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
                    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
                }
                Write-Part -Part $p -Destination $dest
            }
        }
        $written++
    }
    catch {
        # One failure must not abandon the other thirteen.
        Write-Host ("      FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $failed += $item.displayName
    }
}

Write-Host ''
Write-Host ("{0} exported, {1} failed." -f $written, $failed.Count)
if ($failed.Count -gt 0) {
    Write-Host ("  failed: " + ($failed -join ', ')) -ForegroundColor Red
}
Write-Host ''
Write-Host 'Then compare the two environments with:'
Write-Host '  .\Compare-FabricEnvironment.ps1'

exit ($(if ($failed.Count -gt 0) { 1 } else { 0 }))
