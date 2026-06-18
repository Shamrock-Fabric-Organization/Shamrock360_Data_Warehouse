-- Auto Generated (Do not modify) 9375EC3291DD5203FC61FBB6C54384FAF6DAD65F501C66EAFA33C726C9C9F536
--use WH_Transform

/****** Object:  View [dbo].[vw_stage_NewWorkOrder]    Script Date: 2026-06-11 ******/
--drop VIEW dbo.[vw_stage_NewWorkOrder]

CREATE   VIEW [dbo].[vw_stage_NewWorkOrder]
AS
SELECT
     Source.[WorkOrderKey]
    ,Source.[CMPNY]
    ,Source.[WorkId]
    ,Source.[WorkCancelledUTC]
    ,Source.[WorkStartedUTC]
    ,Source.[WorkClosedUTC]
    ,Source.[CreatedDateTime]
    ,Source.[ModifiedDateTime]
    ,Source.[CountWorkStatus]
    ,Source.[WorkCreatedBy]
    ,Source.[IsPartialCount]
    ,Source.[WorkTransType]
    ,Source.[WorkPriority]
    ,Source.[Source]
    ,CAST('1900-01-01' AS DATETIME2(3))              AS RecordEffectiveStartDate
    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    ,1                                               AS RecordStatus

FROM [dbo].[vw_stage_DIM_WorkOrder_incoming] AS Source

WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[tbl_DIM_WorkOrder] AS Target
    WHERE Target.[WorkId] = Source.[WorkId]
      AND Target.[CMPNY]  = Source.[CMPNY]
      AND Target.[RecordStatus] = 1
)