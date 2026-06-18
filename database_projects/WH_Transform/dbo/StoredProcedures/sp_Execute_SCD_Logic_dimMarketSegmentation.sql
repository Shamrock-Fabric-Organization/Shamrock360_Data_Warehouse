CREATE   PROCEDURE [dbo].[sp_Execute_SCD_Logic_dimMarketSegmentation]
AS
BEGIN
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_ForUpdates_Prior;

    -- ============================================================
    -- Step 1: Identify new records not in the current dimension table
    -- ============================================================
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_New AS
    SELECT *
    FROM vw_stage_NewMarketSegmentation;

    -- ============================================================
    -- Step 2: Identify records that need to be expired (SCD Type 2 change)
    -- Triggered by: Industry or SubIndustry change
    -- ============================================================
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Expired AS
    SELECT Target.*
    FROM tbl_DIM_MarketSegmentation AS Target
    JOIN vw_stage_DIM_MarketSegmentation_incoming AS Source
        ON  Target.ProductID  = Source.ProductID
        AND Target.CustomerID = Source.CustomerID
        AND Target.CMPNY      = Source.CMPNY
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.Industry,    '') <> ISNULL(Source.Industry,    '')
            OR ISNULL(Target.SubIndustry, '') <> ISNULL(Source.SubIndustry, '')
            );

    -- ============================================================
    -- Step 3: Identify records with Type 1-only changes
    -- (CPCID, LegacyCPCID, AccountTranslatedToD365, ProductTranslatedToD365)
    -- Excluded if the record is already in the Expired set (Type 2 wins)
    -- ============================================================
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_MarketSegmentation AS Target
    JOIN vw_stage_DIM_MarketSegmentation_incoming AS Source
        ON  Target.ProductID  = Source.ProductID
        AND Target.CustomerID = Source.CustomerID
        AND Target.CMPNY      = Source.CMPNY
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.CPCID,                     '') <> ISNULL(Source.CPCID,                     '')
            OR ISNULL(Target.LegacyCPCID,            '') <> ISNULL(Source.LegacyCPCID,               '')
            OR ISNULL(Target.AccountTranslatedToD365, '') <> ISNULL(Source.AccountTranslatedToD365,  '')
            OR ISNULL(Target.ProductTranslatedToD365, '') <> ISNULL(Source.ProductTranslatedToD365,  '')
            )
        AND NOT EXISTS (
            SELECT 1
            FROM stage_tbl_DIM_MarketSegmentation_Expired AS Expired
            WHERE Expired.ProductID  = Target.ProductID
              AND Expired.CustomerID = Target.CustomerID
              AND Expired.CMPNY      = Target.CMPNY
            );

    -- Create table with Type 1 changes for insert into final table
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Type1_OnlyUpdatedRecords AS
    SELECT
         Target.MarketSegmentationKey
        ,Target.CMPNY
        ,Target.CustomerID
        ,Target.ProductID
        ,Source.CPCID
        ,Source.LegacyCPCID
        ,Target.Industry        -- Type 1 change: keep existing Industry/SubIndustry
        ,Target.SubIndustry
        ,Source.AccountTranslatedToD365
        ,Source.ProductTranslatedToD365
        ,Target.RecordEffectiveStartDate
        ,Target.RecordEffectiveEndDate
        ,Target.RecordStatus
        ,Target.Source
    FROM stage_tbl_DIM_MarketSegmentation_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_MarketSegmentation_incoming AS Source
        ON  Target.ProductID  = Source.ProductID
        AND Target.CustomerID = Source.CustomerID
        AND Target.CMPNY      = Source.CMPNY;

    -- ============================================================
    -- Step 4: Identify records deleted from the source
    -- ============================================================
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Deleted AS
    SELECT *
    FROM tbl_DIM_MarketSegmentation AS Target
    WHERE Target.RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_MarketSegmentation_incoming AS Source
            WHERE Source.ProductID  = Target.ProductID
              AND Source.CustomerID = Target.CustomerID
              AND Source.CMPNY      = Target.CMPNY
            );

    -- ============================================================
    -- Step 5: Build the final dimension state
    -- ISNULL wraps each key column to prevent NULL propagation
    -- silently dropping records from the unchanged set.
    -- ============================================================
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Final AS

    -- Records with no changes (not expired, not deleted, not Type 1 updated)
    SELECT *
    FROM tbl_DIM_MarketSegmentation
    WHERE RecordStatus = 1
        AND (ISNULL(ProductID,'') + '~=~' + ISNULL(CustomerID,'') + '~=~' + ISNULL(CMPNY,'')) NOT IN
            (
            SELECT ISNULL(ProductID,'') + '~=~' + ISNULL(CustomerID,'') + '~=~' + ISNULL(CMPNY,'')
            FROM stage_tbl_DIM_MarketSegmentation_Expired
            UNION
            SELECT ISNULL(ProductID,'') + '~=~' + ISNULL(CustomerID,'') + '~=~' + ISNULL(CMPNY,'')
            FROM stage_tbl_DIM_MarketSegmentation_Deleted
            UNION
            SELECT ISNULL(ProductID,'') + '~=~' + ISNULL(CustomerID,'') + '~=~' + ISNULL(CMPNY,'')
            FROM stage_tbl_DIM_MarketSegmentation_Type1_UpdatesNeeded
            )

    UNION ALL

    -- Expire old versions of changed records (SCD2)
    SELECT
         [MarketSegmentationKey]
        ,[CMPNY]
        ,[CustomerID]
        ,[ProductID]
        ,[CPCID]
        ,[LegacyCPCID]
        ,[Industry]
        ,[SubIndustry]
        ,[AccountTranslatedToD365]
        ,[ProductTranslatedToD365]
        ,[RecordEffectiveStartDate]
        ,CAST(GETDATE() AS DATETIME2(3))  AS RecordEffectiveEndDate
        ,0                                AS RecordStatus
        ,[Source]
    FROM stage_tbl_DIM_MarketSegmentation_Expired

    UNION ALL

    -- Insert new active versions of changed records
    SELECT
         s.[MarketSegmentationKey]
        ,s.[CMPNY]
        ,s.[CustomerID]
        ,s.[ProductID]
        ,s.[CPCID]
        ,s.[LegacyCPCID]
        ,s.[Industry]
        ,s.[SubIndustry]
        ,s.[AccountTranslatedToD365]
        ,s.[ProductTranslatedToD365]
        ,CAST(GETDATE() AS DATETIME2(3))                 AS RecordEffectiveStartDate
        ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
        ,1                                               AS RecordStatus
        ,s.[Source]
    FROM vw_stage_DIM_MarketSegmentation_incoming s
    JOIN stage_tbl_DIM_MarketSegmentation_Expired e
        ON  s.ProductID  = e.ProductID
        AND s.CustomerID = e.CustomerID
        AND s.CMPNY      = e.CMPNY

    UNION ALL

    -- Insert new records
    SELECT *
    FROM stage_tbl_DIM_MarketSegmentation_New

    UNION ALL

    -- Apply Type 1 in-place updates
    SELECT *
    FROM stage_tbl_DIM_MarketSegmentation_Type1_OnlyUpdatedRecords

    UNION ALL

    -- Expire deleted records
    SELECT
         [MarketSegmentationKey]
        ,[CMPNY]
        ,[CustomerID]
        ,[ProductID]
        ,[CPCID]
        ,[LegacyCPCID]
        ,[Industry]
        ,[SubIndustry]
        ,[AccountTranslatedToD365]
        ,[ProductTranslatedToD365]
        ,[RecordEffectiveStartDate]
        ,CAST(GETDATE() AS DATETIME2(3))  AS RecordEffectiveEndDate
        ,0                                AS RecordStatus
        ,[Source]
    FROM stage_tbl_DIM_MarketSegmentation_Deleted;

    -- ============================================================
    -- Step 6: Merge with existing historical records to build Append table
    -- ============================================================
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Append;

    CREATE TABLE stage_tbl_DIM_MarketSegmentation_Append AS
    SELECT *
    FROM tbl_DIM_MarketSegmentation f
    WHERE NOT EXISTS (
            SELECT 1
            FROM stage_tbl_DIM_MarketSegmentation_Final AS d
            WHERE d.ProductID               = f.ProductID
              AND d.CustomerID              = f.CustomerID
              AND d.CMPNY                   = f.CMPNY
              AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
            )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_MarketSegmentation_Final AS f
    ORDER BY ProductID, CustomerID, CMPNY, RecordEffectiveStartDate;

    -- ============================================================
    -- Step 7: Replace DIM table with updated records
    -- ============================================================
    DROP TABLE IF EXISTS tbl_DIM_MarketSegmentation;

    CREATE TABLE tbl_DIM_MarketSegmentation AS
    SELECT *
    FROM stage_tbl_DIM_MarketSegmentation_Append;

    -- ============================================================
    -- Step 7b: Rebuild ForUpdates table (flag-controlled override pattern)
    --
    -- Three goals:
    --   1. All active records are present so the Logic App sees full data.
    --   2. Industry/SubIndustry reflect current effective values from the DIM
    --      (Logic App always shows real values, not NULLs).
    --   3. IsOverride flags track which values were set by a user vs. derived
    --      from marketsegmentation. The incoming view (v5) only uses u.Industry
    --      when IsOverride = 1 — so marketsegmentation remains the live source
    --      for all records with IsOverride = 0, even though ForUpdates has a
    --      populated value for display purposes.
    --
    -- Override flag lifecycle:
    --   Logic App sets IsOverride = 1 when user saves a value.
    --   Logic App sets IsOverride = 0 when user clears an override.
    --   SP preserves IsOverride = 1 across runs via the prior snapshot.
    --   SP never sets IsOverride = 1 — only reads and preserves it.
    --
    -- Limitation: a user cannot override a value TO NULL (NULL Industry in
    -- ForUpdates is indistinguishable from "no value set"). Add a separate
    -- IndustryOverrideValue column if that ever becomes a requirement.
    -- ============================================================

    -- Snapshot current user override flags before ForUpdates is replaced.
    -- Only rows with at least one active override are captured.
    CREATE TABLE stage_tbl_DIM_MarketSegmentation_ForUpdates_Prior AS
    SELECT [CMPNY], [CustomerID], [ProductID], [IndustryIsOverride], [SubIndustryIsOverride]
    FROM tbl_APP_MarketSegmentationDataForUpdates
    WHERE IndustryIsOverride    = 1
       OR SubIndustryIsOverride = 1;

    DROP TABLE IF EXISTS tbl_APP_MarketSegmentationDataForUpdates;

    CREATE TABLE tbl_APP_MarketSegmentationDataForUpdates AS
    SELECT
         f.[MarketSegmentationKey]
        ,f.[CMPNY]
        ,f.[CustomerID]
        ,f.[ProductID]
        ,f.[CPCID]
        ,f.[LegacyCPCID]
        ,f.[Industry]                                           -- current effective value for display
        ,ISNULL(p.[IndustryIsOverride],    0) IndustryIsOverride     -- restored from snapshot; 0 if no prior override
        ,f.[SubIndustry]                                        -- current effective value for display
        ,ISNULL(p.[SubIndustryIsOverride], 0) SubIndustryIsOverride  -- restored from snapshot; 0 if no prior override
    FROM stage_tbl_DIM_MarketSegmentation_Append f
    LEFT JOIN stage_tbl_DIM_MarketSegmentation_ForUpdates_Prior p
        ON  f.CMPNY       = p.CMPNY
        AND f.CustomerID  = p.CustomerID
        AND f.ProductID   = p.ProductID
    WHERE f.RecordStatus      = 1
      AND f.MarketSegmentationKey <> -1;

    -- ============================================================
    -- Step 8: Clean up all intermediate staging tables
    -- ============================================================
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_MarketSegmentation_ForUpdates_Prior;

END;