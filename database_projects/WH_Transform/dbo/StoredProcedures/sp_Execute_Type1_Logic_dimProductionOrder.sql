CREATE     PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimProductionOrder]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_ProductionOrder_New AS
	SELECT *
	FROM vw_stage_NewProductionOrder

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_ProductionOrder_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_ProductionOrder AS Target
	--JOIN vw_stage_DIM_ProductionOrder_incoming AS Source
	--	ON Target.ProductionOrder = Source.ProductionOrder
	--		AND Target.CMPNY = Source.CMPNY
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
	--		OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
	--		OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
	--		OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
	--		OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
	--		);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_ProductionOrder_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_ProductionOrder AS Target
	JOIN vw_stage_DIM_ProductionOrder_incoming AS Source
		ON Target.ProductionOrderID = Source.ProductionOrderID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Product_ID, '') <> ISNULL(Source.Product_ID, '')
			OR ISNULL(Target.name, '') <> ISNULL(Source.name, '')
			OR ISNULL(Target.ProdOrderStatus, '') <> ISNULL(Source.ProdOrderStatus, '')
			OR ISNULL(Target.ProdOrderStatusDesc, '') <> ISNULL(Source.ProdOrderStatusDesc, '')
			OR ISNULL(Target.RouteID, '') <> ISNULL(Source.RouteID, '')
			OR ISNULL(Target.Warehouse, '') <> ISNULL(Source.Warehouse, '')
			OR ISNULL(Target.SiteID, '') <> ISNULL(Source.SiteID, '')
			OR ISNULL(Target.InventoryStatus, '') <> ISNULL(Source.InventoryStatus, '')
			OR ISNULL(Target.BatchID, '') <> ISNULL(Source.BatchID, '')
			OR ISNULL(Target.QTY, 0.0) <> ISNULL(Source.QTY, 0.0)
			OR ISNULL(Target.qtysched, 0.0) <> ISNULL(Source.qtysched, 0.0)
			OR ISNULL(Target.qtystup, 0.0) <> ISNULL(Source.qtystup, 0.0)
			OR ISNULL(Target.remaininventphysical, 0.0) <> ISNULL(Source.remaininventphysical, 0.0)
			OR ISNULL(Target.ProdOrderCreatedDate, '01/01/1900') <> ISNULL(Source.ProdOrderCreatedDate, '01/01/1900')
			OR ISNULL(Target.ProdOrderModifiedDateTime, '01/01/1900') <> ISNULL(Source.ProdOrderModifiedDateTime, '01/01/1900')
			OR ISNULL(Target.CostCalcutaionDate, '01/01/1900') <> ISNULL(Source.CostCalcutaionDate, '01/01/1900')
			OR ISNULL(Target.DateSchedulingPerformed, '01/01/1900') <> ISNULL(Source.DateSchedulingPerformed, '01/01/1900')
			OR ISNULL(Target.ScheduledStartDateTime, '01/01/1900') <> ISNULL(Source.ScheduledStartDateTime, '01/01/1900')
			OR ISNULL(Target.ScheduledEndDateTime, '01/01/1900') <> ISNULL(Source.ScheduledEndDateTime, '01/01/1900')
			OR ISNULL(Target.ScheduledDurationMins, 0) <> ISNULL(Source.ScheduledDurationMins, 0)
			OR ISNULL(Target.ProdOrderFinishedDate, '01/01/1900') <> ISNULL(Source.ProdOrderFinishedDate, '01/01/1900')
			OR ISNULL(Target.BOMDate, '01/01/1900') <> ISNULL(Source.BOMDate, '01/01/1900')
			OR ISNULL(Target.DeliveryDateTime, '01/01/1900') <> ISNULL(Source.DeliveryDateTime, '01/01/1900')
			OR ISNULL(Target.RealiztionDate, '01/01/1900') <> ISNULL(Source.RealiztionDate, '01/01/1900')
			OR ISNULL(Target.ReleasedDate, '01/01/1900') <> ISNULL(Source.ReleasedDate, '01/01/1900')
			OR ISNULL(Target.LatestSchedDateTime, '01/01/1900') <> ISNULL(Source.LatestSchedDateTime, '01/01/1900')
			OR ISNULL(Target.bomid, '') <> ISNULL(Source.bomid, '')
			OR ISNULL(Target.collectreflevel, 0) <> ISNULL(Source.collectreflevel, 0)
			OR ISNULL(Target.collectrefprodid, '') <> ISNULL(Source.collectrefprodid, '')
			OR ISNULL(Target.inventrefid, '') <> ISNULL(Source.inventrefid, '')
			OR ISNULL(Target.inventreftransid, '') <> ISNULL(Source.inventreftransid, '')
			OR ISNULL(Target.inventtransid, '') <> ISNULL(Source.inventtransid, '')
			OR ISNULL(Target.modifiedby, '') <> ISNULL(Source.modifiedby, '')
			OR ISNULL(Target.createdby, '') <> ISNULL(Source.createdby, '')
			OR ISNULL(Target.recid, 0) <> ISNULL(Source.recid, 0)
			OR ISNULL(Target.createdon, '01/01/1900') <> ISNULL(Source.createdon, '01/01/1900')
			OR ISNULL(Target.modifiedon, '01/01/1900') <> ISNULL(Source.modifiedon, '01/01/1900')
			OR ISNULL(Target.IsDelete, 0) <> ISNULL(Source.IsDelete, 0)
			OR ISNULL(Target.backorderstatus, 0) <> ISNULL(Source.backorderstatus, 0)
			OR ISNULL(Target.backorderstatus_$label, '') <> ISNULL(Source.backorderstatus_$label, '')
			OR ISNULL(Target.reservation, 0) <> ISNULL(Source.reservation, 0)
			OR ISNULL(Target.reservation_$label, '') <> ISNULL(Source.reservation_$label, '')
			OR ISNULL(Target.routejobs, 0) <> ISNULL(Source.routejobs, 0)
			OR ISNULL(Target.routejobs_$label, '') <> ISNULL(Source.routejobs_$label, '')
			OR ISNULL(Target.schedstatus, 0) <> ISNULL(Source.schedstatus, 0)
			OR ISNULL(Target.schedstatus_$label, '') <> ISNULL(Source.schedstatus_$label, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_ProductionOrder_Type1_OnlyUpdatedRecords AS
	SELECT Target.ProductionOrderKey
		, Target.CMPNY
		, Target.ProductionOrderID
		, Source.Product_ID
		, Source.name
		, Source.ProdOrderStatus
		, Source.ProdOrderStatusDesc
		, Source.RouteID
		, Source.Warehouse
		, Source.SiteID
		, Source.InventoryStatus
		, Source.BatchID
		, Source.QTY
		, Source.qtysched
		, Source.qtystup
		, Source.remaininventphysical
		, Source.ProdOrderCreatedDate
		, Source.ProdOrderModifiedDateTime
		, Source.CostCalcutaionDate
		, Source.DateSchedulingPerformed
		, Source.ScheduledStartDateTime
		, Source.ScheduledEndDateTime
		, Source.ScheduledDurationMins
		, Source.ProdOrderFinishedDate
		, Source.BOMDate
		, Source.DeliveryDateTime
		, Source.RealiztionDate
		, Source.ReleasedDate
		, Source.LatestSchedDateTime
		, Source.bomid
		, Source.collectreflevel
		, Source.collectrefprodid
		, Source.inventrefid
		, Source.inventreftransid
		, Source.inventtransid
		, Source.modifiedby
		, Source.createdby
		, Source.recid
		, Source.createdon
		, Source.modifiedon
		, Source.IsDelete
		, Source.backorderstatus
		, Source.backorderstatus_$label
		, Source.reservation
		, Source.reservation_$label
		, Source.routejobs
		, Source.routejobs_$label
		, Source.schedstatus
		, Source.schedstatus_$label
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_ProductionOrder_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_ProductionOrder_incoming AS Source
		ON Target.ProductionOrderID = Source.ProductionOrderID
			AND Target.CMPNY = Source.CMPNY

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_ProductionOrder_Deleted AS
	SELECT *
	FROM tbl_DIM_ProductionOrder AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_ProductionOrder_incoming AS Source
			WHERE Target.ProductionOrderID = Source.ProductionOrderID
			AND Target.CMPNY = Source.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_ProductionOrder_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_ProductionOrder
	WHERE RecordStatus = 1
		AND (ProductionOrderID + '~=~' + CMPNY) NOT IN 
			(
			--SELECT ProductionOrder 
			--FROM stage_tbl_DIM_ProductionOrder_Expired
			--UNION
			SELECT ProductionOrderID + '~=~' + CMPNY
			FROM stage_tbl_DIM_ProductionOrder_Deleted
			UNION
			SELECT ProductionOrderID + '~=~' + CMPNY 
			FROM stage_tbl_DIM_ProductionOrder_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [ProductionOrderKey]
	--	, [CMPNY]
	--	, ProductionOrder
	--	, Invoice_Account
	--	, Legacy_ProductionOrder
	--	, GMAccountNo
	--	, GMRecID
	--	, ProductionOrderName
	--	, Harmonized_Name
	--	, Address
	--	, City
	--	, State
	--	, ZIP
	--	, Country
	--	, Territory_ID
	--	, Salesman_ID
	--	, SalesChannel
	--	, Industry_Segment
	--	, Subsegment
	--	, Status
	--	, EffectiveCountry
	--	, Account_Tier
	--	, Longitude
	--	, Latitude
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_ProductionOrder_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[ProductionOrderKey]
	--	, s.[CMPNY]
	--	, s.ProductionOrder
	--	, s.Invoice_Account
	--	, s.Legacy_ProductionOrder
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.ProductionOrderName
	--	, s.Harmonized_Name
	--	, s.Address
	--	, s.City
	--	, s.State
	--	, s.ZIP
	--	, s.Country
	--	, s.Territory_ID
	--	, s.Salesman_ID
	--	, s.SalesChannel
	--	, s.Industry_Segment
	--	, s.Subsegment
	--	, s.Status
	--	, s.EffectiveCountry
	--	, s.Account_Tier
	--	, s.Longitude
	--	, s.Latitude
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_ProductionOrder_incoming s
	--JOIN stage_tbl_DIM_ProductionOrder_Expired e
	--	ON s.ProductionOrder = e.ProductionOrder
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_ProductionOrder_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_ProductionOrder_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT ProductionOrderKey
		, CMPNY
		, ProductionOrderID
		, Product_ID
		, name
		, ProdOrderStatus
		, ProdOrderStatusDesc
		, RouteID
		, Warehouse
		, SiteID
		, InventoryStatus
		, BatchID
		, QTY
		, qtysched
		, qtystup
		, remaininventphysical
		, ProdOrderCreatedDate
		, ProdOrderModifiedDateTime
		, CostCalcutaionDate
		, DateSchedulingPerformed
		, ScheduledStartDateTime
		, ScheduledEndDateTime
		, ScheduledDurationMins
		, ProdOrderFinishedDate
		, BOMDate
		, DeliveryDateTime
		, RealiztionDate
		, ReleasedDate
		, LatestSchedDateTime
		, bomid
		, collectreflevel
		, collectrefprodid
		, inventrefid
		, inventreftransid
		, inventtransid
		, modifiedby
		, createdby
		, recid
		, createdon
		, modifiedon
		, IsDelete
		, backorderstatus
		, backorderstatus_$label
		, reservation
		, reservation_$label
		, routejobs
		, routejobs_$label
		, schedstatus
		, schedstatus_$label
		, Source
		, RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_ProductionOrder_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_ProductionOrder_Append AS
	SELECT *
	FROM tbl_DIM_ProductionOrder f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_ProductionOrder_Final AS d
			WHERE d.ProductionOrderID = f.ProductionOrderID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_ProductionOrder_Final AS f
	ORDER BY CMPNY
		,ProductionOrderID
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_ProductionOrder;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_ProductionOrder AS
	SELECT *
	FROM stage_tbl_DIM_ProductionOrder_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_ProductionOrder_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_ProductionOrder_incoming;
END;