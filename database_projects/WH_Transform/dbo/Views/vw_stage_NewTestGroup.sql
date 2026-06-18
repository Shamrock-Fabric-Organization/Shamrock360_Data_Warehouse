--use WH_Transform

/****** Object:  View [dbo].[vw_stage_NewTestGroup]    Script Date: 2026-06-10 ******/
--drop VIEW dbo.[vw_stage_NewTestGroup]

CREATE   VIEW [dbo].[vw_stage_NewTestGroup]
AS
SELECT
     Source.[TestGroupKey]
    ,Source.[CMPNY]
    ,Source.[TestGroupId]
    ,Source.[TestGroupDescription]
    ,Source.[AcceptableQualityLevel]
    ,Source.[IsDestructive]
    ,Source.[Source]
    ,CAST('1900-01-01' AS DATETIME2(3))              AS RecordEffectiveStartDate
    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    ,1                                               AS RecordStatus

FROM [dbo].[vw_stage_DIM_TestGroup_incoming] AS Source

WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[tbl_DIM_TestGroup] AS Target
    WHERE Target.[TestGroupId] = Source.[TestGroupId]
      AND Target.[CMPNY]       = Source.[CMPNY]
      AND Target.[RecordStatus] = 1
)
GO

