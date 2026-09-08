# Fabric definition comparison

**Built for Shamrock, 2026-09-02. Intended to be delivered into Shamrock's own repository**, next
to the SQL — not to live here. It is theirs to run and maintain, and it should be versioned with
the thing it checks.

> ⛔ **The procedure for running these lives in the deliverable set**, as
> `docs/deliverables/Shamrock/Fabric-Data-Platform/05-Promotion-Verification-Guide.md` — sign-in,
> export, compare, and how to read the output, with every command filled in.
>
> **This file is the engineering rationale**: why there are two checks, what the classifications
> mean, and which mistakes each guard was built after. Keep the two apart — a procedure that also
> argues with itself is a procedure nobody follows.

---

## What problem this solves

Fabric pipelines, notebooks and semantic models are not in Git and cannot be deployed
automatically. They are promoted by hand — both workspaces open in two windows, copying across what
can be copied.

**Nothing checks the result.** If an activity does not come across, the pipeline still runs. It just
does less. There is no error and no signal.

---

## The two scripts

| Script | What it does | Needs |
|---|---|---|
| `Export-FabricItemDefinition.ps1` | Pulls one item definition from a workspace and writes it to a file | Az.Accounts, a signed-in session |
| `Compare-FabricEnvironment.ps1` | **Compares every object in the tree at once.** The one to run after a promotion | Nothing |
| `Compare-FabricDefinition.ps1` | Compares a single pair, with full detail | Nothing |
| `FabricDefinition.psm1` | Shared logic. Not run directly | — |

**`Compare-FabricEnvironment.ps1` is the everyday one.** It prints a line per object and the
detail only for what differs, so a clean run is short enough to actually read — which is what makes
it realistic to run every time rather than only when something is already suspected.

**The comparison always operates on files. The API is one way to produce them.** That is why there
are two scripts rather than one: comparing files already committed to the repository needs no
authentication at all, and comparing live environments just means exporting twice first.

---

## Suggested repository layout

```
fabric/
  pipelines/
    dev/    pl_dimension_logic.json
    prod/   pl_dimension_logic.json
  notebooks/
    dev/
    prod/
  semantic-models/
    dev/
    prod/
tools/
  FabricDefinition.psm1
  Export-FabricItemDefinition.ps1
  Compare-FabricDefinition.ps1
  Compare-FabricEnvironment.ps1
```

**Object type first, then environment.** The two versions of the same object end up as siblings,
one click apart when comparing. The other way round — `fabric/dev/pipelines/` — puts the pair you
care about in different top-level trees.

**The same filename on both sides is what pairs them.** A file with no counterpart is reported as
`DEV ONLY` or `PROD ONLY` rather than skipped, because a missing export usually means a promotion
step was forgotten.

**Folder names are not hardcoded.** `-Root`, `-DevName` and `-ProdName` all take overrides, and the
object-type folders are discovered rather than listed, so adding `reports/` needs no code change.

⛔ **Committing these exports is arguably worth more than the comparison.** These objects have no
version history today and are recoverable from nowhere but the workspace. Even with no tooling at
all, dated JSON in Git answers "what did production hold last month", which nothing currently can.

---

## Running it

**Check everything after a promotion** — the usual case:

```powershell
.\tools\Compare-FabricEnvironment.ps1
```

Run from the repository root. It finds `fabric/` by itself.

**Check one pair, with full detail:**

```powershell
.\tools\Compare-FabricDefinition.ps1 fabric\pipelines\dev\pl_dimension_logic.json fabric\pipelines\prod\pl_dimension_logic.json
```

**Export a whole environment in one command** — this is the normal way to use it:

```powershell
.	ools\Export-FabricItemDefinition.ps1 -TenantId <guid> -WorkspaceName '<dev workspace>'  -ItemType DataPipeline -OutFolder fabric\pipelines\dev
.	ools\Export-FabricItemDefinition.ps1 -TenantId <guid> -WorkspaceName '<prod workspace>' -ItemType DataPipeline -OutFolder fabric\pipelines\prod
.	ools\Compare-FabricEnvironment.ps1
```

`-ItemType` is what makes it a deliberate choice — `DataPipeline`, `Notebook`, `SemanticModel`,
`Report`, `Dataflow`. Each item lands as `<display name>.json`, which is exactly the filename the
comparison pairs on, so the two folders line up with no renaming.

**Add `-Preview` to see what would be exported without writing anything.** Worth doing the first
time against an unfamiliar workspace.

⛔ **Add `-AllParts` for anything that is not a pipeline.** A pipeline is one content part; a
dataflow is `mashup.pq` plus `queryMetadata.json`, and a semantic model is a set of TMDL files.
Without it only the first part is written. The script warns when it sees more than one part.

**Named items only:**

```powershell
.	ools\Export-FabricItemDefinition.ps1 -WorkspaceName '<prod workspace>' -ItemName pl_dimension_logic, pl_fact_table_data -OutFolder fabric\pipelines\prod
```

⛔ **A name that is not found stops the run.** Exporting four of five requested pipelines and
reporting success is the quiet shortfall this whole tool exists to prevent.

**One item to an exact path:**

```powershell
.\tools\Export-FabricItemDefinition.ps1 -WorkspaceName '<dev workspace>'  -ItemName 'pl_dimension_logic' -OutFile fabric\pipelines\dev\pl_dimension_logic.json
.\tools\Export-FabricItemDefinition.ps1 -WorkspaceName '<prod workspace>' -ItemName 'pl_dimension_logic' -OutFile fabric\pipelines\prod\pl_dimension_logic.json
.\tools\Compare-FabricEnvironment.ps1
```

**The cheap check only** — activity name, type and state, not the bodies:

```powershell
.\tools\Compare-FabricEnvironment.ps1 -Brief
```

**What a clean run looks like:**

```
  pipelines        pl_dimension_logic.json     match
  pipelines        pl_fact_table_data.json     match
  notebooks        (empty)                     SKIPPED        no .json files

Everything matched.
```

---

## Recording decisions — `compare-config.json`

**Two kinds of difference are legitimate and would otherwise be reported forever.** Both are
recorded in a `compare-config.json` at the root of the `fabric` folder. `compare-config.example.json`
here is the template, and holds the same decisions so they are not lost when the live file lives
only in the client's repository.

**`pairs`** — objects whose *name* differs between environments. `pl_DEV_Semantic_Models` and
`pl_PROD_Semantic_Models` are the same pipeline, but nothing about the filenames says so.

⛔ **The tool does not guess this from a DEV/PROD token in the name.** A guess would eventually
pair two objects that merely look related and report them as matching, which is worse than not
pairing them at all.

**`expectedDifferences`** — differences confirmed as deliberate. Shamrock disables the email
activities in development so development runs do not notify the production distribution list; that
is correct behavior, not drift.

⛔ **Accepted differences are set aside and counted, never hidden.** Each run prints how many were
set aside and the recorded reason. An invisible rule is one nobody remembers agreeing to, and the
whole point of this file is that the decision stays readable.

---

## ⛔ Pick ONE export method and use it for both environments

**A manual export from the Fabric interface and an API export are not interchangeable.** Proven by
exporting the same pipeline from the same workspace both ways:

| | `artifactId` |
|---|---|
| Manual UI export (ARM-shaped) | `"[parameters('WH_Curated')]"` |
| `getDefinition` API | `"<the real GUID>"` |

Everything else matches. But that one field appears on every activity that touches a warehouse, so
comparing one of each reports **15 differences on a single pipeline, none of them real.**

**The API export is the better of the two**, for three reasons: it is repeatable with no manual
step to forget, both sides come out the same shape, and it carries the **real** `artifactId` — which
is one of the three values that decide which warehouse an activity reads. The manual export writes
the identical placeholder text in both environments, so that value can never be checked.

⛔ **This is deliberately NOT normalized away.** Hiding the placeholder would let a mixed pair
compare "clean" while the comparison was silently blind to a targeting value. The scripts detect the
mismatch and refuse to let it pass unremarked instead.

---

## Reading the output

**Anything set aside carries a numbered note**, and the summary row that was affected shows the
number. The notes are printed underneath in full.

```
  pipelines    pl_D365_data.json          match                    N1
  pipelines    pl_dimension_logic.json    match                    N3     7 exception(s)
  pipelines    pl_snapshot_logic.json     match

  [N1]  applied 5 time(s)
        An orchestrator export freezes a copy of every pipeline it invokes, and that
        copy goes stale as soon as the child is edited...

  [N3]  applied 15 time(s)
        Email activities are deliberately disabled in development, so development runs
        do not notify the production distribution list. Confirmed 2026-09-02.
```

⛔ **The number is the point.** An earlier version printed `7 allowed: Email activities are
deliberately disabled in...` — truncated by the terminal, and unconnected to the three separate
explanations at the bottom. A reader had to work out which explanation belonged to which row, and
the truncation meant the row said nothing anyway. The number links them.

---

## The two checks, and why both are needed

**CHECK 1 — is production the same item as development?** Every GUID is replaced with a placeholder
before comparing, so the environment differences that *should* exist stop burying the ones that
should not. What survives is real: an activity that did not come across, an expression truncated in
the paste, a step left `Inactive`.

**CHECK 2 — is production pointing at production?** Compares nothing. Lists the GUIDs production
uses and flags any that also appear in development.

⛔ **Neither is sufficient alone, because CHECK 1 deliberately discards exactly what CHECK 2
inspects.** An activity pasted into production with development's connection still attached makes
CHECK 1 report "identical" — while that activity quietly reads the development warehouse. It runs,
it succeeds, and it loads the wrong data. CHECK 2 is the only thing that sees it. Equally, CHECK 2
cannot tell you an activity is missing.

**⛔ CHECK 2 classifies references by what they actually control**, because getting this wrong makes
the check shout about the harmless value and stay silent about the dangerous one:

| Kind | Example | A shared value means |
|---|---|---|
| **targeting** | `workspaceId`, `endpoint`, `artifactId` | **Red flag.** These decide which warehouse is read |
| **credential** | `connection` | Expected. Carries the credential, not the destination |
| **metadata** | `lastModifiedByObjectId` | Nothing. The same person edited both |

**This was learned from the client's own exports, not designed in.** Their `WH_Metadata` and
`WH_Curated` connection GUIDs are **identical** in both environments while `workspaceId` and
`endpoint` differ — one connection object legitimately serving two workspaces on a shared capacity.
An earlier version called that "production may be reading development", which was wrong and would
have sent someone hunting a defect that did not exist.

**Only a shared *targeting* value counts against a run.** A reference the script cannot classify is
reported as `unclassified` rather than assumed safe.

Exit code is `0` when CHECK 1 finds nothing and `1` when it does, so it can become a gate later.

---

## ⛔ An orchestrator export contains more than one pipeline

**A pipeline that invokes children exports with those children embedded alongside it.**
`pl_D365_data` is four definitions in one file: itself with 3 activities, plus
`pl_dimension_logic` (11), `pl_fact_table_data` (5) and `pl_managed_table_data` (7).

**Two things follow, and both have already bitten.**

**An early version read only the first definition.** It compared 3 activities, ignored the other
23, and reported `match` — false confidence, which is worse than no check at all.

**Those embedded copies go stale.** They freeze at the moment the orchestrator was exported. On the
client's files, `pl_D365_data` was exported at 11:43 and the three children it embeds were
re-exported at 14:08, 14:31 and 14:36 after a round of renames — so the orchestrator still carried
the old names hours after they were fixed.

**So only the definition matching the filename is compared**, and the run reports how many embedded
copies it set aside. Each child is compared properly from its own export, which is both current and
not duplicated.

⛔ **An embedded child with no export of its own is reported as `NOT CHECKED`**, not skipped
quietly. `-IncludeEmbedded` compares everything if you want the old behavior.

---

## What is tested and what is not

**Both comparison scripts are tested** against real exported pipeline definitions with differences
planted deliberately — a missing activity, a disabled activity, and a changed expression. All three
were found, and nothing was reported on the parts that had not changed.

`Compare-FabricEnvironment.ps1` was additionally tested against a tree containing an empty object
folder, a file present only in development, and a file present only in production. All three are
reported rather than skipped.

⛔ **`Export-FabricItemDefinition.ps1` has NOT been run against a live tenant.** It is written
against Microsoft's documented API. **The token acquisition is the part to confirm first** — the
script handles both the old and new `Get-AzAccessToken` return shapes, but that has not been proven
against a real sign-in.

---

## Limits worth knowing before relying on this

⛔ **Correction, 2026-09-02.** An earlier version of this file said dataflows cannot be exported by
any Fabric API. **That was wrong.** One page of Microsoft's documentation says so, and the support
table on that same page contradicts it — there is a documented `getDefinition` call for Dataflow
Gen2, returning `mashup.pq` and `queryMetadata.json`. Only **Scorecard** genuinely has no
definition API.

**A dataflow can therefore be exported, but not compared by CHECK 1.** Its definition is Power
Query, not a pipeline with activities, so there is nothing for the activity comparison to walk.
CHECK 2 would still work on it. `New Date Dim` can be captured as a versioned record even though
the structural comparison does not apply.

**A bulk export API exists** that would pull a whole workspace in one call and would suit this
better. It entered public preview in March 2026 and still requires a `?beta=true` query string, so
these scripts use the per-item endpoint, which is generally available.

**Semantic models and notebooks export through the same endpoint** and the export script handles
them. CHECK 1's activity comparison is pipeline-shaped, so for those item types the script reports
what it can and the definition comparison is the useful half.
