-- Auto Generated (Do not modify) C38C2737C81A5EBDB9A1A16DA1773F629C3AD30CBFB4D29569FB2FFE215CD907

/****** Object:  View [dbo].[tbl_Fact_PurchaseOrderItemConsumption]    Script Date: 3/6/2026 1:54:14 PM ******/
--use WH_Transform
--go


--DROP VIEW fact_PurchaseOrderItemConsumption

CREATE   VIEW [dbo].[tbl_Fact_PurchaseOrderItemConsumption] as
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
	----, ISNULL(dpa.ProductKey, -1) AllProductKey
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