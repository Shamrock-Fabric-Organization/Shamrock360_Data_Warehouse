<#
.SYNOPSIS
    Compares two exported Fabric item definitions and reports whether they match.

.DESCRIPTION
    Fabric pipelines, notebooks and semantic models are promoted by hand, by copying
    between two open workspaces. Nothing checks the result. This script does.

    Two checks run, and BOTH are needed because each is blind to what the other finds:

      CHECK 1 - Is production the same item as development?
                Every GUID is replaced with a placeholder before comparing, so the
                environment differences that SHOULD exist stop burying the ones that
                should not. What survives is real: an activity that did not come
                across, an expression truncated in the paste, a step left Inactive.

      CHECK 2 - Is production pointing at production?
                Compares nothing. Lists the connection references production uses and
                flags any that ALSO appear in development.

                This exists because CHECK 1 deliberately discards exactly this field.
                An activity pasted into production with development's connection still
                attached makes CHECK 1 report "identical" while that activity quietly
                reads the development warehouse. It runs, it succeeds, and it loads the
                wrong data. CHECK 2 is the only thing that sees it.

    To check every object at once instead of one pair, use Compare-FabricEnvironment.ps1.

.PARAMETER DevPath
    Path to the development export.

.PARAMETER ProdPath
    Path to the production export.

.PARAMETER Brief
    Compare only activity name, type and state - not the activity bodies. The cheap
    check: it catches an activity that did not come across and one that came across
    disabled, which are the two most likely outcomes of copying between windows.

.EXAMPLE
    .\Compare-FabricDefinition.ps1 fabric\pipelines\dev\pl_dimension_logic.json fabric\pipelines\prod\pl_dimension_logic.json

.OUTPUTS
    Exit code 0 when CHECK 1 finds no differences, 1 when it does, so this can be used
    as a gate later. CHECK 2 findings are reported but do not fail the run, because a
    shared GUID is not always wrong - see the note it prints.

.NOTES
    Requires PowerShell 5.1 or later. No modules, no network, no authentication.

    A dataflow CAN be exported, but not compared here. Its definition is Power Query
    (mashup.pq) plus queryMetadata.json, not a pipeline with activities, so CHECK 1 has
    nothing to walk. CHECK 2 would still work on it.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)] [string] $DevPath,
    [Parameter(Mandatory, Position = 1)] [string] $ProdPath,
    [switch] $Brief
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'FabricDefinition.psm1') -Force

function Write-Heading {
    param([string] $Text)
    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host $Text
    Write-Host ('=' * 78)
}

$result = Compare-FabricDefinitionPair -DevPath $DevPath -ProdPath $ProdPath -Brief:$Brief

Write-Host ''
Write-Host "development : $DevPath"
Write-Host "production  : $ProdPath"

if ($result.FormatMismatch) {
    Write-Host ''
    Write-Host ('*' * 78) -ForegroundColor Red
    Write-Host ("  THESE TWO FILES WERE EXPORTED DIFFERENT WAYS  ({0} vs {1})" -f
                $result.DevFormat, $result.ProdFormat) -ForegroundColor Red
    Write-Host '  A manual export from the Fabric interface writes artifactId as' -ForegroundColor Red
    Write-Host "  [parameters('WH_Curated')]; the API writes the real GUID. Every activity" -ForegroundColor Red
    Write-Host '  touching a warehouse will report a difference that is not real.' -ForegroundColor Red
    Write-Host '  Re-export both sides the SAME way before believing anything below.' -ForegroundColor Red
    Write-Host ('*' * 78) -ForegroundColor Red
}

Write-Heading 'CHECK 1 - IS PRODUCTION THE SAME ITEM AS DEVELOPMENT?   (GUIDs normalized)'
Write-Host ("  {0} activities in development, {1} in production" -f
            $result.DevActivityCount, $result.ProdActivityCount)
Write-Host ''

if ($result.Findings.Count -eq 0) {
    if ($Brief) {
        Write-Host '  No differences in activity name, type or state.'
        Write-Host '  (Brief mode: activity bodies were NOT compared. Re-run without -Brief for that.)'
    }
    else {
        Write-Host '  IDENTICAL - same activities, same states, same definitions.'
    }
}
else {
    foreach ($f in $result.Findings) {
        Write-Host ("  {0,-20} {1,-26} {2}" -f $f.Kind, $f.Type, $f.Detail)
    }
    Write-Host ''
    Write-Host ("  {0} difference(s). Each one is real - environment values were normalized out." -f
                $result.Findings.Count)
}

Write-Heading 'CHECK 2 - IS PRODUCTION POINTING AT PRODUCTION?   (listed, not compared)'

if ($result.References.Count -eq 0) {
    Write-Host '  No environment references found in the production export.'
}
else {
    foreach ($r in $result.References) {
        $note = switch ($r.Kind) {
            'targeting'  { 'decides WHICH warehouse is read' }
            'credential' { 'carries the credential, not the destination' }
            'metadata'   { 'who edited the item' }
            default      { 'unclassified' }
        }
        if ($r.InDev -and $r.Kind -eq 'targeting') {
            Write-Host ("  SHARED TARGET {0}   {1,-22} {2}" -f $r.Value, $r.Label, $note) -ForegroundColor Red
        }
        elseif ($r.InDev -and $r.Kind -eq 'unclassified') {
            Write-Host ("  also in dev   {0}   {1,-22} {2}" -f $r.Value, $r.Label, $note) -ForegroundColor Yellow
        }
        elseif ($r.InDev) {
            Write-Host ("  also in dev   {0}   {1,-22} {2} - expected" -f $r.Value, $r.Label, $note)
        }
        else {
            Write-Host ("  prod only     {0}   {1,-22} {2}" -f $r.Value, $r.Label, $note)
        }
    }
    Write-Host ''
    if ($result.SameEnvironmentSuspected) {
        Write-Host '  EVERY targeting value matches, so these two files are probably from the' -ForegroundColor Yellow
        Write-Host '  SAME workspace rather than two environments. That is normal when testing' -ForegroundColor Yellow
        Write-Host '  an export against another export of the same pipeline. If you meant to' -ForegroundColor Yellow
        Write-Host '  compare development against production, check the two paths.' -ForegroundColor Yellow
    }
    elseif ($result.SharedTargeting.Count -gt 0) {
        Write-Host ("  {0} TARGETING value(s) appear in BOTH exports." -f
                    $result.SharedTargeting.Count) -ForegroundColor Red
        Write-Host '  These decide which warehouse is read. A shared one means production may'
        Write-Host '  genuinely be reading development. Investigate each.'
    }
    else {
        Write-Host '  No targeting value is shared - production points at production.'
    }
    if ($result.SharedUnclassified.Count -gt 0) {
        Write-Host ''
        Write-Host ("  {0} unclassified value(s) also appear in both. Judge them yourself; the" -f
                    $result.SharedUnclassified.Count) -ForegroundColor Yellow
        Write-Host '  script does not know whether they control targeting.'
    }
}

Write-Host ''
exit ($(if ($result.Findings.Count -gt 0) { 1 } else { 0 }))
