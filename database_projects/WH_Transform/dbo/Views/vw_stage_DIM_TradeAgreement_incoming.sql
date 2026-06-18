-- Auto Generated (Do not modify) 01B7CB55691D55E4DCC17C7A10A13BFB717FFDD51F253F675EF9A87A4B54BADE
-- USE WH_Transform

/****** Object:  View [dbo].[vw_stage_DIM_TradeAgreement_incoming] ******/
-- DROP VIEW dbo.[vw_stage_DIM_TradeAgreement_incoming]

CREATE   VIEW [dbo].[vw_stage_DIM_TradeAgreement_incoming]
AS
SELECT
    ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Row-specific data for uniqueness
                ,CAST(src.journalnum AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))      AS TradeAgreementKey
    , src.dataareaid                     AS CMPNY
    , src.journalnum                     AS AgreementID
    , src.journalname                    AS JournalName
    , src.name                           AS AgreementName
    , src.posteddate                     AS PostedDate
    , src.posted_$label                  AS Posted
    , src.defaultrelation_$label         AS DefaultRelation

    , 'D365FO'                           AS Source
    , CONVERT(datetime2(3), NULL)        AS RecordEffectiveStartDate
    , CONVERT(datetime2(3), NULL)        AS RecordEffectiveEndDate
    , CONVERT(int, NULL)                 AS RecordStatus

FROM WH_Raw.dbo.[PRICEDISCADMTABLE] src

UNION ALL

SELECT
      -1                                 AS TradeAgreementKey
    , 'Unknown'                          AS CMPNY
    , 'Unknown'                          AS AgreementID
    , NULL                               AS JournalName
    , NULL                               AS AgreementName
    , NULL                               AS PostedDate
    , NULL                               AS Posted
    , NULL                               AS DefaultRelation
    , 'D365FO'                           AS Source
    , NULL                               AS RecordEffectiveStartDate
    , NULL                               AS RecordEffectiveEndDate
    , NULL                               AS RecordStatus