--use WH_Transform

/****** Object:  StoredProcedure [dbo].[sp_Execute_Type1_Logic_dimWorkOrder]    Script Date: 2026-06-11 ******/

CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimWorkOrder]
AS
BEGIN
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Append;

    -- Step 1: Identify new records not in the current dimension table
    CREATE TABLE stage_tbl_DIM_WorkOrder_New AS
    SELECT *
    FROM vw_stage_NewWorkOrder;

    ---- Step 2: Expired records (Type 2 — commented out, Type 1 only)
    --CREATE TABLE stage_tbl_DIM_WorkOrder_Expired AS
    --SELECT Target.*
    --FROM tbl_DIM_WorkOrder AS Target
    --JOIN vw_stage_DIM_WorkOrder_incoming AS Source
    --    ON  Target.WorkId = Source.WorkId
    --    AND Target.CMPNY  = Source.CMPNY
    --WHERE Target.RecordStatus = 1
    --    AND (
    --        ISNULL(Target.WorkCancelledUTC,  '1900-01-01') <> ISNULL(Source.WorkCancelledUTC,  '1900-01-01')
    --        OR ISNULL(Target.WorkStartedUTC, '1900-01-01') <> ISNULL(Source.WorkStartedUTC, '1900-01-01')
    --        OR ISNULL(Target.WorkClosedUTC,  '1900-01-01') <> ISNULL(Source.WorkClosedUTC,  '1900-01-01')
    --        OR ISNULL(Target.CreatedDateTime,'1900-01-01') <> ISNULL(Source.CreatedDateTime,'1900-01-01')
    --        OR ISNULL(Target.ModifiedDateTime,'1900-01-01') <> ISNULL(Source.ModifiedDateTime,'1900-01-01')
    --        OR ISNULL(Target.CountWorkStatus,'')  <> ISNULL(Source.CountWorkStatus,'')
    --        OR ISNULL(Target.WorkCreatedBy,  '')  <> ISNULL(Source.WorkCreatedBy,  '')
    --        OR ISNULL(Target.IsPartialCount, '')  <> ISNULL(Source.IsPartialCount, '')
    --        OR ISNULL(Target.WorkTransType,  '')  <> ISNULL(Source.WorkTransType,  '')
    --        OR ISNULL(Target.WorkPriority,   0)   <> ISNULL(Source.WorkPriority,   0)
    --        );

    -- Step 3: Identify records with Type 1-only changes
    CREATE TABLE stage_tbl_DIM_WorkOrder_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_WorkOrder AS Target
    JOIN vw_stage_DIM_WorkOrder_incoming AS Source
        ON  Target.WorkId = Source.WorkId
        AND Target.CMPNY  = Source.CMPNY
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.WorkCancelledUTC,  '1900-01-01') <> ISNULL(Source.WorkCancelledUTC,  '1900-01-01')
            OR ISNULL(Target.WorkStartedUTC, '1900-01-01') <> ISNULL(Source.WorkStartedUTC, '1900-01-01')
            OR ISNULL(Target.WorkClosedUTC,  '1900-01-01') <> ISNULL(Source.WorkClosedUTC,  '1900-01-01')
            OR ISNULL(Target.CreatedDateTime,'1900-01-01') <> ISNULL(Source.CreatedDateTime,'1900-01-01')
            OR ISNULL(Target.ModifiedDateTime,'1900-01-01') <> ISNULL(Source.ModifiedDateTime,'1900-01-01')
            OR ISNULL(Target.CountWorkStatus,'')  <> ISNULL(Source.CountWorkStatus,'')
            OR ISNULL(Target.WorkCreatedBy,  '')  <> ISNULL(Source.WorkCreatedBy,  '')
            OR ISNULL(Target.IsPartialCount, '')  <> ISNULL(Source.IsPartialCount, '')
            OR ISNULL(Target.WorkTransType,  '')  <> ISNULL(Source.WorkTransType,  '')
            OR ISNULL(Target.WorkPriority,   0)   <> ISNULL(Source.WorkPriority,   0)
            );

    -- Create table with Type 1 changes for insert into final table
    CREATE TABLE stage_tbl_DIM_WorkOrder_Type1_OnlyUpdatedRecords AS
    SELECT
         Target.WorkOrderKey
        ,Target.CMPNY
        ,Target.WorkId
        ,Source.WorkCancelledUTC
        ,Source.WorkStartedUTC
        ,Source.WorkClosedUTC
        ,Source.CreatedDateTime
        ,Source.ModifiedDateTime
        ,Source.CountWorkStatus
        ,Source.WorkCreatedBy
        ,Source.IsPartialCount
        ,Source.WorkTransType
        ,Source.WorkPriority
        ,Target.Source
        ,Target.RecordEffectiveStartDate
        ,Target.RecordEffectiveEndDate
        ,Target.RecordStatus
    FROM stage_tbl_DIM_WorkOrder_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_WorkOrder_incoming AS Source
        ON  Target.WorkId = Source.WorkId
        AND Target.CMPNY  = Source.CMPNY;

    -- Step 4: Identify records deleted from source
    CREATE TABLE stage_tbl_DIM_WorkOrder_Deleted AS
    SELECT *
    FROM tbl_DIM_WorkOrder AS Target
    WHERE Target.RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_WorkOrder_incoming AS Source
            WHERE Target.WorkId = Source.WorkId
              AND Target.CMPNY  = Source.CMPNY
            );

    -- Step 5: Build the final dimension combining all change types
    CREATE TABLE stage_tbl_DIM_WorkOrder_Final AS

    -- Unchanged active records
    SELECT *
    FROM tbl_DIM_WorkOrder
    WHERE RecordStatus = 1
        AND (CMPNY + '~=~' + WorkId) NOT IN (
            SELECT CMPNY + '~=~' + WorkId FROM stage_tbl_DIM_WorkOrder_Deleted
            UNION
            SELECT CMPNY + '~=~' + WorkId FROM stage_tbl_DIM_WorkOrder_Type1_UpdatesNeeded
            )

    --UNION ALL
    ---- Expire old records (Type 2 — commented out)
    --SELECT [WorkOrderKey],[CMPNY],[WorkId],[WorkCancelledUTC],[WorkStartedUTC]
    --    ,[WorkClosedUTC],[CreatedDateTime],[ModifiedDateTime],[CountWorkStatus]
    --    ,[WorkCreatedBy],[IsPartialCount],[WorkTransType],[WorkPriority],[Source]
    --    ,[RecordEffectiveStartDate]
    --    ,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
    --    ,0 AS RecordStatus
    --FROM stage_tbl_DIM_WorkOrder_Expired

    --UNION ALL
    ---- New versions of expired records (Type 2 — commented out)
    --SELECT s.[WorkOrderKey],s.[CMPNY],s.[WorkId],s.[WorkCancelledUTC],s.[WorkStartedUTC]
    --    ,s.[WorkClosedUTC],s.[CreatedDateTime],s.[ModifiedDateTime],s.[CountWorkStatus]
    --    ,s.[WorkCreatedBy],s.[IsPartialCount],s.[WorkTransType],s.[WorkPriority],s.[Source]
    --    ,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
    --    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    --    ,1 AS RecordStatus
    --FROM vw_stage_DIM_WorkOrder_incoming s
    --JOIN stage_tbl_DIM_WorkOrder_Expired e
    --    ON s.WorkId = e.WorkId AND s.CMPNY = e.CMPNY

    UNION ALL

    -- New records
    SELECT *
    FROM stage_tbl_DIM_WorkOrder_New

    UNION ALL

    -- Type 1 updated records
    SELECT *
    FROM stage_tbl_DIM_WorkOrder_Type1_OnlyUpdatedRecords

    UNION ALL

    -- Deleted records (set RecordStatus = 0)
    SELECT
         WorkOrderKey
        ,CMPNY
        ,WorkId
        ,WorkCancelledUTC
        ,WorkStartedUTC
        ,WorkClosedUTC
        ,CreatedDateTime
        ,ModifiedDateTime
        ,CountWorkStatus
        ,WorkCreatedBy
        ,IsPartialCount
        ,WorkTransType
        ,WorkPriority
        ,Source
        ,RecordEffectiveStartDate
        ,GETDATE()  AS RecordEffectiveEndDate
        ,0          AS RecordStatus
    FROM stage_tbl_DIM_WorkOrder_Deleted;

    -- Step 6: Build deduplicated append table
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Append;

    CREATE TABLE stage_tbl_DIM_WorkOrder_Append AS
    SELECT *
    FROM tbl_DIM_WorkOrder f
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_WorkOrder_Final d
        WHERE d.WorkId                   = f.WorkId
          AND d.CMPNY                    = f.CMPNY
          AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
        )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_WorkOrder_Final
    ORDER BY CMPNY
            ,WorkId
            ,RecordEffectiveStartDate;

    -- Step 7: Replace dimension table
    DROP TABLE IF EXISTS tbl_DIM_WorkOrder;

    CREATE TABLE tbl_DIM_WorkOrder AS
    SELECT *
    FROM stage_tbl_DIM_WorkOrder_Append;

    -- Step 8: Clean up staging tables
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_WorkOrder_Type1_OnlyUpdatedRecords;

    ---- Step 9: Drop incoming view (commented out — using view, not table)
    --DROP TABLE IF EXISTS vw_stage_DIM_WorkOrder_incoming;

END;