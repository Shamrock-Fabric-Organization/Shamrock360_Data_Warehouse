--use WH_transform
--go



CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimWorkCenter]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_WorkCenter_New AS
	SELECT *
	FROM vw_stage_NewWorkCenter

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_WorkCenter_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_WorkCenter AS Target
	--JOIN vw_stage_DIM_WorkCenter_incoming AS Source
	--	ON Target.WorkCenterID = Source.WorkCenterID
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
	CREATE TABLE stage_tbl_DIM_WorkCenter_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_WorkCenter AS Target
	JOIN vw_stage_DIM_WorkCenter_incoming AS Source
		ON Target.WorkCenterID = Source.WorkCenterID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.WorkCenterName, '') <> ISNULL(Source.WorkCenterName, '')
			OR ISNULL(Target.WorkCenterIDandName, '') <> ISNULL(Source.WorkCenterIDandName, '')
			OR ISNULL(Target.wrkctrtype, 0) <> ISNULL(Source.wrkctrtype, 0)
			OR ISNULL(Target.wrkctrtype_$label, '') <> ISNULL(Source.wrkctrtype_$label, '')
			OR ISNULL(Target.effectivitypct, 0) <> ISNULL(Source.effectivitypct, 0)
			OR ISNULL(Target.errorpct, 0) <> ISNULL(Source.errorpct, 0)
			OR ISNULL(Target.operationschedpct, 0) <> ISNULL(Source.operationschedpct, 0)
			OR ISNULL(Target.processcategoryid, '') <> ISNULL(Source.processcategoryid, '')
			OR ISNULL(Target.routegroupid, '') <> ISNULL(Source.routegroupid, '')
			OR ISNULL(Target.ResourceGroup, '') <> ISNULL(Source.ResourceGroup, '')
			OR ISNULL(Target.ResourceGroupName, '') <> ISNULL(Source.ResourceGroupName, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_WorkCenter_Type1_OnlyUpdatedRecords AS
	SELECT Target.WorkCenterKey
		,Target.CMPNY
		, Target.WorkCenterID
		, Source.WorkCenterName
		, Source.WorkCenterIDandName
		, Source.wrkctrtype
		, Source.wrkctrtype_$label
		, Source.effectivitypct
		, Source.errorpct
		, Source.operationschedpct
		, Source.processcategoryid
		, Source.routegroupid
		, Source.ResourceGroup
		, Source.ResourceGroupName
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_WorkCenter_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_WorkCenter_incoming AS Source
		ON Target.WorkCenterID = Source.WorkCenterID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_WorkCenter_Deleted AS
	SELECT *
	FROM tbl_DIM_WorkCenter AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_WorkCenter_incoming AS Source
			WHERE Source.WorkCenterID = Target.WorkCenterID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_WorkCenter_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_WorkCenter
	WHERE RecordStatus = 1
		AND (WorkCenterID + '~=~' + CMPNY) NOT IN 
			(
			--SELECT WorkCenterID + '~=~' + CMPNY
			--FROM stage_tbl_DIM_WorkCenter_Expired
			--UNION
			SELECT WorkCenterID + '~=~' + CMPNY
			FROM stage_tbl_DIM_WorkCenter_Deleted
			UNION
			SELECT WorkCenterID + '~=~' + CMPNY
			FROM stage_tbl_DIM_WorkCenter_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [WorkCenterKey]
	--	, [CMPNY]
	--	, WorkCenterID
	--	, Invoice_Account
	--	, Legacy_WorkCenterID
	--	, GMAccountNo
	--	, GMRecID
	--	, WorkCenterName
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
	--FROM stage_tbl_DIM_WorkCenter_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[WorkCenterKey]
	--	, s.[CMPNY]
	--	, s.WorkCenterID
	--	, s.Invoice_Account
	--	, s.Legacy_WorkCenterID
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.WorkCenterName
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
	--FROM vw_stage_DIM_WorkCenter_incoming s
	--JOIN stage_tbl_DIM_WorkCenter_Expired e
	--	ON s.WorkCenterID = e.WorkCenterID
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_WorkCenter_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_WorkCenter_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT WorkCenterKey
		,CMPNY
		,WorkCenterID
		,WorkCenterName
		, WorkCenterIDandName
		, wrkctrtype
		, wrkctrtype_$label
		, effectivitypct
		, errorpct
		, operationschedpct
		, processcategoryid
		, routegroupid
		, ResourceGroup
		, ResourceGroupName
		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_WorkCenter_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_WorkCenter_Append AS
	SELECT *
	FROM tbl_DIM_WorkCenter f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_WorkCenter_Final AS d
			WHERE d.WorkCenterID = f.WorkCenterID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_WorkCenter_Final AS f
	ORDER BY WorkCenterID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_WorkCenter;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_WorkCenter AS
	SELECT *
	FROM stage_tbl_DIM_WorkCenter_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_WorkCenter_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_WorkCenter_incoming;
END;