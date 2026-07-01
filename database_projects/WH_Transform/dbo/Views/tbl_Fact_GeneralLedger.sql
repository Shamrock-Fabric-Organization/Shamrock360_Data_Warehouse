-- Auto Generated (Do not modify) FAFCC21D9C4D4347E81E1EA14FEF179D8C1B6CC5AC5B81BB2947FD04C60D2547



CREATE OR ALTER VIEW [dbo].[tbl_Fact_GeneralLedger] AS
SELECT CASE 
		WHEN LD.GL_Account IS NULL
			THEN ma.mainaccountid
		ELSE LD.GL_Account
		END GL_Account
	,ISNULL(gl.GL_AccountKey, -1) GL_AccountKey
	,gje.accountingdate
	,CONVERT(INT, convert(CHAR(8), gje.accountingdate, 112)) accountingdatekey
	,transactioncurrencyamount
	---- ADDED: transactioncurrencyamount converted (TXN basis · FROM transactioncurrencycode) ----
	,CASE WHEN transactioncurrencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_USD
	,CASE WHEN transactioncurrencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_EUR
	,CASE WHEN transactioncurrencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * transactioncurrencyamount AS transactioncurrencyamount_CNY
	,accountingcurrencyamount
	---- ADDED: accountingcurrencyamount converted (MST/accounting basis · FROM cmp.accountingcurrency) ----
	,CASE WHEN cmp.accountingcurrency = 'USD' THEN 1.0 ELSE erAcctUSD.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_USD
	,CASE WHEN cmp.accountingcurrency = 'EUR' THEN 1.0 ELSE erAcctEUR.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_EUR
	,CASE WHEN cmp.accountingcurrency = 'CNY' THEN 1.0 ELSE erAcctCNY.ExchangeRate END * accountingcurrencyamount AS accountingcurrencyamount_CNY
	,reportingcurrencyamount   -- INTENTIONALLY NOT CONVERTED: already the group reporting currency
	,quantity
	,iscorrection
	,iscorrection_$label
	,iscredit
	,iscredit_$label
	,transactioncurrencycode
	,paymentreference
	,gjae.postingtype
	,gjae.postingtype_$label
	,gjae.ledgerdimension
	,generaljournalentry
	,mainaccount
	--, LD.GL_Account
	--, ma.mainaccountid
	,TEXT
	,reasonref
	,gjae.recid
	,ledgeraccount
	,gje.documentdate
	,gje.createdby
	,gje.createddatetime
	,gje.fiscalcalendarperiod
	,fcp.type FiscalCalendarPeriodType
	,fcp.type_$label FiscalCalendarPeriodType_$label
	,gje.journalcategory
	,gje.journalcategory_$label
	,gje.journalnumber
	,gje.ledger
	,le.name Legal_Entity
	,ISNULL(cmp.Legal_EntityKey, - 1) Legal_EntityKey
	,gje.ledgerentryjournal
	,gje.postinglayer
	,gje.postinglayer_$label
	,gje.subledgervoucher
	,gje.subledgervoucherdataareaid
	,lej.journalnumber lej_journalnumber
	,lej.ledgerjournaltabledataareaid
	,ljt.approver
	,ljt.dataareaid
	,ljt.journalnum
	,LD.Business_Unit
	,LD.Department
	,LD.Product_Line
	,LD.Site
	,ISNULL(d.DepartmentKey, -1) DepartmentKey
	,ISNULL(ds.SiteKey, -1) SiteKey
	---- ADDED: audit / lineage columns exposing each basis' FROM currency ----
	,transactioncurrencycode AS Txn_Source_Currency      -- FROM currency for the TXN basis
	,cmp.accountingcurrency  AS Cost_Source_Currency      -- FROM currency for the MST/accounting basis
	---- ADDED: rate-missing flags (1 = a non-identity conversion could not find a rate row) ----
	,CASE WHEN transactioncurrencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
	,CASE WHEN transactioncurrencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
	,CASE WHEN transactioncurrencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
	,CASE WHEN cmp.accountingcurrency <> 'USD' AND erAcctUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_USD_Rate_Missing
	,CASE WHEN cmp.accountingcurrency <> 'EUR' AND erAcctEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_EUR_Rate_Missing
	,CASE WHEN cmp.accountingcurrency <> 'CNY' AND erAcctCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Acct_CNY_Rate_Missing
FROM WH_Raw.dbo.generaljournalaccountentry gjae

JOIN WH_Raw.dbo.generaljournalentry gje
	ON gjae.generaljournalentry = gje.recid

LEFT JOIN WH_Raw.dbo.vwLedgerDimension LD
	ON gjae.ledgerdimension = LD.LedgerDimension

LEFT JOIN WH_Raw.dbo.mainaccount ma
	ON gjae.mainaccount = ma.recid

LEFT JOIN WH_Raw.dbo.fiscalcalendarperiod fcp
	ON gje.fiscalcalendarperiod = fcp.recid

LEFT JOIN WH_Raw.dbo.ledger le
	ON gje.ledger = le.recid

LEFT JOIN WH_Raw.dbo.ledgerentryjournal lej
	ON gje.ledgerentryjournal = lej.recid

LEFT JOIN WH_Raw.dbo.ledgerjournaltable ljt
	ON gje.subledgervoucherdataareaid = ljt.dataareaid
		AND lej.journalnumber = ljt.journalnum

LEFT JOIN [dbo].[tbl_DIM_Legal_Entity] cmp
	ON le.name = cmp.CMPNY

LEFT JOIN WH_Transform.[dbo].[tbl_DIM_GL_Account] gl
	ON CASE 
		WHEN LD.GL_Account IS NULL
			THEN ma.mainaccountid
		ELSE LD.GL_Account
		END = gl.GL_Account_Number

LEFT JOIN WH_Transform.[dbo].[tbl_DIM_Department] d
	ON LD.Department = d.Department

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON LD.Site = ds.Site_ID
		AND gje.subledgervoucherdataareaid = ds.CMPNY
		AND ds.RecordStatus=1

/* =====================================================================================
   ADDED — Exchange-rate joins (additive; do not affect the original join graph)
   All TXN-basis money columns share erTxn* ; all MST/accounting-basis columns share
   erAcct*. Date = gje.accountingdate, normalized to a clean date for the BETWEEN.
   ===================================================================================== */

-- TXN basis: FROM = transactioncurrencycode, at the GL accounting/posting date
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
	ON erTxnUSD.fromcurrencycode = transactioncurrencycode
	AND erTxnUSD.tocurrencycode   = 'USD'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erTxnUSD.validfrom AND erTxnUSD.validto
	AND erTxnUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = transactioncurrencycode
	AND erTxnEUR.tocurrencycode   = 'EUR'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erTxnEUR.validfrom AND erTxnEUR.validto
	AND erTxnEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = transactioncurrencycode
	AND erTxnCNY.tocurrencycode   = 'CNY'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erTxnCNY.validfrom AND erTxnCNY.validto
	AND erTxnCNY.exchangeratetype = 'Default global rate'

-- MST / accounting basis: FROM = cmp.accountingcurrency, at the GL accounting/posting date
LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctUSD
	ON erAcctUSD.fromcurrencycode = cmp.accountingcurrency
	AND erAcctUSD.tocurrencycode   = 'USD'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erAcctUSD.validfrom AND erAcctUSD.validto
	AND erAcctUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctEUR
	ON erAcctEUR.fromcurrencycode = cmp.accountingcurrency
	AND erAcctEUR.tocurrencycode   = 'EUR'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erAcctEUR.validfrom AND erAcctEUR.validto
	AND erAcctEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erAcctCNY
	ON erAcctCNY.fromcurrencycode = cmp.accountingcurrency
	AND erAcctCNY.tocurrencycode   = 'CNY'
	AND convert(date, convert(char(8), gje.accountingdate, 112)) BETWEEN erAcctCNY.validfrom AND erAcctCNY.validto
	AND erAcctCNY.exchangeratetype = 'Default global rate'

