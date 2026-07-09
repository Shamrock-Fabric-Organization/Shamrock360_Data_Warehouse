-- Auto Generated (Do not modify) 39DF2D48BD099D846315F73D8F54EA4849378CA7F4887271C4F25DE3EFA6A483
/****** Object:  View [dbo].[tbl_Fact_TradeAgreementDetails]    Script Date: 6/2/2026 10:32:06 AM ******/
--USE WH_Transform


/*
============================================================

  VIEW EQUIVALENTS (inlined as CTEs)
  ------------------------------------
  customer_rank_cte  → GUPPRICINGRULECONDITIONRANKVIEW (customer rules)
  customer_cte       → GUPPRICINGRULECONDITIONVIEW     (customer pivot)
  item_rank_cte      → GUPPRICINGRULECONDITIONRANKVIEW (item rules)
  item_cte           → GUPPRICINGRULECONDITIONVIEW     (item pivot)

  JOIN STRUCTURE
  --------------
  price_lines (UNION ALL of PriceDiscTable + PriceDiscAdmTrans)
    → customer_cte   via pricingruleheader  (customer conditions)
    → item_cte       via pricingruleline    (item conditions)
    → CustTable      via COALESCE(InvoiceAccount, CustomerAccount)
    → InventTable    via item_cte.ItemNumber

  FIELD NOTES
  -----------
  - customer_cte pivots by ATTRIBUTENAME (not by rank slot) for reliability.
  - InvoiceAccount = rules configured with ATTRIBUTENAME = 'Invoice account'
    (GUPPRICINGATTRIBUTELINK PRIORITY=2; confirmed as the dominant customer
    attribute in this environment — all 945 customer rules use this field).
  - CustomerAccount = rules configured with ATTRIBUTENAME = 'Customer account'
    (PRIORITY=1). Present in data; included as fallback via COALESCE.
  - CompanyChain = rules configured with ATTRIBUTENAME = 'Company chain'
    (PRIORITY=4). Surfaced as an output column only — not included in the
    customer STRING_SPLIT COALESCE. Rows where only CompanyChain is set
    (InvoiceAccount and CustomerAccount both NULL) produce CustomerAccount = NULL
    and CustomerKey = -1 via OUTER APPLY; CompanyChain remains visible.
  - item_cte pivots by ATTRIBUTENAME = 'Item number' directly.
  - relation = 4  → PriceSales
  - MODULE   = 1  → Customer (sales-facing)
  - AccountCode/ItemCode: 0=Table, 1=Group, 2=All
  - ToDate '1900-01-01' sentinel → no expiry (shown as NULL)

  ISRECENT FLAG
  -------------
  IsRecent = 1 for the row with the maximum PostedDateKey within each
  (Company, CustomerAccount, ItemNumber, Price, Currency) combination.
  All other rows in that partition receive IsRecent = 0.
  Ties at the maximum PostedDateKey both receive IsRecent = 1.
  IsRecent is forced to 0 when any dimension join returns the Unknown member
  (CustomerKey = -1 or ProductKey = -1), or when Currency, Amount, or
  PostedDate is NULL/empty. ISNULL is used to collapse NULL and empty checks
  into a single condition per column.

============================================================
*/

CREATE OR ALTER VIEW [dbo].[tbl_Fact_TradeAgreementDetails] as
WITH

-- ============================================================
-- CUSTOMER SIDE: rank and pivot conditions for Customer Header rules
-- (joined via PriceDiscTable.pricingruleheader)
-- ============================================================
customer_rank_cte AS (
    SELECT
         T1.[RECID]                                                  AS PRICINGRULE
        ,T1.[DATAAREAID]                                             AS DATAAREAID
        ,T3.[ATTRIBUTENAME]                                          AS ATTRIBUTENAME
        ,CAST(
            CASE
                WHEN T3.[SOURCENAME] = 'EcoResProductCategory'
                 AND T3.[FIELDNAME]  = 'Category'
                THEN (
                    SELECT STRING_AGG(A.CATEGORYNAME, ',')
                    FROM (
                        SELECT CONCAT(H.[NAME], '<-->', C.[NAME]) AS CATEGORYNAME
                        FROM STRING_SPLIT(T2.[CONDITIONVALUE], ',') s
                        JOIN WH_Raw.dbo.[ECORESCATEGORY] C
                            ON  C.[RECID] = TRY_CAST(LTRIM(RTRIM(s.[value])) AS BIGINT)
                        JOIN WH_Raw.dbo.[ECORESCATEGORYHIERARCHY] H
                            ON  C.[CATEGORYHIERARCHY] = H.[RECID]
                        WHERE LEFT(LTRIM(s.[value]), 1) <> '!'
                        UNION ALL
                        SELECT CONCAT('!', H.[NAME], '<-->', C.[NAME]) AS CATEGORYNAME
                        FROM STRING_SPLIT(T2.[CONDITIONVALUE], ',') s
                        JOIN WH_Raw.dbo.[ECORESCATEGORY] C
                            ON  C.[RECID] = TRY_CAST(LTRIM(RTRIM(STUFF(s.[value], 1, 1, ''))) AS BIGINT)
                        JOIN WH_Raw.dbo.[ECORESCATEGORYHIERARCHY] H
                            ON  C.[CATEGORYHIERARCHY] = H.[RECID]
                        WHERE LEFT(LTRIM(s.[value]), 1) = '!'
                    ) A
                )
                ELSE T2.[CONDITIONVALUE]
            END
         AS VARCHAR(1000))                                           AS CONDITIONVALUE
        ,CAST(
            DENSE_RANK() OVER (PARTITION BY T2.[RULEID] ORDER BY T3.[PRIORITY] DESC)
         AS INT)                                                     AS RANK
    FROM WH_Raw.dbo.[GUPPRICINGRULE] T1
    JOIN WH_Raw.dbo.[GUPPRICINGRULECONDITION] T2
        ON  T2.[RULEID]     = T1.[RECID]
        AND T2.[DATAAREAID] = T1.[DATAAREAID]
    LEFT JOIN WH_Raw.dbo.[GUPPRICINGATTRIBUTELINK] T3
        ON  T3.[RECID]      = T2.[CONDITIONATTRIBUTE]
),

customer_cte AS (
    SELECT
         T1.[PRICINGRULE]
        ,T1.[DATAAREAID]
        ,CAST(MAX(CASE WHEN T1.[ATTRIBUTENAME] = 'Invoice account'  THEN T1.[CONDITIONVALUE] END) AS VARCHAR(1000))  AS InvoiceAccount
        ,CAST(MAX(CASE WHEN T1.[ATTRIBUTENAME] = 'Customer account' THEN T1.[CONDITIONVALUE] END) AS VARCHAR(1000))  AS CustomerAccount
        ,CAST(MAX(CASE WHEN T1.[ATTRIBUTENAME] = 'Company chain'    THEN T1.[CONDITIONVALUE] END) AS VARCHAR(1000))  AS CompanyChain
        ,CAST(CONCAT(
             MAX(CASE WHEN T1.[RANK] =  1 THEN T1.[ATTRIBUTENAME]          ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  2 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  3 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  4 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  5 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
         ) AS VARCHAR(MAX))                                                  AS COMBINATIONSTRUCTURE
    FROM customer_rank_cte T1
    GROUP BY T1.[PRICINGRULE], T1.[DATAAREAID]
),

-- ============================================================
-- ITEM SIDE: rank and pivot conditions for Item/Category Group rules
-- (joined via PriceDiscTable.pricingruleline)
-- ============================================================
item_rank_cte AS (
    SELECT
         T1.[RECID]                                                  AS PRICINGRULE
        ,T1.[DATAAREAID]                                             AS DATAAREAID
        ,T3.[ATTRIBUTENAME]                                          AS ATTRIBUTENAME
        ,CAST(
            CASE
                WHEN T3.[SOURCENAME] = 'EcoResProductCategory'
                 AND T3.[FIELDNAME]  = 'Category'
                THEN (
                    SELECT STRING_AGG(A.CATEGORYNAME, ',')
                    FROM (
                        SELECT CONCAT(H.[NAME], '<-->', C.[NAME]) AS CATEGORYNAME
                        FROM STRING_SPLIT(T2.[CONDITIONVALUE], ',') s
                        JOIN WH_Raw.dbo.[ECORESCATEGORY] C
                            ON  C.[RECID] = TRY_CAST(LTRIM(RTRIM(s.[value])) AS BIGINT)
                        JOIN WH_Raw.dbo.[ECORESCATEGORYHIERARCHY] H
                            ON  C.[CATEGORYHIERARCHY] = H.[RECID]
                        WHERE LEFT(LTRIM(s.[value]), 1) <> '!'
                        UNION ALL
                        SELECT CONCAT('!', H.[NAME], '<-->', C.[NAME]) AS CATEGORYNAME
                        FROM STRING_SPLIT(T2.[CONDITIONVALUE], ',') s
                        JOIN WH_Raw.dbo.[ECORESCATEGORY] C
                            ON  C.[RECID] = TRY_CAST(LTRIM(RTRIM(STUFF(s.[value], 1, 1, ''))) AS BIGINT)
                        JOIN WH_Raw.dbo.[ECORESCATEGORYHIERARCHY] H
                            ON  C.[CATEGORYHIERARCHY] = H.[RECID]
                        WHERE LEFT(LTRIM(s.[value]), 1) = '!'
                    ) A
                )
                ELSE T2.[CONDITIONVALUE]
            END
         AS VARCHAR(1000))                                           AS CONDITIONVALUE
        ,CAST(
            DENSE_RANK() OVER (PARTITION BY T2.[RULEID] ORDER BY T3.[PRIORITY] DESC)
         AS INT)                                                     AS RANK
    FROM WH_Raw.dbo.[GUPPRICINGRULE] T1
    JOIN WH_Raw.dbo.[GUPPRICINGRULECONDITION] T2
        ON  T2.[RULEID]     = T1.[RECID]
        AND T2.[DATAAREAID] = T1.[DATAAREAID]
    LEFT JOIN WH_Raw.dbo.[GUPPRICINGATTRIBUTELINK] T3
        ON  T3.[RECID]      = T2.[CONDITIONATTRIBUTE]
),

item_cte AS (
    SELECT
         T1.[PRICINGRULE]
        ,T1.[DATAAREAID]
        ,CAST(MAX(CASE WHEN T1.[ATTRIBUTENAME] = 'Item number' THEN T1.[CONDITIONVALUE] END) AS VARCHAR(1000))  AS ItemNumber
        ,CAST(MAX(CASE WHEN T1.[ATTRIBUTENAME] = 'Category'    THEN T1.[CONDITIONVALUE] END) AS VARCHAR(1000))  AS Category
        ,CAST(CONCAT(
             MAX(CASE WHEN T1.[RANK] =  1 THEN T1.[ATTRIBUTENAME]          ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  2 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  3 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  4 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
            ,MAX(CASE WHEN T1.[RANK] =  5 THEN ';' + T1.[ATTRIBUTENAME]    ELSE '' END)
         ) AS VARCHAR(MAX))                                                  AS COMBINATIONSTRUCTURE
    FROM item_rank_cte T1
    GROUP BY T1.[PRICINGRULE], T1.[DATAAREAID]
),

-- ============================================================
-- Price lines: UNION ALL of posted + unposted
-- ============================================================
price_lines AS (
    ----SELECT
    ----     [DATAAREAID]
    ----    ,[RECID]
    ----    ,[PRICINGRULEHEADER]
    ----    ,[PRICINGRULELINE]
    ----    ,[ACCOUNTCODE]
    ----    ,[ACCOUNTRELATION]
    ----    ,[ITEMCODE]
    ----    ,[ITEMRELATION]
    ----    ,[AMOUNT]
    ----    ,[CURRENCY]
    ----    ,[PRICEUNIT]
    ----    ,[UNITID]
    ----    ,[PERCENT1]
    ----    ,[PERCENT2]
    ----    ,[FROMDATE]
    ----    ,[TODATE]
    ----    ,[QUANTITYAMOUNTFROM]
    ----    ,[QUANTITYAMOUNTTO]
    ----    ,[INVENTDIMID]
    ----    ,[AGREEMENT]
    ----    ,'Posted'                                                    AS PriceLineSource
    ----FROM WH_Raw.dbo.[PRICEDISCTABLE]
    ----WHERE [RELATION]          = 4
    ----  AND [MODULE]            = 1
    ----  AND [PRICINGRULEHEADER] IS NOT NULL
    ----  AND [PRICINGRULEHEADER] <> 0

    ----UNION ALL

    SELECT
         pdat.[DATAAREAID]
        ,pdat.[RECID]
        ,pdat.[PRICINGRULEHEADER]
        ,pdat.[PRICINGRULELINE]
        ,pdat.[ACCOUNTCODE]
        ,pdat.[ACCOUNTRELATION]
        ,pdat.[ITEMCODE]
        ,pdat.[ITEMRELATION]
        ,pdat.[AMOUNT]
        ,pdat.[CURRENCY]
        ,pdat.[PRICEUNIT]
        ,pdat.[UNITID]
        ,pdat.[PERCENT1]
        ,pdat.[PERCENT2]
        ,pdat.[FROMDATE]
        ,pdat.[TODATE]
        ,pdat.[QUANTITYAMOUNTFROM]
        ,pdat.[QUANTITYAMOUNTTO]
        ,pdat.[INVENTDIMID]
        ,pdat.[JOURNALNUM]                                               AS AGREEMENT
        ,pda.[POSTED_$label] Posted
        ,pda.posteddate
        --,'Unposted'                                                  AS PriceLineSource
    FROM WH_Raw.dbo.[PRICEDISCADMTRANS] pdat
      JOIN WH_Raw.dbo.[PRICEDISCADMTABLE] pda
        ON pdat.dataareaid = pda.dataareaid
          AND pdat.journalnum = pda.journalnum
    WHERE pdat.[RELATION]          = 4
      AND pdat.[MODULE]            = 1
      AND pdat.[PRICINGRULEHEADER] IS NOT NULL
      AND pdat.[PRICINGRULEHEADER] <> 0
)

-- ============================================================
-- MAIN QUERY
-- ============================================================
SELECT

     p.[DATAAREAID]                                                  AS Company
    ,p.[AGREEMENT]                                                   AS AgreementId
    ,p.Posted
    ,p.[AMOUNT]                                                      AS Price
    ,p.[CURRENCY]                                                    AS Currency
    ,p.[PRICEUNIT]                                                   AS PriceUnit
    ,p.[UNITID]                                                      AS Unit
    ,p.[FROMDATE]                                                    AS ValidFrom
    ,CASE WHEN p.[TODATE] = '1900-01-01' THEN '2154-12-31'
          ELSE p.[TODATE]
     END                                                             AS ValidTo
    ,p.[QUANTITYAMOUNTFROM]                                          AS QtyFrom
    ,p.[QUANTITYAMOUNTTO]                                            AS QtyTo
    ,convert(int, convert(char(8), p.posteddate,112))                AS PostedDateKey
    -- --------------------------------------------------------
    -- IsRecent: 1 for the row(s) with the maximum PostedDateKey
    -- within each (Company, CustomerAccount, ItemNumber, Price, Currency)
    -- combination; 0 for all others.
    -- Ties at the maximum both receive 1.
    -- Forced to 0 when any partition column is unknown/null:
    --   CustomerKey / ProductKey = -1 means the dimension join returned
    --   the Unknown member (customer or item not found in the dim table).
    --   ISNULL on Currency/Amount collapses NULL + empty into one check.
    -- --------------------------------------------------------
    ,CASE
        WHEN ISNULL(cust.CustomerKey, -1) = -1
          OR ISNULL(item.ProductKey,  -1) = -1
          OR p.posteddate                IS NULL
          OR p.[AMOUNT]                  IS NULL
          OR ISNULL(p.[CURRENCY], '')    = ''
        THEN 0
        WHEN convert(int, convert(char(8), p.posteddate, 112))
           = MAX(convert(int, convert(char(8), p.posteddate, 112))) OVER (
                 PARTITION BY
                      p.[DATAAREAID]
                     ,LTRIM(RTRIM(cust_split.[value]))
                     ,LTRIM(RTRIM(item_split.[value]))
                     ,p.[AMOUNT]
                     ,p.[CURRENCY]
             )
        THEN 1 ELSE 0
     END                                                             AS IsRecent
    -- --------------------------------------------------------
    -- Customer  (from customer-side GUP conditions)
    -- InvoiceAccount used where present; CustomerAccount as fallback.
    -- Both attributes identify the customer in D365 trade agreement rules.
    -- cust_split explodes comma-separated lists → one row per account.
    -- --------------------------------------------------------
    ,LTRIM(RTRIM(cust_split.[value]))                                AS CustomerAccount
    ,isnull(cust.CustomerKey, -1)                                    AS CustomerKey
    -- --------------------------------------------------------
    -- Company chain (from customer-side GUP conditions, if configured)
    -- NULL when the rule has no Company chain condition.
    -- --------------------------------------------------------
    ,cv.CompanyChain                                                 AS CompanyChain
    -- --------------------------------------------------------
    -- Item  (from item-side GUP conditions)
    -- ItemNumber column pivoted directly by ATTRIBUTENAME = 'Item number'.
    -- item_split explodes comma-separated lists → one row per item.
    -- --------------------------------------------------------
    ,LTRIM(RTRIM(item_split.[value]))                                AS ItemNumber
    ,isnull(item.ProductKey, -1)                                     AS ProductKey
    , isnull(dle.Legal_EntityKey, -1) Legal_EntityKey
    , isnull(dta.TradeAgreementKey, -1) TradeAgreementKey
    , ISNULL(de.EmployeeKey, -1) CustAcct_EmployeeKey

    -- ========================================================================
    -- ADDED (ITEM-018): MULTI-CURRENCY CONVERSION — TXN BASIS (FROM p.[CURRENCY])
    -- Date for rate effective period: p.[FROMDATE] (price-effective / ValidFrom).
    -- Identity guard: when the row currency already equals the target, rate = 1.0.
    -- ========================================================================
    , p.[CURRENCY] AS Txn_Source_Currency   -- audit: FROM currency for txn basis

    -- Price (p.[AMOUNT]) -> USD / EUR / CNY
    , CASE WHEN p.[CURRENCY] = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.[AMOUNT] AS Price_USD
    , CASE WHEN p.[CURRENCY] = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.[AMOUNT] AS Price_EUR
    , CASE WHEN p.[CURRENCY] = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.[AMOUNT] AS Price_CNY

    -- Rate-missing flags (1 = no matching rate row and currency differs from target)
    , CASE WHEN p.[CURRENCY] <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
    , CASE WHEN p.[CURRENCY] <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
    , CASE WHEN p.[CURRENCY] <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing

FROM price_lines p

-- Customer-side GUP rule conditions
LEFT JOIN customer_cte cv
    ON  cv.[PRICINGRULE]  = p.[PRICINGRULEHEADER]
    AND cv.[DATAAREAID]   = p.[DATAAREAID]

-- Item-side GUP rule conditions
LEFT JOIN item_cte iv
    ON  iv.[PRICINGRULE]  = p.[PRICINGRULELINE]
    AND iv.[DATAAREAID]   = p.[DATAAREAID]

-- Explode comma-separated customer accounts → one row per account.
-- COALESCE: InvoiceAccount is the dominant attribute in this environment;
-- CustomerAccount is the fallback for rules configured with that attribute.
-- CompanyChain is intentionally excluded — it is an output column only and
-- must not flow into CustomerAccount or the CustomerKey surrogate key lookup.
-- OUTER APPLY (not CROSS APPLY): rows where both InvoiceAccount and
-- CustomerAccount are NULL (Company chain-only rules) return one row with
-- NULL cust_split.value, preserving the CompanyChain output column.
-- CROSS APPLY would silently drop those rows.
OUTER APPLY STRING_SPLIT(REPLACE(COALESCE(cv.InvoiceAccount, cv.CustomerAccount), ';', ','), ',') AS cust_split

-- Explode comma-separated item numbers → one row per item.
-- Same Gate 3 justification as above.
CROSS APPLY STRING_SPLIT(REPLACE(iv.ItemNumber, ';', ','), ',') AS item_split

-- Customer name: join on the split single account value
LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer cust
    ON  cust.Customer_ID  = LTRIM(RTRIM(cust_split.[value]))
    AND cust.CMPNY  = p.[DATAAREAID]
    AND cust.recordstatus = 1

-- Item: join on the split single item number value
LEFT JOIN WH_Transform.dbo.tbl_DIM_Product item
    ON  item.Product_ID      = LTRIM(RTRIM(item_split.[value]))
    AND item.CMPNY  = p.[DATAAREAID]
    and item.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
    ON  dle.CMPNY  = p.[DATAAREAID]
    and dle.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_TradeAgreement dta
    ON  dta.CMPNY  = p.[DATAAREAID]
      AND dta.AgreementID = p.[AGREEMENT]
      AND dta.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee de
    ON  cust.Salesman_ID  = de.Personnel_Number
    AND de.recordstatus = 1

-- ============================================================================
-- TXN-BASIS EXCHANGE-RATE JOINS (FROM p.[CURRENCY])
-- One shared set of three joins (USD/EUR/CNY) for the Price money column.
-- Effective date keyed on p.[FROMDATE] (trade-agreement price-effective date).
-- ============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON  erTxnUSD.fromcurrencycode = p.[CURRENCY]
    AND erTxnUSD.tocurrencycode   = 'USD'
    AND convert(date, convert(char(8), p.[FROMDATE], 112)) between erTxnUSD.validfrom and erTxnUSD.validto
    AND erTxnUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON  erTxnEUR.fromcurrencycode = p.[CURRENCY]
    AND erTxnEUR.tocurrencycode   = 'EUR'
    AND convert(date, convert(char(8), p.[FROMDATE], 112)) between erTxnEUR.validfrom and erTxnEUR.validto
    AND erTxnEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON  erTxnCNY.fromcurrencycode = p.[CURRENCY]
    AND erTxnCNY.tocurrencycode   = 'CNY'
    AND convert(date, convert(char(8), p.[FROMDATE], 112)) between erTxnCNY.validfrom and erTxnCNY.validto
    AND erTxnCNY.exchangeratetype = 'Default global rate'
