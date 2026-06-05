


CREATE     PROCEDURE [dbo].[sp_Execute_SCD_Logic_dimStandardCost]
AS
BEGIN

    -- Run Exploded BOM Standard Costing stored procedure to prep the data
    EXEC [dbo].[sp_Process_Exploded_BOM_Costing_Snapshot]

    -- -- Drop intermediate objects --------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Type1_Updates;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_WithDates;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Append_Extended;

    -- =========================================================================
    -- Step 1: Identify brand-new natural keys
    -- (CMPNY + Product_ID + SiteID + ActivationDate not in DIM at all)
    -- vw_stage_NewStandardCost v5 handles the NOT EXISTS check.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_New AS
    SELECT *
    FROM vw_stage_NewStandardCost;

    -- =========================================================================
    -- Step 2: Identify Type 1 updates
    -- Natural key matches an existing DIM row but one or more cost columns differ.
    -- These rows are updated in place — no new version is created.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_Type1_Updates AS
    SELECT Target.*
    FROM tbl_DIM_StandardCost AS Target
    JOIN vw_stage_DIM_StandardCost_incoming AS Source
        ON  Target.CMPNY          = Source.CMPNY
        AND Target.Product_ID     = Source.Product_ID
        AND Target.SiteID         = Source.SiteID
        AND Target.ActivationDate = Source.ActivationDate
    WHERE (
        ISNULL(Target.EndDate,                                '01/01/1900') <> ISNULL(Source.EndDate,                                   '01/01/1900')
        OR ISNULL(Target.Costing_Version,                                   '') <> ISNULL(Source.Costing_Version,                                   '')
        OR ISNULL(Target.CurrentActiveCost,                               0) <> ISNULL(Source.CurrentActiveCost,                               0)
        OR ISNULL(Target.Direct_Material_Cost_Standard,               0.00)  <> ISNULL(Source.Direct_Material_Cost_Standard,               0.00)
        OR ISNULL(Target.Packaging_Cost_Standard,                     0.00)  <> ISNULL(Source.Packaging_Cost_Standard,                     0.00)
        OR ISNULL(Target.Direct_Labor_Cost_Standard,                  0.00)  <> ISNULL(Source.Direct_Labor_Cost_Standard,                  0.00)
        OR ISNULL(Target.Direct_Utility_Cost_Standard,                0.00)  <> ISNULL(Source.Direct_Utility_Cost_Standard,                0.00)
        OR ISNULL(Target.Overhead_Warehouse_Cost_Standard,            0.00)  <> ISNULL(Source.Overhead_Warehouse_Cost_Standard,            0.00)
        OR ISNULL(Target.Overhead_Indirect_Supervisor_Cost_Standard,  0.00)  <> ISNULL(Source.Overhead_Indirect_Supervisor_Cost_Standard,  0.00)
        OR ISNULL(Target.Overhead_Quality_Cost_Standard,              0.00)  <> ISNULL(Source.Overhead_Quality_Cost_Standard,              0.00)
        OR ISNULL(Target.Overhead_Maintenance_Cost_Standard,          0.00)  <> ISNULL(Source.Overhead_Maintenance_Cost_Standard,          0.00)
        OR ISNULL(Target.Overhead_Manufacturing_Admin_Cost_Standard,  0.00)  <> ISNULL(Source.Overhead_Manufacturing_Admin_Cost_Standard,  0.00)
        OR ISNULL(Target.Overhead_Depreciation_Cost_Standard,         0.00)  <> ISNULL(Source.Overhead_Depreciation_Cost_Standard,         0.00)
        OR ISNULL(Target.Overhead_Miscellaneous_Manufacturing_Cost_Standard, 0.00)
                                                                              <> ISNULL(Source.Overhead_Miscellaneous_Manufacturing_Cost_Standard, 0.00)
        OR ISNULL(Target.Outside_Processing_Cost_Standard,            0.00)  <> ISNULL(Source.Outside_Processing_Cost_Standard,            0.00)
        OR ISNULL(Target.Total_Direct_Cost_Standard,                  0.00)  <> ISNULL(Source.Total_Direct_Cost_Standard,                  0.00)
        OR ISNULL(Target.Total_Overhead_Cost_Standard,                0.00)  <> ISNULL(Source.Total_Overhead_Cost_Standard,                0.00)
        OR ISNULL(Target.TotalCost,                                   0.00)  <> ISNULL(Source.TotalCost,                                   0.00)
        OR ISNULL(Target.accountingcurrency,                             '') <> ISNULL(Source.accountingcurrency,                             '')
    );

    -- =========================================================================
    -- Step 3: Identify deleted records
    -- Active rows (RecordStatus IN (1,2)) whose natural key is no longer present
    -- in the source.  Historical rows (RecordStatus = 0) that are already expired
    -- are not re-expired.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_Deleted AS
    SELECT *
    FROM tbl_DIM_StandardCost AS Target
    WHERE Target.RecordStatus IN (1, 2)
      AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_StandardCost_incoming AS Source
            WHERE Source.CMPNY          = Target.CMPNY
              AND Source.Product_ID     = Target.Product_ID
              AND Source.SiteID         = Target.SiteID
              AND Source.ActivationDate = Target.ActivationDate
      );

    -- =========================================================================
    -- Step 4: Build the merged Final table
    -- Contains: all DIM rows not being Type1-updated or deleted,
    --           Type1 rows with updated cost columns,
    --           brand-new rows,
    --           deleted active rows (expired to RecordStatus = 0).
    -- RecordStatus / RecordEffectiveEndDate are placeholders for non-deleted rows
    -- and will be recalculated in Step 5.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_Final AS

    -- -- A. Unchanged rows (neither Type1 updated nor deleted) -----------------
    SELECT [StandardCostKey]
        ,  [CMPNY]
        ,  [Product_ID]
        ,  [SiteID]
        ,  [ActivationDate]
        ,  [EndDate]
        ,  [Costing_Version]
        ,  [CurrentActiveCost]
        ,  [Direct_Material_Cost_Standard]
        ,  [Packaging_Cost_Standard]
        ,  [Direct_Labor_Cost_Standard]
        ,  [Direct_Utility_Cost_Standard]
        ,  [Overhead_Warehouse_Cost_Standard]
        ,  [Overhead_Indirect_Supervisor_Cost_Standard]
        ,  [Overhead_Quality_Cost_Standard]
        ,  [Overhead_Maintenance_Cost_Standard]
        ,  [Overhead_Manufacturing_Admin_Cost_Standard]
        ,  [Overhead_Depreciation_Cost_Standard]
        ,  [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
        ,  [Outside_Processing_Cost_Standard]
        ,  [Total_Direct_Cost_Standard]
        ,  [Total_Overhead_Cost_Standard]
        ,  [TotalCost]
        ,  [accountingcurrency]
        ,  [RecordEffectiveStartDate]   -- recalculated in Step 5 for non-deleted rows
        ,  [RecordEffectiveEndDate]     -- recalculated in Step 5 for non-deleted rows
        ,  [RecordStatus]               -- recalculated in Step 5 for non-deleted rows
        ,  [Source]
    FROM tbl_DIM_StandardCost AS tgt
    WHERE NOT EXISTS (
        SELECT 1 FROM stage_tbl_DIM_StandardCost_Type1_Updates u
        WHERE u.CMPNY          = tgt.CMPNY
          AND u.Product_ID     = tgt.Product_ID
          AND u.SiteID         = tgt.SiteID
          AND u.ActivationDate = tgt.ActivationDate
    )
    AND NOT EXISTS (
        SELECT 1 FROM stage_tbl_DIM_StandardCost_Deleted d
        WHERE d.CMPNY          = tgt.CMPNY
          AND d.Product_ID     = tgt.Product_ID
          AND d.SiteID         = tgt.SiteID
          AND d.ActivationDate = tgt.ActivationDate
    )

    UNION ALL

    -- -- B. Type 1 updated rows: preserve key + dates; replace cost columns ----
    SELECT tgt.[StandardCostKey]
        ,  tgt.[CMPNY]
        ,  tgt.[Product_ID]
        ,  tgt.[SiteID]
        ,  tgt.[ActivationDate]
        ,  src.[EndDate]

        ,  src.[Costing_Version]
        ,  src.[CurrentActiveCost]
        ,  src.[Direct_Material_Cost_Standard]
        ,  src.[Packaging_Cost_Standard]
        ,  src.[Direct_Labor_Cost_Standard]
        ,  src.[Direct_Utility_Cost_Standard]
        ,  src.[Overhead_Warehouse_Cost_Standard]
        ,  src.[Overhead_Indirect_Supervisor_Cost_Standard]
        ,  src.[Overhead_Quality_Cost_Standard]
        ,  src.[Overhead_Maintenance_Cost_Standard]
        ,  src.[Overhead_Manufacturing_Admin_Cost_Standard]
        ,  src.[Overhead_Depreciation_Cost_Standard]
        ,  src.[Overhead_Miscellaneous_Manufacturing_Cost_Standard]
        ,  src.[Outside_Processing_Cost_Standard]
        ,  src.[Total_Direct_Cost_Standard]
        ,  src.[Total_Overhead_Cost_Standard]
        ,  src.[TotalCost]
        ,  src.[accountingcurrency]
        ,  tgt.[RecordEffectiveStartDate]   -- recalculated in Step 5
        ,  tgt.[RecordEffectiveEndDate]     -- recalculated in Step 5
        ,  tgt.[RecordStatus]               -- recalculated in Step 5
        ,  tgt.[Source]
    FROM stage_tbl_DIM_StandardCost_Type1_Updates tgt
    JOIN vw_stage_DIM_StandardCost_incoming src
        ON  tgt.CMPNY          = src.CMPNY
        AND tgt.Product_ID     = src.Product_ID
        AND tgt.SiteID         = src.SiteID
        AND tgt.ActivationDate = src.ActivationDate

    UNION ALL

    -- -- C. Brand-new natural keys ---------------------------------------------
    SELECT *
    FROM stage_tbl_DIM_StandardCost_New

    UNION ALL

    -- -- D. Deleted active rows: expire immediately, skip Step 5 recalculation -
    SELECT [StandardCostKey]
        ,  [CMPNY]
        ,  [Product_ID]
        ,  [SiteID]
        ,  [ActivationDate]
        ,  [EndDate]

        ,  [Costing_Version]
        ,  [CurrentActiveCost]
        ,  [Direct_Material_Cost_Standard]
        ,  [Packaging_Cost_Standard]
        ,  [Direct_Labor_Cost_Standard]
        ,  [Direct_Utility_Cost_Standard]
        ,  [Overhead_Warehouse_Cost_Standard]
        ,  [Overhead_Indirect_Supervisor_Cost_Standard]
        ,  [Overhead_Quality_Cost_Standard]
        ,  [Overhead_Maintenance_Cost_Standard]
        ,  [Overhead_Manufacturing_Admin_Cost_Standard]
        ,  [Overhead_Depreciation_Cost_Standard]
        ,  [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
        ,  [Outside_Processing_Cost_Standard]
        ,  [Total_Direct_Cost_Standard]
        ,  [Total_Overhead_Cost_Standard]
        ,  [TotalCost]
        ,  [accountingcurrency]
        ,  [RecordEffectiveStartDate]
        ,  CAST(GETDATE() AS DATETIME2(3))  AS RecordEffectiveEndDate
        ,  0                                AS RecordStatus
        ,  [Source]
    FROM stage_tbl_DIM_StandardCost_Deleted;

    -- =========================================================================
    -- Step 5: Recalculate RecordEffectiveStartDate, RecordEffectiveEndDate,
    --         and RecordStatus for all non-expired rows using LEAD(ActivationDate).
    --
    --   RecordEffectiveStartDate = ActivationDate
    --   RecordEffectiveEndDate   = LEAD(ActivationDate) - 1 day per group,
    --                              or '2099-12-31 00:00:01.000' if no next row.
    --   RecordStatus:
    --     2 = ActivationDate > today (future)
    --     1 = most recent ActivationDate <= today (current)
    --     0 = older ActivationDate <= today (historical)
    --
    -- Deleted rows (RecordStatus = 0 set in Step 4 Section D) pass through
    -- unchanged — their natural key is no longer in the source so we do not
    -- recalculate their dates.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_WithDates AS

    -- -- Non-deleted rows: apply LEAD-based date recalculation -----------------
    SELECT [StandardCostKey]
        ,  [CMPNY]
        ,  [Product_ID]
        ,  [SiteID]
        ,  [ActivationDate]
        ,  [EndDate]

        ,  [Costing_Version]
        ,  [CurrentActiveCost]
        ,  [Direct_Material_Cost_Standard]
        ,  [Packaging_Cost_Standard]
        ,  [Direct_Labor_Cost_Standard]
        ,  [Direct_Utility_Cost_Standard]
        ,  [Overhead_Warehouse_Cost_Standard]
        ,  [Overhead_Indirect_Supervisor_Cost_Standard]
        ,  [Overhead_Quality_Cost_Standard]
        ,  [Overhead_Maintenance_Cost_Standard]
        ,  [Overhead_Manufacturing_Admin_Cost_Standard]
        ,  [Overhead_Depreciation_Cost_Standard]
        ,  [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
        ,  [Outside_Processing_Cost_Standard]
        ,  [Total_Direct_Cost_Standard]
        ,  [Total_Overhead_Cost_Standard]
        ,  [TotalCost]
        ,  [accountingcurrency]
        ,  CAST([ActivationDate] AS DATETIME2(3)) AS RecordEffectiveStartDate
        ,  CAST(
               CASE
                   WHEN NextActivationDate IS NULL THEN '2099-12-31 00:00:01.000'
                   ELSE DATEADD(day, -1, CAST(NextActivationDate AS DATETIME2(3)))
               END
           AS DATETIME2(3)) AS RecordEffectiveEndDate
        ,  CASE
               WHEN CAST([ActivationDate] AS DATE) > CAST(GETDATE() AS DATE)
                   THEN 2   -- future
               WHEN [ActivationDate] = MaxPastActivationDate
                   THEN 1   -- current (most recent activation <= today)
               ELSE 0       -- historical
           END AS RecordStatus
        ,  [Source]
    FROM (
        SELECT *
             , LEAD([ActivationDate]) OVER (
                   PARTITION BY [CMPNY], [Product_ID], [SiteID]
                   ORDER BY [ActivationDate]
               ) AS NextActivationDate
             , MAX(
                   CASE
                       WHEN CAST([ActivationDate] AS DATE) <= CAST(GETDATE() AS DATE)
                           THEN [ActivationDate]
                   END
               ) OVER (
                   PARTITION BY [CMPNY], [Product_ID], [SiteID]
               ) AS MaxPastActivationDate
        FROM stage_tbl_DIM_StandardCost_Final
        -- Exclude rows that were explicitly deleted in Step 4 Section D.
        -- Those rows are passed through unmodified in the UNION ALL below.
        WHERE NOT EXISTS (
            SELECT 1
            FROM stage_tbl_DIM_StandardCost_Deleted del
            WHERE del.CMPNY          = stage_tbl_DIM_StandardCost_Final.CMPNY
              AND del.Product_ID     = stage_tbl_DIM_StandardCost_Final.Product_ID
              AND del.SiteID         = stage_tbl_DIM_StandardCost_Final.SiteID
              AND del.ActivationDate = stage_tbl_DIM_StandardCost_Final.ActivationDate
        )
    ) calc

    UNION ALL

    -- -- Deleted rows: pass through with RecordStatus = 0 already set ----------
    SELECT [StandardCostKey]
        ,  [CMPNY]
        ,  [Product_ID]
        ,  [SiteID]
        ,  [ActivationDate]
        ,  [EndDate]
        ,  [Costing_Version]
        ,  [CurrentActiveCost]
        ,  [Direct_Material_Cost_Standard]
        ,  [Packaging_Cost_Standard]
        ,  [Direct_Labor_Cost_Standard]
        ,  [Direct_Utility_Cost_Standard]
        ,  [Overhead_Warehouse_Cost_Standard]
        ,  [Overhead_Indirect_Supervisor_Cost_Standard]
        ,  [Overhead_Quality_Cost_Standard]
        ,  [Overhead_Maintenance_Cost_Standard]
        ,  [Overhead_Manufacturing_Admin_Cost_Standard]
        ,  [Overhead_Depreciation_Cost_Standard]
        ,  [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
        ,  [Outside_Processing_Cost_Standard]
        ,  [Total_Direct_Cost_Standard]
        ,  [Total_Overhead_Cost_Standard]
        ,  [TotalCost]
        ,  [accountingcurrency]
        ,  [RecordEffectiveStartDate]
        ,  [RecordEffectiveEndDate]
        ,  [RecordStatus]
        ,  [Source]
    FROM stage_tbl_DIM_StandardCost_Final
    WHERE EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_StandardCost_Deleted del
        WHERE del.CMPNY          = stage_tbl_DIM_StandardCost_Final.CMPNY
          AND del.Product_ID     = stage_tbl_DIM_StandardCost_Final.Product_ID
          AND del.SiteID         = stage_tbl_DIM_StandardCost_Final.SiteID
          AND del.ActivationDate = stage_tbl_DIM_StandardCost_Final.ActivationDate
    );

    -- =========================================================================
    -- Step 6: Build deduplicated Append table
    -- Existing DIM rows that are NOT covered by WithDates (they have already been
    -- processed or are being replaced) are dropped; WithDates rows are canonical.
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_Append AS
    SELECT f.StandardCostKey, f.CMPNY, f.Product_ID, f.SiteID, f.ActivationDate, f.EndDate, f.Costing_Version, f.CurrentActiveCost
    , f.Direct_Material_Cost_Standard, f.Packaging_Cost_Standard, f.Direct_Labor_Cost_Standard, f.Direct_Utility_Cost_Standard
    , f.Overhead_Warehouse_Cost_Standard, f.Overhead_Indirect_Supervisor_Cost_Standard, f.Overhead_Quality_Cost_Standard, f.Overhead_Maintenance_Cost_Standard
    , f.Overhead_Manufacturing_Admin_Cost_Standard, f.Overhead_Depreciation_Cost_Standard, f.Overhead_Miscellaneous_Manufacturing_Cost_Standard
    , f.Outside_Processing_Cost_Standard, f.Total_Direct_Cost_Standard, f.Total_Overhead_Cost_Standard, f.TotalCost, f.accountingcurrency, f.RecordEffectiveStartDate
    , f.RecordEffectiveEndDate, f.RecordStatus, f.Source
    FROM tbl_DIM_StandardCost f
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_StandardCost_WithDates d
        WHERE d.CMPNY          = f.CMPNY
          AND d.Product_ID     = f.Product_ID
          AND d.SiteID         = f.SiteID
          AND d.ActivationDate = f.ActivationDate
    )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_StandardCost_WithDates
    ORDER BY [CMPNY], [Product_ID], [SiteID], [ActivationDate];

    -- =========================================================================
    -- Step 6b: Add ProductName and ProductSearchName
    -- =========================================================================
    CREATE TABLE stage_tbl_DIM_StandardCost_Append_Extended AS
    SELECT s.StandardCostKey, s.CMPNY, s.Product_ID, s.SiteID, s.ActivationDate, s.EndDate, s.Costing_Version, s.CurrentActiveCost, p.ProductName, p.ProductSearchName
    , s.Direct_Material_Cost_Standard, s.Packaging_Cost_Standard, s.Direct_Labor_Cost_Standard, s.Direct_Utility_Cost_Standard
    , s.Overhead_Warehouse_Cost_Standard, s.Overhead_Indirect_Supervisor_Cost_Standard, s.Overhead_Quality_Cost_Standard, s.Overhead_Maintenance_Cost_Standard
    , s.Overhead_Manufacturing_Admin_Cost_Standard, s.Overhead_Depreciation_Cost_Standard, s.Overhead_Miscellaneous_Manufacturing_Cost_Standard
    , s.Outside_Processing_Cost_Standard, s.Total_Direct_Cost_Standard, s.Total_Overhead_Cost_Standard, s.TotalCost, s.accountingcurrency, s.RecordEffectiveStartDate
    , s.RecordEffectiveEndDate, s.RecordStatus, s.Source
    FROM stage_tbl_DIM_StandardCost_Append s
    JOIN tbl_DIM_Product p
        ON  s.Product_ID = p.Product_ID
          AND s.CMPNY      = p.CMPNY
          AND p.recordstatus = 1

    -- =========================================================================
    -- Step 7: Replace the DIM table with the updated Append
    -- =========================================================================
    DROP TABLE IF EXISTS tbl_DIM_StandardCost;

    CREATE TABLE tbl_DIM_StandardCost AS
    SELECT *
    FROM stage_tbl_DIM_StandardCost_Append_Extended
    order by 2,3,4
    -- =========================================================================
    -- Step 8: Cleanup
    -- =========================================================================
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Type1_Updates;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_WithDates;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_StandardCost_Append_Extended;
END;

GO

