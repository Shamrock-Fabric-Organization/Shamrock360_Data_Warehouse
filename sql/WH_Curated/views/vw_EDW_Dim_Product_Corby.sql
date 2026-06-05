-- Auto Generated (Do not modify) 05F34950B4AC17FE07D42EFFEE7B44E708354658C39871672223435116E3AA32
/****** Object:  View [dbo].[vw_EDW_Dim_Product_Corby]    Script Date: 5/4/2026 12:13:21 PM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Product_Corby]    Script Date: 5/1/2026 2:49:51 PM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Product_Corby]    Script Date: 3/6/2026 1:42:56 PM ******/



/****** Object:  View [dbo].[vw_EDW_Dim_Product_Corby]    Script Date: 1/21/2026 2:51:33 PM ******/


--drop view [vw_EDW_Dim_Product_Corby]


CREATE            View [dbo].[vw_EDW_Dim_Product_Corby] 
	--WITH SCHEMABINDING 
		as

      SELECT [ProductKey] --as Record_ID
          ,[CMPNY]
          ,[Product_ID]
          ,[ProductName] as Product_Name
          ,[ProductSearchName] as Search_Name
          ,[Commercial_Name]
          ,[Technology]
          ,[Material]
          ,[Business_Line]
          ,[Product_Line]
          ,[Lifecycle]
          --,[PackageWeight] as Package_Weight
          ,[Inventory_UoM]
          --,[Purchasing_UoM]
          ,[Sales_UoM]
          ,[Item_Type]
          --,[ProductID] as Product_ID
          ,[PTFE_Flag]
          ,[Reorder_Point]
	        ,itemmodelgroupid
	        ,producttype
	        ,producttype_desc
	        ,itemgroupid
	        ,ItemGroupName
	        ,ItemGroupType
	        ,ItemGroupTypeName
            ,ItemBuyerGroupID
            ,ItemBuyerGroupDesc
          ,[RecordEffectiveStartDate] as Start_Date
          ,[RecordEffectiveEndDate] as End_Date
          ,[RecordStatus] as Record_Status
          ,[Source]
      FROM [dbo].[tbl_DIM_Product] 
      --where RecordStatus = '1'

  Union All

        SELECT ABS(CAST(CAST(
                HASHBYTES('SHA2_256', 
                    CONCAT(
                        CAST(NEWID() AS VARCHAR(36)), '|'
                        ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                        ,CAST(NEWID() AS VARCHAR(36)), '|'
                        -- Add row-specific data for extra uniqueness
                        ,CAST(ItemKey AS VARCHAR(100))
                    )
                ) AS BINARY(8)) AS BIGINT))  AS ProductKey
          ,'101' [CMPNY]
          ,ItemKey as [Product_ID]
          ,ItemKey as Product_Name
          ,ItemKey as Search_Name
          ,Desc1 as [Commercial_Name]
          ,'' as [Technology]
          ,'' as [Material]
          ,'' as [Business_Line]
          ,ProdLineAcctg as [Product_Line]
          ,'' as [Lifecycle]
          --,0.00 as Package_Weight
          ,'lbs' as [Inventory_UoM]
          --,'ea' as [Purchasing_UoM]
          ,'lbs' as [Sales_UoM]
          ,'20' [Item_Type]                 --need clarification
          --,[ProductID] as Product_ID
          ,NULL PTFE_Flag
          ,NULL Reorder_Point
 	        ,NULL itemmodelgroupid
	        ,NULL producttype
	        ,NULL producttype_desc
	        ,NULL itemgroupid
	        ,NULL ItemGroupName
	        ,NULL ItemGroupType
	        ,NULL ItemGroupTypeName
            ,NULL ItemBuyerGroupID
            ,NULL ItemBuyerGroupDesc
         ,[RecordEffectiveStartDate] as Start_Date
          ,[RecordEffectiveEndDate] as End_Date
          ,[RecordStatus] as Record_Status
          ,'Legacy' as [Source]
      FROM [dbo].[legacy_tbl_DIM_Product] 
      where 
      --RecordStatus = '1'
      --and 
      NOT(ItemKey in (select [Apollo_ProductID] from [dbo].[XREF_Product_ID]))

   Union ALL

           SELECT ABS(CAST(CAST(
                HASHBYTES('SHA2_256', 
                    CONCAT(
                        CAST(NEWID() AS VARCHAR(36)), '|'
                        ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                        ,CAST(NEWID() AS VARCHAR(36)), '|'
                        -- Add row-specific data for extra uniqueness
                        ,CAST(Product AS VARCHAR(100))
                    )
                ) AS BINARY(8)) AS BIGINT))  AS ProductKey
          ,Warehouse as [CMPNY]
          ,Product as [Product_ID]
          ,Product as Product_Name
          ,Product as Search_Name
          ,'' as [Commercial_Name]
          ,'' as [Technology]
          ,'' as [Material]
          ,'' as [Business_Line]
          ,[Product Line] as [Product_Line]
          ,'' as [Lifecycle]
          --,0.00 as Package_Weight
          ,'lbs' as [Inventory_UoM]
          --,'ea' as [Purchasing_UoM]
          ,'lbs' as [Sales_UoM]
          ,'20' [Item_Type]                 --need clarification
          --,[ProductID] as Product_ID
          ,NULL PTFE_Flag
          ,NULL Reorder_Point
 	        ,NULL itemmodelgroupid
	        ,NULL producttype
	        ,NULL producttype_desc
	        ,NULL itemgroupid
	        ,NULL ItemGroupName
	        ,NULL ItemGroupType
	        ,NULL ItemGroupTypeName
            ,NULL ItemBuyerGroupID
            ,NULL ItemBuyerGroupDesc
         ,[SnapShotDate] as Start_Date
          ,[SnapShotDate] as End_Date
          ,1 as Record_Status
          ,'BVBA' as [Source]
      FROM [dbo].[tbl_RESULTSSLSBYYR_BVBA] 
      where 
      --RecordStatus = '1'
      --and 
      NOT(Product in (select [Apollo_ProductID] from [dbo].[XREF_Product_ID]))
	  
	  --BVBA OPEN

	  Union ALL

           SELECT ABS(CAST(CAST(
                HASHBYTES('SHA2_256', 
                    CONCAT(
                        CAST(NEWID() AS VARCHAR(36)), '|'
                        ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                        ,CAST(NEWID() AS VARCHAR(36)), '|'
                        -- Add row-specific data for extra uniqueness
                        ,CAST(Product AS VARCHAR(100))
                    )
                ) AS BINARY(8)) AS BIGINT))  AS ProductKey
          ,Warehouse as [CMPNY]
          ,Product as [Product_ID]
          ,Product as Product_Name
          ,Product as Search_Name
          ,'' as [Commercial_Name]
          ,'' as [Technology]
          ,'' as [Material]
          ,'' as [Business_Line]
          ,[Product Line] as [Product_Line]
          ,'' as [Lifecycle]
          --,0.00 as Package_Weight
          ,'lbs' as [Inventory_UoM]
          --,'ea' as [Purchasing_UoM]
          ,'lbs' as [Sales_UoM]
          ,'20' [Item_Type]                 --need clarification
          --,[ProductID] as Product_ID
          ,NULL PTFE_Flag
          ,NULL Reorder_Point
 	        ,NULL itemmodelgroupid
	        ,NULL producttype
	        ,NULL producttype_desc
	        ,NULL itemgroupid
	        ,NULL ItemGroupName
	        ,NULL ItemGroupType
	        ,NULL ItemGroupTypeName
            ,NULL ItemBuyerGroupID
            ,NULL ItemBuyerGroupDesc
         ,[SnapShotDate] as Start_Date
          ,[SnapShotDate] as End_Date
          ,1 as Record_Status
          ,'BVBA' as [Source]
      FROM [dbo].[tbl_RESULTSSLSBYYR_BVBA_OPEN]
      where 
      --RecordStatus = '1'
      --and 
      NOT(Product in (select [Apollo_ProductID] from [dbo].[XREF_Product_ID]))
	  
  --Union ALL


  --         SELECT ABS(CAST(CAST(
  --              HASHBYTES('SHA2_256', 
  --                  CONCAT(
  --                      CAST(NEWID() AS VARCHAR(36)), '|'
  --                      ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
  --                      ,CAST(NEWID() AS VARCHAR(36)), '|'
  --                      -- Add row-specific data for extra uniqueness
  --                      ,CAST([Product Name] AS VARCHAR(100))
  --                  )
  --              ) AS BINARY(8)) AS BIGINT))  AS ProductKey
  --        ,'201' as [CMPNY]
  --        ,[Product Name] as [Product_ID]
  --        ,[Product Name] as Product_Name
  --        ,[Product Name] as Search_Name
  --        ,'' as [Commercial_Name]
  --        ,'' as [Technology]
  --        ,'' as [Material]
  --        ,'' as [Business_Line]
  --        ,[Product Description] as [Product_Line]
  --        ,'' as [Lifecycle]
  --        --,0.00 as Package_Weight
  --        ,'lbs' as [Inventory_UoM]
  --        --,'ea' as [Purchasing_UoM]
  --        ,'lbs' as [Sales_UoM]
  --        ,'20' [Item_Type]                 --need clarification
  --        --,[ProductID] as Product_ID
  --        ,NULL PTFE_Flag
  --        ,NULL Reorder_Point
 	--        ,NULL itemmodelgroupid
	 --       ,NULL producttype
	 --       ,[Product Description] producttype_desc
	 --       ,NULL itemgroupid
	 --       ,NULL ItemGroupName
	 --       ,NULL ItemGroupType
	 --       ,NULL ItemGroupTypeName
  --          ,NULL ItemBuyerGroupID
  --          ,NULL ItemBuyerGroupDesc
  --       ,[SnapShotDate] as Start_Date
  --        ,[SnapShotDate] as End_Date
  --        ,1 as Record_Status
  --        ,'BVBA' as [Source]
  --    FROM [dbo].[tbl_RESULTSSLSBYYR_TEDA] 
  --    where 
  --    --RecordStatus = '1'
  --    --and 
  --    NOT([Product Name] in (select [Apollo_ProductID] from [dbo].[XREF_Product_ID]))