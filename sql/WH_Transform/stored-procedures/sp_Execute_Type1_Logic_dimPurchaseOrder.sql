CREATE         PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimPurchaseOrder]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_New AS
	SELECT *
	FROM vw_stage_NewPurchaseOrder

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_PurchaseOrder_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_PurchaseOrder AS Target
	--JOIN vw_stage_DIM_PurchaseOrder_incoming AS Source
	--	ON Target.PurchaseOrder_Number = Source.PurchaseOrder_Number
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
	--		OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
	--		OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
	--		OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
	--		OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
	--		);

	---- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_PurchaseOrder AS Target
	JOIN vw_stage_DIM_PurchaseOrder_incoming AS Source
		ON Target.PurchaseOrderNumber = Source.PurchaseOrderNumber
		  AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.PurchaseOrderName, '') <> ISNULL(Source.PurchaseOrderName, '')
			OR ISNULL(Target.VendorAccount, '') <> ISNULL(Source.VendorAccount, '')
			OR ISNULL(Target.InvoiceVendorAccount, '') <> ISNULL(Source.InvoiceVendorAccount, '')
			OR ISNULL(Target.PaymentTerms, '') <> ISNULL(Source.PaymentTerms, '')
			OR ISNULL(Target.PaymentTermsDesc, '') <> ISNULL(Source.PaymentTermsDesc, '')
			OR ISNULL(Target.PaymentTermsNumOfDays, 0) <> ISNULL(Source.PaymentTermsNumOfDays, 0)
			OR ISNULL(Target.VendorReference, '') <> ISNULL(Source.VendorReference, '')
			OR ISNULL(Target.currencycode, '') <> ISNULL(Source.currencycode, '')
			OR ISNULL(Target.isencumbrancerequired, 0) <> ISNULL(Source.isencumbrancerequired, 0)
			OR ISNULL(Target.EncumberanceRequiredYN, '') <> ISNULL(Source.EncumberanceRequiredYN, '')
			OR ISNULL(Target.purchstatus, 0) <> ISNULL(Source.purchstatus, 0)
			OR ISNULL(Target.PurchStatusDesc, '') <> ISNULL(Source.PurchStatusDesc, '')
			OR ISNULL(Target.ReturnReasonDesc, '') <> ISNULL(Source.ReturnReasonDesc, '')
			OR ISNULL(Target.ReturnReasonGroupDesc, '') <> ISNULL(Source.ReturnReasonGroupDesc, '')
			OR ISNULL(Target.Warehouse, '') <> ISNULL(Source.Warehouse, '')
			OR ISNULL(Target.SiteID, '') <> ISNULL(Source.SiteID, '')
			OR ISNULL(Target.deliveryname, '') <> ISNULL(Source.deliveryname, '')
			OR ISNULL(Target.itembuyergroupid, '') <> ISNULL(Source.itembuyergroupid, '')
			OR ISNULL(Target.purchpoolid, '') <> ISNULL(Source.purchpoolid, '')
			OR ISNULL(Target.PurchPoolName, '') <> ISNULL(Source.PurchPoolName, '')
			OR ISNULL(Target.RequestorPersonnelNumber, '') <> ISNULL(Source.RequestorPersonnelNumber, '')
			OR ISNULL(Target.RequestorName, '') <> ISNULL(Source.RequestorName, '')
			OR ISNULL(Target.POPlacerPersonnelNumber, '') <> ISNULL(Source.POPlacerPersonnelNumber, '')
			OR ISNULL(Target.POPlacerName, '') <> ISNULL(Source.POPlacerName, '')
			OR ISNULL(Target.dlvterm, '') <> ISNULL(Source.dlvterm, '')
			OR ISNULL(Target.minDeliveryDate, '') <> ISNULL(Source.minDeliveryDate, '')
			OR ISNULL(Target.maxDeliveryDate, '') <> ISNULL(Source.maxDeliveryDate, '')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_Type1_OnlyUpdatedRecords AS
	SELECT Target.PurchaseOrderKey
		, Target.CMPNY
		, Target.PurchaseOrderNumber
		, Source.PurchaseOrderName
		, Source.VendorAccount
		, Source.InvoiceVendorAccount
		, Source.PaymentTerms
		, Source.PaymentTermsDesc
		, Source.PaymentTermsNumOfDays
		, Source.VendorReference
		, Source.currencycode
		, Source.isencumbrancerequired
		, Source.EncumberanceRequiredYN
		, Source.purchstatus
		, Source.PurchStatusDesc
		, Source.returnreasoncodeid
		, Source.ReturnReasonDesc
		, Source.ReturnReasonGroupDesc
		, Source.createddatetime
		, Source.Warehouse
		, Source.SiteID
		, Source.deliveryname
		, Source.itembuyergroupid
		, Source.purchpoolid
		, Source.PurchPoolName
		, Source.RequestorPersonnelNumber
		, Source.RequestorName
		, Source.POPlacerPersonnelNumber
		, Source.POPlacerName
		, Source.dlvterm
		, Source.dlvmode
		, Source.minDeliveryDate
		, Source.maxDeliveryDate
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_PurchaseOrder_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_PurchaseOrder_incoming AS Source
		ON Target.PurchaseOrderNumber = Source.PurchaseOrderNumber
		  AND Target.CMPNY = Source.CMPNY

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_Deleted AS
	SELECT *
	FROM tbl_DIM_PurchaseOrder AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_PurchaseOrder_incoming AS Source
			WHERE Source.PurchaseOrderNumber = Target.PurchaseOrderNumber
				  AND Target.CMPNY = Source.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_PurchaseOrder
	WHERE RecordStatus = 1
		AND (CMPNY + '=' +PurchaseOrderNumber) NOT IN 
			(
			--SELECT PurchaseOrder_Number
			--FROM stage_tbl_DIM_PurchaseOrder_Expired
			--UNION
			SELECT CMPNY + '=' +PurchaseOrderNumber
			FROM stage_tbl_DIM_PurchaseOrder_Deleted
			UNION
			SELECT CMPNY + '=' +PurchaseOrderNumber
			FROM stage_tbl_DIM_PurchaseOrder_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	---- Expire old records
	--SELECT PurchaseOrderKey
	--	, PurchaseOrder_Number
	--	, PurchaseOrder_Name
	--	, Account_Category
	--	, Account_Category_Name
	--	, Account_Type
	--	, Account_Type_Description
	--	, Source
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_PurchaseOrder_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.PurchaseOrderKey
	--	, s.PurchaseOrder_Number
	--	, s.PurchaseOrder_Name
	--	, s.Account_Category
	--	, s.Account_Category_Name
	--	, s.Account_Type
	--	, s.Account_Type_Description
	--	, s.Source
	--	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	,1 AS RecordStatus
	--FROM vw_stage_DIM_PurchaseOrder_incoming s
	--JOIN stage_tbl_DIM_PurchaseOrder_Expired e
	--	ON s.PurchaseOrder_Number = e.PurchaseOrder_Number
	
	--UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_PurchaseOrder_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_PurchaseOrder_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT PurchaseOrderKey
		, CMPNY
		, PurchaseOrderNumber
		, PurchaseOrderName
		, VendorAccount
		, InvoiceVendorAccount
		, PaymentTerms
		, PaymentTermsDesc
		, PaymentTermsNumOfDays
		, VendorReference
		, currencycode
		, isencumbrancerequired
		, EncumberanceRequiredYN
		, purchstatus
		, PurchStatusDesc
		, returnreasoncodeid
		, ReturnReasonDesc
		, ReturnReasonGroupDesc
		, createddatetime
		, Warehouse
		, SiteID
		, deliveryname
		, itembuyergroupid
		, purchpoolid
		, PurchPoolName
		, RequestorPersonnelNumber
		, RequestorName
		, POPlacerPersonnelNumber
		, POPlacerName
		, dlvterm
		, dlvmode
		, minDeliveryDate
		, maxDeliveryDate
		, Source
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_PurchaseOrder_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_PurchaseOrder_Append AS
	SELECT *
	FROM tbl_DIM_PurchaseOrder f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_PurchaseOrder_Final AS d
			WHERE d.PurchaseOrderNumber = f.PurchaseOrderNumber
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_PurchaseOrder_Final AS f
	ORDER BY CMPNY
		,PurchaseOrderNumber
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_PurchaseOrder;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_PurchaseOrder AS
	SELECT *
	FROM stage_tbl_DIM_PurchaseOrder_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_PurchaseOrder_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_PurchaseOrder_incoming;
END;