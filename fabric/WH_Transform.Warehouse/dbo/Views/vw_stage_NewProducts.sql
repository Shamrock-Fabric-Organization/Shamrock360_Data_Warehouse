-- Auto Generated (Do not modify) 4739477A5B6B64821A6155E5522B1A98FDDBE62C6297E17B371E32D3E6AD08C7
/****** Object:  View [dbo].[vw_stage_NewProducts]    Script Date: 1/21/2026 2:17:26 PM ******/


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE       VIEW [dbo].[vw_stage_NewProducts]
AS
SELECT 
    ProductKey
	,[CMPNY]
	,[Product_ID]
	,[ProductName]
	,[ProductSearchName]
	,[Commercial_Name]
	,[Technology]
	,[Material]
	,[Business_Line]
	,[Product_Line]
	,[MiscRevenue]
	,[Lifecycle]
	--,[PackageWeight]
	,[Inventory_UoM]
	,[Purchasing_UoM]
	,[Sales_UoM]
	,[Item_Type]
	--,[ProductID]
	,PTFE_Flag
	,Reorder_Point
	,itemmodelgroupid
	,producttype
	,producttype_desc
	,itemgroupid
	,ItemGroupName
	,ItemGroupType
	,ItemGroupTypeName
	,ItemBuyerGroupID
	,ItemBuyerGroupDesc
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

	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
	,[Source]
FROM vw_stage_DIM_Product_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_product AS Target
		WHERE Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);