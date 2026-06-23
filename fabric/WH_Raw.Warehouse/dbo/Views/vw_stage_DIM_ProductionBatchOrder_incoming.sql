-- Auto Generated (Do not modify) 56A108ED7883842CE0D002579AC7E853AEA3185A7F5696F3D848333814ACCF9F

/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_ProductionBatchOrder_incoming]	

CREATE   VIEW [dbo].[vw_stage_DIM_ProductionBatchOrder_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(pt.dataareaid AS VARCHAR(100))
            ,CAST(pt.prodid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS ProductionBatchOrderKey
	, pt.dataareaid  CMPNY
	, pt.prodid  ProductionBatchOrder
	, pt.itemid Product_ID
	, pt.name 
	, pt.prodstatus PBOStatus
	, pt.prodstatus_$label PBOStatusDesc
	--, pt.routeid  RouteID
	--, ID.inventlocationid Warehouse
	--, ID.inventsiteid SiteID
	--, ID.inventstatusid InventoryStatus
	--, ID.inventbatchid BatchID
	--, ID.inventserialid SerialID
	--, ID.wmsPalletID  PalletID
	--, pt.qtycalc QTY
	--, pt.qtysched
	--, pt.qtystup
	--, pt.remaininventphysical
	, pt.createddatetime PBOCreatedDate
	, pt.modifieddatetime PBOModifiedDateTime
	--, pt.calcdate  CostCalcutaionDate --Cost calculation date
	--, pt.scheddate DateSchedulingPerformed --date scheduling performed
	--, pt.schedstart -- Planned start date
	--, pt.schedfromtime -- Planned start time
	--, pt.schedend -- Planned end date
	--, pt.schedtotime -- Planned end time

	---- Convert to datetime by adding seconds to the date
 --   ,DATEADD(SECOND, pt.SchedFromTime, CAST(pt.SchedStart AS DATETIME2(3))) as ScheduledStartDateTime
 --   ,DATEADD(SECOND, pt.SchedToTime, CAST(pt.SchedEnd AS DATETIME2(3))) as ScheduledEndDateTime

 --   -- Calculate scheduled duration in mins
 --   ,DATEDIFF(MINUTE, 
 --       DATEADD(SECOND, pt.SchedFromTime, CAST(pt.SchedStart AS DATETIME2(3))),
 --       DATEADD(SECOND, pt.SchedToTime, CAST(pt.SchedEnd AS DATETIME2(3)))
 --   ) as ScheduledDurationMins
	--, pt.finisheddate  PBOFinishedDate --When production actually finished
	--, pt.bomdate BOMDate --BOM version effective date
	----, pt.dlvdate  --Required delivery date
	----, pt.dlvtime  --Required delivery time
	--, DATEADD(SECOND, pt.DlvTime, CAST(pt.DlvDate AS datetime2(3))) as DeliveryDateTime
	--, pt.realdate  RealiztionDate --realization date?
	--, pt.releaseddate ReleasedDate --date prod order was released (changed from scheduled to released)
	----, pt.stupdate  --statistics update?

	----, pt.latestscheddate  --latest allowed schedule date
	----, pt.latestschedtime  --latest allowed schedule time on schedule date
	--, DATEADD(SECOND, pt.latestschedtime, CAST(pt.latestscheddate AS datetime2(3))) as LatestSchedDateTime


	--, pt.bomid
	--, pt.collectreflevel
	, pt.collectrefprodid
	------, pt.defaultdimension
	--, pt.inventdimid

	--, pt.inventrefid
	--, pt.inventreftransid

	--, pt.inventtransid

	--, pt.modifiedby
	--, pt.createdby
	--, pt.recid
	--, pt.createdon
	--, pt.modifiedon
	--, pt.IsDelete

	, pt.backorderstatus RemainStatus
	, pt.backorderstatus_$label RemainStatusDescription
	--, pt.reservation
	--, pt.reservation_$label
	--, pt.routejobs
	--, pt.routejobs_$label
	, pt.schedstatus SchedulingStatus
	, pt.schedstatus_$label SchedulingStatusDescription

	--, pt.pmfyieldpct
	--, pt.projcategoryid
	--, pt.projcostamount
	--, pt.projcostprice
	--, pt.projsalesprice
	--, pt.projsalesunitid

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

	--------************************************************************************************
	--------** The following columns are available but don't appear to be useful at this time **
	--------************************************************************************************
	--, pt.sysdatastatecode
	--, pt.activitynumber
	------, pt.currencycode_ru
	----, pt.density
	----, pt.depth
	----, pt.ganttcolorid
	----, pt.height
	----, pt.pdscwbatchest
	----, pt.pdscwbatchsched
	----, pt.pdscwbatchsize
	----, pt.pdscwbatchstup
	----, pt.pdscwremaininventphysical
	----, pt.pmfconsordid
	----, pt.pmfyieldpct
	----, pt.pricegroup_ru
	--, pt.prodgroupid
	--, pt.prodorigid
	--, pt.prodpoolid
	--, pt.prodprio
	--, pt.projcategoryid
	--, pt.projcostamount
	--, pt.projcostprice
	--, pt.projid
	--, pt.projlinepropertyid
	--, pt.projsalescurrencyid
	--, pt.projsalesprice
	--, pt.projsalesunitid
	--, pt.projtaxgroupid
	--, pt.projtaxitemgroupid
	--, pt.projtransid
	--, pt.propertyid
	----, pt.reqplanidsched
	----, pt.reqpoid
	----, pt.width
	----, pt.planningpriority
	----, pt.fintag
	----, pt.qmsbatchprodid
	----, pt.stipurchid
	----, pt.modifiedtransactionid
	----, pt.createdtransactionid
	----, pt.recversion
	----, pt.partition
	----, pt.sysrowversion
	----, pt.tableid
	----, pt.versionnumber
	----, pt.PartitionId

	------ Little useful data as of 2026-01-12
	--, pt.checkroute
	--, pt.checkroute_$label
	--, pt.latestscheddirection
	--, pt.latestscheddirection_$label
	--, pt.pmfcobyvarallow
	--, pt.pmfcobyvarallow_$label
	--, pt.pmfreworkbatch
	--, pt.pmfreworkbatch_$label
	--, pt.pmftotalcostallocation
	--, pt.pmftotalcostallocation_$label

	------ Do not appear to be used as of 2026-01-12
	----, pt.inventreftype
	----, pt.inventreftype_$label
	----, pt.pmfbulkord
	----, pt.pmfbulkord_$label
	----, pt.prodlocked
	----, pt.prodlocked_$label
	----, pt.prodpostingtype
	----, pt.prodpostingtype_$label
	----, pt.prodtype
	----, pt.prodtype_$label
	----, pt.prodwhsreleasepolicy
	----, pt.prodwhsreleasepolicy_$label
	----, pt.profitset
	----, pt.profitset_$label
	----, pt.projlinkedtoorder
	----, pt.projlinkedtoorder_$label
	----, pt.projpostingtype
	----, pt.projpostingtype_$label
	----, pt.reflookup
	----, pt.reflookup_$label
	----, pt.skipcreatebomlines
	----, pt.skipcreatebomlines_$label
	----, pt.skipcreaterouteoperations
	----, pt.skipcreaterouteoperations_$label

FROM WH_Raw.dbo.prodtable pt
LEFT JOIN WH_Raw.dbo.InventDIM ID
	ON pt.inventdimid = ID.inventdimid
		AND pt.dataareaid = ID.dataareaid

UNION ALL

SELECT -1 [ProductionOrderKey]
, 'Unknown'  CMPNY
, 'Unknown'  ProductionOrderID
, 'Unknown'  Product_ID
, NULL name
, NULL ProdOrderStatus
, NULL ProdOrderStatusDesc
--, NULL RouteID
--, NULL Warehouse
--, NULL SiteID
--, NULL InventoryStatus
--, NULL BatchID
--, NULL QTY
--, NULL qtysched
--, NULL qtystup
--, NULL remaininventphysical
, NULL ProdOrderCreatedDate
, NULL ProdOrderModifiedDateTime
--, NULL CostCalcutaionDate
--, NULL DateSchedulingPerformed
--, NULL ScheduledStartDateTime
--, NULL ScheduledEndDateTime
--, NULL ScheduledDurationMins
--, NULL ProdOrderFinishedDate
--, NULL BOMDate
--, NULL DeliveryDateTime
--, NULL RealiztionDate
--, NULL ReleasedDate
--, NULL LatestSchedDateTime
--, NULL bomid
--, NULL collectreflevel
, NULL collectrefprodid
--, NULL inventrefid
--, NULL inventreftransid
--, NULL inventtransid
--, NULL modifiedby
--, NULL createdby
--, NULL recid
--, NULL createdon
--, NULL modifiedon
--, NULL IsDelete
, NULL RemainStatus
, NULL RemainStatusDescription
--, NULL reservation
--, NULL reservation_$label
--, NULL routejobs
--, NULL routejobs_$label
, NULL SchedulingStatus
, NULL SchedulingStatusDescription

--, NULL pmfyieldpct
--, NULL projcategoryid
--, NULL projcostamount
--, NULL projcostprice
--, NULL projsalesprice
--, NULL projsalesunitid

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]