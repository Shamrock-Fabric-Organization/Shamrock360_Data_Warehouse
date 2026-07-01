-- Auto Generated (Do not modify) 34BC87A8E26613342073C50823349663A4BB10C06F4661EF30AAE40EE2A6B196

/*  ------ORIGINAL CODE

SELECT ct.dataareaid Company
, ct.voucher
, ct.accountnum Customer_ID
, ct.transdate TransactionDate
, CONVERT(INT, CONVERT(CHAR(8), ct.transdate, 112)) TransactionDateKey
, ct.transtype  GL_TransType
, ct.transtype_$label  GLTransTypeDesc
, ct.currencycode
, ct.invoice Invoice_ID

, case when ct.closed > @asofdate then '01/01/1900' else ct.closed end closed
, CONVERT(INT, CONVERT(CHAR(8), case when ct.closed > @asofdate then '01/01/1900' else ct.closed end, 112)) ClosedDateKey

, ct.duedate
, CONVERT(INT, CONVERT(CHAR(8), ct.duedate, 112)) DueDateKey
, CASE WHEN case when ct.closed > @asofdate then '01/01/1900' else ct.closed end = '01/01/1900' THEN 1 ELSE 0 END OpenID

, CASE WHEN case when ct.closed > @asofdate then '01/01/1900' else ct.closed end = '01/01/1900' THEN DATEDIFF(dd, ct.duedate, @asofdate ) ELSE 999999 END DaysOverdue

, a.AgingBucketKey AgingBucketKey
, a.Description

, ct.amountcur  
, ct.amountmst
, ct.custexchadjustmentrealized
, ct.custexchadjustmentunrealized
, ct.settleamountmst
, CASE WHEN case when ct.closed > @asofdate then '01/01/1900' else ct.closed end = '01/01/1900' THEN ct.amountmst + ct.custexchadjustmentrealized + ct.custexchadjustmentunrealized - ct.settleamountmst
		ELSE ct.amountmst END  Amount

, CASE WHEN ct.transtype = 2 THEN 
		CASE WHEN case when ct.closed > @asofdate then '01/01/1900' else ct.closed end = '01/01/1900' THEN DATEDIFF(dd, ct.transdate, @asofdate ) 
											ELSE DATEDIFF(dd, ct.transdate, ct.closed )  END 
			ELSE 0 END DaysOutstanding

, ct.lastsettledate
, fsd.FirstSettlementDate 
, ct.defaultdimension
--, d.*
--, gjae.mainaccount
--, ma.mainaccountid
--, ma.name
--, gjae.accountingcurrencyamount
FROM custtrans ct
join vwAgingBuckets a
  on CASE WHEN case when ct.closed > @asofdate then '01/01/1900' else ct.closed end = '01/01/1900' THEN DATEDIFF(dd, ct.duedate, @asofdate ) ELSE 999999 END 
		BETWEEN a.FromDays and a.ToDays

LEFT join (select dataareaid, offsetrecid, MIN(transdate) FirstSettlementDate
            from custsettlement 
            group by dataareaid, offsetrecid )fsd
  on ct.dataareaid = fsd.dataareaid
    and ct.recid = fsd.offsetrecid

WHERE ct.transdate <= @asofdate
*/



CREATE OR ALTER VIEW tbl_Fact_CustTrans
as
SELECT ct.dataareaid Company
, ct.voucher
, ct.accountnum Customer_ID
, ct.transdate TransactionDate
, CONVERT(INT, CONVERT(CHAR(8), ct.transdate, 112)) TransactionDateKey
, ct.transtype  GL_TransType
, ct.transtype_$label  GLTransTypeDesc
, ct.currencycode
, ct.invoice Invoice_ID

, ct.closed closed  --will need DAX logic for dynamic date to determine closed date value
, CONVERT(INT, CONVERT(CHAR(8), ct.closed, 112)) ClosedDateKey  --will need DAX logic for dynamic date to determine closed date value

, ct.duedate
, CONVERT(INT, CONVERT(CHAR(8), ct.duedate, 112)) DueDateKey
, CASE WHEN ct.closed = '01/01/1900' THEN 1 ELSE 0 END OpenID   --will need DAX logic for dynamic evaluation of OpenID value

, CASE WHEN ct.closed = '01/01/1900' THEN DATEDIFF(dd, ct.duedate, getdate() ) ELSE 999999 END DaysOverdue   --will need DAX logic for dynamic evaluation of DaysOverdue value

, a.AgingBucketKey AgingBucketKey   --will need DAX logic for dynamic evaluation of aging data
, a.Description   --will need DAX logic for dynamic evaluation of aging data

, ct.amountcur  
, ct.amountmst
, ct.custexchadjustmentrealized
, ct.custexchadjustmentunrealized
, ct.settleamountmst
, CASE WHEN ct.closed = '01/01/1900' THEN ct.amountmst + ct.custexchadjustmentrealized + ct.custexchadjustmentunrealized - ct.settleamountmst
		ELSE ct.amountmst END  Amount  --will need DAX logic for dynamic date to determine closed date value to determine amount

, CASE WHEN ct.transtype = 2 THEN 
		CASE WHEN ct.closed = '01/01/1900' THEN DATEDIFF(dd, ct.transdate, getdate() ) 
											ELSE DATEDIFF(dd, ct.transdate, ct.closed )  END 
			ELSE 0 END DaysOutstanding  --will need DAX logic for dynamic date to determine closed date value to determine DaysOutstanding

, ct.lastsettledate
, ISNULL(dcc.CustomerKey, -1) CustomerKey
, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey

-- ============================================================================
-- MULTI-CURRENCY CONVERSION — TXN BASIS (FROM ct.currencycode)
-- Date for rate effective period: ct.transdate (transaction/posting date).
-- Identity guard: when the row currency already equals the target, rate = 1.0.
-- ============================================================================
-- amountcur (document/transaction currency amount) -> USD / EUR / CNY
, CASE WHEN ct.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * ct.amountcur AS amountcur_USD
, CASE WHEN ct.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * ct.amountcur AS amountcur_EUR
, CASE WHEN ct.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * ct.amountcur AS amountcur_CNY

-- amountmst (accounting-currency amount) -> USD / EUR / CNY
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * ct.amountmst AS amountmst_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * ct.amountmst AS amountmst_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * ct.amountmst AS amountmst_CNY

-- custexchadjustmentrealized (accounting currency) -> USD / EUR / CNY
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * ct.custexchadjustmentrealized AS custexchadjustmentrealized_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * ct.custexchadjustmentrealized AS custexchadjustmentrealized_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * ct.custexchadjustmentrealized AS custexchadjustmentrealized_CNY

-- custexchadjustmentunrealized (accounting currency) -> USD / EUR / CNY
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * ct.custexchadjustmentunrealized AS custexchadjustmentunrealized_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * ct.custexchadjustmentunrealized AS custexchadjustmentunrealized_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * ct.custexchadjustmentunrealized AS custexchadjustmentunrealized_CNY

-- settleamountmst (accounting currency) -> USD / EUR / CNY
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * ct.settleamountmst AS settleamountmst_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * ct.settleamountmst AS settleamountmst_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * ct.settleamountmst AS settleamountmst_CNY

-- derived "Amount" (same accounting-currency basis) -> USD / EUR / CNY
-- Replicates the original Amount CASE expression verbatim, scaled by the cost-basis
-- rate. Because every term is in the accounting currency, scaling the result equals
-- scaling each component, so the converted Amount stays internally consistent.
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END *
    (CASE WHEN ct.closed = '01/01/1900' THEN ct.amountmst + ct.custexchadjustmentrealized + ct.custexchadjustmentunrealized - ct.settleamountmst
          ELSE ct.amountmst END) AS Amount_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END *
    (CASE WHEN ct.closed = '01/01/1900' THEN ct.amountmst + ct.custexchadjustmentrealized + ct.custexchadjustmentunrealized - ct.settleamountmst
          ELSE ct.amountmst END) AS Amount_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END *
    (CASE WHEN ct.closed = '01/01/1900' THEN ct.amountmst + ct.custexchadjustmentrealized + ct.custexchadjustmentunrealized - ct.settleamountmst
          ELSE ct.amountmst END) AS Amount_CNY

, ct.currencycode AS Txn_Source_Currency   -- audit: FROM currency for txn basis
, dle.accountingcurrency AS Cost_Source_Currency   -- audit: FROM currency for cost/MST basis

-- Rate-missing flags (1 = no matching rate row and currency differs from target)
, CASE WHEN ct.currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
, CASE WHEN ct.currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
, CASE WHEN ct.currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
-- Cost/MST rate-missing flags (1 = no matching rate row and accountingcurrency differs from target)
, CASE WHEN dle.accountingcurrency <> 'USD' AND erCostUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_USD_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'EUR' AND erCostEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_EUR_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'CNY' AND erCostCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_CNY_Rate_Missing

FROM WH_Raw.dbo.custtrans ct
join WH_Transform.dbo.tbl_DIM_AgingBuckets a
  on CASE WHEN ct.closed = '01/01/1900' THEN DATEDIFF(dd, ct.duedate, getdate() ) ELSE 999999 END 
		BETWEEN a.FromDays and a.ToDays

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dcc
	ON ct.accountnum = dcc.Customer_ID
		AND ct.dataareaid = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON ct.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

-- ============================================================================
-- TXN-BASIS EXCHANGE-RATE JOINS (FROM ct.currencycode)
-- One shared set of three joins (USD/EUR/CNY) for all txn-basis money columns.
-- ============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
	ON erTxnUSD.fromcurrencycode = ct.currencycode
		AND erTxnUSD.tocurrencycode = 'USD'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
		AND erTxnUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = ct.currencycode
		AND erTxnEUR.tocurrencycode = 'EUR'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
		AND erTxnEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = ct.currencycode
		AND erTxnCNY.tocurrencycode = 'CNY'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
		AND erTxnCNY.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostUSD
	ON erCostUSD.fromcurrencycode = dle.accountingcurrency
		AND erCostUSD.tocurrencycode = 'USD'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erCostUSD.validfrom and erCostUSD.validto
		AND erCostUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostEUR
	ON erCostEUR.fromcurrencycode = dle.accountingcurrency
		AND erCostEUR.tocurrencycode = 'EUR'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erCostEUR.validfrom and erCostEUR.validto
		AND erCostEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostCNY
	ON erCostCNY.fromcurrencycode = dle.accountingcurrency
		AND erCostCNY.tocurrencycode = 'CNY'
		AND convert(date, convert(char(8), ct.transdate, 112)) between erCostCNY.validfrom and erCostCNY.validto
		AND erCostCNY.exchangeratetype = 'Default global rate'
