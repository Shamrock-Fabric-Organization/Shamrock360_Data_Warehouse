-- Auto Generated (Do not modify) 4E930AEAA148E5DB585C15D475916C8A8C3B58726A7ABC2BC07FABCBE346334F


CREATE   VIEW [dbo].[vw_EDW_BRILJANT_Forecast] AS
WITH BaseData AS (
    SELECT
        'A101' + TRIM(KLANTEN.NUMMER) + '000000' + '---' + ARTIKEL.ARTNR AS CPCID,
        KLANTEN.NUMMER                                                      AS CustomerNo,
        ARTIKEL.ARTNR                                                       AS ProductCode,
        FORMAT(tbl_OFFD.DATUM, 'yyyy-MM')                                  AS ForecastMonth,
        SUM(tbl_OFFD.AANTAL * ARTIKEL.NETTO)                               AS Qty_KG,
        SUM(tbl_OFFD.TOTAAL)                                               AS Rev_EUR
    FROM tbl_OFFERTE
    LEFT JOIN tbl_OFFD  ON tbl_OFFERTE.OFFERTENR = tbl_OFFD.OFFERTENR
    LEFT JOIN ARTIKEL   ON tbl_OFFD.ARTIKEL       = ARTIKEL.ARTNR
    LEFT JOIN KLANTEN   ON tbl_OFFERTE.KLANT       = KLANTEN.NUMMER
    WHERE tbl_OFFD.OFFERTEBK = 'FO'
    GROUP BY
        'A101' + TRIM(KLANTEN.NUMMER) + '000000' + '---' + ARTIKEL.ARTNR,
        KLANTEN.NUMMER,
        ARTIKEL.ARTNR,
        FORMAT(tbl_OFFD.DATUM, 'yyyy-MM')
),

-- Generate all 12 months so missing months get 0
AllMonths AS (
    SELECT '2026-01' AS M UNION ALL SELECT '2026-02' UNION ALL SELECT '2026-03'
    UNION ALL SELECT '2026-04' UNION ALL SELECT '2026-05' UNION ALL SELECT '2026-06'
    UNION ALL SELECT '2026-07' UNION ALL SELECT '2026-08' UNION ALL SELECT '2026-09'
    UNION ALL SELECT '2026-10' UNION ALL SELECT '2026-11' UNION ALL SELECT '2026-12'
),

-- Cross join CPCIDs with all months to ensure every combination exists
AllCombos AS (
    SELECT DISTINCT b.CPCID, b.CustomerNo, b.ProductCode, m.M AS ForecastMonth
    FROM BaseData b
    CROSS JOIN AllMonths m
),

-- Left join actual data onto the full grid
Filled AS (
    SELECT
        a.CPCID,
        a.CustomerNo,
        a.ProductCode,
        a.ForecastMonth,
        ISNULL(b.Qty_KG,  0) AS Qty_KG,
        ISNULL(b.Rev_EUR, 0) AS Rev_EUR
    FROM AllCombos a
    LEFT JOIN BaseData b
        ON a.CPCID = b.CPCID AND a.ForecastMonth = b.ForecastMonth
)

SELECT
    CPCID, CustomerNo, ProductCode,

    -- Qty_KG columns
    MAX(CASE WHEN ForecastMonth = '2026-01' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-01_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-02' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-02_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-03' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-03_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-04' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-04_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-05' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-05_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-06' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-06_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-07' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-07_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-08' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-08_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-09' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-09_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-10' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-10_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-11' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-11_Qty_KG],
    MAX(CASE WHEN ForecastMonth = '2026-12' THEN CAST(Qty_KG AS DECIMAL(10, 3))  ELSE 0 END) AS [2026-12_Qty_KG],

    -- Rev_EUR columns
    MAX(CASE WHEN ForecastMonth = '2026-01' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-01_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-02' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-02_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-03' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-03_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-04' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-04_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-05' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-05_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-06' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-06_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-07' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-07_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-08' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-08_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-09' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-09_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-10' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-10_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-11' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-11_Rev_EUR],
    MAX(CASE WHEN ForecastMonth = '2026-12' THEN CAST(Rev_EUR AS DECIMAL(10, 2)) ELSE 0 END) AS [2026-12_Rev_EUR]

FROM Filled
GROUP BY CPCID, CustomerNo, ProductCode
--ORDER BY CPCID