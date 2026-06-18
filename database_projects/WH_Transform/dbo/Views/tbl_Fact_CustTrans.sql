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



CREATE   VIEW tbl_Fact_CustTrans
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