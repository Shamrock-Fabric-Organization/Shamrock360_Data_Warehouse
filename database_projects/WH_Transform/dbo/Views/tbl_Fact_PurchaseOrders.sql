
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 4/13/2026 2:40:36 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 3/6/2026 1:55:34 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/12/2026 11:23:26 AM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/10/2026 12:30:36 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PurchaseOrders]    Script Date: 2/2/2026 3:47:12 PM ******/



CREATE                     VIEW [dbo].[tbl_Fact_PurchaseOrders] AS 		
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
	, case when pl.purchunit = 'lb' then 1 
		else coalesce(UOMC_lb.UOMConversionFactor, UOMC_lb_generic.UOMConversionFactor) end * pl.purchqty	QtyOrdered_LBs
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

GO

