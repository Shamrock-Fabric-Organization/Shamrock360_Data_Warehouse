-- Auto Generated (Do not modify) 77A59CEC9D9C1DEFFE1CB7800F7C65EFD308226A077203B3E7D61C4F88E1537A
/****** Object:  View [dbo].[tbl_Fact_SupplyChain_PickList]    Script Date: 2/24/2026 12:50:18 PM ******/
/****** Object:  View [dbo].[tbl_Fact_SupplyChain_PickList]    Script Date: 1/28/2026 1:41:25 PM ******/

----PickList Data
CREATE        VIEW [dbo].[tbl_Fact_SupplyChain_PickList] 
AS 
SELECT  
    pjt.dataareaid CMPNY
    ,pjt.ProdId
    ,pt.itemid
    ,pjt.JournalId
    ,pjb.inventtransid LotID
    ,pjb.transdate
    --, pjt.posteddatetime  --Sean C may want to add this column from chat on 2026-01-28
    ,pjb.itemid  resource
    ,pjb.bomproposal
    ,pjb.bomconsump
    ,pjb.bomunitid
    ,pjb.endconsump
    ,pjb.endconsump_$label
    ,pjb.matchid
    ,pjb.voucher
    ,pjb.bomscrap
    ,pjb.errorcause
    ,pjb.errorcause_$label
    ,pjb.inventproposal
    ,pjb.inventconsump
    ,pjb.InventTransChildRefId InventoryNumber
    ,pjb.oprnum
    ,pjb.position

    ,pt.inventdimid

    ,pjt.journaltype_$Label

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(db.BatchKey, -1) BatchKey
	, ISNULL(dr.RouteKey, -1) RouteKey

FROM WH_Raw.dbo.ProdJournalTable pjt
JOIN WH_Raw.dbo.prodtable pt
    ON pjt.dataareaid = pt.dataareaid
      AND pjt.prodid = pt.prodid
JOIN WH_Raw.dbo.prodjournalbom pjb
    ON pjt.dataareaid = pjb.dataareaid
      AND pjt.journalid = pjb.journalid


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
	ON pjt.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON pt.itemid = dp.Product_ID
		AND pjt.dataareaid = dp.CMPNY
		AND dp.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
	ON pjt.ProdId = dpbo.ProductionBatchOrder
		AND pjt.dataareaid = dpbo.CMPNY
		AND dpbo.RecordStatus=1

----where pjt.prodid = 'PBO0001075'
----order by 2,1,3