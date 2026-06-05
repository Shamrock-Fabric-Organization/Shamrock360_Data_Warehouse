


CREATE     PROCEDURE [dbo].[sp_Execute_SCD_Logic_dimPhantomProduct]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_New;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Expired;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Deleted;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Final;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_dim_PhantomProduct_New AS
	SELECT *
	FROM vw_stage_NewPhantomProducts;

	-- Step 2: Identify records that need to be expired
	-- Create a table to store records that have changed and need to be expired
	CREATE TABLE stage_tbl_dim_PhantomProduct_Expired AS
	SELECT Target.*
	FROM tbl_dim_PhantomProduct AS Target
	JOIN vw_stage_dim_PhantomProduct_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Business_Line, '') <> ISNULL(Source.Business_Line, '')
			OR ISNULL(Target.Product_Line, '') <> ISNULL(Source.Product_Line, '')
			OR ISNULL(Target.Technology, '') <> ISNULL(Source.Technology, '')
			OR ISNULL(Target.Material, '') <> ISNULL(Source.Material, '')
			);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_dim_PhantomProduct_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_dim_PhantomProduct AS Target
	JOIN vw_stage_dim_PhantomProduct_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Phantom_Product, '') <> ISNULL(Source.Phantom_Product, '')
			OR ISNULL(Target.Commercial_Name, '') <> ISNULL(Source.Commercial_Name, '')
			OR ISNULL(Target.ActiveFormula_ID, '') <> ISNULL(Source.ActiveFormula_ID, '')
			OR ISNULL(Target.Description_Internal, '') <> ISNULL(Source.Description_Internal, '')
			OR ISNULL(Target.Description_External, '') <> ISNULL(Source.Description_External, '')
			OR ISNULL(Target.Application_Benefit, '') <> ISNULL(Source.Application_Benefit, '')
			)
		AND NOT EXISTS (
			SELECT 1
			FROM stage_tbl_dim_PhantomProduct_Expired AS Expired
			WHERE Expired.Product_ID = Target.Product_ID
				AND Expired.CMPNY = Target.CMPNY
			);


	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_dim_PhantomProduct_Type1_OnlyUpdatedRecords AS
	SELECT Target.PhantomProductKey
		,Target.CMPNY
		,Target.Product_ID
		,Source.Phantom_Product
		,Source.Commercial_Name
		,Source.ActiveFormula_ID
		,Target.Business_Line
		,Target.Product_Line
		,Target.Technology
		,Target.Material
		,Source.Description_Internal
		,Source.Description_External
		,Source.Application_Benefit
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
		,Target.Source
	FROM stage_tbl_dim_PhantomProduct_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_dim_PhantomProduct_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_dim_PhantomProduct_Deleted AS
	SELECT *
	FROM tbl_dim_PhantomProduct AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_dim_PhantomProduct_incoming AS Source
			WHERE Source.Product_ID = Target.Product_ID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_dim_PhantomProduct_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_dim_PhantomProduct
	WHERE RecordStatus = 1
		AND (Product_ID + '~=~' + CMPNY) NOT IN 
			(
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_dim_PhantomProduct_Expired
			UNION
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_dim_PhantomProduct_Deleted
			UNION
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_dim_PhantomProduct_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	-- Expire old records
	SELECT [PhantomProductKey]
		, [CMPNY]
		, [Product_ID]
		, [Phantom_Product]
		, [Commercial_Name]
		, [ActiveFormula_ID]
		, [Business_Line]
		, [Product_Line]
		, [Technology]
		, [Material]
		, [Description_Internal]
		, [Description_External]
		, [Application_Benefit]
		, [RecordEffectiveStartDate]
		, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
		, 0 AS RecordStatus
		, [Source]
	FROM stage_tbl_dim_PhantomProduct_Expired
	
	UNION ALL
	
	-- Insert new versions of changed records
	SELECT s.[PhantomProductKey]
		, s.[CMPNY]
		, s.[Product_ID]
		, s.[Phantom_Product]
		, s.[Commercial_Name]
		, s.[ActiveFormula_ID]
		, s.[Business_Line]
		, s.[Product_Line]
		, s.[Technology]
		, s.[Material]
		, s.[Description_Internal]
		, s.[Description_External]
		, s.[Application_Benefit]
		,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
		,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
		,1 AS RecordStatus
		,s.[Source]
	FROM vw_stage_dim_PhantomProduct_incoming s
	JOIN stage_tbl_dim_PhantomProduct_Expired e
		ON s.Product_ID = e.Product_ID
			AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_dim_PhantomProduct_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_dim_PhantomProduct_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT [PhantomProductKey]
		, [CMPNY]
		, [Product_ID]
		, [Phantom_Product]
		, [Commercial_Name]
		, [ActiveFormula_ID]
		, [Business_Line]
		, [Product_Line]
		, [Technology]
		, [Material]
		, [Description_Internal]
		, [Description_External]
		, [Application_Benefit]
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
		, [Source]
	FROM stage_tbl_dim_PhantomProduct_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_dim_PhantomProduct_Append AS
	SELECT *
	FROM tbl_dim_PhantomProduct f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_dim_PhantomProduct_Final AS d
			WHERE d.Product_ID = f.Product_ID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_dim_PhantomProduct_Final AS f
	ORDER BY Product_ID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_dim_PhantomProduct;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_dim_PhantomProduct AS
	SELECT *
	FROM stage_tbl_dim_PhantomProduct_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_New;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Expired;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Deleted;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Final;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Append;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_dim_PhantomProduct_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_dim_PhantomProduct_incoming;
END;

GO

