-- Auto Generated (Do not modify) 01B7CB55691D55E4DCC17C7A10A13BFB717FFDD51F253F675EF9A87A4B54BADE

-- USE WH_Transform

-- Create a view to identify new records not present in the current dimension
-- Needed because CTAS does not allow the surrogate key logic used in the incoming view

CREATE   VIEW [dbo].[vw_stage_NewTradeAgreement]
AS
SELECT
      [TradeAgreementKey]
    , [CMPNY]
    , [AgreementID]
    , [JournalName]
    , [AgreementName]
    , [PostedDate]
    , [Posted]
    , [DefaultRelation]
    , [Source]
    , CAST('1900-01-01' AS DATETIME2(3))              AS RecordEffectiveStartDate
    , CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    , 1                                               AS RecordStatus

FROM [dbo].[vw_stage_DIM_TradeAgreement_incoming] AS Source
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[tbl_DIM_TradeAgreement] AS Target
    WHERE Target.AgreementID  = Source.AgreementID
      AND Target.CMPNY        = Source.CMPNY
      AND Target.RecordStatus = 1
    )