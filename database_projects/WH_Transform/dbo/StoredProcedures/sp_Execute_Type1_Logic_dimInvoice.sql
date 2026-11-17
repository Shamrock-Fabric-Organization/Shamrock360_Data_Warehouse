
CREATE OR ALTER      PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimInvoice]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewInvoice
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Invoice_New AS
	SELECT *
	FROM vw_stage_NewInvoice

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	---- (Type 1: not used. Block kept disabled, with this dimension's own columns, as the starting point for a Type 2 conversion.)
	--CREATE TABLE stage_tbl_DIM_Invoice_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Invoice AS Target
	--JOIN vw_stage_DIM_Invoice_incoming AS Source
	--	ON Target.CMPNY = Source.CMPNY
	--			AND Target.Invoice_ID = Source.Invoice_ID
	--			AND Target.InvoiceDate = Source.InvoiceDate
	--			AND Target.Sales_ID = Source.Sales_ID
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Order_Account, '') <> ISNULL(Source.Order_Account, '')
	--		OR ISNULL(Target.Invoice_Account, '') <> ISNULL(Source.Invoice_Account, '')
	--		OR ISNULL(Target.CustomerGroup, '') <> ISNULL(Source.CustomerGroup, '')
	--		OR ISNULL(Target.CustomerRef, '') <> ISNULL(Source.CustomerRef, '')
	--		OR ISNULL(Target.CustomerPONumber, '') <> ISNULL(Source.CustomerPONumber, '')
	--		OR ISNULL(Target.DocumentNum, '') <> ISNULL(Source.DocumentNum, '')
	--		OR ISNULL(Target.BillOfLadingId, '') <> ISNULL(Source.BillOfLadingId, '')
	--		OR ISNULL(Target.LedgerVoucher, '') <> ISNULL(Source.LedgerVoucher, '')
	--		OR ISNULL(Target.SalesOriginId, '') <> ISNULL(Source.SalesOriginId, '')
	--		OR ISNULL(Target.SalesType, 0) <> ISNULL(Source.SalesType, 0)
	--		OR ISNULL(Target.SalesTypeDesc, '') <> ISNULL(Source.SalesTypeDesc, '')
	--		OR ISNULL(Target.ReferenceType, 0) <> ISNULL(Source.ReferenceType, 0)
	--		OR ISNULL(Target.ReferenceTypeDesc, '') <> ISNULL(Source.ReferenceTypeDesc, '')
	--		OR ISNULL(Target.PostedStateID, 0) <> ISNULL(Source.PostedStateID, 0)
	--		OR ISNULL(Target.PostedState, '') <> ISNULL(Source.PostedState, '')
	--		OR ISNULL(Target.IsCorrection, '') <> ISNULL(Source.IsCorrection, '')
	--		OR ISNULL(Target.IsProforma, '') <> ISNULL(Source.IsProforma, '')
	--		OR ISNULL(Target.IsPrepayment, '') <> ISNULL(Source.IsPrepayment, '')
	--		OR ISNULL(Target.CurrencyCode, '') <> ISNULL(Source.CurrencyCode, '')
	--		OR ISNULL(Target.Tax_Group, '') <> ISNULL(Source.Tax_Group, '')
	--		OR ISNULL(Target.PostingProfile, '') <> ISNULL(Source.PostingProfile, '')
	--		OR ISNULL(Target.PaymentTermId, '') <> ISNULL(Source.PaymentTermId, '')
	--		OR ISNULL(Target.PaymentTermDescription, '') <> ISNULL(Source.PaymentTermDescription, '')
	--		OR ISNULL(Target.DocumentDate, '01/01/1900') <> ISNULL(Source.DocumentDate, '01/01/1900')
	--		OR ISNULL(Target.DueDate, '01/01/1900') <> ISNULL(Source.DueDate, '01/01/1900')
	--		OR ISNULL(Target.DeliveryModeCode, '') <> ISNULL(Source.DeliveryModeCode, '')
	--		OR ISNULL(Target.DeliveryModeDescription, '') <> ISNULL(Source.DeliveryModeDescription, '')
	--		OR ISNULL(Target.DeliveryTermCode, '') <> ISNULL(Source.DeliveryTermCode, '')
	--		OR ISNULL(Target.DeliveryTermDescription, '') <> ISNULL(Source.DeliveryTermDescription, '')
	--		OR ISNULL(Target.DeliveryName, '') <> ISNULL(Source.DeliveryName, '')
	--		OR ISNULL(Target.CreatedDateTime, '01/01/1900') <> ISNULL(Source.CreatedDateTime, '01/01/1900')
	--		OR ISNULL(Target.ModifiedDateTime, '01/01/1900') <> ISNULL(Source.ModifiedDateTime, '01/01/1900')
	--		);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_Invoice_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Invoice AS Target
	JOIN vw_stage_DIM_Invoice_incoming AS Source
		ON Target.CMPNY = Source.CMPNY
		  AND Target.Invoice_ID = Source.Invoice_ID
		  AND Target.InvoiceDate = Source.InvoiceDate
		  AND Target.Sales_ID = Source.Sales_ID
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Order_Account, '') <> ISNULL(Source.Order_Account, '')
			OR ISNULL(Target.Invoice_Account, '') <> ISNULL(Source.Invoice_Account, '')
			OR ISNULL(Target.CustomerGroup, '') <> ISNULL(Source.CustomerGroup, '')
			OR ISNULL(Target.CustomerRef, '') <> ISNULL(Source.CustomerRef, '')
			OR ISNULL(Target.CustomerPONumber, '') <> ISNULL(Source.CustomerPONumber, '')
			OR ISNULL(Target.DocumentNum, '') <> ISNULL(Source.DocumentNum, '')
			OR ISNULL(Target.BillOfLadingId, '') <> ISNULL(Source.BillOfLadingId, '')
			OR ISNULL(Target.LedgerVoucher, '') <> ISNULL(Source.LedgerVoucher, '')
			OR ISNULL(Target.SalesOriginId, '') <> ISNULL(Source.SalesOriginId, '')
			OR ISNULL(Target.SalesType, 0) <> ISNULL(Source.SalesType, 0)
			OR ISNULL(Target.SalesTypeDesc, '') <> ISNULL(Source.SalesTypeDesc, '')
			OR ISNULL(Target.ReferenceType, 0) <> ISNULL(Source.ReferenceType, 0)
			OR ISNULL(Target.ReferenceTypeDesc, '') <> ISNULL(Source.ReferenceTypeDesc, '')
			OR ISNULL(Target.PostedStateID, 0) <> ISNULL(Source.PostedStateID, 0)
			OR ISNULL(Target.PostedState, '') <> ISNULL(Source.PostedState, '')
			OR ISNULL(Target.IsCorrection, '') <> ISNULL(Source.IsCorrection, '')
			OR ISNULL(Target.IsProforma, '') <> ISNULL(Source.IsProforma, '')
			OR ISNULL(Target.IsPrepayment, '') <> ISNULL(Source.IsPrepayment, '')
			OR ISNULL(Target.CurrencyCode, '') <> ISNULL(Source.CurrencyCode, '')
			OR ISNULL(Target.Tax_Group, '') <> ISNULL(Source.Tax_Group, '')
			OR ISNULL(Target.PostingProfile, '') <> ISNULL(Source.PostingProfile, '')
			OR ISNULL(Target.PaymentTermId, '') <> ISNULL(Source.PaymentTermId, '')
			OR ISNULL(Target.PaymentTermDescription, '') <> ISNULL(Source.PaymentTermDescription, '')
			OR ISNULL(Target.DocumentDate, '01/01/1900') <> ISNULL(Source.DocumentDate, '01/01/1900')
			OR ISNULL(Target.DueDate, '01/01/1900') <> ISNULL(Source.DueDate, '01/01/1900')
			OR ISNULL(Target.DeliveryModeCode, '') <> ISNULL(Source.DeliveryModeCode, '')
			OR ISNULL(Target.DeliveryModeDescription, '') <> ISNULL(Source.DeliveryModeDescription, '')
			OR ISNULL(Target.DeliveryTermCode, '') <> ISNULL(Source.DeliveryTermCode, '')
			OR ISNULL(Target.DeliveryTermDescription, '') <> ISNULL(Source.DeliveryTermDescription, '')
			OR ISNULL(Target.DeliveryName, '') <> ISNULL(Source.DeliveryName, '')
			OR ISNULL(Target.CreatedDateTime, '01/01/1900') <> ISNULL(Source.CreatedDateTime, '01/01/1900')
			OR ISNULL(Target.ModifiedDateTime, '01/01/1900') <> ISNULL(Source.ModifiedDateTime, '01/01/1900')
			)


	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Invoice_Type1_OnlyUpdatedRecords AS
	SELECT Target.InvoiceKey
		, Target.CMPNY
		, Target.Invoice_ID
		, Target.InvoiceDate
		, Target.Sales_ID

		, Source.Order_Account
		, Source.Invoice_Account
		, Source.CustomerGroup
		, Source.CustomerRef
		, Source.CustomerPONumber
		, Source.DocumentNum
		, Source.BillOfLadingId
		, Source.LedgerVoucher
		, Source.SalesOriginId
		, Source.SalesType
		, Source.SalesTypeDesc
		, Source.ReferenceType
		, Source.ReferenceTypeDesc
		, Source.PostedStateID
		, Source.PostedState
		, Source.IsCorrection
		, Source.IsProforma
		, Source.IsPrepayment
		, Source.CurrencyCode
		, Source.Tax_Group
		, Source.PostingProfile
		, Source.PaymentTermId
		, Source.PaymentTermDescription
		, Source.DocumentDate
		, Source.DueDate
		, Source.DeliveryModeCode
		, Source.DeliveryModeDescription
		, Source.DeliveryTermCode
		, Source.DeliveryTermDescription
		, Source.DeliveryName
		, Source.CreatedDateTime
		, Source.ModifiedDateTime

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Invoice_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Invoice_incoming AS Source
		ON Target.CMPNY = Source.CMPNY
		  AND Target.Invoice_ID = Source.Invoice_ID
		  AND Target.InvoiceDate = Source.InvoiceDate
		  AND Target.Sales_ID = Source.Sales_ID

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Invoice_Deleted AS
	SELECT *
	FROM tbl_DIM_Invoice AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Invoice_incoming AS Source
			WHERE Target.CMPNY = Source.CMPNY
				  AND Target.Invoice_ID = Source.Invoice_ID
				  AND Target.InvoiceDate = Source.InvoiceDate
				  AND Target.Sales_ID = Source.Sales_ID

			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Invoice_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Invoice
	WHERE RecordStatus = 1
		AND (ISNULL(CMPNY, '') + '~=~' + ISNULL(Invoice_ID, '') + '~=~' + ISNULL(CONVERT(varchar(30), InvoiceDate, 121), '') + '~=~' + ISNULL(Sales_ID, '')) NOT IN 
			(
			--SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(Invoice_ID, '') + '~=~' + ISNULL(CONVERT(varchar(30), InvoiceDate, 121), '') + '~=~' + ISNULL(Sales_ID, '') 
			--FROM stage_tbl_DIM_Invoice_Expired
			--UNION
			SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(Invoice_ID, '') + '~=~' + ISNULL(CONVERT(varchar(30), InvoiceDate, 121), '') + '~=~' + ISNULL(Sales_ID, '')
			FROM stage_tbl_DIM_Invoice_Deleted
			UNION
			SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(Invoice_ID, '') + '~=~' + ISNULL(CONVERT(varchar(30), InvoiceDate, 121), '') + '~=~' + ISNULL(Sales_ID, '')
			FROM stage_tbl_DIM_Invoice_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records (Type 2 only, disabled)
	--SELECT [InvoiceKey]
	--	, CMPNY
	--	, Invoice_ID
	--	, InvoiceDate
	--	, Sales_ID
	--	, Order_Account
	--	, Invoice_Account
	--	, CustomerGroup
	--	, CustomerRef
	--	, CustomerPONumber
	--	, DocumentNum
	--	, BillOfLadingId
	--	, LedgerVoucher
	--	, SalesOriginId
	--	, SalesType
	--	, SalesTypeDesc
	--	, ReferenceType
	--	, ReferenceTypeDesc
	--	, PostedStateID
	--	, PostedState
	--	, IsCorrection
	--	, IsProforma
	--	, IsPrepayment
	--	, CurrencyCode
	--	, Tax_Group
	--	, PostingProfile
	--	, PaymentTermId
	--	, PaymentTermDescription
	--	, DocumentDate
	--	, DueDate
	--	, DeliveryModeCode
	--	, DeliveryModeDescription
	--	, DeliveryTermCode
	--	, DeliveryTermDescription
	--	, DeliveryName
	--	, CreatedDateTime
	--	, ModifiedDateTime
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_Invoice_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records (Type 2 only, disabled)
	--SELECT s.[InvoiceKey]
	--	, s.CMPNY
	--	, s.Invoice_ID
	--	, s.InvoiceDate
	--	, s.Sales_ID
	--	, s.Order_Account
	--	, s.Invoice_Account
	--	, s.CustomerGroup
	--	, s.CustomerRef
	--	, s.CustomerPONumber
	--	, s.DocumentNum
	--	, s.BillOfLadingId
	--	, s.LedgerVoucher
	--	, s.SalesOriginId
	--	, s.SalesType
	--	, s.SalesTypeDesc
	--	, s.ReferenceType
	--	, s.ReferenceTypeDesc
	--	, s.PostedStateID
	--	, s.PostedState
	--	, s.IsCorrection
	--	, s.IsProforma
	--	, s.IsPrepayment
	--	, s.CurrencyCode
	--	, s.Tax_Group
	--	, s.PostingProfile
	--	, s.PaymentTermId
	--	, s.PaymentTermDescription
	--	, s.DocumentDate
	--	, s.DueDate
	--	, s.DeliveryModeCode
	--	, s.DeliveryModeDescription
	--	, s.DeliveryTermCode
	--	, s.DeliveryTermDescription
	--	, s.DeliveryName
	--	, s.CreatedDateTime
	--	, s.ModifiedDateTime
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_Invoice_incoming s
	--JOIN stage_tbl_DIM_Invoice_Expired e
	--	ON s.CMPNY = e.CMPNY
	--			AND s.Invoice_ID = e.Invoice_ID
	--			AND s.InvoiceDate = e.InvoiceDate
	--			AND s.Sales_ID = e.Sales_ID
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Invoice_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Invoice_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT InvoiceKey
		, CMPNY
		, Invoice_ID
		, InvoiceDate
		, Sales_ID

		, Order_Account
		, Invoice_Account
		, CustomerGroup
		, CustomerRef
		, CustomerPONumber
		, DocumentNum
		, BillOfLadingId
		, LedgerVoucher
		, SalesOriginId
		, SalesType
		, SalesTypeDesc
		, ReferenceType
		, ReferenceTypeDesc
		, PostedStateID
		, PostedState
		, IsCorrection
		, IsProforma
		, IsPrepayment
		, CurrencyCode
		, Tax_Group
		, PostingProfile
		, PaymentTermId
		, PaymentTermDescription
		, DocumentDate
		, DueDate
		, DeliveryModeCode
		, DeliveryModeDescription
		, DeliveryTermCode
		, DeliveryTermDescription
		, DeliveryName
		, CreatedDateTime
		, ModifiedDateTime

		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Invoice_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Invoice_Append AS
	SELECT *
	FROM tbl_DIM_Invoice f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Invoice_Final AS d
			WHERE d.CMPNY = f.CMPNY
				AND d.Invoice_ID = f.Invoice_ID
				AND d.InvoiceDate = f.InvoiceDate
				AND d.Sales_ID = f.Sales_ID
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Invoice_Final AS f
	ORDER BY CMPNY
		,Invoice_ID
		,InvoiceDate
		,Sales_ID
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	BEGIN TRY
	BEGIN TRAN;

	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Invoice;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Invoice AS
	SELECT *
	FROM stage_tbl_DIM_Invoice_Append;
		
	COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		THROW;
	END CATCH

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Invoice_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Invoice_incoming;
END;
