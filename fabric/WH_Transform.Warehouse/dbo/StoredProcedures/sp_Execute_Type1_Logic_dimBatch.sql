CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimBatch]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Batch_New AS
	SELECT *
	FROM vw_stage_NewBatch

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_Batch_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Batch AS Target
	--JOIN vw_stage_DIM_Batch_incoming AS Source
	--	ON Target.Batch = Source.Batch
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
	CREATE TABLE stage_tbl_DIM_Batch_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Batch AS Target
	JOIN vw_stage_DIM_Batch_incoming AS Source
		ON Target.BatchID = Source.BatchID
		  AND Target.CMPNY = Source.CMPNY
		  AND Target.ProductID = Source.ProductID
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.CountryOfOrigin, '') <> ISNULL(Source.CountryOfOrigin, '')
			OR ISNULL(Target.DispositionCode, '') <> ISNULL(Source.DispositionCode, '')
			OR ISNULL(Target.ProductionDate, '01/01/1900') <> ISNULL(Source.ProductionDate, '01/01/1900')
			OR ISNULL(Target.FGTestedDate, '01/01/1900') <> ISNULL(Source.FGTestedDate, '01/01/1900')
			OR ISNULL(Target.ExpirationDate, '01/01/1900') <> ISNULL(Source.ExpirationDate, '01/01/1900')
			OR ISNULL(Target.BestBeforeDate, '01/01/1900') <> ISNULL(Source.BestBeforeDate, '01/01/1900')
			OR ISNULL(Target.ShelfAdviceDate, '01/01/1900') <> ISNULL(Source.ShelfAdviceDate, '01/01/1900')
			OR ISNULL(Target.VendorBatchDate, '01/01/1900') <> ISNULL(Source.VendorBatchDate, '01/01/1900')
			OR ISNULL(Target.VendorExpirationDate, '01/01/1900') <> ISNULL(Source.VendorExpirationDate, '01/01/1900')
			OR ISNULL(Target.VendorBatchID, '') <> ISNULL(Source.VendorBatchID, '')
			OR ISNULL(Target.BatchNoteName, '') <> ISNULL(Source.BatchNoteName, '')
			OR ISNULL(Target.BatchNote, '') <> ISNULL(Source.BatchNote, '')
			OR ISNULL(Target.BatchNoteCreatedBy, '') <> ISNULL(Source.BatchNoteCreatedBy, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Batch_Type1_OnlyUpdatedRecords AS
	SELECT Target.BatchKey
		, Target.CMPNY
		, Target.BatchID
		, Target.ProductID
		, Source.CountryOfOrigin
		, Source.DispositionCode
		, Source.ProductionDate
		, Source.FGTestedDate
		, Source.ExpirationDate
		, Source.BestBeforeDate
		, Source.ShelfAdviceDate
		, Source.VendorBatchDate
		, Source.VendorExpirationDate
		, Source.VendorBatchID
		, Source.BatchNoteName
		, Source.BatchNote
		, Source.BatchNoteCreatedBy

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Batch_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Batch_incoming AS Source
		ON Target.BatchID = Source.BatchID
		  AND Target.CMPNY = Source.CMPNY
		  AND Target.ProductID = Source.ProductID

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Batch_Deleted AS
	SELECT *
	FROM tbl_DIM_Batch AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Batch_incoming AS Source
			WHERE Target.BatchID = Source.BatchID
				  AND Target.CMPNY = Source.CMPNY
				  AND Target.ProductID = Source.ProductID

			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Batch_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Batch
	WHERE RecordStatus = 1
		AND (CMPNY + '~=~' +BatchID + '~=~' + ProductID) NOT IN 
			(
			--SELECT Batch 
			--FROM stage_tbl_DIM_Batch_Expired
			--UNION
			SELECT CMPNY + '~=~' +BatchID + '~=~' + ProductID
			FROM stage_tbl_DIM_Batch_Deleted
			UNION
			SELECT CMPNY + '~=~' +BatchID  + '~=~' + ProductID
			FROM stage_tbl_DIM_Batch_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [BatchKey]
	--	, [CMPNY]
	--	, Batch
	--	, Invoice_Account
	--	, Legacy_Batch
	--	, GMAccountNo
	--	, GMRecID
	--	, BatchName
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
	--FROM stage_tbl_DIM_Batch_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[BatchKey]
	--	, s.[CMPNY]
	--	, s.Batch
	--	, s.Invoice_Account
	--	, s.Legacy_Batch
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.BatchName
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
	--FROM vw_stage_DIM_Batch_incoming s
	--JOIN stage_tbl_DIM_Batch_Expired e
	--	ON s.Batch = e.Batch
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Batch_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Batch_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT BatchKey
		, CMPNY
		, BatchID
		, ProductID
		, CountryOfOrigin
		, DispositionCode
		, ProductionDate
		, FGTestedDate
		, ExpirationDate
		, BestBeforeDate
		, ShelfAdviceDate
		, VendorBatchDate
		, VendorExpirationDate
		, VendorBatchID

		, BatchNoteName
		, BatchNote
		, BatchNoteCreatedBy

		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Batch_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Batch_Append AS
	SELECT *
	FROM tbl_DIM_Batch f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Batch_Final AS d
			WHERE d.BatchID = f.BatchID
				AND d.CMPNY = f.CMPNY
 				AND d.ProductID = f.ProductID
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Batch_Final AS f
	ORDER BY CMPNY
		,BatchID
		,ProductID
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Batch;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Batch AS
	SELECT *
	FROM stage_tbl_DIM_Batch_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Batch_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Batch_incoming;
END;