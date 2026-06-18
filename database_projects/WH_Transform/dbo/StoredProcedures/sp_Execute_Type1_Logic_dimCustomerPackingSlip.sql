--use WH_Transform
--go


--drop PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimCustomerPackingSlip]


CREATE       PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimCustomerPackingSlip]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_New AS
	SELECT *
	FROM vw_stage_NewCustomerPackingSlip
--select 'completed step 1'
	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_CustomerPackingSlip AS Target
	--JOIN vw_stage_DIM_CustomerPackingSlip_incoming AS Source
	--	ON Target.CustomerPackingSlip = Source.CustomerPackingSlip
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
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_CustomerPackingSlip AS Target
	JOIN vw_stage_DIM_CustomerPackingSlip_incoming AS Source
		ON Target.CustomerPackingSlipID = Source.CustomerPackingSlipID
		  AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.SalesId, '') <> ISNULL(Source.SalesId, '')
			OR ISNULL(Target.ShipDate, '01/01/1900') <> ISNULL(Source.ShipDate, '01/01/1900')
			OR ISNULL(Target.DocumentDate, '01/01/1900') <> ISNULL(Source.DocumentDate, '01/01/1900')
			OR ISNULL(Target.CustomerAccount, '') <> ISNULL(Source.CustomerAccount, '')
			OR ISNULL(Target.InvoiceAccount, '') <> ISNULL(Source.InvoiceAccount, '')
			OR ISNULL(Target.CustomerPO, '') <> ISNULL(Source.CustomerPO, '')
			OR ISNULL(Target.ShipToName, '') <> ISNULL(Source.ShipToName, '')
			OR ISNULL(Target.DeliveryMode, '') <> ISNULL(Source.DeliveryMode, '')
			OR ISNULL(Target.DeliveryTerms, '') <> ISNULL(Source.DeliveryTerms, '')
			OR ISNULL(Target.DeliveryReason, '') <> ISNULL(Source.DeliveryReason, '')
			OR ISNULL(Target.ShipFromWarehouse, '') <> ISNULL(Source.ShipFromWarehouse, '')
			OR ISNULL(Target.CarrierId, '') <> ISNULL(Source.CarrierId, '')
			OR ISNULL(Target.CreatedDateTime, '01/01/1900') <> ISNULL(Source.CreatedDateTime, '01/01/1900')
			)

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Type1_OnlyUpdatedRecords AS
	SELECT Target.CustomerPackingSlipKey
		, Target.CMPNY
		, Target.CustomerPackingSlipID

		, Source.SalesId
		, Source.ShipDate
		, Source.DocumentDate
		, Source.CustomerAccount
		, Source.InvoiceAccount
		, Source.CustomerPO
		, Source.ShipToName
		, Source.DeliveryMode
		, Source.DeliveryTerms
		, Source.DeliveryReason
		, Source.ShipFromWarehouse
		, Source.CarrierId
		, Source.CreatedDateTime

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_CustomerPackingSlip_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_CustomerPackingSlip_incoming AS Source
		ON Target.CustomerPackingSlipID = Source.CustomerPackingSlipID
		  AND Target.CMPNY = Source.CMPNY
--select 'completed step 3'

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Deleted AS
	SELECT *
	FROM tbl_DIM_CustomerPackingSlip AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_CustomerPackingSlip_incoming AS Source
			WHERE Target.CustomerPackingSlipID = Source.CustomerPackingSlipID
				  AND Target.CMPNY = Source.CMPNY

			);
--select 'completed step 4'

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_CustomerPackingSlip
	WHERE RecordStatus = 1
		AND (CMPNY + '~=~' +CustomerPackingSlipID) NOT IN 
			(
			--SELECT CustomerPackingSlip 
			--FROM stage_tbl_DIM_CustomerPackingSlip_Expired
			--UNION
			SELECT CMPNY + '~=~' +CustomerPackingSlipID
			FROM stage_tbl_DIM_CustomerPackingSlip_Deleted
			UNION
			SELECT CMPNY + '~=~' +CustomerPackingSlipID
			FROM stage_tbl_DIM_CustomerPackingSlip_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [CustomerPackingSlipKey]
	--	, [CMPNY]
	--	, CustomerPackingSlip
	--	, Invoice_Account
	--	, Legacy_CustomerPackingSlip
	--	, GMAccountNo
	--	, GMRecID
	--	, CustomerPackingSlipName
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
	--FROM stage_tbl_DIM_CustomerPackingSlip_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[CustomerPackingSlipKey]
	--	, s.[CMPNY]
	--	, s.CustomerPackingSlip
	--	, s.Invoice_Account
	--	, s.Legacy_CustomerPackingSlip
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.CustomerPackingSlipName
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
	--FROM vw_stage_DIM_CustomerPackingSlip_incoming s
	--JOIN stage_tbl_DIM_CustomerPackingSlip_Expired e
	--	ON s.CustomerPackingSlip = e.CustomerPackingSlip
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_CustomerPackingSlip_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_CustomerPackingSlip_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT CustomerPackingSlipKey
		, CMPNY
		, CustomerPackingSlipID

		, SalesId
		, ShipDate
		, DocumentDate
		, CustomerAccount
		, InvoiceAccount
		, CustomerPO
		, ShipToName
		, DeliveryMode
		, DeliveryTerms
		, DeliveryReason
		, ShipFromWarehouse
		, CarrierId
		, CreatedDateTime

		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_CustomerPackingSlip_Deleted;
--select 'completed step 5'

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_CustomerPackingSlip_Append AS
	SELECT *
	FROM tbl_DIM_CustomerPackingSlip f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_CustomerPackingSlip_Final AS d
			WHERE d.CustomerPackingSlipID = f.CustomerPackingSlipID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_CustomerPackingSlip_Final AS f
	ORDER BY CMPNY
		,CustomerPackingSlipID
		,recordeffectivestartdate
--select 'completed step 6'

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_CustomerPackingSlip;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_CustomerPackingSlip AS
	SELECT *
	FROM stage_tbl_DIM_CustomerPackingSlip_Append;
--select 'completed step 7'

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_CustomerPackingSlip_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_CustomerPackingSlip_incoming;
END;