-- Auto Generated (Do not modify) E87B9EA825290B453A00A989583ED2878EDB842619AA6FDDAB17AC1A2D56F420

--use WH_Transform


CREATE   VIEW [dbo].[vw_stage_DIM_BudgetModel_incoming] AS

SELECT
     ABS(CAST(CAST(HASHBYTES('SHA2_256'
        , CONCAT(bm.[dataareaid], '|', bm.[modelid])
     ) AS BINARY(8)) AS BIGINT))     AS BudgetModelKey
    ,CAST(bm.[dataareaid]  AS VARCHAR(8000)) AS CMPNY
    ,CAST(bm.[modelid]     AS VARCHAR(8000)) AS BudgetModel
    ,CAST(bm.[submodelid]  AS VARCHAR(8000)) AS BudgetSubmodel
    ,CAST(bm.[txt]         AS VARCHAR(8000)) AS BudgetModelDescription
    ,'D365FO'                                AS Source
    ,CONVERT(datetime2(3), NULL)             AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)             AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)                      AS RecordStatus
FROM WH_Raw.dbo.[budgetmodel] bm

UNION ALL

SELECT
     CAST(-1 AS BIGINT)              AS BudgetModelKey
    ,CAST('UNKNOWN' AS VARCHAR(8000)) AS CMPNY
    ,CAST('UNKNOWN' AS VARCHAR(8000)) AS BudgetModel
    ,null AS BudgetSubmodel
    ,null AS BudgetModelDescription
    ,'D365FO'                         AS Source
    ,CONVERT(datetime2(3), NULL)      AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)      AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)               AS RecordStatus

;