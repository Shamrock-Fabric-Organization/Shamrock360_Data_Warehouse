-- Auto Generated (Do not modify) 9375EC3291DD5203FC61FBB6C54384FAF6DAD65F501C66EAFA33C726C9C9F536

/****** Object:  View [dbo].[vw_stage_DIM_WorkOrder_incoming]    Script Date: 6/12/2026 10:04:05 AM ******/
--use WH_Transform

/****** Object:  View [dbo].[vw_stage_DIM_WorkOrder_incoming]    Script Date: 2026-06-11 ******/
--drop VIEW dbo.[vw_stage_DIM_WorkOrder_incoming]

CREATE   VIEW [dbo].[vw_stage_DIM_WorkOrder_incoming]
AS
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
             CAST(NEWID()       AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID()       AS VARCHAR(36)), '|'
            ,CAST(wt.[WORKID]   AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT))              AS WorkOrderKey

    ,wt.[DATAAREAID]                         AS CMPNY
    ,wt.[WORKID]                             AS WorkId
    ,wt.[WORKCANCELLEDUTCDATETIME]           AS WorkCancelledUTC
    ,wt.[WORKINPROCESSUTCDATETIME]           AS WorkStartedUTC
    ,wt.[WORKCLOSEDUTCDATETIME]              AS WorkClosedUTC
    ,wt.[CREATEDDATETIME]                    AS CreatedDateTime
    ,wt.[MODIFIEDDATETIME]                   AS ModifiedDateTime
    ,wt.[WORKSTATUS_$label]                  AS CountWorkStatus
    ,wt.[WORKCREATEDBY]                      AS WorkCreatedBy
    ,wt.[ISPARTIALCYCLECOUNTWORK_$label]     AS IsPartialCount
    ,wt.[worktranstype_$label]               AS WorkTransType
    ,wt.[WORKPRIORITY]                       AS WorkPriority

    ,'D365FO'                                AS Source
    ,CONVERT(datetime2(3), NULL)             AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)             AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)                      AS RecordStatus

FROM [WH_Raw].[dbo].[WHSWORKTABLE] wt

WHERE wt.[WORKTRANSTYPE] in (10,15)   -- CycleCount work orders and Adjustments only

UNION ALL

SELECT
     -1                                      AS WorkOrderKey
    ,'Unknown'                               AS CMPNY
    ,'Unknown'                               AS WorkId
    ,NULL                                    AS WorkCancelledUTC
    ,NULL                                    AS WorkStartedUTC
    ,NULL                                    AS WorkClosedUTC
    ,NULL                                    AS CreatedDateTime
    ,NULL                                    AS ModifiedDateTime
    ,NULL                                    AS CountWorkStatus
    ,NULL                                    AS WorkCreatedBy
    ,NULL                                    AS IsPartialCount
    ,NULL                                    AS WorkTransType
    ,NULL                                    AS WorkPriority
    ,'D365FO'                                AS Source
    ,NULL                                    AS RecordEffectiveStartDate
    ,NULL                                    AS RecordEffectiveEndDate
    ,NULL                                    AS RecordStatus