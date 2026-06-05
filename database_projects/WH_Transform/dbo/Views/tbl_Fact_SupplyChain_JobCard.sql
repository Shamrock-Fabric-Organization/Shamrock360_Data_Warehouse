/****** Object:  View [dbo].[tbl_Fact_SupplyChain_JobCard]    Script Date: 2/24/2026 12:50:07 PM ******/





CREATE      VIEW [dbo].[tbl_Fact_SupplyChain_JobCard] 
AS 
----Job Card / Route Card data  --Route Card Data not needed at this time
SELECT 
    pjt.dataareaid CMPNY,
    pjt.ProdId,
    pt.ItemId,
    pjt.JournalId,
    pjr.linenum,
    pjr.OprNum,
    pjr.OprId,
    pjr.oprpriority,
    pjr.oprpriority_$label,
    pjt.posteddatetime,
    pjr.Hours  JobHours,
    pjr.qtygood JobQtyGood,
    pjr.qtyerror JobQtyError,
    pjr.wrkctrid,
    pjr.worker,
    h.person,
    h.personnelnumber,
    pjr.transdate,
    pjt.dataareaid,
    pjr.oprfinished_$label
    ,pjr.jobtype_$label
    ,pjr.jobfinished_$label
    ,pjr.voucher
    ,pjr.executedpct
    ,pjr.jobid
    ,pt.inventdimid
    ,pjt.journaltype_$Label
    , pjr.fromtime
    ,pjr.totime
    ,pjt.description

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
    , ISNULL(de.EmployeeKey, -1) EmployeeKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(db.BatchKey, -1) BatchKey
	, ISNULL(dr.RouteKey, -1) RouteKey

FROM WH_Raw.dbo.ProdJournalTable pjt

JOIN WH_Raw.dbo.prodtable pt
    ON pjt.dataareaid = pt.dataareaid
      AND pjt.prodid = pt.prodid
INNER JOIN WH_Raw.dbo.ProdJournalRoute pjr
    ON pjt.dataareaid = pjr.dataareaid
      AND pjt.JournalId = pjr.JournalId

LEFT JOIN WH_Raw.dbo.hcmworker h
    ON pjr.worker = h.recid


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

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee de
	ON h.personnelnumber = de.Personnel_Number
		AND de.RecordStatus=1

where 
----pjt.prodid = 'PBO0001075'
----and
pjt.journaltype_$Label = 'JobCard'
----order by 2,1,3

GO

