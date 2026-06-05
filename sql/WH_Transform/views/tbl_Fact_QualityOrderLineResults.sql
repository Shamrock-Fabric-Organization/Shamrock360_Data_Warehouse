-- Auto Generated (Do not modify) 6996EF4631419F66B6905D6188A3DF39FA600C725A97513BD8B0B6AC8BD46C7A
/****** Object:  View [dbo].[tbl_Fact_QualityOrderLineResults]    Script Date: 6/3/2026 9:42:50 AM ******/
/****** Object:  View [dbo].[tbl_Fact_QualityOrderLineResults]    Script Date: 5/15/2026 9:49:51 AM ******/



-----SON, PON, PBO in inventrefid  , also TON - transfer orders but no dim for that
CREATE         VIEW [dbo].[tbl_Fact_QualityOrderLineResults] as
with iqot as
(

select
iqot.dataareaid 
, iqot.qualityorderid
, iqot.accountrelation
, iqot.inventdimid
, iqot.inventrefid
, iqot.inventreftransid
, iqot.inventtransid
, iqot.itemid
, iqot.itemsamplingid
, iqot.oprnum
, iqot.orderstatus
, iqot.orderstatus_$label
, iqot.qty
, iqot.referencetype
, iqot.referencetype_$label
, iqot.routeid
, iqot.routeoprid
, iqot.testgroupid
, iqot.validatedbyworker
, iqot.validateddatetime
, iqot.wrkctrid
, id.inventsiteid
, id.inventlocationid
, id.inventbatchid
, id.inventserialid
, id.licenseplateid
, id.wmslocationid
, id.inventstatusid

from WH_Raw.dbo.inventqualityordertable iqot
  join WH_Raw.dbo.inventdim id
    on iqot.inventdimid = id.inventdimid
      and iqot.dataareaid = id.dataareaid
)
, workcenterdata as
(
SELECT DISTINCT pjr.dataareaid
	,pjr.prodid
	,pjr.oprnum
	,pjr.oprpriority
	,pjr.oprpriority_$label
	, pjr.wrkctrid
FROM WH_Raw.dbo.prodroutejob pjr
JOIN (
	SELECT dataareaid
		,prodid
		,oprpriority
		,max(oprnum) moprnum
	FROM WH_Raw.dbo.prodroutejob
	WHERE oprpriority = 0
	GROUP BY dataareaid
		,prodid
		,oprpriority
	) mpjr
	ON pjr.dataareaid = mpjr.dataareaid
		AND pjr.prodid = mpjr.prodid
		AND pjr.oprpriority = mpjr.oprpriority
		AND pjr.oprnum = mpjr.moprnum
)
select 
r.dataareaid CMPNY
, r.qualityorderid
, r.testsequence
, r.linenum
, r.testid
, l.qmsskiptest
, l.qmsskiptest_$label
, r.testresult
, r.testresult_$label
, r.testresultquantity
, CASE WHEN l.qmsskiptest = 1 THEN NULL ELSE r.testresultvalueoutcome END testresultvalueoutcome
, r.testresultvaluereal
, l.lowerlimit
, l.lowertolerance
, l.pdsattribvalue
, l.pdsbatchattribid
, l.pdsorderlineresult
, l.standardvalue
, l.testinstrumentid
, l.testunitid
, l.upperlimit
, l.uppertolerance
, l.variableid
, l.variableoutcomeidstandard
, i.inventrefid
, i.inventsiteid
, i.inventlocationid
, i.inventbatchid
, i.inventserialid
, i.licenseplateid
, i.wmslocationid
, i.inventstatusid
, l.createddatetime LineCreatedDateTime
, convert(int, convert(char(8), l.createddatetime, 112)) LineCreatedDateKey
, i.validatedbyworker
, i.validateddatetime ValidatedDateTime
, convert(int, convert(char(8), i.validateddatetime, 112)) ValidatedDateKey
, i.accountrelation
, wc.wrkctrid
, i.testgroupid
		,ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
		,ISNULL(dp.ProductKey, -1) ProductKey
		,ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
		,ISNULL(dpo.PurchaseOrderKey, -1) PurchaseOrderKey
		,ISNULL(dso.SalesOrderKey, -1) SalesOrderKey
		,ISNULL(dr.RouteKey, -1) RouteKey
		,ISNULL(ds.SiteKey, -1) SiteKey
		,ISNULL(dw.WarehouseKey, -1) WarehouseKey
		,ISNULL(db.BatchKey, -1) BatchKey

		,ISNULL(dsn.SerialNumberKey, -1) SerialNumberKey
		,ISNULL(dv.VendorKey, -1) VendorKey
		,ISNULL(dc.CustomerKey, -1) CustomerKey
		,ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey
, i.orderstatus_$label QuaityOrderStatus
from WH_Raw.dbo.inventqualityorderlineresults r
  join WH_Raw.dbo.inventqualityorderline l
    on r.testsequence = l.testsequence
      and r.qualityorderid = l.qualityorderid
      and r.dataareaid = l.dataareaid
  join iqot i
    on r.qualityorderid = i.qualityorderid
      and r.dataareaid = i.dataareaid

	LEFT join workcenterdata wc
		ON r.dataareaid = wc.dataareaid
		  AND i.inventrefid = wc.prodid

	LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
		ON i.dataareaid = dw.CMPNY
			AND i.inventlocationid = dw.Warehouse_ID
			AND dw.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
		ON i.inventsiteid = ds.Site_ID
			AND i.dataareaid = ds.CMPNY
			AND ds.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
		ON i.inventbatchid = db.BatchID
			AND i.dataareaid = db.CMPNY
			AND db.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
		ON i.routeid = dr.RouteID
			AND i.dataareaid = dr.CMPNY
			AND dr.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
		ON r.dataareaid = dle.CMPNY
			AND dle.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
		ON i.itemid = dp.Product_ID
			AND i.dataareaid = dp.CMPNY
			AND dp.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
		ON i.inventrefid = dpbo.ProductionBatchOrder
			AND i.dataareaid = dpbo.CMPNY
			AND dpbo.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_PurchaseOrder dpo
		ON i.inventrefid = dpo.PurchaseOrderNumber
			AND i.dataareaid = dpo.CMPNY
			AND dpo.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_SalesOrder dso
		ON i.inventrefid = dso.SalesOrderId
			AND i.dataareaid = dso.CMPNY
			AND dso.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_SerialNumber dsn
		ON i.inventserialid = dsn.SerialNumber
			AND i.dataareaid = dsn.CMPNY
			AND dsn.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dv
		ON i.accountrelation = dv.Vendor_ID
			AND i.dataareaid = dv.CMPNY
			AND dv.RecordStatus=1
	LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
		ON i.accountrelation = dc.Customer_ID
			AND i.dataareaid = dc.CMPNY
			AND dc.RecordStatus=1

	LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
		ON wc.wrkctrid = dwc.WorkCenterID
			AND wc.dataareaid = dwc.CMPNY
			AND dwc.RecordStatus=1