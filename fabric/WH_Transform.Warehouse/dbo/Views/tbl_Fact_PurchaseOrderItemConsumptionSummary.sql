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
CREATE     VIEW [dbo].[tbl_Fact_PurchaseOrderItemConsumptionSummary] 
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
, purchqty
, qtyordered
, purchunit
, QtyOrdered_LBs
, vendaccount
, Inventory_UoM
, COUNT(Distinct FinishedGoodProductID) NumberFinishedGoods
, SUM(isnull(qty,0)) remaining_qty
, (QtyOrdered_LBs - SUM(isnull(qty,0))) consumed_qty
, CASE WHEN ISNULL(QtyOrdered_LBs, 0) = 0 then NULL ELSE ((SUM(isnull(qty,0))) / QtyOrdered_LBs) END remaining_pct
, CASE WHEN ISNULL(QtyOrdered_LBs, 0) = 0 then NULL ELSE ((QtyOrdered_LBs - SUM(isnull(qty,0))) / QtyOrdered_LBs) END consumed_pct

, SUM(costamountphysical) costamountphysical
, SUM(costamountadjustment) costamountadjustment
, SUM(costamountposted) costamountposted
, SUM(costamountNet) costamountNet

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
		, pl.purchqty
		, pl.qtyordered
		, pl.purchunit
			, case when pl.purchunit = 'lb' then 1 
				else coalesce(UOMC_lb.UOMConversionFactor, UOMC_lb_generic.UOMConversionFactor) end * pl.qtyordered	QtyOrdered_LBs
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
		, i.costamountadjustment
		, i.costamountposted
		, i.costamountadjustment + i.costamountposted costamountNet
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