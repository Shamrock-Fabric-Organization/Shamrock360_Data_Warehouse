-- Auto Generated (Do not modify) E250D6D6B31CBD43DE5F3A016D5C408E889F213B81D53485EA972D4C8AAAB335

--use WH_transform
--go


CREATE     VIEW [dbo].[tbl_Fact_Production_Job_Routes] 
as
SELECT prj.dataareaid CMPNY
	, prj.prodid  ProdID
	, prj.wrkctrid  WrkCtrID
	, prj.oprnum
	, prj.oprpriority
	, prj.oprpriority_$label
	, pr.oprid Operation
	, prj.prodid +': '+ convert(varchar(50),prj.oprnum) ProdIDandOprNum
	, rot.name Name
	, prj.jobtype
	, prj.jobtype_$label
	, prj.link
	, prj.link_$label
	, prj.linktype
	, prj.linktype_$label
	, prj.jobid
	, prj.wrkctrid Resource
	, prj.propertyid
	, prj.jobcontrol
	, prj.jobcontrol_$label JobManagement
	, prj.jobstatus
	, prj.jobstatus_$label
	, prj.jobpaytype
	, prj.jobpaytype_$label
	, prj.schedcancelled
	, prj.schedcancelled_$label Canceled
	, prj.calctimehours CalculatedTime
	, prj.schedtimehours ResourceTime
	, prj.executedpct / 100.0 ProcessingPercentage

	,DATEADD(minute, ((prj.fromtime / 60) % 60), DATEADD(HOUR, ROUND(prj.fromtime / 3600, 0, 1), prj.fromdate)) SchedStartDateTime -- Planned start datetime
	,DATEADD(minute, ((prj.totime / 60) % 60), DATEADD(HOUR, ROUND(prj.totime / 3600, 0, 1), prj.todate)) SchedEndDateTime -- Planned start datetime
	,DATEADD(minute, ((prj.realizedstarttime / 60) % 60), DATEADD(HOUR, ROUND(prj.realizedstarttime / 3600, 0, 1), prj.realizedstartdate)) ActualStartDateTime -- Planned start datetime
	,DATEADD(minute, ((prj.realizedendtime / 60) % 60), DATEADD(HOUR, ROUND(prj.realizedendtime / 3600, 0, 1), prj.realizedenddate)) ActualEndDateTime -- Planned start datetime

	, convert(int, convert(char(8), prj.fromdate,112) ) SchedStartDateKey
	, convert(int, convert(char(8), prj.realizedstartdate,112) ) ActualStartDateKey
	, id.inventsiteid
	, id.inventlocationid Warehouse
	, pt.itemid ProductionProductID
	, pt.routeid

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) HistoricalProductKey
    , ISNULL(dpc.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey

	, ISNULL(dr.RouteKey, -1) RouteKey
	, ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey

FROM WH_Raw.dbo.prodroutejob prj
join WH_Raw.dbo.prodroute pr 
  on prj.dataareaid = pr.dataareaid
    and prj.prodid = pr.prodid
	and prj.oprnum = pr.oprnum
	and prj.oprpriority = pr.oprpriority
JOIN WH_Raw.dbo.routeoprtable rot
  on pr.oprid  = rot.oprid
    and pr.dataareaid = rot.dataareaid
JOIN WH_Raw.dbo.prodtable pt
  on prj.prodid  = pt.prodid
    and prj.dataareaid = pt.dataareaid
JOIN WH_Raw.dbo.inventdim id
  on pt.inventdimid = id.inventdimid
    and pt.dataareaid = id.dataareaid


LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
	ON prj.ProdId = dpbo.ProductionBatchOrder
		AND prj.dataareaid = dpbo.CMPNY
		AND dpbo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON pt.itemid = dp.Product_ID
		AND pt.dataareaid = dp.CMPNY
		AND pt.createddatetime between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON pt.itemid = dpc.Product_ID
		AND pt.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON prj.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND prj.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON prj.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
	ON prj.dataareaid = dr.CMPNY
		AND pt.routeid = dr.RouteID
		AND dr.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
	ON prj.dataareaid = dwc.CMPNY
		AND prj.wrkctrid = dwc.WorkCenterID
		AND dwc.RecordStatus=1

----where prj.prodid = 'PBO0001963'

--ORDER BY 1
--	,2
--	,4
--	,5
--	,7

--	--7534

----where prj.prodid = 'PBO0001963'

--ORDER BY 1
--	,2
--	,4
--	,5
--	,7

--	--7534