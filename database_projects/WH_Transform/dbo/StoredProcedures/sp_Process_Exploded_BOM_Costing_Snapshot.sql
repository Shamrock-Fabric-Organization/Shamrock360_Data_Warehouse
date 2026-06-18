CREATE     PROCEDURE [dbo].[sp_Process_Exploded_BOM_Costing_Snapshot]
AS
BEGIN
    -- =====================================================
    -- BOM Explosion Script with Multi-Site Logic
    -- =====================================================
    -- Version History:
    --   v1: Initial release
    --   v2: MAX(ACTIVATIONDATE) per item+site; MAX(PRICECALCID) dedup
    --   v3: Keep ALL activation dates; delta guard (WHERE NOT EXISTS) for incremental load;
    --       MAX(createddatetime) dedup via two-step prelim1
    --   v4 (2026-05-04):
    --       Fix 1 — prelim_step1: removed WHERE NOT EXISTS delta guard.
    --               Proc now processes ALL activation dates on every run (full rerun mode).
    --               TRUNCATE TABLE at INSERT step prevents duplicates.
    --       Fix 2 — stage_expbom_Final: removed AND b.[ACTIVATIONDATE] = fg.[ACTIVATIONDATE]
    --               from the fg subquery join. That condition silently dropped all Level 2+
    --               rows for cross-site subassemblies whose ACTIVATIONDATE differed from the
    --               root FG activation date, making subassemblies appear as direct-material
    --               leaves only. The itempricecalcid join already uniquely identifies the
    --               correct root record — the ACTIVATIONDATE condition was redundant and wrong.
    --       Fix 3 — INSERT: added TRUNCATE TABLE tbl_ExplodedBOM_StandardCost_Snapshot before
    --               INSERT to prevent duplicate rows on full reruns.
    --   v5 (2026-05-12):
    --       Fix 1 — Restructured IIP join in stage_expbom_vwBomCalcTrans to eliminate
    --               versionid fan-out (date-range filter on IIP).
    --       Fix 2 — stage_expbom_Final: changed b.ACTIVATIONDATE → fg.ACTIVATIONDATE.
    --               Root cause of 4-row duplicate: b.ACTIVATIONDATE is the component's
    --               IIP activation date — it varies per component row (a component activated
    --               2025-10-29 still appears with b.ACTIVATIONDATE=2025-10-29 even inside a
    --               2026-05-01 BOM calc, and vice versa via IIP_fallback). fg.ACTIVATIONDATE
    --               is the root FG's activation date — the correct grain for the snapshot.
    --               SELECT DISTINCT could not collapse the duplicates because dw_id (NEWID)
    --               is unique per row, so the only fix was sourcing ACTIVATIONDATE from fg.
    --       Fix 3 — Level1 join to Level0: added AND eb.ITEMPRICECALCID = bct.ITEMPRICECALCID
    --               to the JOIN stage_expbom_Level0 eb condition (Level1 only).
    --               Root cause: join was only eb.RESOURCE = bct.ITEMID. For any FG
    --               with 2+ activations, Level0 has 2 rows (one per activation). Every
    --               component row in prelim2 matched BOTH Level0 rows, producing
    --               cross-activation rows in every Level table. Each cross-activation row
    --               carried the wrong ITEMPRICECALCID (from the other activation's Level0
    --               row) but the correct b.* cost data. In Final, the wrong ITEMPRICECALCID
    --               mapped to the wrong fg row, mixing activation 1 costs into activation 2
    --               output and vice versa. The ITEMPRICECALCID guard prevents this entirely:
    --               each component row now joins only to the Level0 row belonging to the
    --               same BOM calculation.
    --               Note: this guard cannot be applied to Level2+ because at Level2+,
    --               eb.ITEMPRICECALCID = root FG's pricecalcid and bct.ITEMPRICECALCID =
    --               sub-assembly's own pricecalcid — different by design for cross-site BOMs.
    --               Root cause: vwInventItemPrice returns one row per (dataareaid, itemid,
    --               inventdimid, pricecalcid, versionid). When the same pricecalcid exists in
    --               two costing versions, the IIP LEFT JOIN produced 2 rows per bomcalctrans row,
    --               doubling every downstream table (prelim2, Level0-15, ExpBomAll, Final).
    --               SELECT DISTINCT in Final could not collapse the duplicates because dw_id
    --               (NEWID-based) differs between the fan-out rows.
    --               Prior attempts: (1) AND IIP.CurrentActiveCost = 1 on IIP — corrupted
    --               prelim1_maxdt by changing which IIP.activationdate/createddatetime was
    --               returned, causing wrong pricecalcid selection for historical dates.
    --               (2) AND bct.LatestStandardCostFlag = 1 in Final — correct for normal items
    --               but silently dropped 5 legitimate activations where IIPa had no coverage.
    --               Final fix: join IIPa FIRST, then join IIP filtered to IIPa.versionid —
    --               one row per pricecalcid, the temporally-correct version. For gap items
    --               (IIPa IS NULL), IIP_fallback subquery provides the best available version
    --               (CurrentActiveCost DESC) so no activations are dropped. COALESCE in SELECT
    --               combines both paths transparently.
    --       Fix 4 — Level2–Level15 joins: added pfg (stage_expbom_prelim1) join to restrict
    --               each sub-assembly's bct rows to the activation whose date range covers
    --               the root FG's activation date.
    --               Root cause: Fix 2 (fg.ACTIVATIONDATE) correctly unified all rows in an
    --               activation group. But Level2+ joins had no temporal guard — a cross-site
    --               sub-assembly with N activations contributed ALL N activation rows to EACH
    --               FG activation group, inflating TotalCost by N×.
    --               Fix: JOIN stage_expbom_prelim1 pfg ON pfg.ITEMPRICECALCID = eb.ITEMPRICECALCID
    --               AND bct.ACTIVATIONDATE <= pfg.ACTIVATIONDATE AND bct.ToDate >= pfg.ACTIVATIONDATE.
    --               eb.ITEMPRICECALCID = root FG's pricecalcid (propagated through all levels).
    --               pfg.ACTIVATIONDATE = root FG's activation date. The date-range filter ensures
    --               only the sub-assembly activation active at the FG's activation date is used.
    --               Cross-site sub-assemblies with different activation dates (but covering the
    --               FG's date) are correctly included.
    --       Fix 5 — stage_expbom_Final: added LEFT JOIN anti-join against
    --               stage_expbom_Calctype1Intermediate to exclude double-counted rows.
    --               Root cause: when D365 stores a manufactured sub-assembly as calctype=1
    --               (direct material) in a parent BOM calc, the SP includes BOTH that
    --               rolled-up row AND the sub-assembly's own exploded children at deeper
    --               levels, counting the sub-assembly cost twice.  The Level2 row must stay
    --               in the staging tables (Level3 needs it as a join anchor), so the
    --               exclusion must happen at Final.  Two pre-computation steps identify
    --               the affected rows: (1) extract the parent BomPath from every ExpBomAll
    --               row to find which BomPaths have children; (2) join that set back to
    --               ExpBomAll + prelim2 to isolate calctype=1 rows that are intermediate
    --               nodes.  Normal purchased materials (calctype=1, no BOM) have no children
    --               in ExpBomAll so they are never excluded.
    --       Change 2 — stage_expbom_EndDates: new staging table added after stage_expbom_Final.
    --               Computes effective date range per item+site activation using LEAD() over
    --               ACTIVATIONDATE. EndDate = day before next activation date, or 2154-12-31
    --               for the currently active (not yet superseded) record. Since v4 is full
    --               rerun mode, end dates are always recomputed fresh — supersession is handled
    --               automatically on every run without additional logic.
    --       Change 3 — INSERT: modified to JOIN stage_expbom_EndDates and include EndDate
    --               in the output. Requires EndDate DATE column on snapshot table (see DDL).
    --       Fix 7 — Level1–Level15: added CALCTYPE column (from bct) to every Level
    --               SELECT and added AND eb.CALCTYPE IN (1, 2, 5) to the Level2–Level15
    --               eb JOIN condition.
    --               Root cause: D365 bomcalctrans stores one row per cost element for each
    --               BOM component — one physical component row (CALCTYPE=2 manufactured, or
    --               =1 direct material, or =5 sub-assembly) plus N overhead rows (CALCTYPE=9)
    --               and route rows (CALCTYPE=8). Level1 correctly retains all rows for cost
    --               summation. But Level2–Level15 joined to ALL Level(N-1) rows as explosion
    --               anchors, multiplying each Level2 path by the number of cost element rows
    --               (e.g., 12× for a component with 1 physical row + 11 overhead rows).
    --               The fix limits explosion anchors to physical component rows only
    --               (CALCTYPE IN (1,2,5)); overhead and route rows are never BOM structure
    --               and have no sub-BOM to follow. CALCTYPE column is added to all Levels
    --               for UNION ALL compatibility in stage_expbom_ExpBomAll.
    --       Fix 10 — Level1–Level15 prelim1 NOT EXISTS site condition: added
    --               AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE to the NOT EXISTS subquery.
    --               Root cause: the fallback-site path (path 3 of 3 in the site condition)
    --               was blocked for sub-assemblies that switched sites between activations.
    --               The NOT EXISTS checked all historical prelim1 rows for the item at the
    --               root FG's site — finding old records from prior activations — and returned
    --               FALSE, preventing the fallback path from applying. Example: item 11147
    --               was in site 10 for 2025-10-29 and 2026-05-01, then moved to site 20 for
    --               2026-05-11. Root FG site is 10. Old prelim1 records for 11147 at site 10
    --               caused NOT EXISTS to fail, producing zero Level2 rows for 11147 at the
    --               2026-05-11 activation. Fix: scoping NOT EXISTS to the current activation
    --               date asks "is there a record at the root FG's site FOR THIS DATE?" (no)
    --               rather than "has this item EVER been at that site?" (yes). Applied to
    --               Level1–Level15 (15 occurrences via replace_all).
    --       Fix 9 — stage_expbom_vwBomCalcTrans: added AND bv.itemid = bt.itemid to the
    --               bomversion LEFT JOIN.
    --               Root cause: in D365 process manufacturing, a single formula BOM (bomid)
    --               can be assigned to multiple co-product items. bomversion has one row per
    --               co-product sharing that formula. Without the itemid filter, the JOIN
    --               matched all co-product rows, multiplying every bomcalctrans row by the
    --               number of co-products (e.g., 4 co-products = 4× fan-out). Confirmed via
    --               bomid FID01659 with itemids 11855, 11520, 11486, 11591 all sharing the
    --               same formula. Fix pins the JOIN to the specific item that bomcalctable
    --               references (bt.itemid), returning exactly 1 bomversion row.
    --       Fix 8 — Two sources of identical-row fan-out in stage_expbom_prelim2:
    --               (a) prelim1 Step B: no SELECT DISTINCT. Multiple self-referencing
    --               bomcalctrans rows per item (one per CALCTYPE: 0, 2, 8, 9, etc.) share
    --               the same MaxCreatedDatetime. Step B returned N rows per item/activation
    --               with the same PRICECALCID — producing N copies in prelim2 for every
    --               component row that joined to those N prelim1 rows.
    --               Fix: added SELECT DISTINCT to prelim1 Step B — collapses to 1 row per
    --               (DATAAREAID, ITEMID, InventSiteID, ACTIVATIONDATE, PRICECALCID).
    --               (b) IIP join: used date-range filter (activationdate <= b.transdate AND
    --               todate >= b.transdate). When multiple costing versions for the same
    --               pricecalcid have overlapping date ranges, the filter returns M rows per
    --               bomcalctrans row — multiplying vwBomCalcTrans rows by M. Fix 1 comment
    --               said "filtered to IIPa.versionid" but IIPa (vwInventItemPriceAgg) does
    --               not expose versionid — the pin was never implemented. Fix: changed IIP
    --               join condition to AND IIP.activationdate = IIPa.activationdate, which
    --               pins IIP to the single activationdate IIPa resolved. For gap items
    --               (IIPa IS NULL), IIP also returns NULL (NULL equality fails), so COALESCE
    --               falls through to IIP_fallback correctly — no gap coverage lost.
    --               Combined effect: N prelim1 copies × M IIP copies = N×M identical prelim2
    --               rows per source row. For 11855→10777: 4 prelim1 × 4 IIP = 16 copies.
    --               After fix: 1 × 1 = 1 copy.
    --       Fix 6 — Level0–Level15: added fg_ACTIVATIONDATE column (root FG's activation date,
    --               sourced from bct.ACTIVATIONDATE in Level0 and propagated via eb.fg_ACTIVATIONDATE
    --               through Level1–Level15). At Level2–Level15, removed the pfg JOIN (stage_expbom_prelim1
    --               pfg) and replaced with direct date-range conditions on the eb JOIN:
    --               AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE AND bct.ToDate >= eb.fg_ACTIVATIONDATE.
    --               Root cause: the pfg JOIN used a date-range filter (bct.ACTIVATIONDATE <= pfg.ACTIVATIONDATE
    --               AND bct.ToDate >= pfg.ACTIVATIONDATE) that matched ALL root FG activation dates whose
    --               value falls within the sub-assembly's activation window. When a sub-assembly has a wide
    --               ToDate (e.g., 2154-12-31) and the root FG has N activation dates, pfg matches N rows,
    --               multiplying every Level2+ row by N×. The direct date-range comparison against the
    --               propagated fg_ACTIVATIONDATE is exact (one specific target date), so it always returns
    --               0 or 1 match — no fan-out possible.
    --
    --   v6 (2026-05-18):
    --       Fix 12 Option B — Two-part fix for multi-site sub-assembly fan-out at Level2–Level15:
    --
    --               Part A — stage_expbom_item_site_ranked ORDER BY (insufficient alone):
    --               Changed ROW_NUMBER() ORDER BY to rank site 90 last (priority 1) and all
    --               other sites first (priority 0). This ensures the fallback_site chosen for
    --               a sub-assembly is a non-site-90 site when one exists. Does not resolve fan-out
    --               when sub-assemblies have activations at different dates across sites — each
    --               activation has its own rank=1 site because item_site_ranked partitions by
    --               ACTIVATIONDATE. The NOT EXISTS in path 3 (Fix 10) checks exact date equality
    --               against prelim1, so site90's activation at a different date passes NOT EXISTS
    --               regardless of rank.
    --
    --               Part B — NOT EXISTS inside path 3 of Level2–Level15 prelim1 JOIN (the actual fix):
    --               Added AND ( bct.InventSiteID <> '90' OR NOT EXISTS (...) ) to the fallback
    --               branch (path 3) of the site-selection condition at Level2–Level15 (14 occurrences).
    --               Root cause: sub-assembly 11144 has activations at site10 (2025-10-29) and
    --               site90 (2025-11-13). Both cover the root FG activation date 2025-12-22 via
    --               their respective ToDate ranges. item_site_ranked partitions by ACTIVATIONDATE —
    --               each activation has exactly ONE site, making it automatically rank=1 for its own
    --               date. No ranking competition occurs between the two. Fix 10's NOT EXISTS checks
    --               exact ACTIVATIONDATE equality against prelim1: "is there a site10 activation at
    --               exactly 2025-11-13?" → NO → NOT EXISTS = TRUE → site90 included as fallback →
    --               fan-out persists regardless of ORDER BY change in Part A.
    --               Fix: inside path 3 only, after Fix 10's NOT EXISTS, add a second guard:
    --               non-site-90 rows always pass; site-90 rows are blocked if ANY non-site-90
    --               activation in prelim2 covers the FG date via date range (ACTIVATIONDATE <= fg
    --               AND ToDate >= fg). Uses prelim2 (has ToDate) not prelim1 (lacks ToDate).
    --               Not applied to path 2 (direct site match) — site90 FGs are unaffected.
    --               Not applied to Level1 — Level1 only explodes direct children of Level0 root
    --               FGs, which are always at the FG's own site via direct match (path 2).
    --               Design intent: site 90 is always last resort — new sites added in future
    --               are automatically preferred without any code change.
    --               Confirmed fix for: 11948 (~1.85×, sub-assembly 11290, site20 vs site90),
    --               11725/11941/11968 (~1.50×, sub-assembly 11144, site10 vs site90).
    --       Change 2 — Manual cost override logic (ITEM-012):
    --               Two new staging tables built from vwInventItemPrice:
    --               stage_expbom_iip_latest: latest IIP record per (dataareaid, itemid,
    --               inventsiteid, activationdate) via ROW_NUMBER on createddatetime DESC.
    --               stage_expbom_iip_deduped: manual cost periods only — activation dates
    --               where NO site has a pricecalcid, AND the item has at least one other
    --               activation date with a pricecalcid (item_ever_has_bom_calc=1). Pure
    --               purchased materials (never have pricecalcid) are excluded — they
    --               always use BOM calc's stored COSTPRICE. Enddate computed via LEAD() on
    --               DISTINCT (dataareaid, itemid, activationdate) across ALL sites, giving
    --               the tightest possible window (day before next activation on any site).
    --               Level2–Level15 NOT EXISTS guard: when the explosion anchor (eb.RESOURCE)
    --               has a manual cost covering the FG's activation date, its old BOM
    --               sub-components are blocked. Prevents double-counting when a sub-assembly
    --               switches from BOM calc to manual cost mid-period (ToDate extends past
    --               the manual cost start). Guard added after CALCTYPE IN (1,2,5) check,
    --               14 occurrences at Level2–Level15 only. Level1 unaffected (root FG
    --               anchors cannot be manual cost — they have no Level0 rows if they are).
    --               Part 1 — stage_expbom_Final: LEFT JOIN iip_deduped on component
    --               (b.RESOURCE) + site + FG activation date range. When matched, COSTPRICE
    --               and CostPerUnit are overridden with the IIP manual price. BOM calc
    --               components return no match — ISNULL falls back to bomcalctrans COSTPRICE.
    --               Part 2 — INSERT into stage_expbom_Final: root FGs whose activation date
    --               is a manual cost period have no prelim1 rows → no explosion → absent
    --               from Final. A single leaf row per (dataareaid, itemid, inventsiteid,
    --               activationdate) is inserted, sourced from iip_deduped, filtered to
    --               items confirmed as root FGs (appear in stage_expbom_prelim1).
    --               Reference item: 11074 — 4 activation dates alternating BOM calc /
    --               manual cost across 3 sites.
    -- Prerequisite DDL (run once before deploying v5):
    --   ALTER TABLE [dbo].[tbl_ExplodedBOM_StandardCost_Snapshot] ADD EndDate DATE NULL;
    -- =====================================================

    -- Drop existing tables if they exist
    DROP TABLE IF EXISTS stage_expbom_vwBomCalcTrans;
    DROP TABLE IF EXISTS stage_expbom_prelim_step0;
    DROP TABLE IF EXISTS stage_expbom_prelim_step1;
    DROP TABLE IF EXISTS stage_expbom_prelim1_maxdt;
    DROP TABLE IF EXISTS stage_expbom_prelim1;
    DROP TABLE IF EXISTS stage_expbom_item_MULTIPLE_SITES;
    DROP TABLE IF EXISTS stage_expbom_item_site_ranked;
    DROP TABLE IF EXISTS stage_expbom_item_fallback_site;
    DROP TABLE IF EXISTS stage_expbom_prelim2;
    DROP TABLE IF EXISTS stage_expbom_Level0;
    DROP TABLE IF EXISTS stage_expbom_Level1;
    DROP TABLE IF EXISTS stage_expbom_Level2;
    DROP TABLE IF EXISTS stage_expbom_Level3;
    DROP TABLE IF EXISTS stage_expbom_Level4;
    DROP TABLE IF EXISTS stage_expbom_Level5;
    DROP TABLE IF EXISTS stage_expbom_Level6;
    DROP TABLE IF EXISTS stage_expbom_Level7;
    DROP TABLE IF EXISTS stage_expbom_Level8;
    DROP TABLE IF EXISTS stage_expbom_Level9;
    DROP TABLE IF EXISTS stage_expbom_Level10;
    DROP TABLE IF EXISTS stage_expbom_Level11;
    DROP TABLE IF EXISTS stage_expbom_Level12;
    DROP TABLE IF EXISTS stage_expbom_Level13;
    DROP TABLE IF EXISTS stage_expbom_Level14;
    DROP TABLE IF EXISTS stage_expbom_Level15;
    DROP TABLE IF EXISTS stage_expbom_iip_latest;              -- v6 Change 2
    DROP TABLE IF EXISTS stage_expbom_iip_deduped;             -- v6 Change 2
    DROP TABLE IF EXISTS stage_expbom_ExpBomAll;
    DROP TABLE IF EXISTS stage_expbom_Final;
    DROP TABLE IF EXISTS stage_expbom_EndDates;    -- v5: new staging table
    DROP TABLE IF EXISTS stage_expbom_ParentPaths;             -- v5 Fix 5
    DROP TABLE IF EXISTS stage_expbom_Calctype1Intermediate;   -- v5 Fix 5

    -- =====================================================
    -- PRELIMINARY TABLES
    -- =====================================================
    CREATE TABLE stage_expbom_vwBomCalcTrans
    AS
    SELECT b.*
        ,l.accountingcurrency
        ,l.reportingcurrency
        ,bt.bomid
        ,bt.itemid
        ,bt.inventdimid inventdimid_bomcalctable
        ,bv.active
        ,bv.approved
        ,id.inventsiteid
        ,COALESCE(IIP.activationdate, IIP_fallback.activationdate) activationdate
        ,COALESCE(IIP.todate, IIP_fallback.todate) todate
        ,COALESCE(IIP.versionid, IIP_fallback.versionid) versionid
        ,COALESCE(IIP.price, IIP_fallback.price) price
        ,COALESCE(IIP.priceunit, IIP_fallback.priceunit) priceunit
        ,COALESCE(IIP.PricePerUnit, IIP_fallback.PricePerUnit) PricePerUnit
        ,COALESCE(IIP.unitid, IIP_fallback.unitid) unitid_inventitemprice
        ,ISNULL(COALESCE(IIP.CurrentActiveCost, IIP_fallback.CurrentActiveCost), 0) CurrentActiveCost
        ,CASE WHEN IIPa.dataareaid IS NULL THEN 0 ELSE 1 END LatestStandardCostFlag
        ,CASE WHEN calctype IN (5,8,9,10) THEN 1 ELSE 0 END MultiLevelcalc
        ,CASE WHEN calctype IN (2,5,8) THEN 1 ELSE 0 END SingleLevelcalc
        ,CASE WHEN calctype = 0 THEN 1 ELSE 0 END TotalLevelCalc
        ,CASE b.costgroupid
            WHEN 'DirectMatl' THEN 'Direct_Material_Cost_Standard'
            WHEN 'Packaging' THEN 'Packaging_Cost_Standard'
            WHEN 'AdminOVH' THEN 'Overhead_Manufacturing_Admin_Cost_Standard'
            WHEN 'DeprcOVH' THEN 'Overhead_Depreciation_Cost_Standard'
            WHEN 'Labor' THEN 'Direct_Labor_Cost_Standard'
            WHEN 'MiscOVH' THEN 'Overhead_Miscellaneous_Manufacturing_Cost_Standard'
            WHEN 'MtnceOVH' THEN 'Overhead_Maintenance_Cost_Standard'
            WHEN 'QCOVH' THEN 'Overhead_Quality_Cost_Standard'
            WHEN 'SupvOVH' THEN 'Overhead_Indirect_Supervisor_Cost_Standard'
            WHEN 'Utility' THEN 'Direct_Utility_Cost_Standard'
            WHEN 'Utility0' THEN 'Direct_Utility_Cost_Standard'
            WHEN 'WhseOVH' THEN 'Overhead_Warehouse_Cost_Standard'
            WHEN 'Subcontrct' THEN 'Outside_Processing_Cost_Standard'
            ELSE 'Unknown - ' + b.costgroupid
            END CostGroup
        ,CASE WHEN bcg.costgroupbehavior_$label IN ('variable','undefined') THEN cast(round(b.costpriceqty, 4) AS DECIMAL(38, 4)) END VariableCost
        ,CASE WHEN bcg.costgroupbehavior_$label IN ('fixed') THEN cast(round(b.costpriceqty, 4) AS DECIMAL(38, 4)) END FixedCost
        ,isnull(CASE WHEN bcg.costgroupbehavior_$label IN ('variable','undefined') THEN cast(round(b.costpriceqty, 4) AS DECIMAL(38, 4)) END, 0)
         + isnull(CASE WHEN bcg.costgroupbehavior_$label IN ('fixed') THEN cast(round(b.costpriceqty, 4) AS DECIMAL(38, 4)) END, 0) TotalCost
        ,bcg.costgroupbehavior_$label
        ,COALESCE(IIP.createddatetime, IIP_fallback.createddatetime) PriceCreatedDatetime
        ,id.configid
    FROM WH_Raw.dbo.bomcalctrans b
    JOIN WH_Raw.dbo.bomcalctable bt
        ON b.dataareaid = bt.dataareaid
            AND b.pricecalcid = bt.pricecalcid
    JOIN (
        SELECT DISTINCT
            zbt.dataareaid
            , zbt.pricecalcid
        FROM WH_Raw.dbo.bomcalctable zbt
        JOIN WH_Raw.dbo.inventitemprice ziip
            ON  ziip.dataareaid  = zbt.dataareaid
            AND ziip.pricecalcid = zbt.pricecalcid
    ) activated
        ON  bt.dataareaid  = activated.dataareaid
        AND bt.pricecalcid = activated.pricecalcid
    LEFT JOIN WH_Raw.dbo.bomversion bv
        ON b.dataareaid = bv.dataareaid
            AND bt.bomid = bv.bomid
            AND bv.itemid = bt.itemid    -- Fix 9: formula BOMs shared across co-products have one bomversion row per co-product item; without this, the JOIN matches all co-product rows, multiplying every bomcalctrans row by the number of co-products
    JOIN WH_Raw.dbo.bomcostgroup bcg
        ON b.dataareaid = bcg.dataareaid
            AND b.costgroupid = bcg.costgroupid
    JOIN WH_Raw.dbo.inventdim id
        ON bt.inventdimid = id.inventdimid
            AND b.dataareaid = id.dataareaid
    -- ── v5 Fix 1 — IIP join restructured to eliminate versionid fan-out ─────────
    -- IIPa joined first: determines which costing version was active at b.transdate.
    -- IIP then filtered to activationdate <= b.transdate AND todate >= b.transdate — one row
    -- per pricecalcid for normal items (same date-range logic as IIPa; vwInventItemPriceAgg
    -- does not expose versionid).
    -- IIP_fallback handles 5 gap items where IIPa has no coverage (LatestStandardCostFlag=0
    -- for all versions). Fallback picks CurrentActiveCost DESC — keeps gaps in snapshot.
    -- COALESCE(IIP.x, IIP_fallback.x) in SELECT provides seamless coverage for both paths.
    LEFT JOIN WH_Raw.dbo.vwInventItemPriceAgg IIPa
        ON b.dataareaid = IIPa.dataareaid
            AND bt.itemid = IIPa.itemid
            AND b.pricecalcid = IIPa.pricecalcid
            AND IIPa.activationdate <= b.transdate
            AND IIPa.todate >= b.transdate
            AND IIPa.pricetypedesc = 'Cost'
    LEFT JOIN WH_Raw.dbo.vwInventItemPrice IIP
        ON b.dataareaid = IIP.dataareaid
            AND bt.itemid = IIP.itemid
            AND bt.inventdimid = IIP.inventdimid
            AND b.pricecalcid = IIP.pricecalcid
            AND IIP.activationdate = IIPa.activationdate    -- v5 Fix 8: pin IIP to the exact activationdate IIPa found; eliminates versionid fan-out when multiple versions share overlapping date ranges
    LEFT JOIN (
        SELECT dataareaid, itemid, inventdimid, pricecalcid, versionid
            , activationdate, todate, price, priceunit, PricePerUnit
            , unitid, CurrentActiveCost, createddatetime
        FROM (
            SELECT *
                , ROW_NUMBER() OVER (
                    PARTITION BY dataareaid, itemid, inventdimid, pricecalcid
                    ORDER BY CurrentActiveCost DESC, activationdate DESC
                ) AS iip_fb_rn
            FROM WH_Raw.dbo.vwInventItemPrice
        ) fb_ranked
        WHERE iip_fb_rn = 1
    ) IIP_fallback
        ON IIPa.dataareaid IS NULL              -- v5: only activate for gap items
            AND b.dataareaid = IIP_fallback.dataareaid
            AND bt.itemid = IIP_fallback.itemid
            AND bt.inventdimid = IIP_fallback.inventdimid
            AND b.pricecalcid = IIP_fallback.pricecalcid
    -- ─────────────────────────────────────────────────────────────────────────
    LEFT JOIN WH_Raw.dbo.ledger l
        ON b.dataareaid = l.name;


    -- prelim_step0: distinct DATAAREAID + ITEMID + InventSiteID + ACTIVATIONDATE
    -- from vwBOMCALCTRANS where ACTIVATIONDATE is in the past.
    CREATE TABLE stage_expbom_prelim_step0 AS
    SELECT DISTINCT b.[DATAAREAID]
        , b.[ITEMID]
        , b.InventSiteID
        , b.ACTIVATIONDATE
    FROM stage_expbom_vwBomCalcTrans b
    WHERE b.[ACTIVATIONDATE] < CURRENT_TIMESTAMP;

    -- ── prelim_step1 (v4: delta guard removed — full rerun mode) ─────────────
    CREATE TABLE stage_expbom_prelim_step1 AS
    SELECT DISTINCT b.[DATAAREAID]
        , b.[ITEMID]
        , b.InventSiteID
        , b.ACTIVATIONDATE
    FROM stage_expbom_prelim_step0 b;

    -- ── v6 Change 2: IIP Staging — Manual Cost Periods ──────────────────────
    -- Step 1: latest IIP record per (dataareaid, itemid, inventsiteid, activationdate).
    -- ROW_NUMBER picks the most recently created record when multiple costing versions
    -- exist for the same item+site+date.
    CREATE TABLE stage_expbom_iip_latest AS
    SELECT
        dataareaid
        , itemid
        , inventsiteid
        , activationdate
        , pricecalcid
        , PricePerUnit
        , priceunit
        , versionid
        , CurrentActiveCost
        , ROW_NUMBER() OVER (
            PARTITION BY dataareaid, itemid, inventsiteid, activationdate
            ORDER BY createddatetime DESC
          ) AS rn
    FROM WH_Raw.dbo.vwInventItemPrice
    WHERE activationdate < CURRENT_TIMESTAMP;

    -- Step 2: manual cost periods only.
    -- has_bom_calc determined at (dataareaid, itemid, activationdate) level across ALL sites:
    --   BOM calc  = at least one site has a pricecalcid for that date → excluded
    --   Manual    = no site has a pricecalcid for that date → included
    -- Enddate computed via LEAD() on DISTINCT (dataareaid, itemid, activationdate) across
    -- ALL sites — ensures the window ends the day before the next activation on ANY site,
    -- preventing over-wide windows when a site lacks an intermediate activation date.
    CREATE TABLE stage_expbom_iip_deduped AS
    SELECT
        c.dataareaid
        , c.itemid
        , c.inventsiteid
        , c.activationdate
        , d.enddate
        , c.PricePerUnit
        , c.priceunit
        , c.versionid
        , c.CurrentActiveCost
    FROM (
        SELECT
            dataareaid
            , itemid
            , inventsiteid
            , activationdate
            , pricecalcid
            , PricePerUnit
            , priceunit
            , versionid
            , CurrentActiveCost
            , MAX(CASE WHEN pricecalcid IS NOT NULL THEN 1 ELSE 0 END)
                OVER (PARTITION BY dataareaid, itemid, activationdate) AS has_bom_calc
        , MAX(CASE WHEN pricecalcid IS NOT NULL THEN 1 ELSE 0 END)
                OVER (PARTITION BY dataareaid, itemid)                 AS item_ever_has_bom_calc
        FROM stage_expbom_iip_latest
        WHERE rn = 1
    ) c
    JOIN (
        SELECT dataareaid, itemid, activationdate
            , ISNULL(
                DATEADD(DAY, -1, LEAD(activationdate) OVER (
                    PARTITION BY dataareaid, itemid ORDER BY activationdate
                )),
                CAST('2154-12-31' AS DATE)
              ) AS enddate
        FROM (
            SELECT DISTINCT dataareaid, itemid, activationdate
            FROM stage_expbom_iip_latest
            WHERE rn = 1
        ) distinct_dates
    ) d ON d.dataareaid = c.dataareaid
        AND d.itemid = c.itemid
        AND d.activationdate = c.activationdate
    WHERE c.has_bom_calc = 0              -- this activation date has no BOM calc on any site
        AND c.item_ever_has_bom_calc = 1; -- item has a BOM calc on at least one other date — pure purchased materials excluded
    -- ─────────────────────────────────────────────────────────────────────────

    -- ── prelim1 Step A: MAX(createddatetime) per group ───────────────────────
    CREATE TABLE stage_expbom_prelim1_maxdt AS
    SELECT p.[DATAAREAID]
        , p.[ITEMID]
        , p.InventSiteID
        , p.ACTIVATIONDATE
        , MAX(b.createddatetime) AS MaxCreatedDatetime
    FROM stage_expbom_prelim_step1 p
    JOIN stage_expbom_vwBomCalcTrans b
        ON  p.[DATAAREAID]   = b.[DATAAREAID]
        AND p.[ITEMID]       = b.[ITEMID]
        AND p.InventSiteID   = b.InventSiteID
        AND p.ACTIVATIONDATE = b.[ACTIVATIONDATE]
        AND p.[ITEMID]       = b.[RESOURCE]
    GROUP BY p.[DATAAREAID]
        , p.[ITEMID]
        , p.InventSiteID
        , p.ACTIVATIONDATE;

    -- ── prelim1 Step B: join back to get PRICECALCID for MAX createddatetime ─
    -- v5 Fix 8: SELECT DISTINCT added. The self-referencing bomcalctrans rows for an item
    -- (ITEMID=RESOURCE) include one row per cost element (CALCTYPE 0/2/8/9 etc.), all sharing
    -- the same createddatetime. Without DISTINCT, Step B returns N rows per item (one per
    -- matching CALCTYPE), all with the same PRICECALCID. The N duplicate prelim1 rows then
    -- fan-out into prelim2: each bomcalctrans row for that item joins to N prelim1 rows,
    -- producing N copies. DISTINCT collapses to exactly 1 row per (DATAAREAID, ITEMID,
    -- InventSiteID, ACTIVATIONDATE, PRICECALCID).
    CREATE TABLE stage_expbom_prelim1 AS
    SELECT DISTINCT m.[DATAAREAID]
        , m.[ITEMID]
        , m.InventSiteID
        , m.ACTIVATIONDATE
        , b.[PRICECALCID] AS ITEMPRICECALCID
    FROM stage_expbom_prelim1_maxdt m
    JOIN stage_expbom_vwBomCalcTrans b
        ON  m.[DATAAREAID]       = b.[DATAAREAID]
        AND m.[ITEMID]           = b.[ITEMID]
        AND m.InventSiteID       = b.InventSiteID
        AND m.ACTIVATIONDATE     = b.[ACTIVATIONDATE]
        AND m.MaxCreatedDatetime = b.createddatetime
        AND m.[ITEMID]           = b.[RESOURCE];

    -- =====================================================
    -- MULTI-SITE LOGIC TABLES
    -- =====================================================
    CREATE TABLE stage_expbom_item_MULTIPLE_SITES AS
    SELECT dataareaid
        , itemid
        , COUNT(DISTINCT inventsiteid) nbr_sites
    FROM stage_expbom_prelim1
    GROUP BY dataareaid
        , itemid
    HAVING COUNT(DISTINCT inventsiteid) > 1;

    -- =====================================================
    -- PRELIM2 TABLE WITH ALL BOM CALC TRANS DATA
    -- =====================================================
    CREATE TABLE stage_expbom_prelim2 AS
    SELECT ABS(CAST(CAST(HASHBYTES('SHA2_256', CONCAT (
                            CAST(NEWID() AS VARCHAR(36)), '|'
                            , CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                            , CAST(NEWID() AS VARCHAR(36)), '|'
                            , CAST(b.itemid AS VARCHAR(100))
                            , CAST(b.resource AS VARCHAR(100))
                            , CAST(b.linenum AS VARCHAR(100))
                            , CAST(b.pricecalcid AS VARCHAR(100))
                            )) AS BINARY (8)) AS BIGINT)) AS dw_id
        , b.[DATAAREAID]
        , b.[CALCTYPE]
        , b.[calctype_$label]
        , b.[COSTGROUPID]
        , b.CostGroup
        , b.[LEVEL]
        , b.[QTY]
        , b.[COSTPRICE]
        , b.[COSTMARKUP]
        , b.[SALESPRICE]
        , b.[SALESMARKUP]
        , b.[TRANSDATE]
        , b.[LINENUM]
        , b.[RESOURCE]
        , b.[CONSUMPTIONVARIABLE]
        , b.[CONSUMPTIONCONSTANT]
        , b.[BOM]
        , b.[bom_$label]
        , b.[OPRID]
        , b.[COSTPRICEUNIT]
        , b.[COSTPRICEQTY]
        , b.[SALESPRICEQTY]
        , b.[COSTMARKUPQTY]
        , b.[SALESMARKUPQTY]
        , b.[PRICECALCID]
        , b.[NUMOFSERIES]
        , b.[OPRNUMNEXT]
        , b.[OPRPRIORITY]
        , b.[CONSUMPTIONINVENT]
        , b.[VENDID]
        , b.[CONSUMPTYPE]
        , b.[SALESPRICEUNIT]
        , b.[NETWEIGHTQTY]
        , b.[SALESPRICEMODELUSED]
        , b.[PRICEDISCQTY]
        , b.[COSTPRICEMODELUSED]
        , b.[CALCGROUPID]
        , b.[COSTPRICEFALLBACKVERSION]
        , b.[SALESPRICEFALLBACKVERSION]
        , b.[ROUTELEVEL]
        , b.[RECID]
        , b.[INVENTDIMID]
        , b.inventdimid_bomcalctable
        , b.[ITEMID]
        , b.[ACTIVATIONDATE]
        , b.[ToDate]
        , b.[VERSIONID]
        , b.CostGroupID [ItemCostGroupID]
        , b.InventSiteID
        , b.[PRICE]
        , b.[PRICEUNIT]
        , b.[UNITID]
        , b.[BOMID]
        , b.[ACTIVE]
        , bp.[ITEMPRICECALCID]
    FROM stage_expbom_vwBomCalcTrans b
    JOIN [stage_expbom_prelim1] bp
        ON b.[DATAAREAID] = bp.[DATAAREAID]
            AND b.[ITEMID] = bp.[ITEMID]
            AND b.InventSiteID = bp.InventSiteID
            AND b.[ACTIVATIONDATE] = bp.[ACTIVATIONDATE]
            AND b.pricecalcid = bp.itempricecalcid;

    -- For multi-site items, rank sites with site 90 last; any other site with a BOM takes priority
    CREATE TABLE stage_expbom_item_site_ranked AS
    SELECT p.dataareaid
        , p.itemid
        , p.inventsiteid
        , p.ACTIVATIONDATE
        , p.ITEMPRICECALCID
        , sum(b.COSTPRICE) AS avg_cost
        , ROW_NUMBER() OVER (
            PARTITION BY p.dataareaid, p.itemid, p.ACTIVATIONDATE
            ORDER BY CASE WHEN p.inventsiteid = '90' THEN 1 ELSE 0 END,    -- Fix 12 Option B: site 90 is always last resort; any other site with a BOM takes priority (future sites automatically preferred)
                     sum(b.COSTPRICE) DESC,
                     p.inventsiteid
            ) AS site_rank
    FROM stage_expbom_prelim1 p
    JOIN stage_expbom_prelim2 b
        ON b.dataareaid = p.dataareaid
            AND b.itemid = p.itemid
            AND b.inventsiteid = p.inventsiteid
            AND b.ACTIVATIONDATE = p.ACTIVATIONDATE
            AND b.ITEMPRICECALCID = p.ITEMPRICECALCID
    WHERE EXISTS (
            SELECT 1
            FROM stage_expbom_item_MULTIPLE_SITES ms
            WHERE ms.dataareaid = p.dataareaid
                AND ms.itemid = p.itemid
            )
        AND b.LEVEL = 0
    GROUP BY p.dataareaid
        , p.itemid
        , p.inventsiteid
        , p.ACTIVATIONDATE
        , p.ITEMPRICECALCID;

    -- Get fallback site (highest cost) for each multi-site item
    CREATE TABLE stage_expbom_item_fallback_site AS
    SELECT dataareaid
        , itemid
        , inventsiteid AS fallback_site
        , ACTIVATIONDATE
        , ITEMPRICECALCID
    FROM stage_expbom_item_site_ranked
    WHERE site_rank = 1;

    -- =====================================================
    -- LEVEL 0: ROOT ITEMS (ITEMID = RESOURCE)
    -- =====================================================
    CREATE TABLE stage_expbom_Level0 AS
    SELECT bct.[DATAAREAID]
        , bct.[ITEMID]
        , bct.[InventSiteID]
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 0 AS BomDepth
        , CONVERT(VARCHAR(4000), bct.[ITEMID]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , bct.CONSUMPTIONVARIABLE AS root_CONSUMPTIONVARIABLE
        , CONVERT(VARCHAR(30), NULL) AS parent_resource
        , bct.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , bct.QTY AS parent_QTY
        , bct.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , bct.ACTIVATIONDATE AS fg_ACTIVATIONDATE    -- Fix 6: propagated through all levels to anchor pfg date filter
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel1
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel2
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel3
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , CONVERT(DECIMAL(38, 16), NULL) AS Level1Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level2Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level3Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level4Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    JOIN stage_expbom_prelim1 p
        ON bct.DataAreaId = p.[DATAAREAID]
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
    WHERE bct.[ITEMID] = bct.[RESOURCE];

    -- =====================================================
    -- LEVEL 1
    -- =====================================================
    CREATE TABLE stage_expbom_Level1 AS
    SELECT bct.[DATAAREAID]
        , bct.[ITEMID]
        , bct.[InventSiteID]
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 1 AS BomDepth
        , CONVERT(VARCHAR(4000), bct.[ITEMID] + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.CONSUMPTIONVARIABLE AS root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel1
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel2
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel3
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , (eb.CONSUMPTIONVARIABLE * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level1Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level2Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level3Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level4Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level0 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND eb.ITEMPRICECALCID = bct.ITEMPRICECALCID    -- v5 Fix 3: tie to same activation
            AND bct.[ITEMID] <> bct.[RESOURCE]
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                    )
                )
    WHERE bct.[ITEMID] <> bct.[RESOURCE];

    -- =====================================================
    -- LEVEL 2
    -- =====================================================
    CREATE TABLE stage_expbom_Level2 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 2 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel2
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel3
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , (eb.Level1Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level2Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level3Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level4Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level1 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 3
    -- =====================================================
    CREATE TABLE stage_expbom_Level3 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 3 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel3
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , (eb.Level2Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level3Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level4Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level2 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 4
    -- =====================================================
    CREATE TABLE stage_expbom_Level4 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 4 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , (eb.Level3Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level4Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level3 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 5
    -- =====================================================
    CREATE TABLE stage_expbom_Level5 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 5 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , (eb.Level4Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level5Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level4 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 6
    -- =====================================================
    CREATE TABLE stage_expbom_Level6 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 6 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , (eb.Level5Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level6Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level5 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 7
    -- =====================================================
    CREATE TABLE stage_expbom_Level7 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 7 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , (eb.Level6Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level7Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level6 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 8
    -- =====================================================
    CREATE TABLE stage_expbom_Level8 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 8 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , (eb.Level7Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level8Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level7 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 9
    -- =====================================================
    CREATE TABLE stage_expbom_Level9 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 9 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , (eb.Level8Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level9Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level8 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 10
    -- =====================================================
    CREATE TABLE stage_expbom_Level10 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 10 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , (eb.Level9Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level10Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level9 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 11
    -- =====================================================
    CREATE TABLE stage_expbom_Level11 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 11 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , eb.ConsumptionVariableLevel10
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , eb.Level10Consumption
        , (eb.Level10Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level11Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level10 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 12
    -- =====================================================
    CREATE TABLE stage_expbom_Level12 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 12 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , eb.ConsumptionVariableLevel10
        , eb.ConsumptionVariableLevel11
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , eb.Level10Consumption
        , eb.Level11Consumption
        , (eb.Level11Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level12Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level11 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 13
    -- =====================================================
    CREATE TABLE stage_expbom_Level13 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 13 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , eb.ConsumptionVariableLevel10
        , eb.ConsumptionVariableLevel11
        , eb.ConsumptionVariableLevel12
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , eb.Level10Consumption
        , eb.Level11Consumption
        , eb.Level12Consumption
        , (eb.Level12Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level13Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level12 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 14
    -- =====================================================
    CREATE TABLE stage_expbom_Level14 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 14 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , eb.ConsumptionVariableLevel10
        , eb.ConsumptionVariableLevel11
        , eb.ConsumptionVariableLevel12
        , eb.ConsumptionVariableLevel13
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38, 16), NULL) AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , eb.Level10Consumption
        , eb.Level11Consumption
        , eb.Level12Consumption
        , eb.Level13Consumption
        , (eb.Level13Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level14Consumption
        , CONVERT(DECIMAL(38, 16), NULL) AS Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level13 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- LEVEL 15
    -- =====================================================
    CREATE TABLE stage_expbom_Level15 AS
    SELECT bct.[DATAAREAID]
        , eb.ItemId
        , eb.InventSiteID
        , bct.[RESOURCE]
        , bct.[DW_Id]
        , 15 AS BomDepth
        , CONVERT(VARCHAR(4000), eb.BomPath + '-->' + bct.[RESOURCE]) AS BomPath
        , bct.QTY
        , bct.CONSUMPTIONVARIABLE
        , eb.root_CONSUMPTIONVARIABLE
        , eb.RESOURCE AS parent_resource
        , eb.CONSUMPTIONVARIABLE AS parent_CONSUMPTIONVARIABLE
        , eb.QTY AS parent_QTY
        , eb.ITEMPRICECALCID
        , bct.PRICECALCID
        , bct.CALCTYPE
        , eb.fg_ACTIVATIONDATE
        , eb.ConsumptionVariableLevel1
        , eb.ConsumptionVariableLevel2
        , eb.ConsumptionVariableLevel3
        , eb.ConsumptionVariableLevel4
        , eb.ConsumptionVariableLevel5
        , eb.ConsumptionVariableLevel6
        , eb.ConsumptionVariableLevel7
        , eb.ConsumptionVariableLevel8
        , eb.ConsumptionVariableLevel9
        , eb.ConsumptionVariableLevel10
        , eb.ConsumptionVariableLevel11
        , eb.ConsumptionVariableLevel12
        , eb.ConsumptionVariableLevel13
        , eb.ConsumptionVariableLevel14
        , bct.CONSUMPTIONVARIABLE AS ConsumptionVariableLevel15
        , eb.Level1Consumption
        , eb.Level2Consumption
        , eb.Level3Consumption
        , eb.Level4Consumption
        , eb.Level5Consumption
        , eb.Level6Consumption
        , eb.Level7Consumption
        , eb.Level8Consumption
        , eb.Level9Consumption
        , eb.Level10Consumption
        , eb.Level11Consumption
        , eb.Level12Consumption
        , eb.Level13Consumption
        , eb.Level14Consumption
        , (eb.Level14Consumption * (bct.CONSUMPTIONVARIABLE / bct.QTY)) Level15Consumption
    FROM stage_expbom_prelim2 bct
    LEFT JOIN stage_expbom_item_fallback_site fb
        ON fb.dataareaid = bct.dataareaid
            AND fb.itemid = bct.itemid
            AND fb.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 11: activation-date-aware fallback site
    JOIN stage_expbom_Level14 eb
        ON eb.DataAreaId = bct.[DATAAREAID]
            AND eb.[RESOURCE] = bct.[ITEMID]
            AND bct.[ITEMID] <> bct.[RESOURCE]
            AND bct.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE    -- Fix 6: sub-assembly activation must cover root FG date; exact target prevents fan-out
            AND bct.ToDate >= eb.fg_ACTIVATIONDATE
            AND eb.CALCTYPE IN (1, 2, 5)                      -- Fix 7: only physical component rows as explosion anchors; excludes overhead (9) and route (8)
            AND NOT EXISTS (                                   -- v6 Change 2: stop explosion when anchor item has manual cost covering FG date; prevents stale BOM sub-components from double-counting with Part 1 manual price override
                SELECT 1
                FROM stage_expbom_iip_deduped iip_stop
                WHERE iip_stop.dataareaid = eb.DataAreaId
                    AND iip_stop.itemid = eb.[RESOURCE]
                    AND iip_stop.activationdate <= eb.fg_ACTIVATIONDATE
                    AND iip_stop.enddate >= eb.fg_ACTIVATIONDATE
            )
    JOIN stage_expbom_prelim1 p
        ON bct.[DATAAREAID] = p.dataareaid
            AND bct.[ITEMID] = p.itemid
            AND bct.[ACTIVATIONDATE] = p.[ACTIVATIONDATE]
            AND bct.ITEMPRICECALCID = p.ITEMPRICECALCID
            AND (
                fb.itemid IS NULL
                OR bct.InventSiteID = eb.InventSiteID
                OR (
                    bct.InventSiteID = fb.fallback_site
                    AND NOT EXISTS (
                        SELECT 1
                        FROM stage_expbom_prelim1 p2
                        WHERE p2.dataareaid = bct.dataareaid
                            AND p2.itemid = bct.itemid
                            AND p2.inventsiteid = eb.InventSiteID
                            AND p2.ACTIVATIONDATE = bct.ACTIVATIONDATE    -- Fix 10: scope to current activation date only; prevents old site history from blocking fallback path when a sub-assembly switches sites between activations
                        )
                        AND (
                            bct.InventSiteID <> '90'    -- Fix 12 Option B: non-site-90 fallback — no further restriction
                            OR NOT EXISTS (              -- Fix 12 Option B: site-90 fallback — excluded when any non-site-90 activation covers the FG date
                                SELECT 1
                                FROM stage_expbom_prelim2 p_fix12
                                WHERE p_fix12.DATAAREAID = bct.DATAAREAID
                                    AND p_fix12.ITEMID = bct.ITEMID
                                    AND p_fix12.InventSiteID <> '90'
                                    AND p_fix12.ACTIVATIONDATE <= eb.fg_ACTIVATIONDATE
                                    AND p_fix12.ToDate >= eb.fg_ACTIVATIONDATE
                            )
                        )
                    )
                );

    -- =====================================================
    -- COMBINE ALL LEVELS
    -- =====================================================
    SELECT DISTINCT *
    INTO stage_expbom_ExpBomAll
    FROM (
        SELECT * FROM stage_expbom_Level0
        UNION ALL SELECT * FROM stage_expbom_Level1
        UNION ALL SELECT * FROM stage_expbom_Level2
        UNION ALL SELECT * FROM stage_expbom_Level3
        UNION ALL SELECT * FROM stage_expbom_Level4
        UNION ALL SELECT * FROM stage_expbom_Level5
        UNION ALL SELECT * FROM stage_expbom_Level6
        UNION ALL SELECT * FROM stage_expbom_Level7
        UNION ALL SELECT * FROM stage_expbom_Level8
        UNION ALL SELECT * FROM stage_expbom_Level9
        UNION ALL SELECT * FROM stage_expbom_Level10
        UNION ALL SELECT * FROM stage_expbom_Level11
        UNION ALL SELECT * FROM stage_expbom_Level12
        UNION ALL SELECT * FROM stage_expbom_Level13
        UNION ALL SELECT * FROM stage_expbom_Level14
        UNION ALL SELECT * FROM stage_expbom_Level15
        ) AS AllLevels;

    -- =====================================================
    -- v5 Fix 5 — PRE-COMPUTE INTERMEDIATE CALCTYPE=1 NODES
    -- =====================================================
    -- Step 1: for every row at BomDepth >= 1, extract the parent BomPath by removing
    -- the last '-->X' segment.  The resulting set is the collection of BomPaths that
    -- have at least one child in the explosion (i.e., intermediate nodes).
    -- REVERSE + CHARINDEX('>--', ...) locates the last '-->' in the original BomPath.
    SELECT DISTINCT
        DATAAREAID
        , ITEMPRICECALCID
        , LEFT(BomPath, LEN(BomPath) - CHARINDEX('>--', REVERSE(BomPath)) - 2) AS parent_BomPath
    INTO stage_expbom_ParentPaths
    FROM stage_expbom_ExpBomAll
    WHERE BomDepth >= 1
        AND CHARINDEX('>--', REVERSE(BomPath)) > 0;

    -- Step 2: identify calctype=1 rows in ExpBomAll whose BomPath appears as a parent
    -- (i.e., they have children deeper in the explosion).  These are the double-counted
    -- rows — D365 stored the sub-assembly as a purchased direct-material cost AND the SP
    -- also explodes its children via the iterative join chain.
    SELECT DISTINCT e.DATAAREAID, e.ITEMPRICECALCID, e.BomPath
    INTO stage_expbom_Calctype1Intermediate
    FROM stage_expbom_ExpBomAll e
    JOIN stage_expbom_prelim2 b
        ON e.dw_id = b.DW_Id
    JOIN stage_expbom_ParentPaths pp
        ON pp.DATAAREAID = e.DATAAREAID
            AND pp.ITEMPRICECALCID = e.ITEMPRICECALCID
            AND pp.parent_BomPath = e.BomPath
    WHERE b.CALCTYPE = 1;

    -- =====================================================
    -- FINAL TABLE WITH CALCULATIONS
    -- =====================================================
    -- v4: removed AND b.[ACTIVATIONDATE] = fg.[ACTIVATIONDATE] from the fg join.
    -- v5 Fix 5: LEFT JOIN anti-join against stage_expbom_Calctype1Intermediate excludes
    --           double-counted rows (see ci.BomPath IS NULL in WHERE clause).
    CREATE TABLE stage_expbom_Final AS
    SELECT DISTINCT
        b.[DATAAREAID]
        , e.[ITEMID]
        , e.InventSiteID
        , fg.ACTIVATIONDATE     -- v5 Fix 2: root FG activation date, not component IIP date
        , e.dw_id
        , CASE
            WHEN b.CostGroup = 'Direct_Material_Cost_Standard'
                THEN e.BOMPath
            ELSE e.BOMPath + '(' + b.costgroupid + ')'
            END BOMPath
        , e.BomDepth
        , b.[RESOURCE]
        , b.[BOM]
        , b.[bom_$label]
        , b.[CALCTYPE]
        , b.[calctype_$label]
        , b.costgroupid
        , b.CostGroup
        , e.root_CONSUMPTIONVARIABLE
        , e.Parent_Resource
        , b.[LEVEL]
        , b.[QTY]
        , ISNULL(iip_mc.PricePerUnit, b.[COSTPRICE])  AS COSTPRICE    -- v6 Change 2: override with manual price when component has manual cost covering FG activation date
        , b.[CONSUMPTIONVARIABLE]
        , e.Parent_CONSUMPTIONVARIABLE
        , e.parent_QTY
        , e.ConsumptionVariableLevel1
        , e.ConsumptionVariableLevel2
        , e.ConsumptionVariableLevel3
        , e.ConsumptionVariableLevel4
        , e.ConsumptionVariableLevel5
        , e.ConsumptionVariableLevel6
        , e.ConsumptionVariableLevel7
        , e.ConsumptionVariableLevel8
        , e.ConsumptionVariableLevel9
        , e.ConsumptionVariableLevel10
        , e.ConsumptionVariableLevel11
        , e.ConsumptionVariableLevel12
        , e.ConsumptionVariableLevel13
        , e.ConsumptionVariableLevel14
        , e.ConsumptionVariableLevel15
        , e.Level1Consumption
        , e.Level2Consumption
        , e.Level3Consumption
        , e.Level4Consumption
        , e.Level5Consumption
        , e.Level6Consumption
        , e.Level7Consumption
        , e.Level8Consumption
        , e.Level9Consumption
        , e.Level10Consumption
        , e.Level11Consumption
        , e.Level12Consumption
        , e.Level13Consumption
        , e.Level14Consumption
        , e.Level15Consumption
        , COALESCE(e.Level15Consumption, e.Level14Consumption, e.Level13Consumption, e.Level12Consumption, e.Level11Consumption
                , e.Level10Consumption, e.Level9Consumption, e.Level8Consumption, e.Level7Consumption, e.Level6Consumption
                , e.Level5Consumption, e.Level4Consumption, e.Level3Consumption, e.Level2Consumption, e.Level1Consumption) ConsumptionPerLotSize
        , CASE
            WHEN e.root_CONSUMPTIONVARIABLE = 0
                THEN NULL
            ELSE ((COALESCE(e.Level15Consumption, e.Level14Consumption, e.Level13Consumption, e.Level12Consumption, e.Level11Consumption
                    , e.Level10Consumption, e.Level9Consumption, e.Level8Consumption, e.Level7Consumption, e.Level6Consumption
                    , e.Level5Consumption, e.Level4Consumption, e.Level3Consumption, e.Level2Consumption, e.Level1Consumption) * ISNULL(iip_mc.PricePerUnit, b.costprice))    -- v6 Change 2: manual cost override
                    / e.root_CONSUMPTIONVARIABLE)
            END CostPerUnit
        , e.ITEMPRICECALCID
        , fg.versionid
        , bct.CurrentActiveCost
        , bct.accountingcurrency
    FROM stage_expbom_ExpBomAll e
    JOIN stage_expbom_prelim2 b
        ON e.dw_id = b.DW_Id
    JOIN (SELECT dataareaid, itemid, inventsiteid, versionid, activationdate, itempricecalcid
          FROM stage_expbom_prelim2
          WHERE level = 0) fg
        ON e.[DATAAREAID] = fg.[DATAAREAID]
            AND e.[ITEMID] = fg.[ITEMID]
            AND e.InventSiteID = fg.InventSiteID
            AND e.itempricecalcid = fg.itempricecalcid
    -- v5: vwBomCalcTrans is now deduplicated at source (one row per pricecalcid).
    -- No LatestStandardCostFlag filter needed here — dedup handled upstream.
    JOIN stage_expbom_vwBomCalcTrans bct
        ON fg.[DATAAREAID] = bct.[DATAAREAID]
            AND fg.[ITEMID] = bct.[ITEMID]
            AND fg.InventSiteID = bct.InventSiteID
            AND fg.[ACTIVATIONDATE] = bct.[ACTIVATIONDATE]
            AND fg.itempricecalcid = bct.pricecalcid
            AND fg.versionid = bct.versionid
    -- v6 Change 2: manual cost override — when a component (b.RESOURCE) has a manually
    -- assigned cost covering the root FG's activation date, replace bomcalctrans COSTPRICE
    -- with the IIP manual price. Only matches manual cost periods (iip_deduped contains no
    -- BOM calc rows). Returns NULL for BOM calc components → ISNULL falls back to b.COSTPRICE.
    -- Site-aware join: matches the site the component row is sourced from.
    LEFT JOIN stage_expbom_iip_deduped iip_mc
        ON iip_mc.dataareaid = b.[DATAAREAID]
            AND iip_mc.itemid = b.[RESOURCE]
            AND iip_mc.inventsiteid = b.InventSiteID
            AND iip_mc.activationdate <= fg.[ACTIVATIONDATE]
            AND iip_mc.enddate >= fg.[ACTIVATIONDATE]
    -- v5 Fix 5: anti-join — exclude calctype=1 rows that are intermediate nodes
    -- (their cost is already captured by the deeper explosion of their own children).
    -- Normal purchased materials (calctype=1, no BOM children) are never in this table.
    LEFT JOIN stage_expbom_Calctype1Intermediate ci
        ON ci.DATAAREAID = e.DATAAREAID
            AND ci.ITEMPRICECALCID = e.ITEMPRICECALCID
            AND ci.BomPath = e.BomPath
    WHERE ci.BomPath IS NULL
    ORDER BY b.[DATAAREAID]
        , e.[ITEMID]
        , e.InventSiteID
        , CASE
            WHEN b.CostGroup = 'Direct_Material_Cost_Standard'
                THEN e.BOMPath
            ELSE e.BOMPath + '(' + b.costgroupid + ')'
            END;

    -- ── v6 Change 2 Part 2: Manual cost root FG leaf rows ────────────────────
    -- Root FGs whose activation date is a manual cost period have no prelim1/prelim2
    -- rows → no Level 0-15 rows → absent from Final SELECT above.
    -- Insert one leaf row per (dataareaid, itemid, inventsiteid, activationdate)
    -- from iip_deduped, restricted to items confirmed as root FGs in prelim1
    -- (at least one BOM calc activation exists — they are known manufactured items).
    -- COSTPRICE = CostPerUnit = PricePerUnit from IIP (the manual assigned cost).
    INSERT INTO stage_expbom_Final
    SELECT
        iip.dataareaid
        , iip.itemid
        , iip.inventsiteid
        , iip.activationdate
        , ABS(CAST(CAST(HASHBYTES('SHA2_256', CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            , CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            , CAST(iip.dataareaid AS VARCHAR(20)), '|'
            , CAST(iip.itemid AS VARCHAR(100)), '|'
            , CAST(iip.inventsiteid AS VARCHAR(10)), '|'
            , CAST(iip.activationdate AS VARCHAR(30))
          )) AS BINARY(8)) AS BIGINT))                          AS dw_id
        , CAST(iip.itemid AS VARCHAR(4000))                    AS BOMPath
        , 0                                                    AS BomDepth
        , iip.itemid                                           AS RESOURCE
        , CAST(NULL AS VARCHAR(20))                            AS BOM
        , CAST(NULL AS VARCHAR(50))                            AS bom_$label
        , CAST(1 AS INT)                                       AS CALCTYPE
        , CAST('Item' AS VARCHAR(50))                          AS calctype_$label
        , CAST(NULL AS VARCHAR(30))                            AS costgroupid
        , CAST('Direct_Material_Cost_Standard' AS VARCHAR(100)) AS CostGroup
        , iip.priceunit                                        AS root_CONSUMPTIONVARIABLE
        , CAST(NULL AS VARCHAR(30))                            AS Parent_Resource
        , CAST(NULL AS INT)                                    AS [LEVEL]
        , iip.priceunit                                        AS QTY
        , iip.PricePerUnit                                     AS COSTPRICE
        , iip.priceunit                                        AS CONSUMPTIONVARIABLE
        , iip.priceunit                                        AS Parent_CONSUMPTIONVARIABLE
        , iip.priceunit                                        AS parent_QTY
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel1
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel2
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel3
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel4
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel5
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel6
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel7
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel8
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel9
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel10
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel11
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel12
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel13
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel14
        , CONVERT(DECIMAL(38,16), NULL)                        AS ConsumptionVariableLevel15
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level1Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level2Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level3Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level4Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level5Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level6Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level7Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level8Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level9Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level10Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level11Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level12Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level13Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level14Consumption
        , CONVERT(DECIMAL(38,16), NULL)                        AS Level15Consumption
        , iip.priceunit                                        AS ConsumptionPerLotSize
        , iip.PricePerUnit                                     AS CostPerUnit
        , CAST(NULL AS VARCHAR(50))                            AS ITEMPRICECALCID
        , iip.versionid                                        AS versionid
        , iip.CurrentActiveCost                                AS CurrentActiveCost
        , l.accountingcurrency                                 AS accountingcurrency
    FROM stage_expbom_iip_deduped iip
    LEFT JOIN WH_Raw.dbo.ledger l
        ON iip.dataareaid = l.name
    WHERE EXISTS (
        SELECT 1
        FROM stage_expbom_prelim1 p
        WHERE p.DATAAREAID = iip.dataareaid
            AND p.ITEMID = iip.itemid
    );
    -- ─────────────────────────────────────────────────────────────────────────

    -- ── v5 Change 2 ───────────────────────────────────────────────────────────
    -- Compute effective date range per item+site activation.
    -- LEAD() finds the next activation date for the same DATAAREAID+ITEMID+InventSiteID.
    -- EndDate = day before the next activation, or 2154-12-31 if no subsequent activation exists.
    -- Built on DISTINCT activation dates to avoid window function skew from multi-row grain.
    -- Since v4 runs as a full rerun, end dates are always recomputed fresh — when a new
    -- activation is added, the prior record's EndDate updates automatically on the next run.
    CREATE TABLE stage_expbom_EndDates AS
    SELECT
        DATAAREAID
        , ITEMID
        , InventSiteID
        , ACTIVATIONDATE
        , ISNULL(
            DATEADD(DAY, -1, LEAD(ACTIVATIONDATE) OVER (
                PARTITION BY DATAAREAID, ITEMID, InventSiteID
                ORDER BY ACTIVATIONDATE
            )),
            CAST('2154-12-31' AS DATE)
        ) AS EndDate
    FROM (
        SELECT DISTINCT DATAAREAID, ITEMID, InventSiteID, ACTIVATIONDATE
        FROM stage_expbom_Final
    ) distinct_dates;
    -- ─────────────────────────────────────────────────────────────────────────

    -- =====================================================
    -- INSERT INTO SNAPSHOT TABLE
    -- =====================================================
    -- v4: TRUNCATE before INSERT — full rerun mode.
    TRUNCATE TABLE [dbo].[tbl_ExplodedBOM_StandardCost_Snapshot];

    -- ── v5 Change 3 ───────────────────────────────────────────────────────────
    -- JOIN stage_expbom_EndDates to attach EndDate to every snapshot row.
    -- Requires EndDate DATE column on tbl_ExplodedBOM_StandardCost_Snapshot
    -- (prerequisite DDL: ALTER TABLE ... ADD EndDate DATE NULL).
    INSERT INTO [dbo].[tbl_ExplodedBOM_StandardCost_Snapshot]
    SELECT
        CONVERT(int, CONVERT(char(8), f.ACTIVATIONDATE, 112))
        , f.*
        , ed.EndDate
    FROM stage_expbom_Final f
    JOIN stage_expbom_EndDates ed
        ON f.DATAAREAID = ed.DATAAREAID
            AND f.ITEMID = ed.ITEMID
            AND f.InventSiteID = ed.InventSiteID
            AND f.ACTIVATIONDATE = ed.ACTIVATIONDATE;
    -- ─────────────────────────────────────────────────────────────────────────

    -- =====================================================
    -- DROP STAGE TABLES
    -- =====================================================
    DROP TABLE IF EXISTS stage_expbom_vwBomCalcTrans;
    DROP TABLE IF EXISTS stage_expbom_prelim_step0;
    DROP TABLE IF EXISTS stage_expbom_prelim_step1;
    DROP TABLE IF EXISTS stage_expbom_prelim1_maxdt;
    DROP TABLE IF EXISTS stage_expbom_prelim1;
    DROP TABLE IF EXISTS stage_expbom_item_MULTIPLE_SITES;
    DROP TABLE IF EXISTS stage_expbom_item_site_ranked;
    DROP TABLE IF EXISTS stage_expbom_item_fallback_site;
    DROP TABLE IF EXISTS stage_expbom_prelim2;
    DROP TABLE IF EXISTS stage_expbom_Level0;
    DROP TABLE IF EXISTS stage_expbom_Level1;
    DROP TABLE IF EXISTS stage_expbom_Level2;
    DROP TABLE IF EXISTS stage_expbom_Level3;
    DROP TABLE IF EXISTS stage_expbom_Level4;
    DROP TABLE IF EXISTS stage_expbom_Level5;
    DROP TABLE IF EXISTS stage_expbom_Level6;
    DROP TABLE IF EXISTS stage_expbom_Level7;
    DROP TABLE IF EXISTS stage_expbom_Level8;
    DROP TABLE IF EXISTS stage_expbom_Level9;
    DROP TABLE IF EXISTS stage_expbom_Level10;
    DROP TABLE IF EXISTS stage_expbom_Level11;
    DROP TABLE IF EXISTS stage_expbom_Level12;
    DROP TABLE IF EXISTS stage_expbom_Level13;
    DROP TABLE IF EXISTS stage_expbom_Level14;
    DROP TABLE IF EXISTS stage_expbom_Level15;
    DROP TABLE IF EXISTS stage_expbom_iip_latest;              -- v6 Change 2
    DROP TABLE IF EXISTS stage_expbom_iip_deduped;             -- v6 Change 2
    DROP TABLE IF EXISTS stage_expbom_ExpBomAll;
    DROP TABLE IF EXISTS stage_expbom_ParentPaths;             -- v5 Fix 5
    DROP TABLE IF EXISTS stage_expbom_Calctype1Intermediate;   -- v5 Fix 5
    DROP TABLE IF EXISTS stage_expbom_Final;
    DROP TABLE IF EXISTS stage_expbom_EndDates;    -- v5: new staging table

END