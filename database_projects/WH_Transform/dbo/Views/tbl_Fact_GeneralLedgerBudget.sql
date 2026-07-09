-- Auto Generated (Do not modify) B8E2C2AE9893CB4518CE0BA78A78313DF325777EC0A8C9AF4F08B0D127C0BD14

CREATE OR ALTER VIEW tbl_Fact_GeneralLedgerBudget
as
SELECT 
budgetmodeldataareaid CMPNY
, GL_Account
, date
, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) BudgetDateKey
,budgetmodelid  BudgetModel
,budgettype_$label BudgetTypeDesc
,transactioncurrency  CurrencyCode
,budgettransactiontype_$label BudgetTransactionType
,accountingcurrencyamount accountingcurrencyamount
---- ADDED: accountingcurrencyamount converted (MST/accounting basis · FROM dle.accountingcurrency) ----
,CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erAcctUSD.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_USD
,CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erAcctEUR.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_EUR
,CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erAcctCNY.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_CNY
,transactioncurrencyamount transactioncurrencyamount
---- ADDED: transactioncurrencyamount converted (TXN basis · FROM transactioncurrency; see BUDGET-RATE CAVEAT) ----
,CASE WHEN transactioncurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_USD
,CASE WHEN transactioncurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_EUR
,CASE WHEN transactioncurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_CNY
,quantity 
,isnull(dle.Legal_EntityKey, -1) Legal_EntityKey
,isnull(dbm.BudgetModelKey, -1) BudgetModelKey
,isnull(dd.DepartmentKey, -1) DepartmentKey
,isnull(ds.SiteKey, -1) SiteKey
---- ADDED: audit / lineage columns exposing each basis' FROM currency ----
,transactioncurrency    AS Txn_Source_Currency      -- FROM currency for the TXN basis
,dle.accountingcurrency AS Cost_Source_Currency      -- FROM currency for the MST/accounting basis
---- ADDED: rate-missing flags (1 = a non-identity conversion could not find a rate row) ----
,CASE WHEN transactioncurrency <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
,CASE WHEN transactioncurrency <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
,CASE WHEN transactioncurrency <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
,CASE WHEN dle.accountingcurrency <> 'USD' AND erAcctUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_USD_Rate_Missing
,CASE WHEN dle.accountingcurrency <> 'EUR' AND erAcctEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_EUR_Rate_Missing
,CASE WHEN dle.accountingcurrency <> 'CNY' AND erAcctCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_CNY_Rate_Missing

FROM 
(
SELECT 
bth.budgettransactiontype
,bth.[budgettransactiontype_$label]
,bth.transactionstatus
,bth.[transactionstatus_$label]
,bth.budgetmodelid
,bth.budgetsubmodelid
,bth.budgetmodeltype
,bth.[budgetmodeltype_$label]
,bth.budgetmodeldataareaid
,btl.budgettype
, btl.budgettype_$label
, ld.Business_Unit
, ld.Department
, ld.GL_Account
, ld.Product_Line
, ld.Site
, btl.accountingcurrencyamount
, btl.date
, btl.linenumber
, btl.quantity
, btl.transactioncurrency
, btl.transactioncurrencyamount


FROM WH_Raw.dbo.BudgetTransactionLine btl
LEFT JOIN WH_Raw.dbo.BudgetTransactionHeader bth 
  ON bth.RECID = btl.[budgettransactionheader]

LEFT JOIN WH_Raw.dbo.vwLedgerDimension ld
  ON btl.ledgerdimension = ld.LedgerDimension
) b

LEFT JOIN [dbo].[tbl_DIM_Legal_Entity] dle
  ON b.budgetmodeldataareaid = dle.CMPNY
    AND dle.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_Department] dd
  ON b.Department = dd.Department
    AND dd.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_Site] ds
  ON b.Site = ds.Site_ID
    AND b.budgetmodeldataareaid = ds.CMPNY
    AND ds.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_BudgetModel] dbm
  ON b.budgetmodelid = dbm.BudgetModel
    AND b.budgetmodeldataareaid = dbm.CMPNY
    AND dbm.recordstatus = 1

/* =====================================================================================
   ADDED — Exchange-rate joins (additive; do not affect the original join graph)
   All TXN-basis money columns share erTxn* ; all MST/accounting-basis columns share
   erAcct*. Date = b.date (budget line date), normalized for the BETWEEN.
   ===================================================================================== */

-- TXN basis: FROM = b.transactioncurrency, at the budget line date
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
	ON erTxnUSD.fromcurrencycode = b.transactioncurrency
	AND erTxnUSD.tocurrencycode   = 'USD'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erTxnUSD.validfrom AND erTxnUSD.validto
	AND erTxnUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = b.transactioncurrency
	AND erTxnEUR.tocurrencycode   = 'EUR'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erTxnEUR.validfrom AND erTxnEUR.validto
	AND erTxnEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = b.transactioncurrency
	AND erTxnCNY.tocurrencycode   = 'CNY'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erTxnCNY.validfrom AND erTxnCNY.validto
	AND erTxnCNY.exchangeratetype = 'Default global rate'

-- MST / accounting basis: FROM = dle.accountingcurrency, at the budget line date
LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctUSD
	ON erAcctUSD.fromcurrencycode = dle.accountingcurrency
	AND erAcctUSD.tocurrencycode   = 'USD'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erAcctUSD.validfrom AND erAcctUSD.validto
	AND erAcctUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctEUR
	ON erAcctEUR.fromcurrencycode = dle.accountingcurrency
	AND erAcctEUR.tocurrencycode   = 'EUR'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erAcctEUR.validfrom AND erAcctEUR.validto
	AND erAcctEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctCNY
	ON erAcctCNY.fromcurrencycode = dle.accountingcurrency
	AND erAcctCNY.tocurrencycode   = 'CNY'
	AND convert(date, convert(char(8), b.date, 112)) BETWEEN erAcctCNY.validfrom AND erAcctCNY.validto
	AND erAcctCNY.exchangeratetype = 'Default global rate'



--GROUP BY budgetmodeldataareaid --CMPNY
--, GL_Account
--, date
--, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) --BudgetDateKey
--,budgetmodelid -- BudgetModel
--,budgettype_$label --BudgetTypeDesc
--,transactioncurrency  --CurrencyCode
--,budgettransactiontype_$label --BudgetTransactionType

--,isnull(dle.Legal_EntityKey, -1) --Legal_EntityKey
--,isnull(dbm.BudgetModelKey, -1) --BudgetModelKey
--,isnull(dd.DepartmentKey, -1) --DepartmentKey
--,isnull(ds.SiteKey, -1) --SiteKey


--GROUP BY budgetmodeldataareaid --CMPNY
--, GL_Account
--, date
--, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) --BudgetDateKey
--,budgetmodelid -- BudgetModel
--,budgettype_$label --BudgetTypeDesc
--,transactioncurrency  --CurrencyCode
--,budgettransactiontype_$label --BudgetTransactionType

--,isnull(dle.Legal_EntityKey, -1) --Legal_EntityKey
--,isnull(dbm.BudgetModelKey, -1) --BudgetModelKey
--,isnull(dd.DepartmentKey, -1) --DepartmentKey
--,isnull(ds.SiteKey, -1) --SiteKey