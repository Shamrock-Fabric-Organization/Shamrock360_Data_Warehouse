CREATE   PROCEDURE sp_Execute_SCD_Logic 
AS 
BEGIN
    
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS tbl_DIM_Product_New;
    DROP TABLE IF EXISTS tbl_DIM_Product_Expired;
    DROP TABLE IF EXISTS tbl_DIM_Product_Deleted;
    DROP TABLE IF EXISTS tbl_DIM_Product_Final;
    
    -- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
    -- Create a table to store new records identified from the view
    CREATE TABLE tbl_DIM_Product_New AS
    SELECT *
    FROM vw_stage_NewProducts;
    
    -- Step 2: Identify records that need to be expired
    -- Create a table to store records that have changed and need to be expired
    CREATE TABLE tbl_DIM_Product_Expired AS
    SELECT Target.*
    FROM tbl_DIM_Product AS Target
    JOIN tbl_Product_SCD AS Source
    	ON Target.ItemKey = Source.ItemKey
    WHERE Target.RecordStatus = 1
    	AND (
    		ISNULL(Target.PrimaryMfgLocation, '') <> ISNULL(Source.PrimaryMfgLocation, '')
    		OR ISNULL(Target.ProdLineAcctg, '') <> ISNULL(Source.ProdLineAcctg, '')
    		OR ISNULL(Target.ProductLineFunctional, '') <> ISNULL(Source.ProductLineFunctional, '')
    		OR ISNULL(Target.LeadTime, '') <> ISNULL(Source.LeadTime, '')
    		OR ISNULL(Target.gyro_US_InksAndCoatings, '') <> ISNULL(Source.gyro_US_InksAndCoatings, '')
    		OR ISNULL(Target.gyro_US_Thermoplastics, '') <> ISNULL(Source.gyro_US_Thermoplastics, '')
    		OR ISNULL(Target.gyro_US_Lubricants, '') <> ISNULL(Source.gyro_US_Lubricants, '')
    		OR ISNULL(Target.gyro_US_PersonalCare, '') <> ISNULL(Source.gyro_US_PersonalCare, '')
    		OR ISNULL(Target.gyro_US_Other, '') <> ISNULL(Source.gyro_US_Other, '')
    		OR ISNULL(Target.gyro_APAC_InksAndCoatings, '') <> ISNULL(Source.gyro_APAC_InksAndCoatings, '')
    		OR ISNULL(Target.gyro_APAC_Thermoplastics, '') <> ISNULL(Source.gyro_APAC_Thermoplastics, '')
    		OR ISNULL(Target.gyro_APAC_Lubricants, '') <> ISNULL(Source.gyro_APAC_Lubricants, '')
    		OR ISNULL(Target.gyro_APAC_PersonalCare, '') <> ISNULL(Source.gyro_APAC_PersonalCare, '')
    		OR ISNULL(Target.gyro_APAC_Other, '') <> ISNULL(Source.gyro_APAC_Other, '')
    		OR ISNULL(Target.gyro_EMEA_InksAndCoatings, '') <> ISNULL(Source.gyro_EMEA_InksAndCoatings, '')
    		OR ISNULL(Target.gyro_EMEA_Thermoplastics, '') <> ISNULL(Source.gyro_EMEA_Thermoplastics, '')
    		OR ISNULL(Target.gyro_EMEA_Lubricants, '') <> ISNULL(Source.gyro_EMEA_Lubricants, '')
    		OR ISNULL(Target.gyro_EMEA_PersonalCare, '') <> ISNULL(Source.gyro_EMEA_PersonalCare, '')
    		OR ISNULL(Target.gyro_EMEA_Other, '') <> ISNULL(Source.gyro_EMEA_Other, '')
    		);
    
    -- Step 3: Identify records that exist in DIM but are missing from the source (i.e., deleted)
    -- Create a table to store records that are deleted from the source
    CREATE TABLE tbl_DIM_Product_Deleted AS
    SELECT *
    FROM tbl_DIM_Product AS Target
    WHERE Target.RecordStatus = 1
    	AND NOT EXISTS (
    		SELECT 1
    		FROM tbl_Product_SCD AS Source
    		WHERE Source.ItemKey = Target.ItemKey
    		);
    
    -- Step 4: Create the final dimension table
    -- Create the final dimension table combining unchanged, expired, new, and deleted records
    CREATE TABLE tbl_DIM_Product_Final AS
    --Add records from DIM that had no changes
    SELECT *
    FROM tbl_DIM_Product
    WHERE RecordStatus = 1
    	AND ItemKey NOT IN (
    		SELECT ItemKey
    		FROM tbl_DIM_Product_Expired
    		
    		UNION
    		
    		SELECT ItemKey
    		FROM tbl_DIM_Product_Deleted
    		)
    
    UNION ALL
    
    -- Expire old records
    SELECT ItemKey
    	,Desc1
    	,PrintableDesc
    	,ProdLineAcctg
    	,ProductLineFunctional
    	,ProductLineCategory
    	,ProductFamily
    	,pct_PTFEContent
    	,PrimaryMfgLocation
    	,PackageType
    	,PackageLiner
    	,PackageWeight
    	,PackageTare
    	,LeadTime
    	,st_ProductionStatus
    	,st_ObsoletionStatus
    	,ProductDescPublic
    	,ProductDescInternal
    	,ApplBenefit
    	,LevelOfAddition
    	,ExperimentalProductName
    	,BaseProduct
    	,gyro_US_InksAndCoatings
    	,gyro_US_Thermoplastics
    	,gyro_US_Lubricants
    	,gyro_US_PersonalCare
    	,gyro_US_Other
    	,gyro_APAC_InksAndCoatings
    	,gyro_APAC_Thermoplastics
    	,gyro_APAC_Lubricants
    	,gyro_APAC_PersonalCare
    	,gyro_APAC_Other
    	,gyro_EMEA_InksAndCoatings
    	,gyro_EMEA_Thermoplastics
    	,gyro_EMEA_Lubricants
    	,gyro_EMEA_PersonalCare
    	,gyro_EMEA_Other
    	,RecordEffectiveStartDate
    	,GETDATE() AS RecordEffectiveEndDate
    	,0 AS RecordStatus
    	,Source
    FROM tbl_DIM_Product_Expired
    
    UNION ALL
    
    -- Insert new versions of changed records
    SELECT s.ItemKey
    	,s.Desc1
    	,s.PrintableDesc
    	,s.ProdLineAcctg
    	,s.ProductLineFunctional
    	,s.ProductLineCategory
    	,s.ProductFamily
    	,s.pct_PTFEContent
    	,s.PrimaryMfgLocation
    	,s.PackageType
    	,s.PackageLiner
    	,s.PackageWeight
    	,s.PackageTare
    	,s.LeadTime
    	,s.st_ProductionStatus
    	,s.st_ObsoletionStatus
    	,s.ProductDescPublic
    	,s.ProductDescInternal
    	,s.ApplBenefit
    	,s.LevelOfAddition
    	,s.ExperimentalProductName
    	,s.BaseProduct
    	,s.gyro_US_InksAndCoatings
    	,s.gyro_US_Thermoplastics
    	,s.gyro_US_Lubricants
    	,s.gyro_US_PersonalCare
    	,s.gyro_US_Other
    	,s.gyro_APAC_InksAndCoatings
    	,s.gyro_APAC_Thermoplastics
    	,s.gyro_APAC_Lubricants
    	,s.gyro_APAC_PersonalCare
    	,s.gyro_APAC_Other
    	,s.gyro_EMEA_InksAndCoatings
    	,s.gyro_EMEA_Thermoplastics
    	,s.gyro_EMEA_Lubricants
    	,s.gyro_EMEA_PersonalCare
    	,s.gyro_EMEA_Other
    	,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
    	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    	,1 AS RecordStatus
    	,s.Source
    FROM tbl_Product_SCD s
    JOIN tbl_DIM_Product_Expired e
    	ON s.ItemKey = e.ItemKey
    
    UNION ALL
    
    -- Insert new records
    SELECT *
    FROM tbl_DIM_Product_New
    
    UNION ALL
    
    -- Expire deleted records
    SELECT ItemKey
    	,Desc1
    	,PrintableDesc
    	,ProdLineAcctg
    	,ProductLineFunctional
    	,ProductLineCategory
    	,ProductFamily
    	,pct_PTFEContent
    	,PrimaryMfgLocation
    	,PackageType
    	,PackageLiner
    	,PackageWeight
    	,PackageTare
    	,LeadTime
    	,st_ProductionStatus
    	,st_ObsoletionStatus
    	,ProductDescPublic
    	,ProductDescInternal
    	,ApplBenefit
    	,LevelOfAddition
    	,ExperimentalProductName
    	,BaseProduct
    	,gyro_US_InksAndCoatings
    	,gyro_US_Thermoplastics
    	,gyro_US_Lubricants
    	,gyro_US_PersonalCare
    	,gyro_US_Other
    	,gyro_APAC_InksAndCoatings
    	,gyro_APAC_Thermoplastics
    	,gyro_APAC_Lubricants
    	,gyro_APAC_PersonalCare
    	,gyro_APAC_Other
    	,gyro_EMEA_InksAndCoatings
    	,gyro_EMEA_Thermoplastics
    	,gyro_EMEA_Lubricants
    	,gyro_EMEA_PersonalCare
    	,gyro_EMEA_Other
    	,RecordEffectiveStartDate
    	,GETDATE() AS RecordEffectiveEndDate
    	,0 AS RecordStatus
    	,Source
    FROM tbl_DIM_Product_Deleted;
    
    -- Step 5: Replace the original table with deduplicated append
    -- Drop the append table if it exists before rebuilding the dimension
    DROP TABLE IF EXISTS tbl_DIM_Product_Append;
    
    -- Create a new append table by merging existing and final dimension records
    CREATE TABLE tbl_DIM_Product_Append AS
    SELECT *
    FROM tbl_DIM_Product f
    WHERE NOT EXISTS (
    		SELECT 1
    		FROM tbl_DIM_Product_Final AS d
    		WHERE d.ItemKey = f.ItemKey
    			AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
    		)
    
    UNION ALL
    
    SELECT *
    FROM tbl_DIM_Product_Final AS f
    ORDER BY itemkey
    	,recordeffectivestartdate
    
    -- Step 6: Replace the DIM table with the updated records
    -- Drop the original dimension table to replace with the updated one
    DROP TABLE IF EXISTS tbl_DIM_Product;
    
    -- Recreate the dimension table with the updated records from the append table
    CREATE TABLE tbl_DIM_Product AS
    SELECT *
    FROM tbl_DIM_Product_Append;
    
    
    -- Step 7: Clean up intermediate objects used
    -- Drop intermediate tables if they exist
    DROP TABLE IF EXISTS tbl_DIM_Product_New;
    DROP TABLE IF EXISTS tbl_DIM_Product_Expired;
    DROP TABLE IF EXISTS tbl_DIM_Product_Deleted;
    DROP TABLE IF EXISTS tbl_DIM_Product_Final;
    
    
    -- Step 8: Clear staging table
    -- Drop the staging/source table after processing is complete
    DROP TABLE IF EXISTS tbl_Product_SCD;
END;