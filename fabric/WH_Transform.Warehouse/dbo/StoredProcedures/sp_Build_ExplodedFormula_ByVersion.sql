/*
================================================================================
  Procedure:  sp_Build_ExplodedFormula_ByVersion
  Created:    2026-04-27
  Updated:    2026-05-27

  Purpose:
    Builds and maintains tbl_ExplodedFormula_ByVersion — a permanent, versioned
    formula explosion table covering all ACTIVE formula versions (APPROVED=1
    AND ACTIVE=1).  Each row represents one raw-material leaf ingredient of
    one FG formula version, valid for a specific date window.

    The date window [PeriodFromDate, PeriodToDate] reflects the INTERSECTION of
    effective dates across the ENTIRE multi-level BOM tree.  If a sub-assembly
    formula changes mid-period, the intersection splits the parent period into
    sub-periods, each with its own row.

    Sentinel date: D365 uses '1900-01-01' for BOTH "no start restriction"
    (FROMDATE) and "no expiry" (TODATE).  All internal staging comparisons handle this.
    Output conversion: PeriodToDate '1900-01-01' → '2154-12-31' at INSERT time.
    PeriodFromDate retains '1900-01-01' as-is in the output table.

  Parameters:
    @RunMode  VARCHAR(20)  'FULL'        — Truncate and rebuild from scratch
                           'INCREMENTAL' — Hash-compare; reprocess only changed FGs
                           Default: 'INCREMENTAL'

  Prerequisite:
    Run DDL scripts to create tbl_ExplodedFormula_ByVersion and
    tbl_FormulaHash_Tracker before first execution.
    First run must use @RunMode = 'FULL'.

  Source tables (WH_Raw.dbo):
    BOM                        — Formula lines (ingredients)
    BOMVERSION                 — Links FG item to formula version; effective dates
    INVENTDIM                  — Inventory dimensions (site via INVENTDIMID)
    INVENTTABLE                — Item master (names, groups, BOMUNITID)
    InventItemGroupItem        — Item group assignments
    EcoResProductTranslation   — Item names (en-us)
    vwUnitOfMeasureConversion  — Item-specific UOM conversions


  Query patterns for consumers:
    -- Q1: Historical consumption (join to sales/production by transaction date)
    -- PeriodFromDate: '1900-01-01' = no start restriction  |  PeriodToDate: '2154-12-31' = open-ended
    SELECT efv.FgItemId, efv.RmItemId, SUM(efv.LbsPerLbFG) AS TotalLbsPerLbFG
    FROM tbl_ExplodedFormula_ByVersion efv
    WHERE (efv.PeriodFromDate = '1900-01-01' OR sale_date >= efv.PeriodFromDate)
      AND sale_date <= efv.PeriodToDate
    GROUP BY efv.FgItemId, efv.RmItemId;

    -- Q2: Current demand planning (no date join needed)
    SELECT FgItemId, RmItemId, SUM(LbsPerLbFG) AS TotalLbsPerLbFG
    FROM tbl_ExplodedFormula_ByVersion
    WHERE IsCurrentPeriod = 1
    GROUP BY FgItemId, RmItemId;

  [Percent] column — how the hierarchy roll-up works:
    D365 stores PMFFORMULAPCT as a [Percent]age of the IMMEDIATE PARENT sub-formula's
    batch size.  At Level 1 (direct FG ingredient) that is already a [Percent]age of
    the FG batch and no adjustment is needed.  At deeper levels it must be scaled by
    how much of the FG batch the parent sub-assembly represents.

    The scaling factor is QtyLbsPerLbFG from the parent (eb) row.  Although the name
    includes "Lbs", this value is dimensionally lbs/lbs — a dimensionless fraction
    that IS the parent's [Percent]age of the FG batch expressed as a decimal
    (e.g. 0.50 = 50% of FG).  The calculation is therefore pure [Percent]age math:

      [Percent] = PMFFORMULAPCT   ×   parent QtyLbsPerLbFG
              = "RM is X% of    ×   parent sub-assembly is Y% of FG"
                 parent batch"      (expressed as a decimal)

    Example:
      Level 1 sub-assembly QtyLbsPerLbFG = 0.50  (sub-assembly is 50% of FG batch)
      Level 2 RM            PMFFORMULAPCT = 10    (RM is 10% of that sub-assembly)
      Level 2 RM [Percent]    = 10 × 0.50 = 5       (RM is 5% of FG batch)

    At Level 1 the parent is Level 0 (the FG itself) whose QtyLbsPerLbFG = 1.0,
    so [Percent] = PMFFORMULAPCT × 1.0 = PMFFORMULAPCT unchanged.

    [Percent] is NULL when [Percent]Controlled = 0 (BOMQTY-driven ingredient).

================================================================================
*/
CREATE   PROCEDURE [dbo].[sp_Build_ExplodedFormula_ByVersion]
    @RunMode VARCHAR(20) = 'FULL'  --'INCREMENTAL'
AS
BEGIN

    -- =========================================================================
    -- CLEANUP — drop all stage tables from previous run
    -- =========================================================================
    DROP TABLE IF EXISTS stage_fml_all_versions;
    DROP TABLE IF EXISTS stage_fml_item_fallback_site;
    DROP TABLE IF EXISTS stage_fml_all_formula_lines;
    DROP TABLE IF EXISTS stage_fml_bomid_strings;
    DROP TABLE IF EXISTS stage_fml_sub_assembly_map;
    DROP TABLE IF EXISTS stage_fml_current_hashes;
    DROP TABLE IF EXISTS stage_fml_changed_boms;
    DROP TABLE IF EXISTS stage_fml_items_to_process;
    DROP TABLE IF EXISTS stage_fml_upstream_L0;
    DROP TABLE IF EXISTS stage_fml_upstream_L1;
    DROP TABLE IF EXISTS stage_fml_upstream_L2;
    DROP TABLE IF EXISTS stage_fml_upstream_L3;
    DROP TABLE IF EXISTS stage_fml_upstream_L4;
    DROP TABLE IF EXISTS stage_fml_upstream_L5;
    DROP TABLE IF EXISTS stage_fml_upstream_L6;
    DROP TABLE IF EXISTS stage_fml_upstream_L7;
    DROP TABLE IF EXISTS stage_fml_upstream_L8;
    DROP TABLE IF EXISTS stage_fml_upstream_L9;
    DROP TABLE IF EXISTS stage_fml_upstream_L10;
    DROP TABLE IF EXISTS stage_fml_upstream_L11;
    DROP TABLE IF EXISTS stage_fml_upstream_L12;
    DROP TABLE IF EXISTS stage_fml_Level0;
    DROP TABLE IF EXISTS stage_fml_Level1;
    DROP TABLE IF EXISTS stage_fml_Level2;
    DROP TABLE IF EXISTS stage_fml_Level3;
    DROP TABLE IF EXISTS stage_fml_Level4;
    DROP TABLE IF EXISTS stage_fml_Level5;
    DROP TABLE IF EXISTS stage_fml_Level6;
    DROP TABLE IF EXISTS stage_fml_Level7;
    DROP TABLE IF EXISTS stage_fml_Level8;
    DROP TABLE IF EXISTS stage_fml_Level9;
    DROP TABLE IF EXISTS stage_fml_Level10;
    DROP TABLE IF EXISTS stage_fml_Level11;
    DROP TABLE IF EXISTS stage_fml_Level12;
    DROP TABLE IF EXISTS stage_fml_ExpAll;
    DROP TABLE IF EXISTS stage_fml_Result_New;

    -- =========================================================================
    -- STEP 1: ALL ACTIVE FORMULA VERSIONS (APPROVED=1 AND ACTIVE=1)
    --
    -- Covers ALL producible items: root FGs and sub-assemblies alike.
    -- Includes every approved formula version, not just the most recent.
    --
    -- =========================================================================
    CREATE TABLE stage_fml_all_versions AS
    SELECT bv.[DATAAREAID]
        , bv.[ITEMID]
        , bv.[BOMID]
        , id.[INVENTSITEID]
        , bv.[pmfbatchsize]                                             AS FormulaQty
        , bv_it.[BOMUNITID]                                             AS FormulaUomId
        , bv.[FROMDATE]                                                 AS FromDate   -- 1900-01-01 = no start restriction
        , bv.[TODATE]                                                   AS ToDate     -- 1900-01-01 = no expiry
        , bv.[ACTIVE]                                                   AS IsActive   -- carried for reference only
        , ISNULL(uc.[UOMConversionFactor], 1)                          AS FormulaToLbFactor
        , bv.[pmfbatchsize] * ISNULL(uc.[UOMConversionFactor], 1)      AS FormulaQtyLbs
        , CASE
            WHEN bv_it.[BOMUNITID] = 'LB'                    THEN CAST(0 AS INT)
            WHEN uc.[UOMConversionFactor] IS NOT NULL         THEN CAST(1 AS INT)
            ELSE                                                   CAST(0 AS INT)
          END                                                           AS FormulaUomConverted
        , CASE
            WHEN uc.[UOMConversionFactor] IS NULL
             AND bv_it.[BOMUNITID] <> 'LB'                   THEN CAST(1 AS INT)
            ELSE                                                   CAST(0 AS INT)
          END                                                           AS FormulaUomConversionMissing
        , ROW_NUMBER() OVER (
            PARTITION BY bv.[DATAAREAID], bv.[ITEMID], id.[INVENTSITEID]
            ORDER BY bv.[FROMDATE] DESC, bv.[BOMID] DESC
          )                                                             AS version_rn  -- for fallback site only
    FROM WH_Raw.dbo.[BOMVERSION] bv
    LEFT JOIN WH_Raw.dbo.[INVENTDIM] id
        ON  id.[DATAAREAID]  = bv.[DATAAREAID]
        AND id.[INVENTDIMID] = bv.[INVENTDIMID]
    LEFT JOIN WH_Raw.dbo.[INVENTTABLE] bv_it
        ON  bv_it.[DATAAREAID] = bv.[DATAAREAID]
        AND bv_it.[ITEMID]     = bv.[ITEMID]
    LEFT JOIN WH_Raw.dbo.[vwUnitOfMeasureConversion] uc
        ON  uc.[Product]    = bv_it.[PRODUCT]
        AND uc.[SymbolFrom] = bv_it.[BOMUNITID]
        AND uc.[SymbolTo]   = 'LB'
    WHERE bv.[APPROVED] = 1
      AND bv.[ACTIVE]   = 1;

    -- =========================================================================
    -- STEP 2: PER-ITEM FALLBACK SITE
    -- When a sub-assembly has no formula for the parent's site, use this site.
    -- One row per item — site 90 is always the last resort; any other site
    -- with an active formula is preferred over site 90.
    -- Fix v6: previously returned one row per item per site, causing the
    -- Level 2-12 fallback join to fan-out for multi-site sub-assemblies and
    -- allowing site 90 to be selected even when a better site was available.
    -- =========================================================================
    CREATE TABLE stage_fml_item_fallback_site AS
    SELECT [DATAAREAID]
        , [ITEMID]
        , [INVENTSITEID]    AS FallbackSite
    FROM (
        SELECT [DATAAREAID]
            , [ITEMID]
            , [INVENTSITEID]
            , ROW_NUMBER() OVER (
                PARTITION BY [DATAAREAID], [ITEMID]
                ORDER BY
                    CASE WHEN ISNULL([INVENTSITEID], '') = '90' THEN 1 ELSE 0 END ASC, -- site 90 last resort
                    [FromDate] DESC,
                    [BOMID] DESC
              ) AS fallback_rn
        FROM stage_fml_all_versions
    ) ranked
    WHERE fallback_rn = 1;

    -- =========================================================================
    -- STEP 3: ALL FORMULA LINES FOR ALL ACTIVE VERSIONS
    -- =========================================================================
    CREATE TABLE stage_fml_all_formula_lines AS
    SELECT av.[DATAAREAID]
        , av.[ITEMID]                   AS FormulaItemId
        , av.[INVENTSITEID]
        , av.[BOMID]
        , av.[FromDate]                 AS VersionFromDate   -- version-level validity start
        , av.[ToDate]                   AS VersionToDate     -- version-level validity end
        , av.[FormulaQty]
        , av.[FormulaUomId]
        , av.[FormulaQtyLbs]
        , av.[FormulaUomConverted]
        , av.[FormulaUomConversionMissing]
        , b.[ITEMID]                    AS ComponentItemId
        , b.[BOMQTY]                    AS ComponentQty
        , b.[UNITID]                    AS ComponentNativeUomId
        , b.[LINENUM]
        , b.[BOMTYPE]
        , ISNULL(uc.[UOMConversionFactor], 1)               AS CompToLbFactor
        , b.[BOMQTY] * ISNULL(uc.[UOMConversionFactor], 1)  AS ComponentQtyLbs
        , CASE
            WHEN b.[UNITID] = 'LB'                          THEN CAST(0 AS INT)
            WHEN uc.[UOMConversionFactor] IS NOT NULL        THEN CAST(1 AS INT)
            ELSE                                                  CAST(0 AS INT)
          END                                                AS CompUomConverted
        , CASE
            WHEN uc.[UOMConversionFactor] IS NULL
             AND b.[UNITID] <> 'LB'                         THEN CAST(1 AS INT)
            ELSE                                                  CAST(0 AS INT)
          END                                                AS CompUomConversionMissing
        -- Qty of this component per 1 lb of formula item (LB-denominator space)
        , CASE
            WHEN av.[FormulaQtyLbs] = 0
              OR av.[FormulaQtyLbs] IS NULL                  THEN CAST(NULL AS DECIMAL(28,8))
            ELSE CAST(
                b.[BOMQTY] * ISNULL(uc.[UOMConversionFactor], 1)
                / av.[FormulaQtyLbs]
              AS DECIMAL(28,8))
          END                                                AS QtyLbsPerLbOfFormulaItem
        -- Native UOM qty per 1 lb of formula item
        , CASE
            WHEN av.[FormulaQtyLbs] = 0
              OR av.[FormulaQtyLbs] IS NULL                  THEN CAST(NULL AS DECIMAL(28,8))
            ELSE CAST(
                b.[BOMQTY]
                / av.[FormulaQtyLbs]
              AS DECIMAL(28,8))
          END                                                AS NativeQtyPerLbOfFormulaItem
        -- [Percent]-control fields (BOM ingredient line)
        , b.[PMFPCTENABLE]                                   AS PMFPCTENABLE   -- 1 = qty is [Percent]-driven
        , b.[PMFFORMULAPCT]                                  AS PMFFORMULAPCT  -- target % when PMFPCTENABLE = 1
    FROM stage_fml_all_versions av  -- all active versions
    JOIN WH_Raw.dbo.[BOM] b
        ON  b.[DATAAREAID] = av.[DATAAREAID]
        AND b.[BOMID]      = av.[BOMID]
    LEFT JOIN WH_Raw.dbo.[INVENTTABLE] comp_it
        ON  comp_it.[DATAAREAID] = b.[DATAAREAID]
        AND comp_it.[ITEMID]     = b.[ITEMID]
    LEFT JOIN WH_Raw.dbo.[vwUnitOfMeasureConversion] uc
        ON  uc.[Product]    = comp_it.[PRODUCT]
        AND uc.[SymbolFrom] = b.[UNITID]
        AND uc.[SymbolTo]   = 'LB';

    -- =========================================================================
    -- STEP 4: SUB-ASSEMBLY MAP
    -- Items that have ANY approved formula version.
    -- Used at Levels 2-12 to gate expansion: only expand components that are
    -- themselves sub-assemblies.  Leaf = no approved formula → raw material.
    -- =========================================================================
    CREATE TABLE stage_fml_sub_assembly_map AS
    SELECT DISTINCT [DATAAREAID]
        , [ITEMID]
    FROM stage_fml_all_versions;

    -- =========================================================================
    -- STEP 5: HASH COMPUTATION PER BOMID
    -- Builds a SHA2_256 fingerprint of each formula's ingredient set.
    -- =========================================================================
    CREATE TABLE stage_fml_bomid_strings AS
    SELECT fl.[DATAAREAID]
        , fl.[BOMID]
        , STRING_AGG(
            fl.[ComponentItemId] + '|'
            + CAST(fl.[ComponentQty] AS VARCHAR(50)) + '|'
            + fl.[ComponentNativeUomId]
            , '~'
          ) WITHIN GROUP (ORDER BY fl.[ComponentItemId], fl.[LINENUM])
                                        AS IngredientString
    FROM stage_fml_all_formula_lines fl
    GROUP BY fl.[DATAAREAID], fl.[BOMID];

    CREATE TABLE stage_fml_current_hashes AS
    SELECT av.[DATAAREAID]
        , av.[BOMID]
        , av.[ITEMID]
        , CONVERT(
            VARCHAR(64),
            HASHBYTES('SHA2_256', CONVERT(NVARCHAR(MAX), ISNULL(bs.[IngredientString], ''))),
            2
          )                             AS IngredientHash
    FROM (SELECT DISTINCT [DATAAREAID], [BOMID], [ITEMID] FROM stage_fml_all_versions) av
    LEFT JOIN stage_fml_bomid_strings bs
        ON  bs.[DATAAREAID] = av.[DATAAREAID]
        AND bs.[BOMID]      = av.[BOMID];

    -- =========================================================================
    -- STEP 6: DETERMINE SCOPE — FULL vs INCREMENTAL
    --
    -- Populates stage_fml_items_to_process (DATAAREAID, ITEMID) with:
    --   FULL:        all items in stage_fml_all_versions
    --   INCREMENTAL: items linked to changed/new/removed BOMs + upstream cascade
    --
    -- Level 0-12 explosion always filters to stage_fml_items_to_process,
    -- so the same explosion code runs in both modes.
    -- =========================================================================
    IF @RunMode = 'FULL'
    BEGIN
        -- Full rebuild: process all items
        CREATE TABLE stage_fml_items_to_process AS
        SELECT DISTINCT [DATAAREAID], [ITEMID]
        FROM stage_fml_all_versions;

        TRUNCATE TABLE [dbo].[tbl_ExplodedFormula_ByVersion];
        TRUNCATE TABLE [dbo].[tbl_FormulaHash_Tracker];
    END
    ELSE  -- INCREMENTAL
    BEGIN
        -- ----------------------------------------------------------------
        -- 6a. Find changed BOMs: hash changed, new, or removed
        -- ----------------------------------------------------------------
        CREATE TABLE stage_fml_changed_boms AS

            -- New or modified BOMs
            SELECT ch.[DATAAREAID], ch.[BOMID], ch.[ITEMID]
            FROM stage_fml_current_hashes ch
            LEFT JOIN [dbo].[tbl_FormulaHash_Tracker] ht
                ON  ht.[DataAreaId] = ch.[DATAAREAID]
                AND ht.[BomId]      = ch.[BOMID]
            WHERE ht.[BomId] IS NULL                             -- new BOMID
               OR ch.[IngredientHash] <> ht.[IngredientHash]    -- ingredient set changed

        UNION

            -- Removed BOMs (in tracker but no longer in source)
            SELECT ht.[DataAreaId], ht.[BomId], ht.[ItemId]
            FROM [dbo].[tbl_FormulaHash_Tracker] ht
            WHERE NOT EXISTS (
                SELECT 1
                FROM stage_fml_current_hashes ch
                WHERE ch.[DATAAREAID] = ht.[DataAreaId]
                  AND ch.[BOMID]      = ht.[BomId]
            );

        -- ----------------------------------------------------------------
        -- 6b. Upstream cascade — find all parent FG items that contain a
        --     changed sub-assembly BOMID anywhere in their explosion tree.
        --
        -- Level 0: items directly using a changed BOMID as their own formula
        -- Level N: items that use Level N-1 items as a component in ANY formula
        --
        -- The UNION at the end de-duplicates and drives re-explosion.
        -- ----------------------------------------------------------------

        -- Items directly linked to changed BOMs
        CREATE TABLE stage_fml_upstream_L0 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_versions av
        JOIN stage_fml_changed_boms cb
            ON  cb.[DATAAREAID] = av.[DATAAREAID]
            AND cb.[BOMID]      = av.[BOMID];

        -- Items that use L0 items as a component in any formula (1 level up)
        CREATE TABLE stage_fml_upstream_L1 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L0 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L2 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L1 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L3 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L2 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L4 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L3 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L5 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L4 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L6 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L5 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L7 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L6 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L8 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L7 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L9 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L8 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L10 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L9 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L11 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L10 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        CREATE TABLE stage_fml_upstream_L12 AS
        SELECT DISTINCT av.[DATAAREAID], av.[ITEMID]
        FROM stage_fml_all_formula_lines fl
        JOIN stage_fml_upstream_L11 u
            ON  u.[DATAAREAID] = fl.[DATAAREAID]
            AND u.[ITEMID]     = fl.[ComponentItemId]
        JOIN stage_fml_all_versions av
            ON  av.[DATAAREAID] = fl.[DATAAREAID]
            AND av.[BOMID]      = fl.[BOMID];

        -- Union all upstream levels into items_to_process
        CREATE TABLE stage_fml_items_to_process AS
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L0
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L1
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L2
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L3
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L4
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L5
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L6
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L7
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L8
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L9
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L10
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L11
        UNION
        SELECT [DATAAREAID], [ITEMID] FROM stage_fml_upstream_L12;

        -- Delete affected FG items from target table (will be re-inserted below)
        DELETE FROM [dbo].[tbl_ExplodedFormula_ByVersion]
        WHERE EXISTS (
            SELECT 1
            FROM stage_fml_items_to_process itp
            WHERE itp.[DATAAREAID] = [dbo].[tbl_ExplodedFormula_ByVersion].[DataAreaId]
              AND itp.[ITEMID]     = [dbo].[tbl_ExplodedFormula_ByVersion].[FgItemId]
        );
    END  -- end INCREMENTAL

    -- =========================================================================
    -- LEVEL 0: ROOT ITEMS — one row per FG item × formula version
    --
    -- Each approved formula version for each item gets its own Level 0 row.
    -- PeriodFromDate / PeriodToDate are seeded directly from BOMVERSION dates.
    -- ComponentItemId is set to FgItemId (self-reference); BomDepth = 0.
    -- These rows are NOT leaf nodes (BomDepth = 0 is excluded from results).
    --
    -- Filtered to stage_fml_items_to_process (FULL: all items; INCREMENTAL:
    -- only items whose BOM tree contains a changed BOMID).
    -- =========================================================================
    CREATE TABLE stage_fml_Level0 AS
    SELECT av.[DATAAREAID]
        , av.[ITEMID]                   AS FgItemId
        , av.[INVENTSITEID]             AS FgSiteId
        , av.[BOMID]                    AS FgBomId
        , CAST(av.[FromDate] AS DATETIME2(3))  AS PeriodFromDate  -- 1900-01-01 = no start restriction
        , CAST(av.[ToDate]   AS DATETIME2(3))  AS PeriodToDate    -- 1900-01-01 = open-ended
        , av.[FormulaQtyLbs]
        , av.[FormulaUomId]
        , av.[FormulaUomConverted]
        , av.[FormulaUomConversionMissing]
        , av.[IsActive]
        , av.[ITEMID]                   AS ComponentItemId   -- self at Level 0
        , av.[INVENTSITEID]             AS INVENTSITEID      -- used for site-match at Level 1
        , CAST(0 AS INT)                AS BomDepth
        , CONVERT(VARCHAR(4000), av.[ITEMID]) AS BomPath
        , CAST(1 AS DECIMAL(28,8))      AS QtyLbsPerLbFG
        , CAST(0 AS INT)                AS UomConverted
        , CAST(0 AS INT)                AS UomConversionMissing
        , av.[FormulaUomId]             AS ComponentNativeUomId
        , CAST(1 AS DECIMAL(28,8))      AS NativeQtyPerLbFG
        -- Level 0 = self-reference, no BOM line; placeholders so UNION ALL in ExpAll matches all levels
        , CAST(0 AS INT)                AS PMFPCTENABLE
        , CAST(NULL AS DECIMAL(28,8))   AS [Percent]
    FROM stage_fml_all_versions av
    WHERE EXISTS (
        SELECT 1
        FROM stage_fml_items_to_process itp
        WHERE itp.[DATAAREAID] = av.[DATAAREAID]
          AND itp.[ITEMID]     = av.[ITEMID]
    );

    -- =========================================================================
    -- LEVEL 1: DIRECT INGREDIENTS OF EACH FG FORMULA VERSION
    --
    -- Join strategy: fl.BOMID = eb.FgBomId (exact formula version match)
    -- This ensures we read ingredients for THAT specific formula version only,
    -- not ingredients from other versions of the same item.
    -- =========================================================================
    CREATE TABLE stage_fml_Level1 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId]
        , eb.[FgSiteId]
        , eb.[FgBomId]
        , eb.[PeriodFromDate]           -- inherited, no intersection
        , eb.[PeriodToDate]
        , fl.[FormulaQtyLbs]
        , fl.[FormulaUomId]
        , fl.[FormulaUomConverted]
        , fl.[FormulaUomConversionMissing]
        , eb.[IsActive]
        , fl.[ComponentItemId]
        , fl.[INVENTSITEID]
        , CAST(1 AS INT)                AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(
            eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem]
          AS DECIMAL(28,8))             AS QtyLbsPerLbFG
        , fl.[CompUomConverted]         AS UomConverted
        , fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(
            eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem]
          AS DECIMAL(28,8))             AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    JOIN stage_fml_Level0 eb
        ON  fl.[DATAAREAID]    = eb.[DATAAREAID]
        AND fl.[BOMID]         = eb.[FgBomId]
        AND fl.[FormulaItemId] = eb.[FgItemId];  -- Fix v6: prevent co-product fan-out
        -- Without this, a BOMID shared by multiple co-products pulls in all co-product
        -- formula line rows, multiplying Level 1 output by the number of co-products.
        -- Levels 2-12 already join on FormulaItemId = ComponentItemId and are unaffected.

    -- =========================================================================
    -- LEVELS 2-12: ITERATIVE SUB-ASSEMBLY EXPLOSION
    --
    -- Join strategy (differs from Level 1):
    --   - fl.FormulaItemId = eb.ComponentItemId  (sub-assembly's formula)
    --   - Site match with fallback
    --   - DATE-RANGE OVERLAP: sub-assembly version must overlap parent period
    --       fl.VersionToDate >= eb.PeriodFromDate  (child not expired before parent starts)
    --       fl.VersionFromDate <= eb.PeriodToDate  (child doesn't start after parent ends)
    --       Both comparisons handle sentinel '1900-01-01' as open on each end
    --   - Sub-assembly gate: eb.ComponentItemId must be in stage_fml_sub_assembly_map
    --
    -- Period intersection (sentinel-aware):
    --   PeriodFromDate = MAX(parent.PeriodFromDate, child.VersionFromDate)
    --   PeriodToDate   = MIN(parent.PeriodToDate,   child.VersionToDate)
    --   Sentinel '1900-01-01' on FROMDATE = -infinity (open start → other wins)
    --   Sentinel '1900-01-01' on TODATE   = +infinity (open end  → other wins)
    --
    -- This correctly splits the parent period whenever a sub-assembly formula
    -- version boundary falls within it.
    -- =========================================================================

    -- ----- LEVEL 2 -----
    CREATE TABLE stage_fml_Level2 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId]
        , eb.[FgSiteId]
        , eb.[FgBomId]
        -- Sentinel-aware MAX(parent.PeriodFromDate, child.VersionFromDate)
        , CAST(CASE
            WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate]
            WHEN eb.[PeriodFromDate]  = '1900-01-01' THEN fl.[VersionFromDate]
            WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate]
            ELSE eb.[PeriodFromDate]
          END AS DATETIME2(3))          AS PeriodFromDate
        -- Sentinel-aware MIN(parent.PeriodToDate, child.VersionToDate)
        , CAST(CASE
            WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]
            WHEN eb.[PeriodToDate]    = '1900-01-01' THEN fl.[VersionToDate]
            WHEN fl.[VersionToDate]   < eb.[PeriodToDate] THEN fl.[VersionToDate]
            ELSE eb.[PeriodToDate]
          END AS DATETIME2(3))          AS PeriodToDate
        , fl.[FormulaQtyLbs]
        , fl.[FormulaUomId]
        , fl.[FormulaUomConverted]
        , fl.[FormulaUomConversionMissing]
        , eb.[IsActive]
        , fl.[ComponentItemId]
        , fl.[INVENTSITEID]
        , CAST(2 AS INT)                AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(
            eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem]
          AS DECIMAL(28,8))             AS QtyLbsPerLbFG
        , fl.[CompUomConverted]         AS UomConverted
        , fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(
            eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem]
          AS DECIMAL(28,8))             AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb
        ON  fb.[DATAAREAID] = fl.[DATAAREAID]
        AND fb.[ITEMID]     = fl.[FormulaItemId]
    JOIN stage_fml_Level1 eb
        ON  fl.[DATAAREAID]    = eb.[DATAAREAID]
        AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (
            ISNULL(fl.[INVENTSITEID], '') = ISNULL(eb.[INVENTSITEID], '')
            OR (
                ISNULL(fl.[INVENTSITEID], '') = ISNULL(fb.[FallbackSite], '')
                AND NOT EXISTS (
                    SELECT 1
                    FROM stage_fml_all_formula_lines fl2
                    WHERE fl2.[DATAAREAID]    = fl.[DATAAREAID]
                      AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                      AND ISNULL(fl2.[INVENTSITEID], '') = ISNULL(eb.[INVENTSITEID], '')
                )
            )
        )
        -- Date-range overlap: child version must overlap parent period
        AND (
            fl.[VersionToDate]   = '1900-01-01'  -- child open-ended → overlaps always
            OR eb.[PeriodFromDate] = '1900-01-01'  -- parent open start → overlaps always
            OR fl.[VersionToDate] >= eb.[PeriodFromDate]
        )
        AND (
            fl.[VersionFromDate] = '1900-01-01'  -- child no-start → overlaps always
            OR eb.[PeriodToDate]   = '1900-01-01'  -- parent open-ended → overlaps always
            OR fl.[VersionFromDate] <= eb.[PeriodToDate]
        )
    -- Sub-assembly gate: only expand components that have their own formula
    JOIN stage_fml_sub_assembly_map sa
        ON  sa.[DATAAREAID] = eb.[DATAAREAID]
        AND sa.[ITEMID]     = eb.[ComponentItemId];

    -- ----- LEVEL 3 -----
    CREATE TABLE stage_fml_Level3 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE
            WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate]
            WHEN eb.[PeriodFromDate]  = '1900-01-01' THEN fl.[VersionFromDate]
            WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate]
            ELSE eb.[PeriodFromDate]
          END AS DATETIME2(3))          AS PeriodFromDate
        , CAST(CASE
            WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]
            WHEN eb.[PeriodToDate]    = '1900-01-01' THEN fl.[VersionToDate]
            WHEN fl.[VersionToDate]   < eb.[PeriodToDate] THEN fl.[VersionToDate]
            ELSE eb.[PeriodToDate]
          END AS DATETIME2(3))          AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive]
        , fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(3 AS INT)                AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level2 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 4 -----
    CREATE TABLE stage_fml_Level4 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(4 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level3 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 5 -----
    CREATE TABLE stage_fml_Level5 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(5 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level4 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 6 -----
    CREATE TABLE stage_fml_Level6 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(6 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level5 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 7 -----
    CREATE TABLE stage_fml_Level7 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(7 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level6 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 8 -----
    CREATE TABLE stage_fml_Level8 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(8 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level7 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 9 -----
    CREATE TABLE stage_fml_Level9 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(9 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level8 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 10 -----
    CREATE TABLE stage_fml_Level10 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(10 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level9 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 11 -----
    CREATE TABLE stage_fml_Level11 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(11 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level10 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- ----- LEVEL 12 -----
    CREATE TABLE stage_fml_Level12 AS
    SELECT fl.[DATAAREAID]
        , eb.[FgItemId], eb.[FgSiteId], eb.[FgBomId]
        , CAST(CASE WHEN fl.[VersionFromDate] = '1900-01-01' THEN eb.[PeriodFromDate] WHEN eb.[PeriodFromDate] = '1900-01-01' THEN fl.[VersionFromDate] WHEN fl.[VersionFromDate] > eb.[PeriodFromDate] THEN fl.[VersionFromDate] ELSE eb.[PeriodFromDate] END AS DATETIME2(3)) AS PeriodFromDate
        , CAST(CASE WHEN fl.[VersionToDate]   = '1900-01-01' THEN eb.[PeriodToDate]   WHEN eb.[PeriodToDate]   = '1900-01-01' THEN fl.[VersionToDate]   WHEN fl.[VersionToDate]   < eb.[PeriodToDate]   THEN fl.[VersionToDate]   ELSE eb.[PeriodToDate]   END AS DATETIME2(3)) AS PeriodToDate
        , fl.[FormulaQtyLbs], fl.[FormulaUomId], fl.[FormulaUomConverted], fl.[FormulaUomConversionMissing]
        , eb.[IsActive], fl.[ComponentItemId], fl.[INVENTSITEID]
        , CAST(12 AS INT) AS BomDepth
        , CONVERT(VARCHAR(4000), eb.[BomPath] + '-->' + fl.[ComponentItemId]) AS BomPath
        , CAST(eb.[QtyLbsPerLbFG] * fl.[QtyLbsPerLbOfFormulaItem] AS DECIMAL(28,8)) AS QtyLbsPerLbFG
        , fl.[CompUomConverted] AS UomConverted, fl.[CompUomConversionMissing] AS UomConversionMissing
        , fl.[ComponentNativeUomId]
        , CAST(eb.[QtyLbsPerLbFG] * fl.[NativeQtyPerLbOfFormulaItem] AS DECIMAL(28,8)) AS NativeQtyPerLbFG
        , fl.[PMFPCTENABLE]
        , CASE WHEN fl.[PMFPCTENABLE] = 1 THEN CAST(fl.[PMFFORMULAPCT] * eb.[QtyLbsPerLbFG] AS DECIMAL(28,8)) ELSE NULL END AS [Percent]
    FROM stage_fml_all_formula_lines fl
    LEFT JOIN stage_fml_item_fallback_site fb ON fb.[DATAAREAID] = fl.[DATAAREAID] AND fb.[ITEMID] = fl.[FormulaItemId]
    JOIN stage_fml_Level11 eb
        ON  fl.[DATAAREAID] = eb.[DATAAREAID] AND fl.[FormulaItemId] = eb.[ComponentItemId]
        AND (ISNULL(fl.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],'')
             OR (ISNULL(fl.[INVENTSITEID],'') = ISNULL(fb.[FallbackSite],'')
                 AND NOT EXISTS (SELECT 1 FROM stage_fml_all_formula_lines fl2
                     WHERE fl2.[DATAAREAID] = fl.[DATAAREAID] AND fl2.[FormulaItemId] = fl.[FormulaItemId]
                       AND ISNULL(fl2.[INVENTSITEID],'') = ISNULL(eb.[INVENTSITEID],''))))
        AND (fl.[VersionToDate]   = '1900-01-01' OR eb.[PeriodFromDate] = '1900-01-01' OR fl.[VersionToDate]   >= eb.[PeriodFromDate])
        AND (fl.[VersionFromDate] = '1900-01-01' OR eb.[PeriodToDate]   = '1900-01-01' OR fl.[VersionFromDate] <= eb.[PeriodToDate])
    JOIN stage_fml_sub_assembly_map sa ON sa.[DATAAREAID] = eb.[DATAAREAID] AND sa.[ITEMID] = eb.[ComponentItemId];

    -- =========================================================================
    -- COMBINE ALL LEVELS
    -- Level 0 rows (BomDepth = 0) are included here but excluded from the
    -- result in the next step (BomDepth > 0 filter).
    -- =========================================================================
    CREATE TABLE stage_fml_ExpAll AS
    SELECT * FROM stage_fml_Level0
    UNION ALL SELECT * FROM stage_fml_Level1
    UNION ALL SELECT * FROM stage_fml_Level2
    UNION ALL SELECT * FROM stage_fml_Level3
    UNION ALL SELECT * FROM stage_fml_Level4
    UNION ALL SELECT * FROM stage_fml_Level5
    UNION ALL SELECT * FROM stage_fml_Level6
    UNION ALL SELECT * FROM stage_fml_Level7
    UNION ALL SELECT * FROM stage_fml_Level8
    UNION ALL SELECT * FROM stage_fml_Level9
    UNION ALL SELECT * FROM stage_fml_Level10
    UNION ALL SELECT * FROM stage_fml_Level11
    UNION ALL SELECT * FROM stage_fml_Level12;

    -- =========================================================================
    -- RESULT: LEAF NODES (INGREDIENT ROWS FOR tbl_ExplodedFormula_ByVersion)
    --
    -- Leaf = ComponentItemId NOT in stage_fml_sub_assembly_map
    --         (no approved formula of its own → purchased raw material / packaging)
    -- BomDepth > 0 excludes the Level 0 self-reference rows.
    --
    -- Group 40 EA-fraction 
    --   For Group 40 items with no LB conversion and non-LB native UOM,
    --   QtyLbsPerLbFG holds bags/LB_formula (LB-space accumulation).
    --   We divide by the FG's FormulaUomId→ComponentNativeUomId factor to
    --   yield bags per FG-formula-UOM.  Stored in LbsPerLbFG; UomConversionMissing=1
    --   identifies these rows.  NULL if FG conversion factor is missing.
    -- =========================================================================
    CREATE TABLE stage_fml_Result_New AS
    SELECT ex.[DATAAREAID]
        , ex.[FgItemId]
        , ex.[FgSiteId]
        , ex.[FgBomId]
        , ex.[PeriodFromDate]
        , ex.[PeriodToDate]
        , ex.[ComponentItemId]          AS RmItemId
        , ex.[INVENTSITEID]             AS RmSiteId
        -- LbsPerLbFG — Group 40 exception applied at result time (same as v2.2)
        , CASE
            WHEN comp_ig.[ItemGroupId]              = '40'
             AND ex.[UomConversionMissing]          = 1
             AND ex.[ComponentNativeUomId]          <> 'LB'
             AND uc_fg_result.[UOMConversionFactor] IS NOT NULL
             AND uc_fg_result.[UOMConversionFactor]  > 0
            THEN CAST(
                ex.[QtyLbsPerLbFG] / uc_fg_result.[UOMConversionFactor]
              AS DECIMAL(28,8))
            ELSE ex.[QtyLbsPerLbFG]
          END                                       AS LbsPerLbFG
        , ex.[NativeQtyPerLbFG]         AS NativeLbsPerLbFG
        , ex.[ComponentNativeUomId]     AS RmNativeUomId
        , ex.[UomConverted]
        , ex.[UomConversionMissing]
        , ex.[PMFPCTENABLE]             AS PercentControlled
        , ex.[Percent]
        , ex.[BomPath]
        , ex.[BomDepth]                 AS BomLevel
        , ex.[FormulaUomId]             AS FgFormulaUomId
        , ex.[FormulaQtyLbs]            AS FgFormulaQtyLbs
        , fg_pt.[Name]                  AS FgItemName
        , fg_ig.[ItemGroupId]           AS FgItemGroupId
        , comp_pt.[Name]                AS RmItemName
        , comp_ig.[ItemGroupId]         AS RmItemGroupId
    FROM stage_fml_ExpAll ex
    LEFT JOIN WH_Raw.dbo.[INVENTTABLE] fg_it
        ON  fg_it.[DATAAREAID] = ex.[DATAAREAID]
        AND fg_it.[ITEMID]     = ex.[FgItemId]
    LEFT JOIN WH_Raw.dbo.[EcoResProductTranslation] fg_pt
        ON  fg_pt.[Product]    = fg_it.[PRODUCT]
        AND fg_pt.[LanguageId] = 'en-us'
    LEFT JOIN WH_Raw.dbo.[InventItemGroupItem] fg_ig
        ON  fg_ig.[ItemDataAreaId] = ex.[DATAAREAID]
        AND fg_ig.[ItemId]         = ex.[FgItemId]
    LEFT JOIN WH_Raw.dbo.[INVENTTABLE] comp_it
        ON  comp_it.[DATAAREAID] = ex.[DATAAREAID]
        AND comp_it.[ITEMID]     = ex.[ComponentItemId]
    LEFT JOIN WH_Raw.dbo.[EcoResProductTranslation] comp_pt
        ON  comp_pt.[Product]    = comp_it.[PRODUCT]
        AND comp_pt.[LanguageId] = 'en-us'
    LEFT JOIN WH_Raw.dbo.[InventItemGroupItem] comp_ig
        ON  comp_ig.[ItemDataAreaId] = ex.[DATAAREAID]
        AND comp_ig.[ItemId]         = ex.[ComponentItemId]
    -- FG item UOM conversion for Group 40: FormulaUomId → ComponentNativeUomId
    LEFT JOIN WH_Raw.dbo.[vwUnitOfMeasureConversion] uc_fg_result
        ON  uc_fg_result.[Product]    = fg_it.[PRODUCT]
        AND uc_fg_result.[SymbolFrom] = ex.[FormulaUomId]
        AND uc_fg_result.[SymbolTo]   = ex.[ComponentNativeUomId]
    -- Leaf nodes only
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_fml_sub_assembly_map sa
        WHERE sa.[DATAAREAID] = ex.[DATAAREAID]
          AND sa.[ITEMID]     = ex.[ComponentItemId]
    )
      AND ex.[BomDepth] > 0;

    -- =========================================================================
    -- INSERT INTO TARGET TABLE
    -- Surrogate key: SHA2_256 of the natural key + BomPath (path-unique)
    -- IsCurrentPeriod seeded here; refreshed by the UPDATE below.
    -- =========================================================================
    INSERT INTO [dbo].[tbl_ExplodedFormula_ByVersion] (
          [ExplodedFormulaKey]
        , [DataAreaId]
        , [FgItemId]
        , [FgSiteId]
        , [FgBomId]
        , [PeriodFromDate]
        , [PeriodToDate]
        , [RmItemId]
        , [RmSiteId]
        , [LbsPerLbFG]
        , [NativeLbsPerLbFG]
        , [RmNativeUomId]
        , [UomConverted]
        , [UomConversionMissing]
        , [PercentControlled]
        , [Percent]
        , [BomPath]
        , [BomLevel]
        , [FgFormulaUomId]
        , [FgFormulaQtyLbs]
        , [FgItemName]
        , [FgItemGroupId]
        , [RmItemName]
        , [RmItemGroupId]
        , [IsCurrentPeriod]
        , [LoadedAtUtc]
    )
    SELECT
          -- BIGINT surrogate key — BINARY not supported in Fabric Warehouse
          ABS(CAST(CAST(
            HASHBYTES('SHA2_256',
              ISNULL(r.[DATAAREAID], '') + '|'
              + ISNULL(r.[FgItemId], '')    + '|'
              + ISNULL(r.[FgSiteId], '')    + '|'
              + ISNULL(r.[FgBomId], '')     + '|'
              + ISNULL(CAST(r.[PeriodFromDate] AS VARCHAR(30)), '') + '|'
              + ISNULL(r.[RmItemId], '')    + '|'
              + ISNULL(r.[BomPath], '')
            ) AS BINARY(8)) AS BIGINT))                   AS ExplodedFormulaKey
        , r.[DATAAREAID]
        , r.[FgItemId]
        , r.[FgSiteId]
        , r.[FgBomId]
        , r.[PeriodFromDate]
        -- PeriodToDate: convert D365 open-end sentinel '1900-01-01' → '2154-12-31'
        -- Internal staging tables retain '1900-01-01' so overlap/intersection logic is unaffected.
        , CASE
            WHEN r.[PeriodToDate] = '1900-01-01' THEN CAST('2154-12-31' AS DATETIME2(3))
            ELSE r.[PeriodToDate]
          END
        , r.[RmItemId]
        , r.[RmSiteId]
        , r.[LbsPerLbFG]
        , r.[NativeLbsPerLbFG]
        , r.[RmNativeUomId]
        , r.[UomConverted]
        , r.[UomConversionMissing]
        , r.[PercentControlled]
        , r.[Percent]
        , r.[BomPath]
        , r.[BomLevel]
        , r.[FgFormulaUomId]
        , r.[FgFormulaQtyLbs]
        , r.[FgItemName]
        , r.[FgItemGroupId]
        , r.[RmItemName]
        , r.[RmItemGroupId]
        -- IsCurrentPeriod: preliminary value; refreshed by sweep below.
        -- r.[PeriodToDate] is still '1900-01-01' here (pre-conversion), so sentinel check applies.
        , CASE
            WHEN (r.[PeriodFromDate] = '1900-01-01' OR r.[PeriodFromDate] <= SYSDATETIME())
             AND (r.[PeriodToDate]   = '1900-01-01' OR r.[PeriodToDate]   >= SYSDATETIME())
            THEN 1
            ELSE 0
          END
        , CAST(GETUTCDATE() AS DATETIME2(3))
    FROM stage_fml_Result_New r;

    -- =========================================================================
    -- IsCurrentPeriod REFRESH — sweep the ENTIRE target table
    -- Run on every execution regardless of mode.  Ensures rows from prior runs
    -- whose periods have expired are updated to IsCurrentPeriod = 0, and rows
    -- that became current (future-dated versions) are updated to 1.
    -- =========================================================================
    -- PeriodToDate is stored as '2154-12-31' (not '1900-01-01') for open-ended rows,
    -- so no sentinel check needed on the ToDate side.
    UPDATE [dbo].[tbl_ExplodedFormula_ByVersion]
    SET [IsCurrentPeriod] = CASE
        WHEN ([PeriodFromDate] = '1900-01-01' OR [PeriodFromDate] <= SYSDATETIME())
         AND [PeriodToDate] >= SYSDATETIME()
        THEN 1
        ELSE 0
    END;

    -- =========================================================================
    -- UPDATE HASH TRACKER
    -- Truncate and re-insert from stage_fml_current_hashes (reflects full
    -- current state of approved formula versions).
    -- LastChangedUtc: v1.0 sets to run timestamp on every refresh.
    -- =========================================================================
    TRUNCATE TABLE [dbo].[tbl_FormulaHash_Tracker];

    INSERT INTO [dbo].[tbl_FormulaHash_Tracker] (
          [DataAreaId]
        , [BomId]
        , [ItemId]
        , [IngredientHash]
        , [LastCheckedUtc]
        , [LastChangedUtc]
    )
    SELECT ch.[DATAAREAID]
        , ch.[BOMID]
        , ch.[ITEMID]
        , ch.[IngredientHash]
        , CAST(GETUTCDATE() AS DATETIME2(3))
        , CAST(GETUTCDATE() AS DATETIME2(3))
    FROM stage_fml_current_hashes ch;

    -- =========================================================================
    -- CLEANUP — drop all stage tables (target table and tracker preserved)
    -- =========================================================================
    DROP TABLE IF EXISTS stage_fml_all_versions;
    DROP TABLE IF EXISTS stage_fml_item_fallback_site;
    DROP TABLE IF EXISTS stage_fml_all_formula_lines;
    DROP TABLE IF EXISTS stage_fml_bomid_strings;
    DROP TABLE IF EXISTS stage_fml_sub_assembly_map;
    DROP TABLE IF EXISTS stage_fml_current_hashes;
    DROP TABLE IF EXISTS stage_fml_changed_boms;
    DROP TABLE IF EXISTS stage_fml_items_to_process;
    DROP TABLE IF EXISTS stage_fml_upstream_L0;
    DROP TABLE IF EXISTS stage_fml_upstream_L1;
    DROP TABLE IF EXISTS stage_fml_upstream_L2;
    DROP TABLE IF EXISTS stage_fml_upstream_L3;
    DROP TABLE IF EXISTS stage_fml_upstream_L4;
    DROP TABLE IF EXISTS stage_fml_upstream_L5;
    DROP TABLE IF EXISTS stage_fml_upstream_L6;
    DROP TABLE IF EXISTS stage_fml_upstream_L7;
    DROP TABLE IF EXISTS stage_fml_upstream_L8;
    DROP TABLE IF EXISTS stage_fml_upstream_L9;
    DROP TABLE IF EXISTS stage_fml_upstream_L10;
    DROP TABLE IF EXISTS stage_fml_upstream_L11;
    DROP TABLE IF EXISTS stage_fml_upstream_L12;
    DROP TABLE IF EXISTS stage_fml_Level0;
    DROP TABLE IF EXISTS stage_fml_Level1;
    DROP TABLE IF EXISTS stage_fml_Level2;
    DROP TABLE IF EXISTS stage_fml_Level3;
    DROP TABLE IF EXISTS stage_fml_Level4;
    DROP TABLE IF EXISTS stage_fml_Level5;
    DROP TABLE IF EXISTS stage_fml_Level6;
    DROP TABLE IF EXISTS stage_fml_Level7;
    DROP TABLE IF EXISTS stage_fml_Level8;
    DROP TABLE IF EXISTS stage_fml_Level9;
    DROP TABLE IF EXISTS stage_fml_Level10;
    DROP TABLE IF EXISTS stage_fml_Level11;
    DROP TABLE IF EXISTS stage_fml_Level12;
    DROP TABLE IF EXISTS stage_fml_ExpAll;
    DROP TABLE IF EXISTS stage_fml_Result_New;

END;