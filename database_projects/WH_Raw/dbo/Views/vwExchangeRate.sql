-- Auto Generated (Do not modify) 8EF74670B29E9571A8CEC39922198C0FF52CDC136B7820F03C39F9908631CB4B

create or alter  view vwExchangeRate
as
WITH rate AS (
    SELECT
          ert.description                              AS exchangeratetype
        , ercp.fromcurrencycode                        AS fromcurrencycode
        , ercp.tocurrencycode                          AS tocurrencycode
        , er.validfrom
        , er.validto
        , er.exchangerate                              AS OrigExchangeRate
        , ercp.ExchangeRateDisplayFactor               AS DisplayFactorEnum
        , ercp.ExchangeRateDisplayFactor_$label               AS DisplayFactorEnumLabel
        , CASE ercp.ExchangeRateDisplayFactor
              WHEN 1 THEN 1.0      -- One
              WHEN 2 THEN 10.0     -- Ten
              WHEN 3 THEN 100.0    -- Hundred
              WHEN 4 THEN 1000.0   -- Thousand
              WHEN 5 THEN 10000.0  -- TenThousand
              ELSE 1.0
          END                                          AS DisplayFactorUnits
        , er.exchangeratecurrencypair
    FROM exchangerate er
    JOIN exchangeratecurrencypair ercp
      ON ercp.recid = er.exchangeratecurrencypair
    JOIN exchangeratetype ert
      ON ert.recid = ercp.exchangeratetype
)
SELECT
      exchangeratetype
    , fromcurrencycode
    , tocurrencycode
    , validfrom
    , validto
    , OrigExchangeRate
    , DisplayFactorEnum
    , DisplayFactorUnits
    , (OrigExchangeRate / 100.0) / DisplayFactorUnits                    AS ExchangeRate
    , exchangeratecurrencypair
FROM rate

UNION

SELECT
      exchangeratetype
    , tocurrencycode      AS fromcurrencycode
    , fromcurrencycode    AS tocurrencycode
    , validfrom
    , validto
    , OrigExchangeRate
    , DisplayFactorEnum
    , DisplayFactorUnits
    , 1.0 / NULLIF( (OrigExchangeRate / 100.0) / DisplayFactorUnits , 0) AS ExchangeRate
    , exchangeratecurrencypair
FROM rate