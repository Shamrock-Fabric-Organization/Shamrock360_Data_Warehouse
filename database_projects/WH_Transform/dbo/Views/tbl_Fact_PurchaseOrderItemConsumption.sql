-- Auto Generated (Do not modify) C38C2737C81A5EBDB9A1A16DA1773F629C3AD30CBFB4D29569FB2FFE215CD907
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrderItemConsumption]    Script Date: 3/6/2026 1:54:14 PM ******/
--use WH_Transform
--go


--DROP VIEW fact_PurchaseOrderItemConsumption

CREATE OR ALTER    VIEW [dbo].[tbl_Fact_PurchaseOrderItemConsumption] as
select pt.dataareaid CMPNY
, pt.purchid PurchaseOrderNumber
, pl.linenumber
, pl.itemid ProductID
, pl.inventdimid
, id.inventbatchid  BatchID
, id.inventsiteid  SiteID
, id.inventlocationid  Warehouse
, id.licenseplateid
	--,iigi.itemgroupid
	--,iig.name AS ItemGroupName
, pl.purchstatus_$label pl_purchstatus_label
, pt.purchstatus_$label pt_purchstatus_label
, pl.inventtransid
, pl.currencycode curreny_code
, pl.lineamount
-- ===== ADDED: TXN-basis conversion of pl.lineamount (FROM = pt.currencycode, PO document currency) =====
, CASE WHEN pl.currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * pl.lineamount AS lineamount_USD
, CASE WHEN pl.currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * pl.lineamount AS lineamount_EUR
, CASE WHEN pl.currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * pl.lineamount AS lineamount_CNY
, pl.purchqty
, pl.qtyordered
, pl.purchunit
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
	
, pl.vendaccount

, ito.referencecategory
, ito.referencecategory_$label
, ito.referenceid
, pbo.itemid FinishedGoodProductID
, FG.ProductName FinishedGoodName
, FG.Commercial_Name FinishedGoodCommercialName
, dp.Inventory_UoM
, i.qty
, i.costamountphysical
-- ===== ADDED: COST/MST-basis conversion of i.costamountphysical (FROM = dle.accountingcurrency) =====
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountphysical AS costamountphysical_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountphysical AS costamountphysical_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountphysical AS costamountphysical_CNY
, i.costamountadjustment
-- ===== ADDED: COST/MST-basis conversion of i.costamountadjustment =====
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountadjustment AS costamountadjustment_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountadjustment AS costamountadjustment_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountadjustment AS costamountadjustment_CNY
, i.costamountposted
-- ===== ADDED: COST/MST-basis conversion of i.costamountposted =====
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountposted AS costamountposted_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountposted AS costamountposted_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountposted AS costamountposted_CNY
, i.costamountadjustment + i.costamountposted costamountNet
-- ===== ADDED: COST/MST-basis conversion of costamountNet (= adjustment + posted) =====
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * (i.costamountadjustment + i.costamountposted) AS costamountNet_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * (i.costamountadjustment + i.costamountposted) AS costamountNet_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * (i.costamountadjustment + i.costamountposted) AS costamountNet_CNY
, i.currencycode
, i.dateexpected
, i.datephysical
, i.datefinancial
, i.inventtransorigin
, i.invoiceid
, i.packingslipid
, i.voucher
, i.voucherphysical
, i.statusissue
, i.statusissue_$label
, i.statusreceipt
, i.statusreceipt_$label

	, ISNULL(dv.VendorKey, -1) VendorKey
	, ISNULL(div.VendorKey, -1) InvoiceVendorKey
	, ISNULL(dp.ProductKey, -1) ProductKey
	----, ISNULL(dpa.ProductKey, -1) AllProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(de.EmployeeKey, -1) EmployeeKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(dpo.PurchaseOrderKey, -1)  PurchaseOrerKey
	, ISNULL(db.BatchKey, -1)  BatchKey

-- ===== ADDED: currency-conversion AUDIT columns (FROM-currency exposure) =====
, dle.accountingcurrency AS Cost_Source_Currency          -- FROM currency for all COST/MST conversions
, pt.currencycode        AS Txn_Source_Currency           -- FROM currency for lineamount (PO document currency)

-- ===== ADDED: Rate_Missing flags (1 = no rate row found for a non-identity conversion) =====
, CASE WHEN pl.currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
, CASE WHEN pl.currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
, CASE WHEN pl.currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'USD' AND erCostUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_USD_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'EUR' AND erCostEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_EUR_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'CNY' AND erCostCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_CNY_Rate_Missing

from WH_Raw.dbo.purchtable pt
  join WH_Raw.dbo.purchline pl
    on pt.dataareaid = pl.dataareaid
      and pt.purchid = pl.purchid
  join WH_Raw.dbo.inventdim id
    on id.dataareaid = pl.dataareaid
      and id.inventdimid = pl.inventdimid
LEFT JOIN WH_Raw.dbo.InventItemGroupItem iigi 
    ON pl.ItemId = iigi.ItemId
    AND pl.DATAAREAID = iigi.ItemDataAreaId
LEFT JOIN WH_Raw.dbo.InventItemGroup iig
    ON iigi.ItemGroupId = iig.ItemGroupId
    AND iigi.ItemGroupDataAreaId = iig.DATAAREAID

LEFT JOIN (WH_Raw.dbo.inventtrans i
        JOIN WH_Raw.dbo.inventdim iid
          on i.inventdimid = iid.inventdimid
            and i.dataareaid = iid.dataareaid)
    on pl.itemid = i.itemid
      and pl.dataareaid = i.dataareaid
      and id.inventbatchid = iid.inventbatchid
LEFT JOIN WH_Raw.dbo.inventtransorigin ito
    on i.inventtransorigin = ito.recid


LEFT JOIN WH_Raw.dbo.InventTable IT
	ON pl.itemid = IT.itemid
		AND pl.dataareaid = IT.dataareaid

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

LEFT JOIN WH_Raw.dbo.prodtable pbo
	ON ito.referenceid = pbo.prodid
	  AND ito.dataareaid = pbo.dataareaid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product FG
	ON pbo.itemid = FG.Product_ID
		AND pbo.dataareaid = FG.CMPNY
		AND FG.RecordStatus=1

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

-- =================================================================================================
-- ADDED: Exchange-rate joins (additive). NO PARTITION in any join. Set-based LEFT JOINs.
-- All TXN-basis columns share erTxn* ; all COST-basis columns share erCost*. One set per basis.
-- Date driver for BOTH bases: i.datefinancial, normalized convert(date,convert(char(8),...,112)).
-- =================================================================================================

-- TXN basis (FROM = pt.currencycode = PO document currency)
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON erTxnUSD.fromcurrencycode = pl.currencycode
   AND erTxnUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
   AND erTxnUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON erTxnEUR.fromcurrencycode = pl.currencycode
   AND erTxnEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
   AND erTxnEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON erTxnCNY.fromcurrencycode = pl.currencycode
   AND erTxnCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
   AND erTxnCNY.exchangeratetype = 'Default global rate'

-- COST / MST basis (FROM = dle.accountingcurrency = legal-entity accounting currency)
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostUSD
    ON erCostUSD.fromcurrencycode = dle.accountingcurrency
   AND erCostUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erCostUSD.validfrom and erCostUSD.validto
   AND erCostUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostEUR
    ON erCostEUR.fromcurrencycode = dle.accountingcurrency
   AND erCostEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erCostEUR.validfrom and erCostEUR.validto
   AND erCostEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostCNY
    ON erCostCNY.fromcurrencycode = dle.accountingcurrency
   AND erCostCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), i.datefinancial, 112)) between erCostCNY.validfrom and erCostCNY.validto
   AND erCostCNY.exchangeratetype = 'Default global rate'

where pl.itemid is not null
