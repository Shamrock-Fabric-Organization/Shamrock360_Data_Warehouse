CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimLegal_Entity]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Legal_Entity_New AS
	SELECT *
	FROM vw_stage_NewLegal_Entity

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_Legal_Entity_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Legal_Entity AS Target
	--JOIN vw_stage_DIM_Legal_Entity_incoming AS Source
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
	CREATE TABLE stage_tbl_DIM_Legal_Entity_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Legal_Entity AS Target
	JOIN vw_stage_DIM_Legal_Entity_incoming AS Source
		ON Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Legal_Entity_Name, '') <> ISNULL(Source.Legal_Entity_Name, '')
			OR ISNULL(Target.accountingcurrency, '') <> ISNULL(Source.accountingcurrency, '')
			OR ISNULL(Target.reportingcurrency, '') <> ISNULL(Source.reportingcurrency, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Legal_Entity_Type1_OnlyUpdatedRecords AS
	SELECT Target.Legal_EntityKey
		,Target.CMPNY
		, Source.Legal_Entity_Name
		, Source.accountingcurrency
		, Source.reportingcurrency
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Legal_Entity_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Legal_Entity_incoming AS Source
		ON Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Legal_Entity_Deleted AS
	SELECT *
	FROM tbl_DIM_Legal_Entity AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Legal_Entity_incoming AS Source
			WHERE Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Legal_Entity_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Legal_Entity
	WHERE RecordStatus = 1
		AND (CMPNY) NOT IN 
			(
			--SELECT CMPNY
			--FROM stage_tbl_DIM_Legal_Entity_Expired
			--UNION
			SELECT CMPNY
			FROM stage_tbl_DIM_Legal_Entity_Deleted
			UNION
			SELECT CMPNY
			FROM stage_tbl_DIM_Legal_Entity_Type1_UpdatesNeeded
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
	--FROM stage_tbl_DIM_Legal_Entity_Expired
	
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
	--FROM vw_stage_DIM_Legal_Entity_incoming s
	--JOIN stage_tbl_DIM_Legal_Entity_Expired e
	--	ON s.Vendor_ID = e.Vendor_ID
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Legal_Entity_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Legal_Entity_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT Legal_EntityKey
		,CMPNY
		,Legal_Entity_Name
		,accountingcurrency
		,reportingcurrency
		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Legal_Entity_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Legal_Entity_Append AS
	SELECT *
	FROM tbl_DIM_Legal_Entity f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Legal_Entity_Final AS d
			WHERE d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Legal_Entity_Final AS f
	ORDER BY CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Legal_Entity;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Legal_Entity AS
	SELECT *
	FROM stage_tbl_DIM_Legal_Entity_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Legal_Entity_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Legal_Entity_incoming;
END;