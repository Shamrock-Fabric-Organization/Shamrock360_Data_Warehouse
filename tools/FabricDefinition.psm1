<#
    Shared logic for comparing exported Fabric item definitions.

    This is a module rather than duplicated code because two scripts need it:
    Compare-FabricDefinition.ps1 reports on one pair, and
    Compare-FabricEnvironment.ps1 walks a whole folder tree and reports on all of
    them. Both call Compare-FabricDefinitionPair and render the result their own
    way, so the comparison itself is defined exactly once.
#>

Set-StrictMode -Version Latest

$script:GuidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

# A warehouse SQL endpoint hostname. This is environment wiring exactly like a
# connection GUID, and it MUST differ between workspaces:
#
#   dev   ...-uqz36rnpmmsetmasru36rmwxsu.datawarehouse.fabric.microsoft.com
#   prod  ...-qg2ask2keqhepf4xm5b72jokau.datawarehouse.fabric.microsoft.com
#
# Missing this made the first real run report 15, 24, 14 and 5 "differences" on
# four pipelines that were logically identical - one legitimate value repeated
# once per activity. A checker that cries wolf on every run is a checker nobody
# runs, so this is normalized for CHECK 1 and reported by CHECK 2 instead.
$script:EndpointPattern = '[A-Za-z0-9][A-Za-z0-9\-]*(\.[A-Za-z0-9\-]+)*\.fabric\.microsoft\.com'

# ---------------------------------------------------------------------------
# CHECK 2 classifies every environment reference into one of three kinds. Getting
# this wrong makes the check shout about the harmless value and stay quiet about
# the dangerous one, which is worse than not checking at all.
#
# TARGETING - decides WHICH warehouse an activity reads. Proven from the client's
#   own exports: the same activity carries workspaceId 45bf33a4 in development and
#   2b09b481 in production, with a matching endpoint change. A shared value here is
#   a genuine red flag - it would mean one environment reaching into the other.
#
# CREDENTIAL - a reusable connection object. It carries the credential, NOT the
#   destination. On a shared capacity the SAME connection legitimately serves both
#   workspaces: the client's WH_Metadata and WH_Curated connections are identical
#   in both environments while workspaceId and endpoint differ. An earlier version
#   of this check called that "production may be reading development", which was
#   simply wrong and would have sent someone hunting a defect that did not exist.
#
# METADATA - describes WHO edited the item, not what it points at. A shared value
#   means the same person edited both. Meaningless either way.
# ---------------------------------------------------------------------------
$script:TargetingLabels  = @('workspaceId', 'endpoint', 'artifactId', 'targetWorkspaceId')
$script:CredentialLabels = @('connection', 'connectionId', 'externalReferences')
$script:MetadataLabels   = @('lastModifiedByObjectId', 'createdByObjectId', 'lastPublishTime')


function Read-FabricDefinition {
    param([Parameter(Mandatory)][string] $Path, [string] $Label = 'definition')

    if (-not (Test-Path -LiteralPath $Path)) { throw "$Label not found: $Path" }
    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "$Label is empty: $Path" }
    try { return $raw | ConvertFrom-Json }
    catch { throw "$Label is not valid JSON ($Path): $($_.Exception.Message)" }
}


function Get-FabricResources {
    <#
        Returns every pipeline definition in an export, as name + activities.

        ⛔ AN EXPORT IS NOT ALWAYS ONE PIPELINE. An orchestrator that invokes child
        pipelines exports with the CHILDREN EMBEDDED ALONGSIDE IT. The client's
        pl_D365_data carries four resources: itself with 3 activities, plus
        pl_dimension_logic (11), pl_fact_table_data (5) and pl_managed_table_data (7).

        An earlier version read resources[0] only. It therefore compared 3 activities,
        ignored the other 23, and reported "match" - false confidence, which is worse
        than no check at all. Every resource is now returned and compared.

        Fabric hands the same content out in more than one wrapper. An ARM-style export
        nests under resources[].properties, while the getDefinition API returns
        pipeline-content.json with properties at the root. Both are handled here so
        nothing downstream cares where the file came from.
    #>
    param($Json, [string] $Label = 'export')

    $out = @()

    if ($Json.PSObject.Properties.Name -contains 'resources') {
        foreach ($r in @($Json.resources)) {
            if ($r.PSObject.Properties.Name -notcontains 'properties') { continue }
            if ($r.properties.PSObject.Properties.Name -notcontains 'activities') { continue }
            $name = if ($r.PSObject.Properties.Name -contains 'name') { $r.name } else { '(unnamed)' }
            $out += [pscustomobject]@{ Resource = $name; Activities = $r.properties.activities }
        }
    }
    elseif ($Json.PSObject.Properties.Name -contains 'properties' -and
            $Json.properties.PSObject.Properties.Name -contains 'activities') {
        $out += [pscustomobject]@{ Resource = ''; Activities = $Json.properties.activities }
    }
    elseif ($Json.PSObject.Properties.Name -contains 'activities') {
        $out += [pscustomobject]@{ Resource = ''; Activities = $Json.activities }
    }

    if ($out.Count -eq 0) {
        throw "No activity list found in the $Label. Is this a pipeline definition?"
    }
    return $out
}


function Get-FabricActivities {
    # Kept for callers that only want the first definition in a file.
    param($Json, [string] $Label = 'export')
    return (Get-FabricResources -Json $Json -Label $Label)[0].Activities
}


function Get-FabricInventory {
    <#
        Flattens the activity tree to one row per activity.

        The path carries the nesting, so an activity inside a ForEach is not
        confused with a same-named activity elsewhere - which matters here,
        because this platform reuses names like "Error Email from Copy" across
        several branches of the same pipeline.
    #>
    param($Activities, [string] $Prefix = '')

    $rows = @()
    foreach ($a in $Activities) {
        $name  = if ($a.PSObject.Properties.Name -contains 'name') { $a.name } else { '(unnamed)' }
        $type  = if ($a.PSObject.Properties.Name -contains 'type') { $a.type } else { '(untyped)' }
        $state = if ($a.PSObject.Properties.Name -contains 'state' -and $a.state) { $a.state } else { 'Active' }
        $path  = if ($Prefix) {
            if ($Prefix.EndsWith('::')) { "$Prefix $name" } else { "$Prefix > $name" }
        } else { $name }

        $rows += [pscustomobject]@{
            Path = $path; Name = $name; Type = $type; State = $state; Activity = $a
        }

        if ($a.PSObject.Properties.Name -contains 'typeProperties' -and $a.typeProperties) {
            foreach ($branch in @('activities', 'ifTrueActivities', 'ifFalseActivities')) {
                if ($a.typeProperties.PSObject.Properties.Name -contains $branch -and
                    $a.typeProperties.$branch) {
                    $rows += Get-FabricInventory -Activities $a.typeProperties.$branch -Prefix $path
                }
            }
        }
    }
    return $rows
}


function Get-FabricNormalizedActivity {
    <#
        Serializes an activity with every GUID blanked, so only logic differences
        survive the comparison.

        Nested activity branches are stripped first. Without that, a container
        reports a difference merely because one of its children changed - and the
        child is already reported on its own line. One real change would print at
        every level above it.
    #>
    param($Activity)

    $copy = $Activity | ConvertTo-Json -Depth 100 | ConvertFrom-Json
    if ($copy.PSObject.Properties.Name -contains 'typeProperties' -and $copy.typeProperties) {
        foreach ($branch in @('activities', 'ifTrueActivities', 'ifFalseActivities')) {
            if ($copy.typeProperties.PSObject.Properties.Name -contains $branch) {
                $copy.typeProperties.PSObject.Properties.Remove($branch)
            }
        }
    }
    $json = $copy | ConvertTo-Json -Depth 100 -Compress
    $json = [regex]::Replace($json, $script:GuidPattern, '<GUID>')
    return [regex]::Replace($json, $script:EndpointPattern, '<ENDPOINT>')
}


function Get-FabricEnvironmentReferences {
    <#
        Every environment-specific value in the file - GUIDs and endpoint hostnames -
        with the nearest preceding JSON key as a label.

        These are precisely the values CHECK 1 normalizes away, which is why CHECK 2
        exists to look at them directly.

        The label is a readability hint, not a guarantee - it is read off the raw
        text rather than the object model, because a connection reference sits in
        different shapes depending on activity type. The GUID itself is what the
        comparison uses.
    #>
    param([Parameter(Mandatory)][string] $Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    $found = @{}
    foreach ($pattern in @($script:GuidPattern, $script:EndpointPattern)) {
        foreach ($m in [regex]::Matches($raw, $pattern)) {
            $value = $m.Value.ToLower()
            if ($found.ContainsKey($value)) { continue }
            $before = $raw.Substring([Math]::Max(0, $m.Index - 160), [Math]::Min(160, $m.Index)) -replace '\s+', ' '
            $keys = [regex]::Matches($before, '"([A-Za-z][A-Za-z0-9_]*)"\s*:')
            # A GUID inside a Logic Apps connection resource path is not next to a key,
            # so the nearest-key label comes back unlabeled and the value falls through
            # to 'unclassified'. Those paths look like:
            #
            #   /subscriptions/<sub>/resourceGroups/connections-<workspaceId>/providers/
            #    Microsoft.Web/connections/1_<connectionId>_<creator object id>
            #
            # The creator's object id is the same in both environments because the same
            # person made both connections - benign. What decides where the connection
            # POINTS is the subscription and the resource group, and those carry the
            # workspace id, which is classified as targeting wherever it appears keyed.
            $inConnectionPath = ($before -match 'logicAppsConnectionPayload' -or
                                 $before -match '/providers/Microsoft\.Web/connections/')
            $found[$value] =
                if ($keys.Count -gt 0)  { $keys[$keys.Count - 1].Groups[1].Value }
                elseif ($inConnectionPath) { 'connection' }
                else                    { '(unlabeled)' }
        }
    }
    return $found
}


function Get-FabricExportFormat {
    <#
        Which way the file was produced. The two methods are NOT interchangeable.

        A manual export from the Fabric interface is ARM-shaped and PARAMETERIZES the
        artifactId: "artifactId":"[parameters('WH_Curated')]". The getDefinition API
        returns the real GUID. Everything else about the two is the same.

        Comparing one of each therefore reports a DEFINITION DIFFERS on every activity
        that touches a warehouse - 15 of them on pl_dimension_logic - all from this one
        cause. Normalizing it away would be worse than warning: the placeholder really
        does hide the artifact id, so a normalized comparison would be quietly blind to
        one of the three values that decide which warehouse is read.
    #>
    param($Json)
    if ($Json.PSObject.Properties.Name -contains 'resources' -and
        $Json.PSObject.Properties.Name -contains 'contentVersion') { return 'manual' }
    if ($Json.PSObject.Properties.Name -contains 'properties') { return 'api' }
    return 'unknown'
}


function Compare-FabricDefinitionPair {
    <#
    .SYNOPSIS
        Compares one development export against one production export.

    .DESCRIPTION
        Returns a result object rather than printing, so the caller decides how to
        render it. Runs both checks:

          CHECK 1  Every GUID is blanked before comparing, so the environment
                   differences that SHOULD exist stop burying the ones that should
                   not. What survives is real.

          CHECK 2  Lists the GUIDs production uses and flags those that also appear
                   in development, because CHECK 1 deliberately discards exactly
                   that field. An activity pasted into production with
                   development's connection still attached makes CHECK 1 report
                   "identical" while that activity quietly reads the development
                   warehouse.
    #>
    param(
        [Parameter(Mandatory)][string] $DevPath,
        [Parameter(Mandatory)][string] $ProdPath,
        [switch] $Brief,
        $Expected = @(),
        [switch] $IncludeEmbedded
    )

    $devJson  = Read-FabricDefinition -Path $DevPath  -Label 'Development export'
    $prodJson = Read-FabricDefinition -Path $ProdPath -Label 'Production export'

    $devFormat  = Get-FabricExportFormat -Json $devJson
    $prodFormat = Get-FabricExportFormat -Json $prodJson

    $devRes  = @(Get-FabricResources -Json $devJson  -Label 'development export')
    $prodRes = @(Get-FabricResources -Json $prodJson -Label 'production export')

    # ⛔ AN ORCHESTRATOR EXPORT CARRIES FROZEN COPIES OF ITS CHILDREN, and they go stale
    # the moment a child is edited and re-exported on its own. Proven on the client's
    # files: pl_D365_data was exported at 11:43, the three children it embeds were
    # re-exported at 14:08, 14:31 and 14:36 after a round of renames. The embedded
    # copies still held the OLD names.
    #
    # Comparing those copies is worse than useless. The child is already compared from
    # its own file, so the embedded pass adds no coverage - it only reports differences
    # that were fixed hours ago, which trains the reader to disbelieve the tool.
    #
    # So only the definition matching the FILE is compared, and the rest are named in
    # EmbeddedResources so the caller can say what it set aside. -IncludeEmbedded
    # forces the old behavior for anyone who wants it.
    $primary = [System.IO.Path]::GetFileNameWithoutExtension($DevPath)
    $embedded = @()
    if (-not $IncludeEmbedded -and @($devRes).Count -gt 1) {
        $match = @($devRes | Where-Object { $_.Resource -eq $primary })
        if ($match.Count -eq 1) {
            $embedded = @($devRes | Where-Object { $_.Resource -ne $primary } |
                          ForEach-Object { $_.Resource })
            $devRes  = $match
            $prodRes = @($prodRes | Where-Object { $_.Resource -eq $primary })
        }
    }

    # With more than one definition in the file, every activity path is prefixed with
    # its resource name. Without that, an activity in the embedded pl_dimension_logic
    # would collide with the same-named activity in the standalone one.
    function Build-Inventory($resources) {
        $rows = @()
        $multi = (@($resources).Count -gt 1)
        foreach ($r in $resources) {
            $prefix = if ($multi -and $r.Resource) { $r.Resource + ' ::' } else { '' }
            $rows += Get-FabricInventory -Activities $r.Activities -Prefix $prefix
        }
        return $rows
    }

    $devInv  = @(Build-Inventory $devRes)
    $prodInv = @(Build-Inventory $prodRes)

    $devByPath = @{}; foreach ($r in $devInv)  { $devByPath[$r.Path]  = $r }
    $prodByPath = @{}; foreach ($r in $prodInv) { $prodByPath[$r.Path] = $r }

    $findings = @()

    foreach ($p in $devInv.Path) {
        if (-not $prodByPath.ContainsKey($p)) {
            $findings += [pscustomobject]@{
                Kind = 'MISSING IN PROD'; Type = $devByPath[$p].Type; Path = $p
                DevValue = ''; ProdValue = ''; Detail = $p }
        }
    }
    foreach ($p in $prodInv.Path) {
        if (-not $devByPath.ContainsKey($p)) {
            $findings += [pscustomobject]@{
                Kind = 'EXTRA IN PROD'; Type = $prodByPath[$p].Type; Path = $p
                DevValue = ''; ProdValue = ''; Detail = $p }
        }
    }
    foreach ($p in $devInv.Path) {
        if (-not $prodByPath.ContainsKey($p)) { continue }
        $d = $devByPath[$p]; $q = $prodByPath[$p]

        if ($d.Type -ne $q.Type) {
            $findings += [pscustomobject]@{
                Kind = 'TYPE DIFFERS'; Type = $d.Type; Path = $p
                DevValue = $d.Type; ProdValue = $q.Type
                Detail = "$p  dev=$($d.Type)  prod=$($q.Type)" }
        }
        if ($d.State -ne $q.State) {
            $findings += [pscustomobject]@{
                Kind = 'STATE DIFFERS'; Type = $d.Type; Path = $p
                DevValue = $d.State; ProdValue = $q.State
                Detail = "$p  dev=$($d.State)  prod=$($q.State)" }
        }
        if (-not $Brief -and $d.Type -eq $q.Type -and $d.State -eq $q.State) {
            if ((Get-FabricNormalizedActivity -Activity $d.Activity) -ne
                (Get-FabricNormalizedActivity -Activity $q.Activity)) {
                $findings += [pscustomobject]@{
                    Kind = 'DEFINITION DIFFERS'; Type = $d.Type; Path = $p
                    DevValue = ''; ProdValue = ''; Detail = $p }
            }
        }
    }

    # A renamed or missing CONTAINER drags every one of its children into the report:
    # rename a ForEach and its ten activities each appear as MISSING plus EXTRA, so one
    # rename reads as twenty findings. Drop any missing/extra whose parent is already
    # reported - the parent line says everything the child lines would.
    $structural = @($findings | Where-Object { $_.Kind -in @('MISSING IN PROD', 'EXTRA IN PROD') })
    if ($structural.Count -gt 0) {
        $parents = @($structural | ForEach-Object { $_.Detail })
        $findings = @($findings | Where-Object {
            $f = $_
            if ($f.Kind -notin @('MISSING IN PROD', 'EXTRA IN PROD')) { return $true }
            $covered = $false
            foreach ($p in $parents) {
                if ($p -ne $f.Detail -and $f.Detail.StartsWith($p + ' > ')) { $covered = $true; break }
            }
            -not $covered
        })
    }

    # Differences the client has confirmed are deliberate. They are SEPARATED, not
    # discarded: the caller reports how many were set aside and why, so an accepted
    # difference stays visible as a decision rather than becoming an invisible rule.
    $expectedFindings = @()
    if ($Expected -and @($Expected).Count -gt 0) {
        $kept = @()
        foreach ($f in $findings) {
            $matched = $null
            foreach ($rule in @($Expected)) {
                if ($rule.PSObject.Properties.Name -contains 'kind' -and $rule.kind -ne $f.Kind) { continue }
                if ($rule.PSObject.Properties.Name -contains 'activityType' -and
                    $rule.activityType -and $rule.activityType -ne $f.Type) { continue }
                if ($rule.PSObject.Properties.Name -contains 'dev' -and
                    $rule.dev -and $rule.dev -ne $f.DevValue) { continue }
                if ($rule.PSObject.Properties.Name -contains 'prod' -and
                    $rule.prod -and $rule.prod -ne $f.ProdValue) { continue }
                $matched = $rule; break
            }
            if ($matched) {
                # The LABEL travels with the finding so the summary line can say WHAT was
                # allowed rather than just how many. "7 expected" means nothing to someone
                # reading this in six months, or to a customer who was never in the room.
                $label = if ($matched.PSObject.Properties.Name -contains 'label' -and $matched.label) {
                    $matched.label
                } elseif ($matched.PSObject.Properties.Name -contains 'reason' -and $matched.reason) {
                    $r = $matched.reason
                    if ($r.Length -gt 46) { $r.Substring(0, 46).TrimEnd() + '...' } else { $r }
                } else { 'no reason recorded' }
                $expectedFindings += [pscustomobject]@{ Finding = $f; Rule = $matched; Label = $label }
            }
            else { $kept += $f }
        }
        $findings = @($kept)
    }

    $devRefs  = Get-FabricEnvironmentReferences -Path $DevPath
    $prodRefs = Get-FabricEnvironmentReferences -Path $ProdPath

    $refs = @()
    foreach ($g in ($prodRefs.Keys | Sort-Object)) {
        $label = $prodRefs[$g]
        $kind =
            if     ($script:MetadataLabels   -contains $label) { 'metadata' }
            elseif ($script:TargetingLabels  -contains $label) { 'targeting' }
            elseif ($script:CredentialLabels -contains $label) { 'credential' }
            else                                              { 'unclassified' }

        $refs += [pscustomobject]@{
            Value      = $g
            Label      = $label
            Kind       = $kind
            InDev      = $devRefs.ContainsKey($g)
            IsMetadata = ($kind -eq 'metadata')
        }
    }

    return [pscustomobject]@{
        DevPath           = $DevPath
        ProdPath          = $ProdPath
        DevActivityCount  = $devInv.Count
        ProdActivityCount = $prodInv.Count
        DevResources      = @($devRes  | ForEach-Object { $_.Resource })
        ProdResources     = @($prodRes | ForEach-Object { $_.Resource })
        EmbeddedResources = @($embedded)
        DevFormat         = $devFormat
        ProdFormat        = $prodFormat
        FormatMismatch    = ($devFormat -ne $prodFormat -and
                             $devFormat -ne 'unknown' -and $prodFormat -ne 'unknown')

        # If EVERY targeting value matches, the two files are probably from the same
        # workspace rather than two environments. Saying so turns a page of red into
        # one sentence - the author of the run compared dev against dev.
        SameEnvironmentSuspected = (
            @($refs | Where-Object { $_.Kind -eq 'targeting' }).Count -gt 0 -and
            @($refs | Where-Object { $_.Kind -eq 'targeting' -and -not $_.InDev }).Count -eq 0)
        Findings          = $findings
        ExpectedFindings  = $expectedFindings
        References        = $refs
        # Only a SHARED TARGETING value means one environment may be reaching into the
        # other. A shared credential is expected on a common capacity.
        SharedTargeting   = @($refs | Where-Object { $_.InDev -and $_.Kind -eq 'targeting' })
        SharedUnclassified = @($refs | Where-Object { $_.InDev -and $_.Kind -eq 'unclassified' })
        SharedConnections = @($refs | Where-Object { $_.InDev -and $_.Kind -eq 'targeting' })
        Brief             = [bool]$Brief
    }
}

Export-ModuleMember -Function Read-FabricDefinition, Get-FabricResources, Get-FabricActivities,
                              Get-FabricExportFormat, Get-FabricInventory,
                              Get-FabricNormalizedActivity, Get-FabricEnvironmentReferences,
                              Compare-FabricDefinitionPair
