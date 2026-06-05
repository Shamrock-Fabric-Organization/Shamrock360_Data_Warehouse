-- Auto Generated (Do not modify) D56156621A26DD3A0760704FD703A206C77D3638DDDB34B0DC3138A2CD7450C0
/****** Object:  View [dbo].[tbl_Fact_PlannedPurchaseTransferProd_Orders]    Script Date: 3/6/2026 1:53:24 PM ******/
/****** Object:  View [dbo].[tbl_Fact_PlannedPurchaseTransferProd_Orders]    Script Date: 2/2/2026 3:48:59 PM ******/



--Need to change dim_product to include phantoms for the prod order part

CREATE             VIEW [dbo].[tbl_Fact_PlannedPurchaseTransferProd_Orders] AS 		
SELECT 
CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT (
				NEWID()
				,GETDATE()
				))) RecordID
	,rpo.dataareaid CMPNY
	,rpo.RefId
	,rpo.reftype
	,CASE 
		WHEN rpo.reftype_$label = 'ItemPlannedOrder' THEN 'Planned purchase orders'
		WHEN rpo.reftype_$label = 'TransferPlannedOrder' THEN 'Planned transfer'
		WHEN rpo.reftype_$label = 'PmfPlannedProdBatch' THEN 'Planned batch order'
		ELSE rpo.reftype_$label
	 END reftype_$label
	,rpo.ItemId
	,rp.reqplanid
	,rp.name ReqPlanName
	,rpo.Qty AS RequirementQuantity
	,ITMi.unitid Inventory_UoM
	,ITMp.unitid Purchasing_UoM
	,ITMs.unitid Sales_UoM
	,rpo.ReqDateOrder AS OrderDate
	, CONVERT(INT, CONVERT(CHAR(8), rpo.ReqDateOrder, 112)) OrderDateKey  
	,rpo.ReqDateDlv DeliveryDate
	, CONVERT(INT, CONVERT(CHAR(8), rpo.ReqDateDlv, 112)) DeliveryDateKey  
	,rt.reqdatedlvorig  RequestedDate
	, CONVERT(INT, CONVERT(CHAR(8), rt.reqdatedlvorig, 112)) RequestedDateKey  
	,isnull(rt.futuresdays, 0) Delay_days
	,rt.actiontype
	,rt.actiontype_$label
	,rpo.vendid Vendor
	,rpo.isderiveddirectly
	,rpo.isderiveddirectly_$label
	,rpo.ReqPOStatus
	,CASE 
		WHEN rpo.reqpostatus_$label = 'Unadministered' THEN 'Unprocessed'
		ELSE rpo.reqpostatus_$label
	 END reqpostatus_$label
	,rpo.leadtime

	, id.inventlocationid  Warehouse
	, id.inventsiteid  SiteID

	, ISNULL(dpc.ProductKey, -1) ProductKey
	----, ISNULL(dpa.ProductKey, -1) AllProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dvc.VendorKey, -1) VendorKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey

FROM WH_Raw.dbo.ReqPO rpo

INNER JOIN WH_Raw.dbo.ReqPlanVersion rpv
	ON rpo.planversion = rpv.recid
		AND rpo.dataareaid = rpv.reqplandataareaid

INNER JOIN WH_Raw.dbo.ReqPlan rp
	ON rpv.reqplanid = rp.reqplanid
		AND rpv.reqplandataareaid = rp.DataAreaId

LEFT JOIN WH_Raw.dbo.ReqTrans rt
	ON rpo.RefType = rt.RefType
		AND rpo.RefId = rt.RefId
		AND rpo.PlanVersion = rt.PlanVersion
		AND rpo.ItemId = rt.ItemId

LEFT JOIN WH_Raw.dbo.InventTableModule ITMi
	ON rpo.ItemId = ITMi.ItemId
		AND rpo.dataareaid = ITMi.DataAreaId
		AND ITMi.moduletype = 0

LEFT JOIN WH_Raw.dbo.InventTableModule ITMp
	ON rpo.ItemId = ITMp.ItemId
		AND rpo.dataareaid = ITMp.DataAreaId
		AND ITMp.moduletype = 1

LEFT JOIN WH_Raw.dbo.InventTableModule ITMs
	ON rpo.ItemId = ITMs.ItemId
		AND rpo.dataareaid = ITMs.DataAreaId
		AND ITMs.moduletype = 2

LEFT JOIN WH_Raw.dbo.InventDim id
	ON rpo.covinventdimid = id.inventdimid
		AND rpo.dataareaid = id.DataAreaId


----LEFT JOIN WH_Transform.dbo.tbl_DIM_Product_All dpa
----	ON rpo.itemid = dpa.Product_ID
----		AND rpo.dataareaid = dpa.CMPNY
----		AND dpa.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON rpo.itemid = dpc.Product_ID
		AND rpo.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON rpo.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dvc
	ON rpo.vendid = dvc.Vendor_ID
		AND rpo.dataareaid = dvc.CMPNY
		AND dvc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON rpo.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND rpo.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1