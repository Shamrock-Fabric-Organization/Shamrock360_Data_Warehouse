-- Auto Generated (Do not modify) 72ACDEAF9B180D17505C9FD28A75141743494A1101434EBFBFC5802574A75E3A

--use WH_Transform

    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE   VIEW [dbo].[vw_stage_NewProject]
AS
SELECT
      [ProjectKey]
    , [CMPNY]
    , [ProjId]
    , [ProjectName]
    , [ProjectContractID]
    , [ProjectType]
    , [ProjectStage]
    , [BudgetControlInterval]
    , [ProjectedStartDate]
    , [ProjectedEndDate]
    , [StartDate]
    , [EndDate]
    , [Status]
    , [Source]

    ,CAST('1900-01-01' AS DATETIME2(3))             AS RecordEffectiveStartDate
    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    ,1                                              AS RecordStatus

FROM vw_stage_DIM_Project_incoming AS Source
WHERE NOT EXISTS (
        SELECT 1
        FROM tbl_DIM_Project AS Target
        WHERE Target.ProjId  = Source.ProjId
          AND Target.CMPNY   = Source.CMPNY
          AND Target.RecordStatus = 1
        );