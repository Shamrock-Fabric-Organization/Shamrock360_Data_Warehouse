

CREATE OR ALTER VIEW [dbo].[vw_stage_NewForecastModel]
AS
SELECT
      Source.[ForecastModelKey]
    , Source.[CMPNY]
    , Source.[ModelId]
    , Source.[Model_Description]
    , Source.[Blocked]
    , Source.[ModelType]
    , Source.[Source]
	  , CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	  , CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate

    , Source.[RecordStatus]
FROM vw_stage_DIM_ForecastModel_incoming AS Source
WHERE NOT EXISTS (
    SELECT 1
    FROM tbl_DIM_ForecastModel AS Target
    WHERE Target.CMPNY   = Source.CMPNY
      AND Target.ModelId = Source.ModelId
);

