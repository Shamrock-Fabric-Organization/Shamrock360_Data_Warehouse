CREATE       PROCEDURE [dbo].[sp_Execute_SCD_Logic_dimProduct]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Append;
	
	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProducts    
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Product_New AS
	SELECT *
	FROM vw_stage_NewProducts;

	-- Step 2: Identify records that need to be expired
	-- Create a table to store records that have changed and need to be expired
	CREATE TABLE stage_tbl_DIM_Product_Expired AS
	SELECT Target.*
	FROM tbl_DIM_Product AS Target
	JOIN vw_stage_DIM_Product_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.Business_Line, '') <> ISNULL(Source.Business_Line, '')
			OR ISNULL(Target.Product_Line, '') <> ISNULL(Source.Product_Line, '')
			OR ISNULL(Target.Technology, '') <> ISNULL(Source.Technology, '')
			OR ISNULL(Target.Material, '') <> ISNULL(Source.Material, '')
			OR ISNULL(Target.MiscRevenue, '') <> ISNULL(Source.MiscRevenue, '')
			);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_Product_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Product AS Target
	JOIN vw_stage_DIM_Product_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.ProductName, '') <> ISNULL(Source.ProductName, '')
			OR ISNULL(Target.ProductSearchName, '') <> ISNULL(Source.ProductSearchName, '')
			OR ISNULL(Target.Commercial_Name, '') <> ISNULL(Source.Commercial_Name, '')
			OR ISNULL(Target.Lifecycle, 0.0) <> ISNULL(Source.Lifecycle, 0.0)
			--OR ISNULL(Target.PackageWeight, 0.0) <> ISNULL(Source.PackageWeight, 0.0)
			OR ISNULL(Target.Inventory_UoM, '') <> ISNULL(Source.Inventory_UoM, '')
			OR ISNULL(Target.Purchasing_UoM, '') <> ISNULL(Source.Purchasing_UoM, '')
			OR ISNULL(Target.Sales_UoM, '') <> ISNULL(Source.Sales_UoM, '')
			OR ISNULL(Target.Item_Type, '') <> ISNULL(Source.Item_Type, '')
			--OR ISNULL(Target.ProductID, 0) <> ISNULL(Source.ProductID, 0)
			OR ISNULL(Target.PTFE_Flag, 0) <> ISNULL(Source.PTFE_Flag, 0)
			OR ISNULL(Target.Reorder_Point, 0.0) <> ISNULL(Source.Reorder_Point, 0.0)

			OR ISNULL(Target.itemmodelgroupid, '') <> ISNULL(Source.itemmodelgroupid, '')
			OR ISNULL(Target.producttype, 0) <> ISNULL(Source.producttype, 0)
			OR ISNULL(Target.producttype_desc, '') <> ISNULL(Source.producttype_desc, '')
			OR ISNULL(Target.itemgroupid, '') <> ISNULL(Source.itemgroupid, '')
			OR ISNULL(Target.ItemGroupName, '') <> ISNULL(Source.ItemGroupName, '')
			OR ISNULL(Target.ItemGroupType, 0) <> ISNULL(Source.ItemGroupType, 0)
			OR ISNULL(Target.ItemGroupTypeName, '') <> ISNULL(Source.ItemGroupTypeName, '')
			OR ISNULL(Target.ItemBuyerGroupID, '') <> ISNULL(Source.ItemBuyerGroupID, '')
			OR ISNULL(Target.ItemBuyerGroupDesc, '') <> ISNULL(Source.ItemBuyerGroupDesc, '')

			OR ISNULL(Target.Phantom, 0) <> ISNULL(Source.Phantom, 0)
			OR ISNULL(Target.IsPhantom, '') <> ISNULL(Source.IsPhantom, '')

			OR ISNULL(Target.min_purchase_qty, 0) <> ISNULL(Source.min_purchase_qty, 0)
			OR ISNULL(Target.multiple_purchase_qty, 0) <> ISNULL(Source.multiple_purchase_qty, 0)
			OR ISNULL(Target.std_purchase_order_qty, 0) <> ISNULL(Source.std_purchase_order_qty, 0)
			OR ISNULL(Target.max_purchase_order_qty, 0) <> ISNULL(Source.max_purchase_order_qty, 0)
			OR ISNULL(Target.purchase_leadtime, 0) <> ISNULL(Source.purchase_leadtime, 0)

			OR ISNULL(Target.min_inventory_qty, 0) <> ISNULL(Source.min_inventory_qty, 0)
			OR ISNULL(Target.multiple_inventory_qty, 0) <> ISNULL(Source.multiple_inventory_qty, 0)
			OR ISNULL(Target.std_inventory_order_qty, 0) <> ISNULL(Source.std_inventory_order_qty, 0)
			OR ISNULL(Target.max_inventory_order_qty, 0) <> ISNULL(Source.max_inventory_order_qty, 0)
			OR ISNULL(Target.inventory_leadtime, 0) <> ISNULL(Source.inventory_leadtime, 0)

			OR ISNULL(Target.min_sales_qty, 0) <> ISNULL(Source.min_sales_qty, 0)
			OR ISNULL(Target.multiple_sales_qty, 0) <> ISNULL(Source.multiple_sales_qty, 0)
			OR ISNULL(Target.std_sales_order_qty, 0) <> ISNULL(Source.std_sales_order_qty, 0)
			OR ISNULL(Target.max_sales_order_qty, 0) <> ISNULL(Source.max_sales_order_qty, 0)
			OR ISNULL(Target.sales_leadtime, 0) <> ISNULL(Source.sales_leadtime, 0)
			OR ISNULL(Target.BaseSalesPrice, 0) <> ISNULL(Source.BaseSalesPrice, 0)
			OR ISNULL(Target.BaseSalesPricePerLB, 0) <> ISNULL(Source.BaseSalesPricePerLB, 0)
			)
		AND NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Product_Expired AS Expired
			WHERE Expired.Product_ID = Target.Product_ID
				AND Expired.CMPNY = Target.CMPNY
			);

	--Create table with Type1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Product_Type1_OnlyUpdatedRecords AS
	SELECT Target.ProductKey
		,Target.CMPNY
		,Target.Product_ID
		,Source.ProductName
		,Source.ProductSearchName
		,Source.Commercial_Name
		,Target.Technology
		,Target.Material
		,Target.Business_Line
		,Target.Product_Line
		,Target.MiscRevenue
		,Source.Lifecycle
		--,Source.PackageWeight
		,Source.Inventory_UoM
		,Source.Purchasing_UoM
		,Source.Sales_UoM
		,Source.Item_Type
		--,Source.ProductID
		,Source.PTFE_Flag
		,Source.Reorder_Point
		,Source.itemmodelgroupid
		,Source.producttype
		,Source.producttype_desc
		,Source.itemgroupid
		,Source.ItemGroupName
		,Source.ItemGroupType
		,Source.ItemGroupTypeName
		,Source.ItemBuyerGroupID
		,Source.ItemBuyerGroupDesc
		, Source.Phantom 
		, Source.IsPhantom

		, Source.min_purchase_qty
		, Source.multiple_purchase_qty
		, Source.std_purchase_order_qty
		, Source.max_purchase_order_qty
		, Source.purchase_leadtime

		, Source.min_inventory_qty
		, Source.multiple_inventory_qty
		, Source.std_inventory_order_qty
		, Source.max_inventory_order_qty
		, Source.inventory_leadtime

		, Source.min_sales_qty
		, Source.multiple_sales_qty
		, Source.std_sales_order_qty
		, Source.max_sales_order_qty
		, Source.sales_leadtime
		, Source.BaseSalesPrice
		, Source.BaseSalesPricePerLB

		,Target.RecordEffectiveStartDate
		,Target.RecordEffectiveEndDate
		,Target.RecordStatus
		,Target.Source
	FROM stage_tbl_DIM_Product_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Product_incoming AS Source
		ON Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY;

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Product_Deleted AS
	SELECT *
	FROM tbl_DIM_Product AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Product_incoming AS Source
			WHERE Source.Product_ID = Target.Product_ID
				AND Source.CMPNY = Target.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Product_Final AS
		--Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Product
	WHERE RecordStatus = 1
		AND (Product_ID + '~=~' + CMPNY) NOT IN 
			(
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Product_Expired
			UNION
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Product_Deleted
			UNION
			SELECT Product_ID + '~=~' + CMPNY
			FROM stage_tbl_DIM_Product_Type1_UpdatesNeeded
			)
	
	UNION ALL
	
	-- Expire old records
	SELECT [ProductKey]
		, [CMPNY]
		, [Product_ID]
		, [ProductName]
		, [ProductSearchName]
		, [Commercial_Name]
		, [Technology]
		, [Material]
		, [Business_Line]
		, [Product_Line]
		, [MiscRevenue]
		, [Lifecycle]
		--, [PackageWeight]
		, [Inventory_UoM]
		, [Purchasing_UoM]
		, [Sales_UoM]
		, [Item_Type]
		--, [ProductID]
		, [PTFE_Flag]
		, [Reorder_Point]
		, [itemmodelgroupid]
		, [producttype]
		, [producttype_desc]
		, [itemgroupid]
		, [ItemGroupName]
		, [ItemGroupType]
		, [ItemGroupTypeName]
		, ItemBuyerGroupID
		, ItemBuyerGroupDesc

		,Phantom 
		,IsPhantom
		
		, min_purchase_qty
		, multiple_purchase_qty
		, std_purchase_order_qty
		, max_purchase_order_qty
		, purchase_leadtime

		, min_inventory_qty
		, multiple_inventory_qty
		, std_inventory_order_qty
		, max_inventory_order_qty
		, inventory_leadtime

		, min_sales_qty
		, multiple_sales_qty
		, std_sales_order_qty
		, max_sales_order_qty
		, sales_leadtime
		, BaseSalesPrice
		, BaseSalesPricePerLB

		, [RecordEffectiveStartDate]
		, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
		, 0 AS RecordStatus
		, [Source]
	FROM stage_tbl_DIM_Product_Expired
	
	UNION ALL
	
	-- Insert new versions of changed records
	SELECT s.[ProductKey]
		, s.[CMPNY]
		, s.[Product_ID]
		, s.[ProductName]
		, s.[ProductSearchName]
		, s.[Commercial_Name]
		, s.[Technology]
		, s.[Material]
		, s.[Business_Line]
		, s.[Product_Line]
		, s.[MiscRevenue]
		, s.[Lifecycle]
		--, s.[PackageWeight]
		, s.[Inventory_UoM]
		, s.[Purchasing_UoM]
		, s.[Sales_UoM]
		, s.[Item_Type]
		--, s.[ProductID]
		, s.[PTFE_Flag]
		, s.[Reorder_Point]
		, s.[itemmodelgroupid]
		, s.[producttype]
		, s.[producttype_desc]
		, s.[itemgroupid]
		, s.[ItemGroupName]
		, s.[ItemGroupType]
		, s.[ItemGroupTypeName]
		, s.ItemBuyerGroupID
		, s.ItemBuyerGroupDesc

		, s.Phantom 
		, s.IsPhantom

		, s.min_purchase_qty
		, s.multiple_purchase_qty
		, s.std_purchase_order_qty
		, s.max_purchase_order_qty
		, s.purchase_leadtime

		, s.min_inventory_qty
		, s.multiple_inventory_qty
		, s.std_inventory_order_qty
		, s.max_inventory_order_qty
		, s.inventory_leadtime

		, s.min_sales_qty
		, s.multiple_sales_qty
		, s.std_sales_order_qty
		, s.max_sales_order_qty
		, s.sales_leadtime
		, s.BaseSalesPrice
		, s.BaseSalesPricePerLB

		,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
		,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
		,1 AS RecordStatus
		,s.[Source]
	FROM vw_stage_DIM_Product_incoming s
	JOIN stage_tbl_DIM_Product_Expired e
		ON s.Product_ID = e.Product_ID
			AND s.CMPNY = e.CMPNY
	
	UNION ALL
	
	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Product_New
	
	UNION ALL
	
	--Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Product_Type1_OnlyUpdatedRecords
	
	UNION ALL
	
	-- Expire deleted records
	SELECT [ProductKey]
		, [CMPNY]
		, [Product_ID]
		, [ProductName]
		, [ProductSearchName]
		, [Commercial_Name]
		, [Technology]
		, [Material]
		, [Business_Line]
		, [Product_Line]
		, [MiscRevenue]
		, [Lifecycle]
		--, [PackageWeight]
		, [Inventory_UoM]
		, [Purchasing_UoM]
		, [Sales_UoM]
		, [Item_Type]
		--, [ProductID]
		, [PTFE_Flag]
		, [Reorder_Point]
		, [itemmodelgroupid]
		, [producttype]
		, [producttype_desc]
		, [itemgroupid]
		, [ItemGroupName]
		, [ItemGroupType]
		, [ItemGroupTypeName]
		, ItemBuyerGroupID
		, ItemBuyerGroupDesc

		,Phantom 
		,IsPhantom

		, min_purchase_qty
		, multiple_purchase_qty
		, std_purchase_order_qty
		, max_purchase_order_qty
		, purchase_leadtime

		, min_inventory_qty
		, multiple_inventory_qty
		, std_inventory_order_qty
		, max_inventory_order_qty
		, inventory_leadtime

		, min_sales_qty
		, multiple_sales_qty
		, std_sales_order_qty
		, max_sales_order_qty
		, sales_leadtime
		, BaseSalesPrice
		, BaseSalesPricePerLB

		, [RecordEffectiveStartDate]
		, GETDATE() AS RecordEffectiveEndDate
		, 0 AS RecordStatus
		, [Source]
	FROM stage_tbl_DIM_Product_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Product_Append AS
	SELECT *
	FROM tbl_DIM_Product f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Product_Final AS d
			WHERE d.Product_ID = f.Product_ID
				AND d.CMPNY = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)
	
	UNION ALL
	
	SELECT *
	FROM stage_tbl_DIM_Product_Final AS f
	ORDER BY Product_ID
		,CMPNY
		,recordeffectivestartdate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Product;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Product AS
	SELECT *
	FROM stage_tbl_DIM_Product_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Product_Type1_OnlyUpdatedRecords;
		
	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Product_incoming;
END;