-- Auto Generated (Do not modify) EE3009FA922F6F5FBD3472B468E42D18EB3F4252683756C1D3A889A37A797CAF

/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 4/13/2026 2:40:36 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 3/6/2026 1:55:34 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/12/2026 11:23:26 AM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/10/2026 12:30:36 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/2/2026 3:47:12 PM ******/



CREATE  OR ALTER                   VIEW [dbo].[tbl_Fact_PurchaseOrders] AS 		
SELECT 
	pl.dataareaid CMPNY
	, pl.purchid PurchaseOrderNumber
	, pl.inventtransid
	, pl.itemid
	, pl.vendaccount
	, pt.invoiceaccount
	, pl.procurementcategory
	, erc.name procurementcategoryname
	, pl.name
	, pl.purchunit
	, pl.purchqty  qtyordered
		, CASE
			WHEN pl.purchunit = 'lb' THEN 1                                               -- already in LB
			WHEN coalesce(UOMC_lb.UOMConversionFactor, UOMC_lb_generic.UOMConversionFactor) IS NOT NULL THEN coalesce(UOMC_lb.UOMConversionFactor, UOMC_lb_generic.UOMConversionFactor)  -- direct sales-unit -> LB conversion
			ELSE (case when pl.purchunit = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) * 2.20462262185 -- fallback: convert KG -> LB (1 / 0.45359237)
		END * pl.purchqty      QtyOrdered_LBs

		, CASE
			WHEN pl.purchunit = 'kg' THEN 1                                               -- already in KG
			WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor  -- direct sales-unit -> KG conversion
			ELSE (case when pl.purchunit = 'lb' then 1 else coalesce(UOMC_lb.UOMConversionFactor, UOMC_lb_generic.UOMConversionFactor) end ) * 0.45359237  -- fallback: convert LBs -> KG
		END * pl.purchqty      QtyOrdered_KGs
	, pl.remainpurchphysical
	, pl.remainpurchfinancial
	, pl.remainpurchphysical + pl.remainpurchfinancial  OutstandingQTY
	, pl.purchstatus
	, pl.purchstatus_$label
	, pl.returnstatus
	, pl.returnstatus_$label
	, pl.lineamount
	, CASE WHEN pl.qtyordered = 0 then NULL else 
		CASE WHEN (pl.remainpurchphysical + pl.remainpurchfinancial) = 0 THEN 0
		ELSE (((pl.remainpurchphysical + pl.remainpurchfinancial) / pl.qtyordered ) * pl.lineamount ) END END OutstandingLineAmount
	, pl.inventdimid

	, id.[inventbatchid]
	, id.[inventlocationid]
	, id.[inventsiteid]
	, id.[inventstatusid]
	--, id.
	--, id.

	, pl.purchasetype
	, pl.purchasetype_$label
	, pl.currencycode
	, pl.deliverydate
	, convert(int, convert(char(8),pl.deliverydate,112))	DeliveryDateKey

	, pl.purchprice
	, pl.linenumber
	, pl.priceunit
	, pl.confirmeddlv
	, convert(int, convert(char(8),pl.confirmeddlv,112))	ConfirmedDeliveryDateKey
	, CASE WHEN pl.confirmeddlv = '1900-01-01' THEN pl.deliverydate ELSE pl.confirmeddlv END  ConfirmedOrRequestedReceiptDate
	, convert(int, convert(char(8),CASE WHEN pl.confirmeddlv = '1900-01-01' THEN pl.deliverydate ELSE pl.confirmeddlv END,112))	ConfirmedOrRequestedReceiptDateKey

	, pl.createddatetime
	, convert(int, convert(char(8),pl.createddatetime,112))	CreatedDateKey
	, pt.createddatetime  PurchOrder_CreatedDateTime
	, convert(int, convert(char(8),pt.createddatetime,112))	PurchOrder_CreatedDateKey
	, hcm.personnelnumber
	, pdt.amount DiscountPrice
	, pdt.priceunit DiscountPriceUnit
	, ISNULL(dv.VendorKey, -1) VendorKey
	, ISNULL(div.VendorKey, -1) InvoiceVendorKey
	, ISNULL(dp.ProductKey, -1) ProductKey
	--, ISNULL(dpa.ProductKey, -1) AllProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(de.EmployeeKey, -1) EmployeeKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(dpo.PurchaseOrderKey, -1)  PurchaseOrerKey
	, ISNULL(db.BatchKey, -1)  BatchKey

-- ============================================================================
-- MULTI-CURRENCY CONVERSION — TXN BASIS (FROM pl.currencycode)
-- Date for rate effective period: pl.deliverydate (order/delivery date).
-- Identity guard: when the row currency already equals the target, rate = 1.0.
-- All txn-basis money columns share the single erTxnUSD/EUR/CNY join set below.
-- ============================================================================
	, pl.currencycode AS Txn_Source_Currency   -- audit: FROM currency for txn basis

	-- lineamount -> USD / EUR / CNY
	, CASE WHEN pl.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * pl.lineamount AS lineamount_USD
	, CASE WHEN pl.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * pl.lineamount AS lineamount_EUR
	, CASE WHEN pl.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * pl.lineamount AS lineamount_CNY

	-- OutstandingLineAmount (derived) -> USD / EUR / CNY (rate applied to the same derived expression)
	, CASE WHEN pl.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END *
		(CASE WHEN pl.purchqty = 0 then NULL else 
			CASE WHEN (pl.remainpurchphysical + pl.remainpurchfinancial) = 0 THEN 0
			ELSE (((pl.remainpurchphysical + pl.remainpurchfinancial) / pl.purchqty ) * pl.lineamount ) END END) AS OutstandingLineAmount_USD
	, CASE WHEN pl.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END *
		(CASE WHEN pl.purchqty = 0 then NULL else 
			CASE WHEN (pl.remainpurchphysical + pl.remainpurchfinancial) = 0 THEN 0
			ELSE (((pl.remainpurchphysical + pl.remainpurchfinancial) / pl.purchqty ) * pl.lineamount ) END END) AS OutstandingLineAmount_EUR
	, CASE WHEN pl.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END *
		(CASE WHEN pl.purchqty = 0 then NULL else 
			CASE WHEN (pl.remainpurchphysical + pl.remainpurchfinancial) = 0 THEN 0
			ELSE (((pl.remainpurchphysical + pl.remainpurchfinancial) / pl.purchqty ) * pl.lineamount ) END END) AS OutstandingLineAmount_CNY

	-- purchprice -> USD / EUR / CNY
	, CASE WHEN pl.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * pl.purchprice AS purchprice_USD
	, CASE WHEN pl.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * pl.purchprice AS purchprice_EUR
	, CASE WHEN pl.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * pl.purchprice AS purchprice_CNY

	-- DiscountPrice (pdt.amount) -> USD / EUR / CNY
	-- converted FROM pdt.currency (PriceDiscTable.Currency), the
	-- currency the trade-agreement Amount is actually denominated in — NOT
	-- pl.currencycode. 
	, pdt.currency AS Disc_Source_Currency   -- audit: FROM currency for the discount/price basis
	, CASE WHEN pdt.currency = 'USD' THEN 1.0 ELSE erDiscUSD.ExchangeRate END * pdt.amount AS DiscountPrice_USD
	, CASE WHEN pdt.currency = 'EUR' THEN 1.0 ELSE erDiscEUR.ExchangeRate END * pdt.amount AS DiscountPrice_EUR
	, CASE WHEN pdt.currency = 'CNY' THEN 1.0 ELSE erDiscCNY.ExchangeRate END * pdt.amount AS DiscountPrice_CNY

	-- Rate-missing flags (1 = no matching rate row and currency differs from target)
	, CASE WHEN pl.currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
	, CASE WHEN pl.currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
	, CASE WHEN pl.currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing

	-- Discount/price (pdt.amount) rate-missing flags — only meaningful when a trade
	, CASE WHEN pdt.currency IS NOT NULL AND pdt.currency <> 'USD' AND erDiscUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Disc_USD_Rate_Missing
	, CASE WHEN pdt.currency IS NOT NULL AND pdt.currency <> 'EUR' AND erDiscEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Disc_EUR_Rate_Missing
	, CASE WHEN pdt.currency IS NOT NULL AND pdt.currency <> 'CNY' AND erDiscCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Disc_CNY_Rate_Missing

FROM WH_Raw.dbo.purchline pl
	JOIN WH_Raw.dbo.purchtable pt
	  ON pl.purchid = pt.purchid
	    AND pl.dataareaid = pt.dataareaid

LEFT JOIN WH_Raw.dbo.InventTable IT
	ON pl.itemid = IT.itemid
		AND pl.dataareaid = IT.dataareaid

LEFT JOIN WH_Raw.dbo.ecorescategory erc
	ON pl.procurementcategory = erc.recid

LEFT JOIN WH_Raw.dbo.InventDIM ID
	ON pl.inventdimid = ID.inventdimid
		AND pl.dataareaid = ID.dataareaid

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND pl.purchunit = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb_generic
    ON UOMC_lb_generic.product = 0
	    AND pl.purchunit = UOMC_lb_generic.SYMBOLFROM
		AND UOMC_lb_generic.SYMBOLTO = 'lb'

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
	ON IT.product = UOMC_kg.product
		AND pl.purchunit = UOMC_kg.SYMBOLFROM
		AND UOMC_kg.SYMBOLTO = 'kg'
		
LEFT JOIN WH_Raw.dbo.hcmworker HCM
	ON pt.workerpurchplacer = HCM.recid

LEFT JOIN WH_Raw.dbo.pricedisctable pdt
	ON pdt.dataareaid = pl.dataareaid
		AND pdt.itemrelation = pl.itemid
		AND pl.createddatetime between pdt.fromdate and pdt.todate



LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dv
	ON pl.vendaccount = dv.Vendor_ID
		AND pl.dataareaid = dv.CMPNY
		AND dv.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor div
	ON pt.invoiceaccount = div.Vendor_ID
		AND pl.dataareaid = div.CMPNY
		AND div.RecordStatus=1

--LEFT JOIN WH_Transform.dbo.tbl_DIM_Product_All dpa
--	ON pl.itemid = dpa.Product_ID
--		AND pl.dataareaid = dpa.CMPNY
--		AND dpa.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON pl.itemid = dp.Product_ID
		AND pl.dataareaid = dp.CMPNY
		AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON pl.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee de
	ON HCM.personnelnumber = de.Personnel_Number
		AND de.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON pl.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND pl.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_PurchaseOrder dpo
	  ON pl.purchid = dpo.PurchaseOrderNumber
	    AND pl.dataareaid = dpo.CMPNY
		AND dpo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
	  ON ID.inventbatchid = db.BatchID
	    AND ID.dataareaid = db.CMPNY
		AND pl.itemid = db.ProductID
		AND db.RecordStatus=1

-- ============================================================================
-- TXN-BASIS EXCHANGE-RATE JOINS (FROM pl.currencycode)
-- One shared set of three joins (USD/EUR/CNY) for the txn-basis money columns
-- (lineamount, OutstandingLineAmount, purchprice). DiscountPrice uses its own
-- erDisc* joins (FROM pdt.currency) — see below.
-- Effective date keyed on pl.deliverydate.
-- ============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
	ON erTxnUSD.fromcurrencycode = pl.currencycode
		AND erTxnUSD.tocurrencycode = 'USD'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
		AND erTxnUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = pl.currencycode
		AND erTxnEUR.tocurrencycode = 'EUR'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
		AND erTxnEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = pl.currencycode
		AND erTxnCNY.tocurrencycode = 'CNY'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
		AND erTxnCNY.exchangeratetype = 'Default global rate'

-- ============================================================================
-- DISCOUNT-BASIS EXCHANGE-RATE JOINS (FROM pdt.currency)
-- For DiscountPrice (pdt.amount), which is denominated in PriceDiscTable.Currency
-- NOT the purchase-line currency. Same date key (pl.deliverydate)
-- and 'Default global rate' type as the txn joins. Rows with no matching trade
-- agreement have pdt.currency = NULL, so these joins no-op and DiscountPrice_* = NULL.
-- ============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erDiscUSD
	ON erDiscUSD.fromcurrencycode = pdt.currency
		AND erDiscUSD.tocurrencycode = 'USD'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erDiscUSD.validfrom and erDiscUSD.validto
		AND erDiscUSD.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erDiscEUR
	ON erDiscEUR.fromcurrencycode = pdt.currency
		AND erDiscEUR.tocurrencycode = 'EUR'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erDiscEUR.validfrom and erDiscEUR.validto
		AND erDiscEUR.exchangeratetype = 'Default global rate'

LEFT JOIN WH_Raw.dbo.vwExchangeRate erDiscCNY
	ON erDiscCNY.fromcurrencycode = pdt.currency
		AND erDiscCNY.tocurrencycode = 'CNY'
		AND convert(date, convert(char(8), pl.deliverydate, 112)) between erDiscCNY.validfrom and erDiscCNY.validto
		AND erDiscCNY.exchangeratetype = 'Default global rate'
