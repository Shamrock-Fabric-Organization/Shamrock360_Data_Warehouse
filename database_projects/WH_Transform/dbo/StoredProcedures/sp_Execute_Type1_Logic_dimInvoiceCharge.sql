
CREATE OR ALTER      PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimInvoiceCharge]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewInvoiceCharge
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_New AS
	SELECT *
	FROM vw_stage_NewInvoiceCharge

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	---- (Type 1: not used. Block kept disabled, with this dimension's own columns, as the starting point for a Type 2 conversion.)
	--CREATE TABLE stage_tbl_DIM_InvoiceCharge_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_InvoiceCharge AS Target
	--JOIN vw_stage_DIM_InvoiceCharge_incoming AS Source
	--	ON Target.CMPNY = Source.CMPNY
	--			AND Target.MarkupCode = Source.MarkupCode
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.ChargeDescription, '') <> ISNULL(Source.ChargeDescription, '')
	--		OR ISNULL(Target.TaxItemGroup, '') <> ISNULL(Source.TaxItemGroup, '')
	--		OR ISNULL(Target.MaxAmount, 0) <> ISNULL(Source.MaxAmount, 0)
	--		OR ISNULL(Target.IsShipping, 0) <> ISNULL(Source.IsShipping, 0)
	--		OR ISNULL(Target.IsRefundable, 0) <> ISNULL(Source.IsRefundable, 0)
	--		OR ISNULL(Target.InMarkupTable, 0) <> ISNULL(Source.InMarkupTable, 0)
	--		);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_InvoiceCharge AS Target
	JOIN vw_stage_DIM_InvoiceCharge_incoming AS Source
		ON Target.CMPNY = Source.CMPNY
		  AND Target.MarkupCode = Source.MarkupCode
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.ChargeDescription, '') <> ISNULL(Source.ChargeDescription, '')
			OR ISNULL(Target.TaxItemGroup, '') <> ISNULL(Source.TaxItemGroup, '')
			OR ISNULL(Target.MaxAmount, 0) <> ISNULL(Source.MaxAmount, 0)
			OR ISNULL(Target.IsShipping, 0) <> ISNULL(Source.IsShipping, 0)
			OR ISNULL(Target.IsRefundable, 0) <> ISNULL(Source.IsRefundable, 0)
			OR ISNULL(Target.InMarkupTable, 0) <> ISNULL(Source.InMarkupTable, 0)
			)


	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_Type1_OnlyUpdatedRecords AS
	SELECT Target.InvoiceChargeKey
		, Target.CMPNY
		, Target.MarkupCode

		, Source.ChargeDescription
		, Source.TaxItemGroup
		, Source.MaxAmount
		, Source.IsShipping
		, Source.IsRefundable
		, Source.InMarkupTable

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_InvoiceCharge_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_InvoiceCharge_incoming AS Source
		ON Target.CMPNY = Source.CMPNY
		  AND Target.MarkupCode = Source.MarkupCode

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_Deleted AS
	SELECT *
	FROM tbl_DIM_InvoiceCharge AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_InvoiceCharge_incoming AS Source
			WHERE Target.CMPNY = Source.CMPNY
				  AND Target.MarkupCode = Source.MarkupCode

			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_InvoiceCharge
	WHERE RecordStatus = 1
		AND (ISNULL(CMPNY, '') + '~=~' + ISNULL(MarkupCode, '')) NOT IN 
			(
			--SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(MarkupCode, '') 
			--FROM stage_tbl_DIM_InvoiceCharge_Expired
			--UNION
			SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(MarkupCode, '')
			FROM stage_tbl_DIM_InvoiceCharge_Deleted
			UNION
			SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(MarkupCode, '')
			FROM stage_tbl_DIM_InvoiceCharge_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records (Type 2 only, disabled)
	--SELECT [InvoiceChargeKey]
	--	, CMPNY
	--	, MarkupCode
	--	, ChargeDescription
	--	, TaxItemGroup
	--	, MaxAmount
	--	, IsShipping
	--	, IsRefundable
	--	, InMarkupTable
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_InvoiceCharge_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records (Type 2 only, disabled)
	--SELECT s.[InvoiceChargeKey]
	--	, s.CMPNY
	--	, s.MarkupCode
	--	, s.ChargeDescription
	--	, s.TaxItemGroup
	--	, s.MaxAmount
	--	, s.IsShipping
	--	, s.IsRefundable
	--	, s.InMarkupTable
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_InvoiceCharge_incoming s
	--JOIN stage_tbl_DIM_InvoiceCharge_Expired e
	--	ON s.CMPNY = e.CMPNY
	--			AND s.MarkupCode = e.MarkupCode
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_InvoiceCharge_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_InvoiceCharge_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT InvoiceChargeKey
		, CMPNY
		, MarkupCode

		, ChargeDescription
		, TaxItemGroup
		, MaxAmount
		, IsShipping
		, IsRefundable
		, InMarkupTable

		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_InvoiceCharge_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_InvoiceCharge_Append AS
	SELECT *
	FROM tbl_DIM_InvoiceCharge f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_InvoiceCharge_Final AS d
			WHERE d.CMPNY = f.CMPNY
				AND d.MarkupCode = f.MarkupCode
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_InvoiceCharge_Final AS f
	ORDER BY CMPNY
		,MarkupCode
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	BEGIN TRY
	BEGIN TRAN;

	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_InvoiceCharge;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_InvoiceCharge AS
	SELECT *
	FROM stage_tbl_DIM_InvoiceCharge_Append;
		
	COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		THROW;
	END CATCH

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_InvoiceCharge_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_InvoiceCharge_incoming;
END;
