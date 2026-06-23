CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimQualityOrder]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_QualityOrder_New AS
	SELECT *
	FROM vw_stage_NewQualityOrder

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_QualityOrder_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_QualityOrder AS Target
	--JOIN vw_stage_DIM_QualityOrder_incoming AS Source
	--	ON Target.QualityOrder_Number = Source.QualityOrder_Number
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
	--		OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
	--		OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
	--		OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
	--		OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
	--		);

	---- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_QualityOrder_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_QualityOrder AS Target
	JOIN vw_stage_DIM_QualityOrder_incoming AS Source
		ON Target.[QualityOrderID] = Source.[QualityOrderID]
			AND Target.[CMPNY] = Source.[CMPNY]
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.inventrefid, '') <> ISNULL(Source.inventrefid, '')
			OR ISNULL(Target.inventrefid, '') <> ISNULL(Source.inventrefid, '')
			OR ISNULL(Target.ProductID, '') <> ISNULL(Source.ProductID, '')
			OR ISNULL(Target.itemsamplingid, '') <> ISNULL(Source.itemsamplingid, '')
			OR ISNULL(Target.oprnum, 0) <> ISNULL(Source.oprnum, 0)
			OR ISNULL(Target.orderstatus, 0) <> ISNULL(Source.orderstatus, 0)
			OR ISNULL(Target.orderstatus_$label, '') <> ISNULL(Source.orderstatus_$label, '')
			OR ISNULL(Target.qty, 0) <> ISNULL(Source.qty, 0)
			OR ISNULL(Target.referencetype, 0) <> ISNULL(Source.referencetype, 0)
			OR ISNULL(Target.referencetype_$label, '') <> ISNULL(Source.referencetype_$label, '')
			OR ISNULL(Target.routeid, '') <> ISNULL(Source.routeid, '')
			OR ISNULL(Target.testgroupid, '') <> ISNULL(Source.testgroupid, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_QualityOrder_Type1_OnlyUpdatedRecords AS
	SELECT Target.QualityOrderKey
		, Target.CMPNY
		, Target.QualityOrderID

		, Source.inventrefid
		, Source.inventreftransid
		, Source.ProductID
		, Source.itemsamplingid
		, Source.oprnum
		, Source.orderstatus
		, Source.orderstatus_$label
		, Source.qty
		, Source.referencetype
		, Source.referencetype_$label
		, Source.routeid
		, Source.testgroupid

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_QualityOrder_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_QualityOrder_incoming AS Source
		ON Target.[QualityOrderID] = Source.[QualityOrderID]
			AND Target.[CMPNY] = Source.[CMPNY]

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_QualityOrder_Deleted AS
	SELECT *
	FROM tbl_DIM_QualityOrder AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_QualityOrder_incoming AS Source
			WHERE Target.[QualityOrderID] = Source.[QualityOrderID]
				AND Target.[CMPNY] = Source.[CMPNY]
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_QualityOrder_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_QualityOrder
	WHERE RecordStatus = 1
		AND (CMPNY +'='+ QualityOrderID) NOT IN 
			(
			--SELECT QualityOrder_Number
			--FROM stage_tbl_DIM_QualityOrder_Expired
			--UNION
			SELECT CMPNY +'='+ QualityOrderID
			FROM stage_tbl_DIM_QualityOrder_Deleted
			UNION
			SELECT CMPNY +'='+ QualityOrderID
			FROM stage_tbl_DIM_QualityOrder_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	---- Expire old records
	--SELECT QualityOrderKey
	--	, QualityOrder_Number
	--	, QualityOrder_Name
	--	, Account_Category
	--	, Account_Category_Name
	--	, Account_Type
	--	, Account_Type_Description
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_QualityOrder_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.QualityOrderKey
	--	, s.QualityOrder_Number
	--	, s.QualityOrder_Name
	--	, s.Account_Category
	--	, s.Account_Category_Name
	--	, s.Account_Type
	--	, s.Account_Type_Description
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_QualityOrder_incoming s
	--JOIN stage_tbl_DIM_QualityOrder_Expired e
	--	ON s.QualityOrder_Number = e.QualityOrder_Number
	
	--UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_QualityOrder_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_QualityOrder_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT QualityOrderKey
		, CMPNY
		, QualityOrderID

		, inventrefid
		, inventreftransid
		, ProductID
		, itemsamplingid
		, oprnum
		, orderstatus
		, orderstatus_$label
		, qty
		, referencetype
		, referencetype_$label
		, routeid
		, testgroupid

		, Source
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_QualityOrder_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_QualityOrder_Append AS
	SELECT *
	FROM tbl_DIM_QualityOrder f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_QualityOrder_Final AS d
			WHERE d.QualityOrderID = f.QualityOrderID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_QualityOrder_Final AS f
	ORDER BY CMPNY
		,QualityOrderID
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_QualityOrder;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_QualityOrder AS
	SELECT *
	FROM stage_tbl_DIM_QualityOrder_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_QualityOrder_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_QualityOrder_incoming;
END;