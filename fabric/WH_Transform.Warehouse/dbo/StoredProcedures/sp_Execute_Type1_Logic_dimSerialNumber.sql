--truncate table tbl_DIM_SerialNumber

CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimSerialNumber]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_SerialNumber_New AS
	SELECT *
	FROM vw_stage_NewSerialNumber

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_SerialNumber_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_SerialNumber AS Target
	--JOIN vw_stage_DIM_SerialNumber_incoming AS Source
	--	ON Target.SerialNumber_Number = Source.SerialNumber_Number
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
	--		OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
	--		OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
	--		OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
	--		OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
	--		);

	---- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_SerialNumber_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_SerialNumber AS Target
	JOIN vw_stage_DIM_SerialNumber_incoming AS Source
		ON Target.[SerialNumber] = Source.[SerialNumber]
			--AND Target.[ProductID] = Source.[ProductID]
			AND Target.[CMPNY] = Source.[CMPNY]
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.proddate, '01/01/1900') <> ISNULL(Source.proddate, '01/01/1900')
			OR ISNULL(Target.description, '') <> ISNULL(Source.description, '')
			OR ISNULL(Target.rfidtagid, '') <> ISNULL(Source.rfidtagid, '')
			OR ISNULL(Target.SerialNumberNoteName, '') <> ISNULL(Source.SerialNumberNoteName, '')
			OR ISNULL(Target.SerialNumberNote, '') <> ISNULL(Source.SerialNumberNote, '')
			OR ISNULL(Target.SeralNumberNoteCreatedBy, '') <> ISNULL(Source.SeralNumberNoteCreatedBy, '')
			)


	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_SerialNumber_Type1_OnlyUpdatedRecords AS
	SELECT Target.SerialNumberKey
		, Target.CMPNY
		, Target.SerialNumber
		--, Target.ProductID

		, Source.proddate
		, Source.description
		, Source.rfidtagid
		, Source.SerialNumberNoteName
		, Source.SerialNumberNote
		, Source.SeralNumberNoteCreatedBy

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_SerialNumber_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_SerialNumber_incoming AS Source
		ON Target.[SerialNumber] = Source.[SerialNumber]
			--AND Target.[ProductID] = Source.[ProductID]
			AND Target.[CMPNY] = Source.[CMPNY]


	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_SerialNumber_Deleted AS
	SELECT *
	FROM tbl_DIM_SerialNumber AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_SerialNumber_incoming AS Source
			WHERE Target.[SerialNumber] = Source.[SerialNumber]
				--AND Target.[ProductID] = Source.[ProductID]
				AND Target.[CMPNY] = Source.[CMPNY]
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_SerialNumber_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_SerialNumber
	WHERE RecordStatus = 1
		AND (CMPNY +'='+ SerialNumber /*+'='+ ProductID*/) NOT IN 
			(
			--SELECT SerialNumber_Number
			--FROM stage_tbl_DIM_SerialNumber_Expired
			--UNION
			SELECT CMPNY +'='+ SerialNumber /*+'='+ ProductID*/
			FROM stage_tbl_DIM_SerialNumber_Deleted
			UNION
			SELECT CMPNY +'='+ SerialNumber /*+'='+ ProductID*/
			FROM stage_tbl_DIM_SerialNumber_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	---- Expire old records
	--SELECT SerialNumberKey
	--	, SerialNumber_Number
	--	, SerialNumber_Name
	--	, Account_Category
	--	, Account_Category_Name
	--	, Account_Type
	--	, Account_Type_Description
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_SerialNumber_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.SerialNumberKey
	--	, s.SerialNumber_Number
	--	, s.SerialNumber_Name
	--	, s.Account_Category
	--	, s.Account_Category_Name
	--	, s.Account_Type
	--	, s.Account_Type_Description
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_SerialNumber_incoming s
	--JOIN stage_tbl_DIM_SerialNumber_Expired e
	--	ON s.SerialNumber_Number = e.SerialNumber_Number
	
	--UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_SerialNumber_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_SerialNumber_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT SerialNumberKey
		, CMPNY
		, SerialNumber

		--, ProductID
		, proddate
		, description
		, rfidtagid
		,SerialNumberNoteName
		,SerialNumberNote
		,SeralNumberNoteCreatedBy

		, Source
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_SerialNumber_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_SerialNumber_Append AS
	SELECT *
	FROM tbl_DIM_SerialNumber f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_SerialNumber_Final AS d
			WHERE d.SerialNumber = f.SerialNumber
				--AND d.ProductID = f.ProductID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_SerialNumber_Final AS f
	ORDER BY CMPNY
		,SerialNumber
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_SerialNumber;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_SerialNumber AS
	SELECT *
	FROM stage_tbl_DIM_SerialNumber_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_SerialNumber_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_SerialNumber_incoming;
END;