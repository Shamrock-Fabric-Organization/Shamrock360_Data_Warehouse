-- Auto Generated (Do not modify) E87B9EA825290B453A00A989583ED2878EDB842619AA6FDDAB17AC1A2D56F420

--use WH_Transform




CREATE   VIEW [dbo].[vw_stage_NewBudgetModel] AS

SELECT
     Source.[BudgetModelKey]
    ,Source.[CMPNY]
    ,Source.[BudgetModel]
    ,Source.[BudgetSubmodel]
    ,Source.[BudgetModelDescription]
    ,Source.[Source]
    ,CAST('1900-01-01'              AS DATETIME2(3)) AS RecordEffectiveStartDate
    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    ,CAST(1 AS INT)                                  AS RecordStatus
FROM [dbo].[vw_stage_DIM_BudgetModel_incoming] AS Source
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[tbl_DIM_BudgetModel] AS Target
    WHERE Target.[CMPNY]        = Source.[CMPNY]
      AND Target.[BudgetModel]  = Source.[BudgetModel]
)
;