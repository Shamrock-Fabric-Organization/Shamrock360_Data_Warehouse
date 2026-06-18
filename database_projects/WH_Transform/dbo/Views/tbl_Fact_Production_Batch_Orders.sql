-- Auto Generated (Do not modify) 5D2BD037039862C788D0B4E64EE73DF7981C9E8342133BAF5BECE3BCD3D5B5FE
/****** Object:  View [dbo].[tbl_Fact_Production_Batch_Orders]    Script Date: 2/24/2026 2:44:02 PM ******/

/****** Object:  View [dbo].[vw_stage_DIM_ProductionBatchOrder_incoming]    Script Date: 2/11/2026 2:37:20 PM ******/
/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[[tbl_Fact_Production_Batch_Orders]]	




--Fact Production Orders
CREATE       VIEW [dbo].[tbl_Fact_Production_Batch_Orders]
as
select 
	pt.dataareaid  CMPNY
	, pt.prodid  ProductionBatchOrder
	, pt.itemid Product_ID
, pt.bomid
, pt.bomdate BOMDate --BOM version effective date
, itm.unitid
, pt.routeid  RouteID
, pt.finisheddate PBOFinishedDate --When production actually finished
, convert(int, convert(char(8), pt.finisheddate,112)) PBOFinishedDatekey
, pt.qtysched
, pt.schedstart schedstartdate
, convert(int, convert(char(8), pt.schedstart,112)) schedstartdatekey
, pt.schedend schedenddate
, convert(int, convert(char(8), pt.schedend,112)) schedenddatekey
----, pt.collectrefprodid ReferenceProdID    ----in dimProductBatOrder
, pt.dlvdate RequestedDeliveryDate
, convert(int, convert(char(8), pt.dlvdate,112)) RequestedDeliveryDatekey
----, pt.schedfromtime  ---- not needed in fact
----, pt.schedtotime  ---- not needed in fact
----, pt.inventdimid   ---- not needed in fact
, CASE WHEN pt.dlvdate >= pt.schedend and pt.schedend <> '01/01/1900' THEN 1 ELSE 0 END ScheduledFinishOnTime
, CASE WHEN pt.dlvdate < pt.schedend THEN 1 ELSE 0 END ScheduledFinishDelayed
, itdp.max_datephysical LastPhysicalInventoryReceiptDate
, convert(int, convert(char(8), itdp.max_datephysical,112)) LastPhysicalInventoryReceiptDatekey
, CASE WHEN pt.dlvdate >= pt.finisheddate and pt.finisheddate <> '01/01/1900' THEN 1 ELSE 0 END ActualFinishOnTime
, CASE WHEN pt.dlvdate < pt.finisheddate THEN 1 ELSE 0 END ActualFinishDelayed

, isnull(ptj.qtygood, 0) QtyGood
, pt.remainInventphysical ReportRemainder

, DATEADD(minute, ((pt.schedfromtime / 60) % 60), DATEADD(HOUR, ROUND(pt.schedfromtime / 3600, 0, 1), pt.schedstart) ) ScheduledStartDateTime -- Planned start datetime
, DATEADD(minute, ((pt.schedtotime / 60) % 60), DATEADD(HOUR, ROUND(pt.schedtotime / 3600, 0, 1), pt.schedend) ) ScheduledEndDateTime -- Planned end datetime
, DATEDIFF(MINUTE, 
    DATEADD(minute, ((pt.schedfromtime / 60) % 60), DATEADD(HOUR, ROUND(pt.schedfromtime / 3600, 0, 1), pt.schedstart) ), 
    DATEADD(minute, ((pt.schedtotime / 60) % 60), DATEADD(HOUR, ROUND(pt.schedtotime / 3600, 0, 1), pt.schedend) ) 
    ) / 60.0  ScheduledCalendarDurationHrs
, id.inventlocationid warehouse
, id.configid
, id.inventcolorid
, id.inventbatchid
, id.inventserialid SerialNumber
, Id.inventsiteid
, id.inventsizeid
, id.wmslocationid 
, id.licenseplateid
, id.inventstatusid
, id.wmspalletid PalletID
, le.accountingcurrency
, pt.qtystup
, pt.qtycalc
, pt.inventrefid
, pt.inventreftransid
, pt.inventreftype
, pt.inventreftype_$label
, pt.inventtransid
, pt.prodorigid
, pt.scheddate DateSchedulingPerformed --date scheduling performed
, convert(int, convert(char(8), pt.scheddate,112)) DateSchedulingPerformedkey
, pt.stupdate
, convert(int, convert(char(8), pt.stupdate,112)) stupdatekey
, pt.calcdate CostCalcutaionDate --Cost calculation date
, convert(int, convert(char(8), pt.calcdate,112)) CostCalcutaionDatekey
, DATEADD(SECOND, pt.latestschedtime, CAST(pt.latestscheddate AS datetime2(3))) as LatestSchedDateTime --latest allowed schedule datetime
, convert(int, convert(char(8), pt.latestscheddate,112)) latestscheddatekey
, pt.realdate  RealiztionDate --realization date?
, convert(int, convert(char(8), pt.realdate,112)) realdatekey
, pt.releaseddate ReleasedDate --date prod order was released (changed from scheduled to released)
, convert(int, convert(char(8), pt.releaseddate,112)) releaseddatekey

, pt.projcategoryid
, pt.projcostamount
, pt.projcostprice
, pt.projsalesprice
, pt.pmfyieldpct

, case when pt.remaininventphysical > 0 then 'Yes' Else 'No' end IsOpen
, case when pt.dlvdate < getdate() then 'Yes' Else 'No' end IsLate
, case when pt.remaininventphysical > 0 and pt.dlvdate < getdate() then 'Yes' Else 'No' end IsLateOpenOrder


    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) HistoricalProductKey
    , ISNULL(dpc.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey

	, ISNULL(dr.RouteKey, -1) RouteKey


from WH_Raw.dbo.prodtable pt
  JOIN WH_Transform.dbo.tbl_Dim_Legal_Entity le
    on pt.dataareaid = le.CMPNY
  join WH_Raw.dbo.inventtablemodule itm
    on pt.itemid = itm.itemid
      and pt.dataareaid = itm.dataareaid
      and itm.moduletype = 0

left join (select dataareaid, prodid, journaltype, sum(qtygood) qtygood
			FROM WH_Raw.dbo.prodtablejour ptj
			WHERE journaltype=2
			group by dataareaid, prodid, journaltype
			) ptj
  on pt.prodid = ptj.prodid
    and pt.dataareaid = ptj.dataareaid
    and ptj.journaltype=2

LEFT JOIN (select sqit.dataareaid, sqito.inventtransid, MAX(datephysical) max_datephysical
            from WH_Raw.dbo.inventtrans sqit
            join   WH_Raw.dbo.inventtransorigin sqito
            on sqit.inventtransorigin = sqito.recid
              and sqit.dataareaid = sqito.dataareaid
            where sqit.statusreceipt > 0
            group by sqit.dataareaid, sqito.inventtransid) itdp
  on pt.dataareaid = itdp.dataareaid
    and pt.inventtransid = itdp.inventtransid

left join WH_Raw.dbo.inventdim id
  on pt.inventdimid = id.inventdimid
    and pt.dataareaid = id.dataareaid





LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
	ON pt.ProdId = dpbo.ProductionBatchOrder
		AND pt.dataareaid = dpbo.CMPNY
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
	ON pt.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND pt.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON pt.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
	ON pt.dataareaid = dr.CMPNY
		AND pt.routeid = dr.RouteID
		AND dr.RecordStatus=1


--where pt.prodid = 'PBO0000001'


--order by 
--pt.dataareaid
--, pt.prodid
--, pt.itemid
----, ptj.transdate
----, ptj.journaltype
----, it.voucherphysical
----, pb.linenum

----order by 1,2


--where pt.prodid = 'PBO0000001'


--order by 
--pt.dataareaid
--, pt.prodid
--, pt.itemid
----, ptj.transdate
----, ptj.journaltype
----, it.voucherphysical
----, pb.linenum

----order by 1,2