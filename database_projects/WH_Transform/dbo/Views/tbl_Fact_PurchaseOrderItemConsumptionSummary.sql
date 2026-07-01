-- Auto Generated (Do not modify) 642A1DDAA044535EFEA08BDFEBA4F04B764FA767010B43F20CE649288F1E45D9
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrderItemConsumptionSummary]    Script Date: 3/6/2026 1:54:46 PM ******/

/*
Select f.*
from 
tbl_Fact_PurchaseOrders f
join tbl_Dim_Product_All p
  on f.AllProductKey = p.ProductKey
where itemgroupid is not null
--and f.batchkey = -1
*/
/*

----Full Line level detail for inventory consumption
Select f.*
from 
fact_PurchaseOrderItemConsumption f
order by 1,2,3,4
*/


----Summary Purchase Order Level consumption
CREATE OR ALTER    VIEW [dbo].[tbl_Fact_PurchaseOrderItemConsumptionSummary] 
as
select CMPNY
, PurchaseOrderNumber
, linenumber
, ProductID
, inventdimid
, BatchID
, SiteID
, Warehouse
, licenseplateid
	--,iigi.itemgroupid
	--,iig.name AS ItemGroupName
, pl_purchstatus_label
, pt_purchstatus_label
, inventtransid
, lineamount
-- ===== ADDED: TXN-basis converted lineamount (MAX = one representative per line; see header caveat) =====
, MAX(lineamount_USD) lineamount_USD
, MAX(lineamount_EUR) lineamount_EUR
, MAX(lineamount_CNY) lineamount_CNY
, purchqty
, qtyordered
, purchunit
, QtyOrdered_LBs
, QtyOrdered_KGs
, vendaccount
, Inventory_UoM
, COUNT(Distinct FinishedGoodProductID) NumberFinishedGoods
, SUM(isnull(qty,0)) remaining_qty
, (QtyOrdered_LBs - SUM(isnull(qty,0))) consumed_qty
, CASE WHEN ISNULL(QtyOrdered_LBs, 0) = 0 then NULL ELSE ((SUM(isnull(qty,0))) / QtyOrdered_LBs) END remaining_pct
, CASE WHEN ISNULL(QtyOrdered_LBs, 0) = 0 then NULL ELSE ((QtyOrdered_LBs - SUM(isnull(qty,0))) / QtyOrdered_LBs) END consumed_pct

, SUM(costamountphysical) costamountphysical
-- ===== ADDED: COST/MST-basis converted costamountphysical (convert-then-aggregate: SUM of per-row converted) =====
, SUM(costamountphysical_USD) costamountphysical_USD
, SUM(costamountphysical_EUR) costamountphysical_EUR
, SUM(costamountphysical_CNY) costamountphysical_CNY
, SUM(costamountadjustment) costamountadjustment
-- ===== ADDED: COST/MST-basis converted costamountadjustment =====
, SUM(costamountadjustment_USD) costamountadjustment_USD
, SUM(costamountadjustment_EUR) costamountadjustment_EUR
, SUM(costamountadjustment_CNY) costamountadjustment_CNY
, SUM(costamountposted) costamountposted
-- ===== ADDED: COST/MST-basis converted costamountposted =====
, SUM(costamountposted_USD) costamountposted_USD
, SUM(costamountposted_EUR) costamountposted_EUR
, SUM(costamountposted_CNY) costamountposted_CNY
, SUM(costamountNet) costamountNet
-- ===== ADDED: COST/MST-basis converted costamountNet =====
, SUM(costamountNet_USD) costamountNet_USD
, SUM(costamountNet_EUR) costamountNet_EUR
, SUM(costamountNet_CNY) costamountNet_CNY

, VendorKey
, InvoiceVendorKey
, ProductKey
--, AllProductKey
, Legal_EntityKey
, EmployeeKey
, SiteKey
, WarehouseKey
, PurchaseOrerKey
, BatchKey

-- ===== ADDED: currency-conversion AUDIT columns (constant per group -> MAX) =====
, MAX(Cost_Source_Currency) Cost_Source_Currency        -- FROM currency for COST/MST conversions
, MAX(Txn_Source_Currency)  Txn_Source_Currency         -- FROM currency for lineamount (PO document currency)

-- ===== ADDED: Rate_Missing flags aggregated to group (1 = any contributing row had no rate) =====
, MAX(Txn_USD_Rate_Missing)  Txn_USD_Rate_Missing
, MAX(Txn_EUR_Rate_Missing)  Txn_EUR_Rate_Missing
, MAX(Txn_CNY_Rate_Missing)  Txn_CNY_Rate_Missing
, MAX(Cost_USD_Rate_Missing) Cost_USD_Rate_Missing
, MAX(Cost_EUR_Rate_Missing) Cost_EUR_Rate_Missing
, MAX(Cost_CNY_Rate_Missing) Cost_CNY_Rate_Missing
from 
		(select pt.dataareaid CMPNY
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
		, pl.lineamount
		-- ===== ADDED: TXN-basis per-row conversion of pl.lineamount (FROM = pl.currencycode) =====
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
		-- ===== ADDED: COST/MST-basis per-row conversion of i.costamountphysical (FROM = dle.accountingcurrency) =====
		, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountphysical AS costamountphysical_USD
		, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountphysical AS costamountphysical_EUR
		, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountphysical AS costamountphysical_CNY
		, i.costamountadjustment
		-- ===== ADDED: COST/MST-basis per-row conversion of i.costamountadjustment =====
		, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountadjustment AS costamountadjustment_USD
		, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountadjustment AS costamountadjustment_EUR
		, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountadjustment AS costamountadjustment_CNY
		, i.costamountposted
		-- ===== ADDED: COST/MST-basis per-row conversion of i.costamountposted =====
		, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END * i.costamountposted AS costamountposted_USD
		, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END * i.costamountposted AS costamountposted_EUR
		, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END * i.costamountposted AS costamountposted_CNY
		, i.costamountadjustment + i.costamountposted costamountNet
		-- ===== ADDED: COST/MST-basis per-row conversion of costamountNet (= adjustment + posted) =====
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
			--, ISNULL(dpa.ProductKey, -1) AllProductKey
			, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
			, ISNULL(de.EmployeeKey, -1) EmployeeKey
			, ISNULL(ds.SiteKey, -1) SiteKey
			, ISNULL(dw.WarehouseKey, -1) WarehouseKey
			, ISNULL(dpo.PurchaseOrderKey, -1)  PurchaseOrerKey
			, ISNULL(db.BatchKey, -1)  BatchKey

		-- ===== ADDED: per-row currency-conversion AUDIT + Rate_Missing flags (rolled up in outer query) =====
		, dle.accountingcurrency AS Cost_Source_Currency
		, pt.currencycode        AS Txn_Source_Currency
		, CASE WHEN pt.currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
		, CASE WHEN pt.currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
		, CASE WHEN pt.currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
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

		-- =========================================================================================
		-- ADDED: Exchange-rate joins (additive, inside the row-level subquery). NO PARTITION.
		-- erTxn* FROM pt.currencycode ; erCost* FROM dle.accountingcurrency. Date = i.datefinancial.
		-- =========================================================================================

		-- TXN basis (FROM = pt.currencycode = PO document currency)
		LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
			ON erTxnUSD.fromcurrencycode = pt.currencycode
		   AND erTxnUSD.tocurrencycode   = 'USD'
		   AND convert(date, convert(char(8), i.datefinancial, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
		   AND erTxnUSD.exchangeratetype = 'Default global rate'
		LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
			ON erTxnEUR.fromcurrencycode = pt.currencycode
		   AND erTxnEUR.tocurrencycode   = 'EUR'
		   AND convert(date, convert(char(8), i.datefinancial, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
		   AND erTxnEUR.exchangeratetype = 'Default global rate'
		LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
			ON erTxnCNY.fromcurrencycode = pt.currencycode
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
		) f

GROUP by CMPNY
, PurchaseOrderNumber
, linenumber
, ProductID
, inventdimid
, BatchID
, SiteID
, Warehouse
, licenseplateid
	--,iigi.itemgroupid
	--,iig.name AS ItemGroupName
, pl_purchstatus_label
, pt_purchstatus_label
, inventtransid
, lineamount
, purchqty
, qtyordered
, purchunit
, QtyOrdered_LBs
, QtyOrdered_KGs
, vendaccount
--, NumberOfFinishedGoods
--, FinishedGoodName
--, FinishedGoodCommercialName
, Inventory_UoM


, VendorKey
, InvoiceVendorKey
, ProductKey
--, AllProductKey
, Legal_EntityKey
, EmployeeKey
, SiteKey
, WarehouseKey
, PurchaseOrerKey
, BatchKey
