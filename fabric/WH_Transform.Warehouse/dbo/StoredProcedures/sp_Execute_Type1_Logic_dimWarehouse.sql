CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimWarehouse]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Warehouse_New AS
	SELECT *
	FROM vw_stage_NewWarehouse

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_Warehouse_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Warehouse AS Target
	--JOIN vw_stage_DIM_Warehouse_incoming AS Source
	--	ON Target.Warehouse_ID = Source.Warehouse_ID
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
	CREATE TABLE stage_tbl_DIM_Warehouse_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Warehouse AS Target
	JOIN vw_stage_DIM_Warehouse_incoming AS Source
		ON Target.Warehouse_ID = Source.Warehouse_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Warehouse_Name, '') <> ISNULL(Source.Warehouse_Name, '')
			OR ISNULL(Target.Site_ID, '') <> ISNULL(Source.Site_ID, '')
			OR ISNULL(Target.Site_Name, '') <> ISNULL(Source.Site_Name, '')
			OR ISNULL(Target.LocationType, 0) <> ISNULL(Source.LocationType, 0)
			OR ISNULL(Target.LocationTypeDesc, '') <> ISNULL(Source.LocationTypeDesc, '')
			OR ISNULL(Target.LocationLevel, 0) <> ISNULL(Source.LocationLevel, 0)
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Warehouse_Type1_OnlyUpdatedRecords AS
	SELECT Target.WarehouseKey
		,Target.CMPNY
		, Target.Warehouse_ID
		, Source.Warehouse_Name
		, Source.Site_ID
		, Source.Site_Name
		, Source.LocationType
		, Source.LocationTypeDesc
		, Source.LocationLevel
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Warehouse_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Warehouse_incoming AS Source
		ON Target.Warehouse_ID = Source.Warehouse_ID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Warehouse_Deleted AS
	SELECT *
	FROM tbl_DIM_Warehouse AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Warehouse_incoming AS Source
			WHERE Source.Warehouse_ID = Target.Warehouse_ID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Warehouse_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Warehouse
	WHERE RecordStatus = 1
		AND (Warehouse_ID + '~=~' + CMPNY) NOT IN 
			(
			--SELECT Warehouse_ID + '~=~' + CMPNY
			--FROM stage_tbl_DIM_Warehouse_Expired
			--UNION
			SELECT Warehouse_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Warehouse_Deleted
			UNION
			SELECT Warehouse_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Warehouse_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [WarehouseKey]
	--	, [CMPNY]
	--	, Warehouse_ID
	--	, Invoice_Account
	--	, Legacy_Warehouse_ID
	--	, GMAccountNo
	--	, GMRecID
	--	, WarehouseName
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
	--FROM stage_tbl_DIM_Warehouse_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[WarehouseKey]
	--	, s.[CMPNY]
	--	, s.Warehouse_ID
	--	, s.Invoice_Account
	--	, s.Legacy_Warehouse_ID
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.WarehouseName
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
	--FROM vw_stage_DIM_Warehouse_incoming s
	--JOIN stage_tbl_DIM_Warehouse_Expired e
	--	ON s.Warehouse_ID = e.Warehouse_ID
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Warehouse_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Warehouse_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT WarehouseKey
		,CMPNY
		,Warehouse_ID
		,Warehouse_Name
		,Site_ID
		,Site_Name
		,LocationType
		,LocationTypeDesc
		,LocationLevel
		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Warehouse_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Warehouse_Append AS
	SELECT *
	FROM tbl_DIM_Warehouse f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Warehouse_Final AS d
			WHERE d.Warehouse_ID = f.Warehouse_ID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Warehouse_Final AS f
	ORDER BY Warehouse_ID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Warehouse;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Warehouse AS
	SELECT *
	FROM stage_tbl_DIM_Warehouse_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Warehouse_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Warehouse_incoming;
END;