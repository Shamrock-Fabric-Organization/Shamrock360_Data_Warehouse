--use WH_Transform

/****** Object:  StoredProcedure [dbo].[sp_Execute_Type1_Logic_dimTestGroup]    Script Date: 2026-06-10 ******/

CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimTestGroup]
AS
BEGIN
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Append;

    -- Step 1: Identify new records not in the current dimension table
    CREATE TABLE stage_tbl_DIM_TestGroup_New AS
    SELECT *
    FROM vw_stage_NewTestGroup;

    ---- Step 2: Identify records that need to be expired (Type 2 — commented out, Type 1 only)
    --CREATE TABLE stage_tbl_DIM_TestGroup_Expired AS
    --SELECT Target.*
    --FROM tbl_DIM_TestGroup AS Target
    --JOIN vw_stage_DIM_TestGroup_incoming AS Source
    --    ON  Target.TestGroupId = Source.TestGroupId
    --    AND Target.CMPNY       = Source.CMPNY
    --WHERE Target.RecordStatus = 1
    --    AND (
    --        ISNULL(Target.TestGroupDescription,   '') <> ISNULL(Source.TestGroupDescription,   '')
    --        OR ISNULL(Target.AcceptableQualityLevel, 0) <> ISNULL(Source.AcceptableQualityLevel, 0)
    --        OR ISNULL(Target.IsDestructive,         '') <> ISNULL(Source.IsDestructive,         '')
    --        );

    -- Step 3: Identify records with Type 1-only changes
    CREATE TABLE stage_tbl_DIM_TestGroup_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_TestGroup AS Target
    JOIN vw_stage_DIM_TestGroup_incoming AS Source
        ON  Target.TestGroupId = Source.TestGroupId
        AND Target.CMPNY       = Source.CMPNY
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.TestGroupDescription,   '') <> ISNULL(Source.TestGroupDescription,   '')
            OR ISNULL(Target.AcceptableQualityLevel, 0) <> ISNULL(Source.AcceptableQualityLevel, 0)
            OR ISNULL(Target.IsDestructive,         '') <> ISNULL(Source.IsDestructive,         '')
            );

    -- Create table with Type 1 changes for insert into final table
    CREATE TABLE stage_tbl_DIM_TestGroup_Type1_OnlyUpdatedRecords AS
    SELECT
         Target.TestGroupKey
        ,Target.CMPNY
        ,Target.TestGroupId
        ,Source.TestGroupDescription
        ,Source.AcceptableQualityLevel
        ,Source.IsDestructive
        ,Target.Source
        ,Target.RecordEffectiveStartDate
        ,Target.RecordEffectiveEndDate
        ,Target.RecordStatus
    FROM stage_tbl_DIM_TestGroup_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_TestGroup_incoming AS Source
        ON  Target.TestGroupId = Source.TestGroupId
        AND Target.CMPNY       = Source.CMPNY;

    -- Step 4: Identify records deleted from source
    CREATE TABLE stage_tbl_DIM_TestGroup_Deleted AS
    SELECT *
    FROM tbl_DIM_TestGroup AS Target
    WHERE Target.RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_TestGroup_incoming AS Source
            WHERE Target.TestGroupId = Source.TestGroupId
              AND Target.CMPNY       = Source.CMPNY
            );

    -- Step 5: Build the final dimension combining all change types
    CREATE TABLE stage_tbl_DIM_TestGroup_Final AS

    -- Unchanged active records
    SELECT *
    FROM tbl_DIM_TestGroup
    WHERE RecordStatus = 1
        AND (CMPNY + '~=~' + TestGroupId) NOT IN (
            SELECT CMPNY + '~=~' + TestGroupId FROM stage_tbl_DIM_TestGroup_Deleted
            UNION
            SELECT CMPNY + '~=~' + TestGroupId FROM stage_tbl_DIM_TestGroup_Type1_UpdatesNeeded
            )

    --UNION ALL
    ---- Expire old records (Type 2 — commented out)
    --SELECT [TestGroupKey],[CMPNY],[TestGroupId],[TestGroupDescription],[AcceptableQualityLevel]
    --    ,[IsDestructive],[Source],[RecordEffectiveStartDate]
    --    ,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
    --    ,0 AS RecordStatus
    --FROM stage_tbl_DIM_TestGroup_Expired

    --UNION ALL
    ---- New versions of expired records (Type 2 — commented out)
    --SELECT s.[TestGroupKey],[s.CMPNY],[s.TestGroupId],[s.TestGroupDescription],[s.AcceptableQualityLevel]
    --    ,[s.IsDestructive],[s.Source]
    --    ,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
    --    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    --    ,1 AS RecordStatus
    --FROM vw_stage_DIM_TestGroup_incoming s
    --JOIN stage_tbl_DIM_TestGroup_Expired e
    --    ON s.TestGroupId = e.TestGroupId AND s.CMPNY = e.CMPNY

    UNION ALL

    -- New records
    SELECT *
    FROM stage_tbl_DIM_TestGroup_New

    UNION ALL

    -- Type 1 updated records
    SELECT *
    FROM stage_tbl_DIM_TestGroup_Type1_OnlyUpdatedRecords

    UNION ALL

    -- Deleted records (set RecordStatus = 0)
    SELECT
         TestGroupKey
        ,CMPNY
        ,TestGroupId
        ,TestGroupDescription
        ,AcceptableQualityLevel
        ,IsDestructive
        ,Source
        ,RecordEffectiveStartDate
        ,GETDATE()  AS RecordEffectiveEndDate
        ,0          AS RecordStatus
    FROM stage_tbl_DIM_TestGroup_Deleted;

    -- Step 6: Build deduplicated append table
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Append;

    CREATE TABLE stage_tbl_DIM_TestGroup_Append AS
    SELECT *
    FROM tbl_DIM_TestGroup f
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_TestGroup_Final d
        WHERE d.TestGroupId              = f.TestGroupId
          AND d.CMPNY                    = f.CMPNY
          AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
        )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_TestGroup_Final
    ORDER BY CMPNY
            ,TestGroupId
            ,RecordEffectiveStartDate;

    -- Step 7: Replace dimension table
    DROP TABLE IF EXISTS tbl_DIM_TestGroup;

    CREATE TABLE tbl_DIM_TestGroup AS
    SELECT *
    FROM stage_tbl_DIM_TestGroup_Append;

    -- Step 8: Clean up staging tables
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_TestGroup_Type1_OnlyUpdatedRecords;

    ---- Step 9: Drop incoming view (commented out — using view, not table)
    --DROP TABLE IF EXISTS vw_stage_DIM_TestGroup_incoming;

END;