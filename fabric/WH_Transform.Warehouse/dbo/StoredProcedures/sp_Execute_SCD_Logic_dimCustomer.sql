CREATE   PROCEDURE [dbo].[sp_Execute_SCD_Logic_dimCustomer]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Customer_New AS
	SELECT *
	FROM vw_stage_NewCustomer

	-- Step 2: Identify records that need to be expired
	-- Create a table to store records that have changed and need to be expired
	CREATE TABLE stage_tbl_DIM_Customer_Expired AS
	SELECT Target.*
	FROM tbl_DIM_Customer AS Target
	JOIN vw_stage_DIM_Customer_incoming AS Source
		ON Target.Customer_ID = Source.Customer_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
			OR ISNULL(Target.Salesman_ID, '') <> ISNULL(Source.Salesman_ID, '')
			OR ISNULL(Target.Industry_Segment, '') <> ISNULL(Source.Industry_Segment, '')
			OR ISNULL(Target.Subsegment, '') <> ISNULL(Source.Subsegment, '')
			OR ISNULL(Target.Account_Tier, 0) <> ISNULL(Source.Account_Tier, 0)
			);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_Customer_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Customer AS Target
	JOIN vw_stage_DIM_Customer_incoming AS Source
		ON Target.Customer_ID = Source.Customer_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Invoice_Account, '') <> ISNULL(Source.Invoice_Account, '')
			OR ISNULL(Target.Legacy_Customer_ID, 0) <> ISNULL(Source.Legacy_Customer_ID, 0)
			OR ISNULL(Target.GMAccountNo, 0) <> ISNULL(Source.GMAccountNo, 0)
			OR ISNULL(Target.GMRecID, 0) <> ISNULL(Source.GMRecID, 0)
			OR ISNULL(Target.CustomerName, '') <> ISNULL(Source.CustomerName, '')
			OR ISNULL(Target.Address, '') <> ISNULL(Source.Address, '')
			OR ISNULL(Target.City, '') <> ISNULL(Source.City, '')
			OR ISNULL(Target.State, '') <> ISNULL(Source.State, '')
			OR ISNULL(Target.ZIP, '') <> ISNULL(Source.ZIP, '')
			OR ISNULL(Target.Country, '') <> ISNULL(Source.Country, '')
			OR ISNULL(Target.Territory_ID, '') <> ISNULL(Source.Territory_ID, '')
			OR ISNULL(Target.SalesChannel, '') <> ISNULL(Source.SalesChannel, '')
			OR ISNULL(Target.Status, 0) <> ISNULL(Source.Status, 0)
			OR ISNULL(Target.EffectiveCountry, '') <> ISNULL(Source.EffectiveCountry, '')
			OR ISNULL(Target.Longitude, 0) <> ISNULL(Source.Longitude, 0)
			OR ISNULL(Target.Latitude, 0) <> ISNULL(Source.Latitude, 0)
			OR ISNULL(Target.PaymentTerms, '') <> ISNULL(Source.PaymentTerms, '')
			OR ISNULL(Target.PhoneNumber, '') <> ISNULL(Source.PhoneNumber, '')
			OR ISNULL(Target.PurchasingEmail, '') <> ISNULL(Source.PurchasingEmail, '')
			OR ISNULL(Target.InvoicingEmail, '') <> ISNULL(Source.InvoicingEmail, '')
			OR ISNULL(Target.customergroup, '') <> ISNULL(Source.customergroup, '')
			OR ISNULL(Target.customer_currency, '') <> ISNULL(Source.customer_currency, '')
			)
		AND NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Customer_Expired AS Expired
			WHERE Expired.Customer_ID = Target.Customer_ID
				AND Expired.CMPNY = Target.CMPNY
			);

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Customer_Type1_OnlyUpdatedRecords AS
	SELECT Target.CustomerKey
		,Target.CMPNY
		, Target.Customer_ID
		, Source.Invoice_Account
		, Source.Legacy_Customer_ID
		, Source.GMAccountNo
		, Source.GMRecID
		, Source.CustomerName
		, Target.Harmonized_Name
		, Source.Address
		, Source.City
		, Source.State
		, Source.ZIP
		, Source.Country
		, Source.Territory_ID
		, Target.Salesman_ID
		, Source.SalesChannel
		, Target.Industry_Segment
		, Target.Subsegment
		, Source.Status
		, Source.EffectiveCountry
		, Target.Account_Tier
		, Source.Longitude
		, Source.Latitude
		, Source.PaymentTerms
		, Source.PhoneNumber
		, Source.PurchasingEmail
		, Source.InvoicingEmail

		, Source.customergroup
		, Source.customer_currency
		,Target.Source
		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
	FROM stage_tbl_DIM_Customer_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Customer_incoming AS Source
		ON Target.Customer_ID = Source.Customer_ID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Customer_Deleted AS
	SELECT *
	FROM tbl_DIM_Customer AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Customer_incoming AS Source
			WHERE Source.Customer_ID = Target.Customer_ID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Customer_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Customer
	WHERE RecordStatus = 1
		AND (Customer_ID + '~=~' + CMPNY) NOT IN 
			(
			SELECT Customer_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Customer_Expired
			UNION
			SELECT Customer_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Customer_Deleted
			UNION
			SELECT Customer_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Customer_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	-- Expire old records
	SELECT [CustomerKey]
		, [CMPNY]
		, Customer_ID
		, Invoice_Account
		, Legacy_Customer_ID
		, GMAccountNo
		, GMRecID
		, CustomerName
		, Harmonized_Name
		, Address
		, City
		, State
		, ZIP
		, Country
		, Territory_ID
		, Salesman_ID
		, SalesChannel
		, Industry_Segment
		, Subsegment
		, Status
		, EffectiveCountry
		, Account_Tier
		, Longitude
		, Latitude
		, PaymentTerms
		, PhoneNumber
		, PurchasingEmail
		, InvoicingEmail
		, customergroup
		, customer_currency
		, Source
		, [RecordEffectiveStartDate]
		, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Customer_Expired
	
	UNION ALL
	
	-- Insert new versions of changed records
	SELECT s.[CustomerKey]
		, s.[CMPNY]
		, s.Customer_ID
		, s.Invoice_Account
		, s.Legacy_Customer_ID
		, s.GMAccountNo
		, s.GMRecID
		, s.CustomerName
		, s.Harmonized_Name
		, s.Address
		, s.City
		, s.State
		, s.ZIP
		, s.Country
		, s.Territory_ID
		, s.Salesman_ID
		, s.SalesChannel
		, s.Industry_Segment
		, s.Subsegment
		, s.Status
		, s.EffectiveCountry
		, s.Account_Tier
		, s.Longitude
		, s.Latitude
		, s.PaymentTerms
		, s.PhoneNumber
		, s.PurchasingEmail
		, s.InvoicingEmail
		, s.customergroup
		, s.customer_currency
		, s.Source
		,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
		,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
		,1 AS RecordStatus
	FROM vw_stage_DIM_Customer_incoming s
	JOIN stage_tbl_DIM_Customer_Expired e
		ON s.Customer_ID = e.Customer_ID
			AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Customer_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Customer_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT [CustomerKey]
		, [CMPNY]
		, Customer_ID
		, Invoice_Account
		, Legacy_Customer_ID
		, GMAccountNo
		, GMRecID
		, CustomerName
		, Harmonized_Name
		, Address
		, City
		, State
		, ZIP
		, Country
		, Territory_ID
		, Salesman_ID
		, SalesChannel
		, Industry_Segment
		, Subsegment
		, Status
		, EffectiveCountry
		, Account_Tier
		, Longitude
		, Latitude
		, PaymentTerms
		, PhoneNumber
		, PurchasingEmail
		, InvoicingEmail
		, customergroup
		, customer_currency
		, Source
		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
	FROM stage_tbl_DIM_Customer_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Customer_Append AS
	SELECT *
	FROM tbl_DIM_Customer f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Customer_Final AS d
			WHERE d.Customer_ID = f.Customer_ID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Customer_Final AS f
	ORDER BY Customer_ID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Customer;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Customer AS
	SELECT *
	FROM stage_tbl_DIM_Customer_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Customer_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Customer_incoming;
END;