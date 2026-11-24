
CREATE OR ALTER VIEW [dbo].[tbl_Fact_Customer_Invoice_Charges]
as
select  mt.dataareaid CMPNY
, cij.invoiceid Invoice_ID
, cij.invoicedate InvoiceDate
, convert(int, convert(char(8), cij.invoicedate,112)) InvoiceDateKey
, isnull(case when cij.salesid = '' then null else cij.salesid end, 'none') Sales_ID   -- a blank counts as NULL. The D365 link can store a blank as '' instead of NULL.
, mt.markupcode MarkupCode
, mt.linenum LineNum
, mt.transrecid TransRecId

, mt.calculatedamount CalculatedAmount
, mt.currencycode CurrencyCode

, CASE WHEN mt.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * mt.calculatedamount CalculatedAmount_USD
, CASE WHEN mt.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * mt.calculatedamount CalculatedAmount_EUR
, CASE WHEN mt.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * mt.calculatedamount CalculatedAmount_CNY
, 'D365FO' Source

, ISNULL(dinv.InvoiceKey, -1) InvoiceKey
, ISNULL(dch.InvoiceChargeKey, -1) InvoiceChargeKey
, ISNULL(dc.CustomerKey, -1) CustomerKey
, ISNULL(dic.CustomerKey, -1) InvoiceCustomerKey
, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
, ISNULL(dso.SalesOrderKey, -1) SalesOrderKey
, ISNULL(da.AddressKey, -1) DeliveryAddressKey
, ISNULL(dect.EmployeeKey, -1) CustAcct_EmployeeKey
-- Rate_Missing flags: 1 when a NON-identity conversion found no matching rate row (else 0).
, CASE WHEN mt.currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END Txn_USD_Rate_Missing
, CASE WHEN mt.currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END Txn_EUR_Rate_Missing
, CASE WHEN mt.currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END Txn_CNY_Rate_Missing

from WH_Raw.dbo.markuptrans mt
join WH_Raw.dbo.custinvoicejour cij
  on mt.transrecid = cij.recid
    and mt.dataareaid = cij.dataareaid

-- =========================== Dimension keys ===========================
LEFT JOIN WH_Transform.dbo.tbl_DIM_Invoice dinv
	ON mt.dataareaid = dinv.CMPNY
		AND cij.invoiceid = dinv.Invoice_ID
		AND cij.invoicedate = dinv.InvoiceDate
		AND isnull(case when cij.salesid = '' then null else cij.salesid end, 'none') = dinv.Sales_ID   -- a blank counts as NULL. The D365 link can store a blank as '' instead of NULL.
		AND dinv.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_InvoiceCharge dch
	ON mt.dataareaid = dch.CMPNY
		AND mt.markupcode = dch.MarkupCode
		AND dch.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
	ON cij.orderaccount = dc.Customer_ID
		AND cij.dataareaid = dc.CMPNY
		AND cij.createddatetime between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dic
	ON cij.invoiceaccount = dic.Customer_ID
		AND cij.dataareaid = dic.CMPNY
		AND cij.createddatetime between dic.RecordEffectiveStartDate and dic.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON cij.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SalesOrder dso
	ON cij.salesid = dso.SalesOrderId
		AND cij.dataareaid = dso.CMPNY
		AND dso.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Address da
	ON cij.deliverypostaladdress = da.AddressRecID
		AND da.RecordStatus=1

-- Salestable Customer CustomerAccount EmployeeKey (same joins as tbl_Fact_Customer_Invoices, from the invoice header sales order)
LEFT JOIN WH_Raw.dbo.salestable ST
    ON cij.salesid = ST.salesid
        AND cij.dataareaid = ST.dataareaid

LEFT JOIN WH_Raw.dbo.CustTable CT
	ON ST.custaccount = CT.accountnum
		AND ST.dataareaid = CT.dataareaid

LEFT JOIN WH_Raw.dbo.hcmworker HCM
	ON ST.workersalesresponsible = HCM.recid

LEFT JOIN WH_Raw.dbo.hcmworker HCMct
	ON CT.maincontactworker = HCMct.recid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee dect
	ON coalesce(HCMct.personnelnumber, HCM.personnelnumber) = dect.Personnel_Number
		AND dect.RecordStatus=1

-- =========================== Exchange-rate joins (currency conversion) ===========================
-- TXN-BASIS joins: fromcurrencycode = mt.currencycode (transaction currency of the charge), invoice date, 'Default global rate'.
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON erTxnUSD.fromcurrencycode = mt.currencycode
   AND erTxnUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), cij.invoicedate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
   AND erTxnUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON erTxnEUR.fromcurrencycode = mt.currencycode
   AND erTxnEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), cij.invoicedate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
   AND erTxnEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON erTxnCNY.fromcurrencycode = mt.currencycode
   AND erTxnCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), cij.invoicedate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
   AND erTxnCNY.exchangeratetype = 'Default global rate'

where mt.transtableid = 11259
-- ========================================================================================================
