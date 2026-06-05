


CREATE     PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimGL_Account]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_GL_Account_New AS
	SELECT *
	FROM vw_stage_NewGL_Account

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_GL_Account_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_GL_Account AS Target
	--JOIN vw_stage_DIM_GL_Account_incoming AS Source
	--	ON Target.GL_Account_Number = Source.GL_Account_Number
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
	--		OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
	--		OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
	--		OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
	--		OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
	--		);

	---- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_GL_Account_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_GL_Account AS Target
	JOIN vw_stage_DIM_GL_Account_incoming AS Source
		ON Target.GL_Account_Number = Source.GL_Account_Number
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.GL_Account_Name, '') <> ISNULL(Source.GL_Account_Name, '')
			OR ISNULL(Target.accountcategoryref, 0) <> ISNULL(Source.accountcategoryref, 0)
			OR ISNULL(Target.Account_Category, '') <> ISNULL(Source.Account_Category, '')
			OR ISNULL(Target.Account_Category_Name, '') <> ISNULL(Source.Account_Category_Name, '')
			OR ISNULL(Target.Account_Type, 0) <> ISNULL(Source.Account_Type, 0)
			OR ISNULL(Target.Account_Type_Description, '') <> ISNULL(Source.Account_Type_Description, '')
			OR ISNULL(Target.Category_Account_Type, 0) <> ISNULL(Source.Category_Account_Type, 0)
			OR ISNULL(Target.Category_Account_Type_Description, '') <> ISNULL(Source.Category_Account_Type_Description, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_GL_Account_Type1_OnlyUpdatedRecords AS
	SELECT Target.GL_AccountKey
		, Target.GL_Account_Number
		, Source.GL_Account_Name
		, Source.accountcategoryref
		, Source.Account_Category
		, Source.Account_Category_Name
		, Source.Account_Type
		, Source.Account_Type_Description
		, Source.Category_Account_Type
		, Source.Category_Account_Type_Description
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_GL_Account_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_GL_Account_incoming AS Source
		ON Target.GL_Account_Number = Source.GL_Account_Number

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_GL_Account_Deleted AS
	SELECT *
	FROM tbl_DIM_GL_Account AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_GL_Account_incoming AS Source
			WHERE Source.GL_Account_Number = Target.GL_Account_Number
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_GL_Account_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_GL_Account
	WHERE RecordStatus = 1
		AND (GL_Account_Number) NOT IN 
			(
			--SELECT GL_Account_Number
			--FROM stage_tbl_DIM_GL_Account_Expired
			--UNION
			SELECT GL_Account_Number
			FROM stage_tbl_DIM_GL_Account_Deleted
			UNION
			SELECT GL_Account_Number
			FROM stage_tbl_DIM_GL_Account_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	---- Expire old records
	--SELECT GL_AccountKey
	--	, GL_Account_Number
	--	, GL_Account_Name
	--	, Account_Category
	--	, Account_Category_Name
	--	, Account_Type
	--	, Account_Type_Description
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_GL_Account_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.GL_AccountKey
	--	, s.GL_Account_Number
	--	, s.GL_Account_Name
	--	, s.Account_Category
	--	, s.Account_Category_Name
	--	, s.Account_Type
	--	, s.Account_Type_Description
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_GL_Account_incoming s
	--JOIN stage_tbl_DIM_GL_Account_Expired e
	--	ON s.GL_Account_Number = e.GL_Account_Number
	
	--UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_GL_Account_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_GL_Account_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT GL_AccountKey
		, GL_Account_Number
		, GL_Account_Name
		, accountcategoryref
		, Account_Category
		, Account_Category_Name
		, Account_Type
		, Account_Type_Description
		, Category_Account_Type
		, Category_Account_Type_Description
		, Source
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_GL_Account_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_GL_Account_Append AS
	SELECT *
	FROM tbl_DIM_GL_Account f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_GL_Account_Final AS d
			WHERE d.GL_Account_Number = f.GL_Account_Number
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_GL_Account_Final AS f
	ORDER BY GL_Account_Number
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_GL_Account;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_GL_Account AS
	SELECT *
	FROM stage_tbl_DIM_GL_Account_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_GL_Account_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_GL_Account_incoming;
END;

GO

