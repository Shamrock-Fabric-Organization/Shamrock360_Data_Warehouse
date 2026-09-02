

CREATE OR ALTER VIEW [dbo].[vw_stage_DIM_ForecastModel_incoming]
AS
WITH src AS (
    SELECT
          fm.[dataareaid]         AS CMPNY
        , fm.[ModelId]            AS ModelId
        , fm.[Txt]                AS Model_Description
        , fm.[Blocked_$label]     AS Blocked
        , fm.[Type_$label]        AS ModelType
        , ROW_NUMBER() OVER (
              PARTITION BY fm.[dataareaid], fm.[ModelId]
              ORDER BY fm.[SubModelId] ASC          -- blank SubModelId (model header) first
          ) AS _rn
    FROM WH_Raw.dbo.forecastmodel AS fm
)
SELECT
      ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(CAST(s.CMPNY AS VARCHAR(20)), '|', CAST(s.ModelId AS VARCHAR(50)))
        ) AS BINARY(8)) AS BIGINT))                              AS ForecastModelKey   -- deterministic surrogate
    , s.CMPNY
    , s.ModelId
    , s.Model_Description
    , s.Blocked
    , s.ModelType
    , 'D365FO'                                                   AS [Source]
    , NULL                                                      AS RecordEffectiveStartDate
    , NULL                                                      AS RecordEffectiveEndDate
    , 1                                                          AS RecordStatus
FROM src AS s
WHERE s._rn = 1                                                  -- one row per CMPNY + ModelId (model-id level)

UNION ALL

-- Unknown / default member (for star-schema fact joins)
SELECT
      CAST(-1 AS BIGINT)                 AS ForecastModelKey
    , 'Unknown'                          AS CMPNY
    , 'Unknown'                          AS ModelId
    , 'Unknown'                          AS Model_Description
    , CAST(NULL AS VARCHAR(10))          AS Blocked
    , CAST(NULL AS VARCHAR(10))          AS ModelType
    , 'D365FO'                           AS [Source]
    , CAST(NULL AS DATETIME2(3))         AS RecordEffectiveStartDate
    , CAST(NULL AS DATETIME2(3))         AS RecordEffectiveEndDate
    , 1                                  AS RecordStatus
;

