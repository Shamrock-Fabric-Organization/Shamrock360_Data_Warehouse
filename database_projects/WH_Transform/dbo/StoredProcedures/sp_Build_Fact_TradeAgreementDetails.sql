

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


CREATE OR ALTER PROCEDURE sp_Build_Fact_TradeAgreementDetails 
as
BEGIN
    DROP TABLE IF EXISTS stage_TradeAgreement_customer_rank_cte  ;
    DROP TABLE IF EXISTS stage_TradeAgreement_customer_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_rank_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_price_lines ;
    DROP TABLE IF EXISTS stage_TradeAgreement_inv_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_cust_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_prelim;

-- ============================================================
-- CUSTOMER SIDE: rank and pivot conditions for Customer Header rules
-- (joined via PriceDiscTable.pricingruleheader)
-- ============================================================
CREATE TABLE stage_TradeAgreement_customer_rank_cte  AS
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

CREATE TABLE stage_TradeAgreement_customer_cte  AS
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
    FROM stage_TradeAgreement_customer_rank_cte T1
    GROUP BY T1.[PRICINGRULE], T1.[DATAAREAID]

-- ============================================================
-- ITEM SIDE: rank and pivot conditions for Item/Category Group rules
-- (joined via PriceDiscTable.pricingruleline)
-- ============================================================
CREATE TABLE stage_TradeAgreement_item_rank_cte  AS
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

CREATE TABLE stage_TradeAgreement_item_cte  AS
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
    FROM stage_TradeAgreement_item_rank_cte T1
    GROUP BY T1.[PRICINGRULE], T1.[DATAAREAID]

-- ============================================================
-- Price lines: UNION ALL of posted + unposted
-- ============================================================
CREATE TABLE stage_TradeAgreement_price_lines  AS
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



------------------------------------------------------------------------------
-- 1) InvoiceAccount explosion  (was: OUTER APPLY inv_split)
--    Keyed by the customer rule (PRICINGRULE, DATAAREAID) so it can be
--    LEFT JOINed back to p on p.[PRICINGRULEHEADER].
--    Null/empty InvoiceAccount -> STRING_SPLIT returns 0 rows -> no stage row
--    -> LEFT JOIN yields NULL, matching OUTER APPLY's NULL-preservation.
------------------------------------------------------------------------------
CREATE TABLE stage_TradeAgreement_inv_split AS
SELECT
     cv.[PRICINGRULE]
    ,cv.[DATAAREAID]
    ,LTRIM(RTRIM(s.[value]))                                         AS [value]
FROM stage_TradeAgreement_customer_cte cv
CROSS APPLY STRING_SPLIT(REPLACE(cv.InvoiceAccount, ';', ','), ',') AS s;

------------------------------------------------------------------------------
-- 2) CustomerAccount explosion  (was: correlated OUTER APPLY cust_split)
--    OPTION A GUARD is baked in here as a WHERE clause: only explode the
--    CustomerAccount list for rules that have NO InvoiceAccount. This keeps
--    the two account streams mutually exclusive exactly like the original.
------------------------------------------------------------------------------
CREATE TABLE stage_TradeAgreement_cust_split AS
SELECT
     cv.[PRICINGRULE]
    ,cv.[DATAAREAID]
    ,LTRIM(RTRIM(s.[value]))                                         AS [value]
FROM stage_TradeAgreement_customer_cte cv
CROSS APPLY STRING_SPLIT(REPLACE(cv.CustomerAccount, ';', ','), ',') AS s
WHERE cv.InvoiceAccount IS NULL
   OR LTRIM(RTRIM(cv.InvoiceAccount)) = '';

------------------------------------------------------------------------------
-- 3) ItemNumber explosion  (was: CROSS APPLY item_split)
--    Keyed by the item rule (PRICINGRULE, DATAAREAID); LEFT/INNER? -> INNER
--    in the main query so rows with no item are dropped, same as CROSS APPLY.
------------------------------------------------------------------------------
CREATE TABLE stage_TradeAgreement_item_split AS
SELECT
     iv.[PRICINGRULE]
    ,iv.[DATAAREAID]
    ,LTRIM(RTRIM(s.[value]))                                         AS [value]
FROM stage_TradeAgreement_item_cte iv
CROSS APPLY STRING_SPLIT(REPLACE(iv.ItemNumber, ';', ','), ',') AS s;



-- ============================================================
-- MAIN QUERY PRELIM
-- ============================================================
 CREATE TABLE stage_TradeAgreement_prelim  AS
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
    -- within each (Company, effective account, ItemNumber, Price, Currency)
    -- combination; 0 for all others. Ties at the max both receive 1.
    -- Forced to 0 when any partition column is unknown/null.
    -- --------------------------------------------------------
    ,CASE
        WHEN ISNULL(COALESCE(invcust.CustomerKey, cust.CustomerKey), -1) = -1
          OR ISNULL(item.ProductKey,  -1) = -1
          OR p.posteddate                IS NULL
          OR p.[AMOUNT]                  IS NULL
          OR ISNULL(p.[CURRENCY], '')    = ''
        THEN 0
        WHEN convert(int, convert(char(8), p.posteddate, 112))
           = MAX(convert(int, convert(char(8), p.posteddate, 112))) OVER (
                 PARTITION BY
                      p.[DATAAREAID]
                     ,LTRIM(RTRIM(COALESCE(inv_split.[value], cust_split.[value])))
                     ,LTRIM(RTRIM(item_split.[value]))
                     ,p.[AMOUNT]
                     ,p.[CURRENCY]
             )
        THEN 1 ELSE 0
     END                                                             AS IsRecent
    -- --------------------------------------------------------
    -- Customer (invoice + customer accounts, each with its own key)
    -- --------------------------------------------------------
    ,LTRIM(RTRIM(inv_split.[value]))                                 AS InvoiceAccount
    ,isnull(invcust.CustomerKey, -1)                                 AS InvoiceCustomerKey
    ,LTRIM(RTRIM(cust_split.[value]))                                AS CustomerAccount
    ,isnull(cust.CustomerKey, -1)                                    AS CustomerKey
    -- Company chain (output-only column, from customer-side rule)
    ,cv.CompanyChain                                                 AS CompanyChain
    -- Item
    ,LTRIM(RTRIM(item_split.[value]))                                AS ItemNumber
    ,isnull(item.ProductKey, -1)                                     AS ProductKey
    ,isnull(dle.Legal_EntityKey, -1)                                 AS Legal_EntityKey
    ,isnull(dta.TradeAgreementKey, -1)                               AS TradeAgreementKey
    ,ISNULL(de.EmployeeKey, -1)                                      AS CustAcct_EmployeeKey
    -- ========================================================================
    -- MULTI-CURRENCY CONVERSION — TXN BASIS (FROM p.[CURRENCY])
    -- ========================================================================
    ,p.[CURRENCY]                                                    AS Txn_Source_Currency
    ,CASE WHEN p.[CURRENCY] = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.[AMOUNT] AS Price_USD
    ,CASE WHEN p.[CURRENCY] = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.[AMOUNT] AS Price_EUR
    ,CASE WHEN p.[CURRENCY] = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.[AMOUNT] AS Price_CNY
    ,CASE WHEN p.[CURRENCY] <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
    ,CASE WHEN p.[CURRENCY] <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
    ,CASE WHEN p.[CURRENCY] <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing

FROM stage_TradeAgreement_price_lines p

-- Customer-side GUP rule conditions (kept for CompanyChain output column)
LEFT JOIN stage_TradeAgreement_customer_cte cv
    ON  cv.[PRICINGRULE]  = p.[PRICINGRULEHEADER]
    AND cv.[DATAAREAID]   = p.[DATAAREAID]

-- Exploded InvoiceAccount stream  (was OUTER APPLY inv_split)
LEFT JOIN stage_TradeAgreement_inv_split inv_split
    ON  inv_split.[PRICINGRULE] = p.[PRICINGRULEHEADER]
    AND inv_split.[DATAAREAID]  = p.[DATAAREAID]

-- Exploded CustomerAccount stream, Option A guard baked into the stage table
-- (was correlated OUTER APPLY cust_split)
LEFT JOIN stage_TradeAgreement_cust_split cust_split
    ON  cust_split.[PRICINGRULE] = p.[PRICINGRULEHEADER]
    AND cust_split.[DATAAREAID]  = p.[DATAAREAID]

-- Exploded ItemNumber stream  (was CROSS APPLY item_split -> INNER JOIN)
INNER JOIN stage_TradeAgreement_item_split item_split
    ON  item_split.[PRICINGRULE] = p.[PRICINGRULELINE]
    AND item_split.[DATAAREAID]  = p.[DATAAREAID]

-- Invoice-account customer lookup
LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer invcust
    ON  invcust.Customer_ID  = LTRIM(RTRIM(inv_split.[value]))
    AND invcust.CMPNY        = p.[DATAAREAID]
    AND invcust.recordstatus = 1

-- Customer-account customer lookup
LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer cust
    ON  cust.Customer_ID  = LTRIM(RTRIM(cust_split.[value]))
    AND cust.CMPNY        = p.[DATAAREAID]
    AND cust.recordstatus = 1

-- Item lookup
LEFT JOIN WH_Transform.dbo.tbl_DIM_Product item
    ON  item.Product_ID   = LTRIM(RTRIM(item_split.[value]))
    AND item.CMPNY        = p.[DATAAREAID]
    AND item.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
    ON  dle.CMPNY        = p.[DATAAREAID]
    AND dle.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_TradeAgreement dta
    ON  dta.CMPNY        = p.[DATAAREAID]
    AND dta.AgreementID  = p.[AGREEMENT]
    AND dta.recordstatus = 1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee de
    ON  cust.Salesman_ID = de.Personnel_Number
    AND de.recordstatus  = 1

-- ============================================================================
-- TXN-BASIS EXCHANGE-RATE JOINS (FROM p.[CURRENCY])
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
    AND erTxnCNY.exchangeratetype = 'Default global rate';
--)

-- ============================================================
-- MAIN QUERY 
-- ============================================================

DROP TABLE IF EXISTS tbl_Fact_TradeAgreementDetails;

CREATE TABLE tbl_Fact_TradeAgreementDetails AS
SELECT p.Company CMPNY
, p.AgreementId
, p.Posted
, p.Price
, p.Currency
, p.PriceUnit
, p.Unit
, p.ValidFrom
, p.ValidTo
, p.QtyFrom
, p.QtyTo
, p.PostedDateKey
, p.IsRecent
, p.InvoiceAccount InvoiceCustomerAccount
, p.InvoiceCustomerKey
--, p.CustomerAccount
--, p.CustomerKey
, cust.Customer_ID CustomerAccount
, cust.CustomerKey
, p.CompanyChain
, p.ItemNumber
, p.ProductKey
, p.Legal_EntityKey
, p.TradeAgreementKey
, p.CustAcct_EmployeeKey
, p.Txn_Source_Currency
, p.Price_USD
, p.Price_EUR
, p.Price_CNY
, p.Txn_USD_Rate_Missing
, p.Txn_EUR_Rate_Missing
, p.Txn_CNY_Rate_Missing

FROM stage_TradeAgreement_prelim p
-- Customer-account customer lookup: join on the split single account value
LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer cust
    ON  cust.Invoice_Account = p.InvoiceAccount
    AND cust.CMPNY  = p.Company
    AND cust.recordstatus = 1

WHERE p.CustomerAccount is null



UNION


SELECT Company
,  AgreementId
,  Posted
,  Price
,  Currency
,  PriceUnit
,  Unit
,  ValidFrom
,  ValidTo
,  QtyFrom
,  QtyTo
,  PostedDateKey
,  IsRecent
,  InvoiceAccount
,  InvoiceCustomerKey
,  CustomerAccount
,  CustomerKey
,  CompanyChain
,  ItemNumber
,  ProductKey
,  Legal_EntityKey
,  TradeAgreementKey
,  CustAcct_EmployeeKey
,  Txn_Source_Currency
,  Price_USD
,  Price_EUR
,  Price_CNY
,  Txn_USD_Rate_Missing
,  Txn_EUR_Rate_Missing
,  Txn_CNY_Rate_Missing

FROM stage_TradeAgreement_prelim
WHERE InvoiceAccount is null



    DROP TABLE IF EXISTS stage_TradeAgreement_customer_rank_cte  ;
    DROP TABLE IF EXISTS stage_TradeAgreement_customer_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_rank_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_cte ;
    DROP TABLE IF EXISTS stage_TradeAgreement_price_lines ;
    DROP TABLE IF EXISTS stage_TradeAgreement_inv_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_cust_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_item_split;
    DROP TABLE IF EXISTS stage_TradeAgreement_prelim;

END


