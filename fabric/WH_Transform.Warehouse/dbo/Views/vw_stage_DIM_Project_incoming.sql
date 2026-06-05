-- Auto Generated (Do not modify) 72ACDEAF9B180D17505C9FD28A75141743494A1101434EBFBFC5802574A75E3A
--use WH_Transform

/****** Object:  View [dbo].[vw_stage_DIM_Project_incoming]    Script Date: 3/30/2026 ******/
--drop  VIEW dbo.[vw_stage_DIM_Project_incoming]

CREATE     VIEW [dbo].[vw_stage_DIM_Project_incoming]
AS
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(pt.projid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS ProjectKey
    , pt.dataareaid                     CMPNY
    , pt.projid                         ProjId
    , pt.name                           ProjectName
    , pt.projinvoiceprojid              ProjectContractID
    , pt.type_$label                    ProjectType
    , pst.stage                         ProjectStage
    , pt.projbudgetinterval_$label      BudgetControlInterval
    , pt.projectedstartdate             ProjectedStartDate
    , pt.projectedenddate               ProjectedEndDate
    , pt.psaschedstartdate              StartDate
    , pt.psaschedenddate                EndDate
    , pt.psaprojstatus_$label           Status

    ,'D365FO'                           Source
    ,CONVERT(datetime2(3), NULL)        RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)        RecordEffectiveEndDate
    ,CONVERT(int, NULL)                 RecordStatus

FROM WH_Raw.dbo.projtable pt
    JOIN WH_Raw.dbo.projstagetable pst
        ON  pt.status      = pst.status
        AND pt.dataareaid  = pst.dataareaid
        AND pst.language   = 'en-US'

UNION ALL

SELECT -1                               [ProjectKey]
, 'Unknown'                             CMPNY
, 'Unknown'                             ProjId
, NULL                                  ProjectName
, NULL                                  ProjectContractID
, NULL                                  ProjectType
, NULL                                  ProjectStage
, NULL                                  BudgetControlInterval
, NULL                                  ProjectedStartDate
, NULL                                  ProjectedEndDate
, NULL                                  StartDate
, NULL                                  EndDate
, NULL                                  Status

, 'D365FO'                              [Source]
, NULL                                  [RecordEffectiveStartDate]
, NULL                                  [RecordEffectiveEndDate]
, NULL                                  [RecordStatus]