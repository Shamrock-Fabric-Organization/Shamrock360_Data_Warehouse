CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimVendor]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Vendor_New AS
	SELECT *
	FROM vw_stage_NewVendor

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_Vendor_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Vendor AS Target
	--JOIN vw_stage_DIM_Vendor_incoming AS Source
	--	ON Target.Vendor_ID = Source.Vendor_ID
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
	CREATE TABLE stage_tbl_DIM_Vendor_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Vendor AS Target
	JOIN vw_stage_DIM_Vendor_incoming AS Source
		ON Target.Vendor_ID = Source.Vendor_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Vendor_Name, '') <> ISNULL(Source.Vendor_Name, '')
			OR ISNULL(Target.Vendor_Type, '') <> ISNULL(Source.Vendor_Type, '')
			OR ISNULL(Target.Address, '') <> ISNULL(Source.Address, '')
			OR ISNULL(Target.City, '') <> ISNULL(Source.City, '')
			OR ISNULL(Target.State, '') <> ISNULL(Source.State, '')
			OR ISNULL(Target.ZIP, '') <> ISNULL(Source.ZIP, '')
			OR ISNULL(Target.Country, '') <> ISNULL(Source.Country, '')
			OR ISNULL(Target.Currency, '') <> ISNULL(Source.Currency, '')
			OR ISNULL(Target.vendgroup, '') <> ISNULL(Source.vendgroup, '')
			OR ISNULL(Target.VendGroupName, '') <> ISNULL(Source.VendGroupName, '')
			OR ISNULL(Target.segmentid, '') <> ISNULL(Source.segmentid, '')
			OR ISNULL(Target.subsegmentid, '') <> ISNULL(Source.subsegmentid, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Vendor_Type1_OnlyUpdatedRecords AS
	SELECT Target.VendorKey
		,Target.CMPNY
		, Target.Vendor_ID
		, Source.Vendor_Name
		, Source.Vendor_Type
		, Source.Address
		, Source.City
		, Source.State
		, Source.ZIP
		, Source.Country
		, Source.Currency
		, Source.vendgroup
		, Source.VendGroupName
		, Source.segmentid
		, Source.subsegmentid

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Vendor_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Vendor_incoming AS Source
		ON Target.Vendor_ID = Source.Vendor_ID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Vendor_Deleted AS
	SELECT *
	FROM tbl_DIM_Vendor AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Vendor_incoming AS Source
			WHERE Source.Vendor_ID = Target.Vendor_ID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Vendor_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Vendor
	WHERE RecordStatus = 1
		AND (Vendor_ID + '~=~' + CMPNY) NOT IN 
			(
			--SELECT Vendor_ID + '~=~' + CMPNY
			--FROM stage_tbl_DIM_Vendor_Expired
			--UNION
			SELECT Vendor_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Vendor_Deleted
			UNION
			SELECT Vendor_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Vendor_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [VendorKey]
	--	, [CMPNY]
	--	, Vendor_ID
	--	, Invoice_Account
	--	, Legacy_Vendor_ID
	--	, GMAccountNo
	--	, GMRecID
	--	, VendorName
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
	--FROM stage_tbl_DIM_Vendor_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[VendorKey]
	--	, s.[CMPNY]
	--	, s.Vendor_ID
	--	, s.Invoice_Account
	--	, s.Legacy_Vendor_ID
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.VendorName
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
	--FROM vw_stage_DIM_Vendor_incoming s
	--JOIN stage_tbl_DIM_Vendor_Expired e
	--	ON s.Vendor_ID = e.Vendor_ID
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Vendor_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Vendor_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT VendorKey
		,CMPNY
		,Vendor_ID
		,Vendor_Name
		,Vendor_Type
		,Address
		,City
		,State
		,ZIP
		,Country
		,Currency
		, vendgroup
		, VendGroupName
		, segmentid
		, subsegmentid
		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Vendor_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Vendor_Append AS
	SELECT *
	FROM tbl_DIM_Vendor f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Vendor_Final AS d
			WHERE d.Vendor_ID = f.Vendor_ID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Vendor_Final AS f
	ORDER BY Vendor_ID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Vendor;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Vendor AS
	SELECT *
	FROM stage_tbl_DIM_Vendor_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Vendor_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Vendor_incoming;
END;