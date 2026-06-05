



CREATE       PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimSalesOrder]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_SalesOrder_New AS
	SELECT *
	FROM vw_stage_NewSalesOrder

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_SalesOrder_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_SalesOrder AS Target
	--JOIN vw_stage_DIM_SalesOrder_incoming AS Source
	--	ON Target.SalesOrder = Source.SalesOrder
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
	CREATE TABLE stage_tbl_DIM_SalesOrder_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_SalesOrder AS Target
	JOIN vw_stage_DIM_SalesOrder_incoming AS Source
		ON Target.SalesOrderID = Source.SalesOrderID
		  AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.SalesType, 0) <> ISNULL(Source.SalesType, 0)
			OR ISNULL(Target.SalesTypeDesc, '') <> ISNULL(Source.SalesTypeDesc, '')
			OR ISNULL(Target.SalesStatus, 0) <> ISNULL(Source.SalesStatus, 0)
			OR ISNULL(Target.SalesStatusDesc, '') <> ISNULL(Source.SalesStatusDesc, '')

			OR ISNULL(Target.DocumentStatus, 0) <> ISNULL(Source.DocumentStatus, 0)
			OR ISNULL(Target.DocumentStatusDesc, '') <> ISNULL(Source.DocumentStatusDesc, '')
			OR ISNULL(Target.SalesOriginId, '') <> ISNULL(Source.SalesOriginId, '')
			OR ISNULL(Target.SalesPoolId, '') <> ISNULL(Source.SalesPoolId, '')
			OR ISNULL(Target.DeliveryModeCode, '') <> ISNULL(Source.DeliveryModeCode, '')
			OR ISNULL(Target.DeliveryModeDescription, '') <> ISNULL(Source.DeliveryModeDescription, '')
			OR ISNULL(Target.DeliveryTermCode, '') <> ISNULL(Source.DeliveryTermCode, '')
			OR ISNULL(Target.DeliveryTermDescription, '') <> ISNULL(Source.DeliveryTermDescription, '')
			OR ISNULL(Target.DeliveryName, '') <> ISNULL(Source.DeliveryName, '')
			OR ISNULL(Target.DeliveryReason, '') <> ISNULL(Source.DeliveryReason, '')

			OR ISNULL(Target.SiteId, '') <> ISNULL(Source.SiteId, '')
			OR ISNULL(Target.WarehouseId, '') <> ISNULL(Source.WarehouseId, '')
			OR ISNULL(Target.PaymentTermDescription, '') <> ISNULL(Source.PaymentTermDescription, '')
			OR ISNULL(Target.CurrencyCode, '') <> ISNULL(Source.CurrencyCode, '')
			OR ISNULL(Target.SalesResponsiblePersonnelNo, '') <> ISNULL(Source.SalesResponsiblePersonnelNo, '')
			OR ISNULL(Target.SalesResponsibleName, '') <> ISNULL(Source.SalesResponsibleName, '')
			OR ISNULL(Target.SalesTakerPersonnelNo, '') <> ISNULL(Source.SalesTakerPersonnelNo, '')
			OR ISNULL(Target.CustomerPONumber, '') <> ISNULL(Source.CustomerPONumber, '')
			OR ISNULL(Target.QuotationId, '') <> ISNULL(Source.QuotationId, '')
			OR ISNULL(Target.ProjectId, '') <> ISNULL(Source.ProjectId, '')
			OR ISNULL(Target.ReturnItemNum, '') <> ISNULL(Source.ReturnItemNum, '')

			OR ISNULL(Target.OrderCreatedDate, '01/01/1900') <> ISNULL(Source.OrderCreatedDate, '01/01/1900')
			OR ISNULL(Target.ShippingDateRequested, '01/01/1900') <> ISNULL(Source.ShippingDateRequested, '01/01/1900')
			OR ISNULL(Target.ShippingDateConfirmed, '01/01/1900') <> ISNULL(Source.ShippingDateConfirmed, '01/01/1900')
			OR ISNULL(Target.ReceiptDateRequested, '01/01/1900') <> ISNULL(Source.ReceiptDateRequested, '01/01/1900')
			OR ISNULL(Target.ReceiptDateConfirmed, '01/01/1900') <> ISNULL(Source.ReceiptDateConfirmed, '01/01/1900')
			OR ISNULL(Target.CreatedDateTime, '01/01/1900') <> ISNULL(Source.CreatedDateTime, '01/01/1900')
			OR ISNULL(Target.ModifiedDateTime, '01/01/1900') <> ISNULL(Source.ModifiedDateTime, '01/01/1900')
			)


	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_SalesOrder_Type1_OnlyUpdatedRecords AS
	SELECT Target.SalesOrderKey
		, Target.CMPNY
		, Target.SalesOrderID

		, Source.SalesType
		, Source.SalesTypeDesc
		, Source.SalesStatus
		, Source.SalesStatusDesc
		, Source.DocumentStatus
		, Source.DocumentStatusDesc
		, Source.SalesOriginId
		, Source.SalesPoolId
		, Source.DeliveryModeCode
		, Source.DeliveryModeDescription
		, Source.DeliveryTermCode
		, Source.DeliveryTermDescription
		, Source.DeliveryName
		, Source.DeliveryReason
		, Source.SiteId
		, Source.WarehouseId
		, Source.PaymentTermId
		, Source.PaymentTermDescription
		, Source.CurrencyCode
		, Source.SalesResponsiblePersonnelNo
		, Source.SalesResponsibleName
		, Source.SalesTakerPersonnelNo
		, Source.SalesTakerName
		, Source.CustomerPONumber
		, Source.QuotationId
		, Source.ProjectId
		, Source.ReturnItemNum
		, Source.OrderCreatedDate
		, Source.ShippingDateRequested
		, Source.ShippingDateConfirmed
		, Source.ReceiptDateRequested
		, Source.ReceiptDateConfirmed
		, Source.CreatedDateTime
		, Source.ModifiedDateTime

		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_SalesOrder_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_SalesOrder_incoming AS Source
		ON Target.SalesOrderID = Source.SalesOrderID
		  AND Target.CMPNY = Source.CMPNY

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_SalesOrder_Deleted AS
	SELECT *
	FROM tbl_DIM_SalesOrder AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_SalesOrder_incoming AS Source
			WHERE Target.SalesOrderID = Source.SalesOrderID
				  AND Target.CMPNY = Source.CMPNY

			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_SalesOrder_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_SalesOrder
	WHERE RecordStatus = 1
		AND (CMPNY + '~=~' +SalesOrderID) NOT IN 
			(
			--SELECT SalesOrder 
			--FROM stage_tbl_DIM_SalesOrder_Expired
			--UNION
			SELECT CMPNY + '~=~' +SalesOrderID
			FROM stage_tbl_DIM_SalesOrder_Deleted
			UNION
			SELECT CMPNY + '~=~' +SalesOrderID
			FROM stage_tbl_DIM_SalesOrder_Type1_UpdatesNeeded
			)
	
	--UNION ALL
	
	---- Expire old records
	--SELECT [SalesOrderKey]
	--	, [CMPNY]
	--	, SalesOrder
	--	, Invoice_Account
	--	, Legacy_SalesOrder
	--	, GMAccountNo
	--	, GMRecID
	--	, SalesOrderName
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
	--FROM stage_tbl_DIM_SalesOrder_Expired
	
	--UNION ALL
	
	---- Insert new versions of changed records
	--SELECT s.[SalesOrderKey]
	--	, s.[CMPNY]
	--	, s.SalesOrder
	--	, s.Invoice_Account
	--	, s.Legacy_SalesOrder
	--	, s.GMAccountNo
	--	, s.GMRecID
	--	, s.SalesOrderName
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
	--FROM vw_stage_DIM_SalesOrder_incoming s
	--JOIN stage_tbl_DIM_SalesOrder_Expired e
	--	ON s.SalesOrder = e.SalesOrder
	--		AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_SalesOrder_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_SalesOrder_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT SalesOrderKey
		, CMPNY
		, SalesOrderID

		, SalesType
		, SalesTypeDesc
		, SalesStatus
		, SalesStatusDesc
		, DocumentStatus
		, DocumentStatusDesc
		, SalesOriginId
		, SalesPoolId
		, DeliveryModeCode
		, DeliveryModeDescription
		, DeliveryTermCode
		, DeliveryTermDescription
		, DeliveryName
		, DeliveryReason
		, SiteId
		, WarehouseId
		, PaymentTermId
		, PaymentTermDescription
		, CurrencyCode
		, SalesResponsiblePersonnelNo
		, SalesResponsibleName
		, SalesTakerPersonnelNo
		, SalesTakerName
		, CustomerPONumber
		, QuotationId
		, ProjectId
		, ReturnItemNum
		, OrderCreatedDate
		, ShippingDateRequested
		, ShippingDateConfirmed
		, ReceiptDateRequested
		, ReceiptDateConfirmed
		, CreatedDateTime
		, ModifiedDateTime

		,Source
		,RecordEffectiveStartDate
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_SalesOrder_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_SalesOrder_Append AS
	SELECT *
	FROM tbl_DIM_SalesOrder f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_SalesOrder_Final AS d
			WHERE d.SalesOrderID = f.SalesOrderID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_SalesOrder_Final AS f
	ORDER BY CMPNY
		,SalesOrderID
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_SalesOrder;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_SalesOrder AS
	SELECT *
	FROM stage_tbl_DIM_SalesOrder_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_SalesOrder_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_SalesOrder_incoming;
END;

GO

