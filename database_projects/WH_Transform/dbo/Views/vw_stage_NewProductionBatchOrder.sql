
--drop view [vw_stage_NewProductionBatchOrder]

    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewProductionBatchOrder]
AS
SELECT 
ProductionBatchOrderKey
, CMPNY
, ProductionBatchOrder
, Product_ID
, name
, PBOStatus
, PBOStatusDesc
--, RouteID
--, Warehouse
--, SiteID
--, InventoryStatus
--, BatchID
--, QTY
--, qtysched
--, qtystup
--, remaininventphysical
, PBOCreatedDate
, PBOModifiedDateTime
--, CostCalcutaionDate
--, DateSchedulingPerformed
--, ScheduledStartDateTime
--, ScheduledEndDateTime
--, ScheduledDurationMins
--, PBOFinishedDate
--, BOMDate
--, DeliveryDateTime
--, RealiztionDate
--, ReleasedDate
--, LatestSchedDateTime
--, bomid
--, collectreflevel
, collectrefprodid
--, inventrefid
--, inventreftransid
--, inventtransid
--, modifiedby
--, createdby
--, recid
--, createdon
--, modifiedon
--, IsDelete
, RemainStatus
, RemainStatusDescription
--, reservation
--, reservation_$label
--, routejobs
--, routejobs_$label
, SchedulingStatus
, SchedulingStatusDescription
, Source

	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_ProductionBatchOrder_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_ProductionBatchOrder AS Target
		WHERE Target.ProductionBatchOrder = Source.ProductionBatchOrder
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);

GO

