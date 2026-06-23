-- Auto Generated (Do not modify) 539D1665A7D3F104202CBA822A0B802CE024B26DDCE63991663FEBA625F88B88
/****** Object:  View [dbo].[vw_stage_DIM_Product_incoming]    Script Date: 6/17/2026 9:12:46 AM ******/

/****** Object:  View [dbo].[vw_stage_DIM_Product_incoming]    Script Date: 1/21/2026 2:17:03 PM ******/


----select * from vw_stage_DIM_Product_incoming

CREATE OR ALTER        VIEW [dbo].[vw_stage_DIM_Product_incoming]			
AS			
WITH base AS (
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(IT.ItemID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS ProductKey
	,IT.dataareaid	  CMPNY	
	,IT.ItemID	 Product_ID
	,ERPT.name	 ProductName	
	,ERP.searchname	 ProductSearchName	
	,COALESCE(IT.STICommertialName,ERPT.name)	Commercial_Name
	,SC_t.Level3Category	 Technology	 --Type 2 from product attributes
	,SC_t.Level4Category	 Material	 --Type 2 from product attributes
	,SC_bl.Level3Category	 Business_Line	 --Type 2 from product attributes
	,SC_bl.Level4Category	 Product_Line	 --Type 2 from product attributes
	,SC_m.Level3Category	 MiscRevenue	 --Type 2 from product attributes
	, NULL Lifecycle
	,ITMi.unitid  Inventory_UoM
	,ITMp.unitid  Purchasing_UoM
	,ITMs.unitid  Sales_UoM
	,IT.itemtype_$label	 Item_Type
	,CONVERT(int, NULL) PTFE_Flag
	,CONVERT(numeric(20,4), NULL) Reorder_Point

	,img.ModelGroupId as itemmodelgroupid
	,erp.producttype
	,erp.producttype_$label AS producttype_desc
	,iigi.itemgroupid
	,iig.name AS ItemGroupName
	,iig.revrecrevenuetype AS ItemGroupType
	,iig.revrecrevenuetype_$label AS ItemGroupTypeName
	,it.itembuyergroupid
	,ibg.description ItemBuyerGroupDesc
	,IT.Phantom 
	,IT.Phantom_$Label IsPhantom

	, iips.lowestqty min_purchase_qty
	, iips.multipleqty multiple_purchase_qty
	, iips.standardqty std_purchase_order_qty
	, iips.highestqty max_purchase_order_qty
	, iips.leadtime purchase_leadtime

	, iiis.lowestqty min_inventory_qty
	, iiis.multipleqty multiple_inventory_qty
	, iiis.standardqty std_inventory_order_qty
	, iiis.highestqty max_inventory_order_qty
	, iiis.leadtime inventory_leadtime

	, iiss.lowestqty min_sales_qty
	, iiss.multipleqty multiple_sales_qty
	, iiss.standardqty std_sales_order_qty
	, iiss.highestqty max_sales_order_qty
	, case when iiss.overridesalesleadtime = 0 then 0 else iiss.leadtime end sales_leadtime

	, ITMs.price BaseSalesPrice
	, CASE WHEN ISNULL(CASE WHEN ITMs.unitid = 'lb' then 1 else UOM_s.UOMConversionFactor end, 0) = 0
		THEN NULL
		ELSE (ITMs.price / CASE WHEN ITMs.unitid = 'lb' then 1 else UOM_s.UOMConversionFactor end ) 
		END BaseSalesPricePerLB
	,CAST(NULL AS DATETIME2(3))	 RecordEffectiveStartDate	 --SCD2 control field
	,CAST(NULL AS DATETIME2(3))	 RecordEffectiveEndDate	 --SCD2 control field
	,CAST(NULL AS INT)	 RecordStatus	 --SCD2 control field
	,'D365FO'	 Source

	-- Collapse any join fan-out to a single row per product. The observed
	-- duplicates are identical across attribute columns, so the pick is
	-- lossless. If two genuinely different attribute rows ever appear for one
	-- product, revisit this ORDER BY to encode the business-preferred winner.
	, ROW_NUMBER() OVER (
	      PARTITION BY IT.dataareaid, IT.ItemID
	      ORDER BY (SELECT 1)
	  ) AS _dedupe_rn

FROM WH_Raw.dbo.InventTable IT		
LEFT JOIN WH_Raw.dbo.InventTableModule ITMi
    ON IT.ItemId = ITMi.ItemId
	    AND IT.dataareaid = ITMi.DataAreaId
		AND ITMi.moduletype = 0
LEFT JOIN WH_Raw.dbo.InventTableModule ITMp
    ON IT.ItemId = ITMp.ItemId
	    AND IT.dataareaid = ITMp.DataAreaId
		AND ITMp.moduletype = 1
LEFT JOIN WH_Raw.dbo.InventTableModule ITMs
    ON IT.ItemId = ITMs.ItemId
	    AND IT.dataareaid = ITMs.DataAreaId
		AND ITMs.moduletype = 2
LEFT JOIN WH_Raw.dbo.EcoResProductTranslation ERPT			
	ON IT.product = ERPT.product		
		AND ERPT.languageid = 'en-US'	
LEFT JOIN WH_Raw.dbo.EcoResProduct ERP			
	ON IT.product = ERP.recid		
LEFT JOIN WH_Raw.dbo.vwItemSalesCategories SC_bl
	ON IT.Product = SC_bl.Product
	    AND SC_bl.Level2Category = 'Business Line'
LEFT JOIN WH_Raw.dbo.vwItemSalesCategories SC_t
	ON IT.Product = SC_t.Product
	    AND SC_t.Level2Category = 'Technology'
LEFT JOIN WH_Raw.dbo.vwItemSalesCategories SC_m
	ON IT.Product = SC_m.Product
	    AND SC_m.Level2Category = 'Miscellaneous Revenue'

LEFT JOIN WH_Raw.dbo.InventItemGroupItem iigi 
    ON it.ItemId = iigi.ItemId
    AND it.DATAAREAID = iigi.ItemDataAreaId
LEFT JOIN WH_Raw.dbo.InventItemGroup iig
    ON iigi.ItemGroupId = iig.ItemGroupId
    AND iigi.ItemGroupDataAreaId = iig.DATAAREAID

LEFT JOIN WH_Raw.dbo.InventModelGroupItem img 
    ON it.ItemId = img.ItemId
    AND it.DATAAREAID = img.ItemDataAreaId
LEFT JOIN WH_Raw.dbo.inventbuyergroup ibg
    on it.itembuyergroupid = ibg.[group]
    and it.dataareaid = ibg.dataareaid

LEFT JOIN WH_Raw.[dbo].[inventitempurchsetup] iips
    ON IT.ItemId = iips.ItemId
	    AND IT.dataareaid = iips.DataAreaId
		AND iips.sequence = 0

LEFT JOIN WH_Raw.[dbo].[inventiteminventsetup] iiis
    ON IT.ItemId = iiis.ItemId
	    AND IT.dataareaid = iiis.DataAreaId
		AND iiis.sequence = 0

LEFT JOIN WH_Raw.[dbo].[inventitemsalessetup] iiss
    ON IT.ItemId = iiss.ItemId
	    AND IT.dataareaid = iiss.DataAreaId
		AND iiss.sequence = 0

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOM_s
	ON IT.product = UOM_s.product
		AND ITMs.unitid = UOM_s.SYMBOLFROM
		AND UOM_s.SYMBOLTO = 'lb'
)

SELECT
     ProductKey
    ,CMPNY
    ,Product_ID
    ,ProductName
    ,ProductSearchName
    ,Commercial_Name
    ,Technology
    ,Material
    ,Business_Line
    ,Product_Line
    ,MiscRevenue
    ,Lifecycle
    ,Inventory_UoM
    ,Purchasing_UoM
    ,Sales_UoM
    ,Item_Type
    ,PTFE_Flag
    ,Reorder_Point
    ,itemmodelgroupid
    ,producttype
    ,producttype_desc
    ,itemgroupid
    ,ItemGroupName
    ,ItemGroupType
    ,ItemGroupTypeName
    ,itembuyergroupid
    ,ItemBuyerGroupDesc
    ,Phantom
    ,IsPhantom
    ,min_purchase_qty
    ,multiple_purchase_qty
    ,std_purchase_order_qty
    ,max_purchase_order_qty
    ,purchase_leadtime
    ,min_inventory_qty
    ,multiple_inventory_qty
    ,std_inventory_order_qty
    ,max_inventory_order_qty
    ,inventory_leadtime
    ,min_sales_qty
    ,multiple_sales_qty
    ,std_sales_order_qty
    ,max_sales_order_qty
    ,sales_leadtime
    ,BaseSalesPrice
    ,BaseSalesPricePerLB
    ,RecordEffectiveStartDate
    ,RecordEffectiveEndDate
    ,RecordStatus
    ,Source
FROM base
WHERE _dedupe_rn = 1

----WHERE ISNULL(IT.Phantom,0) <> 1  --removed on 2026-02-24 per Kevin Y

UNION ALL

SELECT -1 [ProductKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Product_ID]
, 'Unknown' [ProductName]
, 'Unknown' [ProductSearchName]
, 'Unknown' [Commercial_Name]
, NULL [Technology]
, NULL [Material]
, NULL [Business_Line]
, NULL [Product_Line]
, NULL [MiscRevenue]
, NULL [Lifecycle]
, NULL [Inventory_UoM]
, NULL Purchasing_UoM
, NULL [Sales_UoM]
, NULL [Item_Type]
, NULL [PTFE_Flag]
, NULL [Reorder_Point]

, NULL itemmodelgroupid
, NULL producttype
, NULL producttype_desc
, NULL itemgroupid
, NULL ItemGroupName
, NULL ItemGroupType
, NULL ItemGroupTypeName
, NULL itembuyergroupid
, NULL ItemBuyerGroupDesc
, NULL Phantom 
, NULL IsPhantom

, NULL min_purchase_qty
, NULL multiple_purchase_qty
, NULL std_purchase_order_qty
, NULL max_purchase_order_qty
, NULL purchase_leadtime

, NULL min_inventory_qty
, NULL multiple_inventory_qty
, NULL std_inventory_order_qty
, NULL max_inventory_order_qty
, NULL inventory_leadtime

, NULL min_sales_qty
, NULL multiple_sales_qty
, NULL std_sales_order_qty
, NULL max_sales_order_qty
, NULL sales_leadtime
, NULL BaseSalesPrice
, NULL BaseSalesPricePerLB

, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]
, 'D365FO' [Source]