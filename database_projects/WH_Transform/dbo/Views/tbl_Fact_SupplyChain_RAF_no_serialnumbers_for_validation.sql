-- Auto Generated (Do not modify) 895D47B0B49C0E0678B61C5FEADD015C13BEC3D33114F00E024D181BB61D227A
/****** Object:  View [dbo].[tbl_Fact_SupplyChain_RAF]    Script Date: 3/11/2026 8:38:02 AM ******/
/****** Object:  View [dbo].[tbl_Fact_SupplyChain_RAF]    Script Date: 2/24/2026 12:50:27 PM ******/

--RAF data
CREATE        VIEW [dbo].[tbl_Fact_SupplyChain_RAF_no_serialnumbers_for_validation] 
AS 
SELECT 
    pjp.dataareaid CMPNY,
    pjp.ProdId,
    pt.ItemId,
    pjp.JournalId,
    pjp.linenum,

    pjt.posteddatetime,
    pjp.qtygood,
    pjp.qtyerror,
    pjp.transdate,
    pjp.voucher,

    pjp.prodfinished,
    pjp.prodfinished_$label,
    pjt.journaltype_$Label

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(db.BatchKey, -1) BatchKey
	, ISNULL(dr.RouteKey, -1) RouteKey
    --,'@@@@'
    --,pjp.*
FROM WH_Raw.dbo.ProdJournalProd pjp
JOIN WH_Raw.dbo.ProdJournalTable pjt
    ON pjp.dataareaid = pjt.dataareaid
      AND pjp.JournalId = pjt.JournalId
JOIN WH_Raw.dbo.ProdTable pt
    ON pjp.dataareaid = pt.dataareaid
      AND pjp.prodid = pt.prodid

LEFT JOIN WH_Raw.dbo.InventDim id
	ON pt.inventdimid = id.inventdimid
		AND pt.dataareaid = id.DataAreaId

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON pt.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND pt.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
	ON ID.inventbatchid = db.BatchID
		AND pt.dataareaid = db.CMPNY
		AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
	ON pt.routeid = dr.RouteID
		AND pt.dataareaid = dr.CMPNY
		AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON pjp.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON pt.itemid = dp.Product_ID
		AND pjp.dataareaid = dp.CMPNY
		AND dp.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
	ON pjp.ProdId = dpbo.ProductionBatchOrder
		AND pjp.dataareaid = dpbo.CMPNY
		AND dpbo.RecordStatus=1


WHERE 
----pjt.prodid = 'PBO0001075'
----and    
pjt.journaltype_$Label = 'ReportFinished'
--ORDER BY pjp.ProdId, pjp.JournalId, pt.ItemId