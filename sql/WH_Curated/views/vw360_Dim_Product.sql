-- Auto Generated (Do not modify) 9E052F26D7A22A17B23DDBF009C9D8F1FD47432E73D4E828623839E4380720FC
/****** Object:  View [dbo].[vw360_Dim_Product]    Script Date: 5/4/2026 12:14:12 PM ******/
/****** Object:  View [dbo].[vw360_Dim_Product]    Script Date: 5/1/2026 2:49:26 PM ******/



/****** Object:  View [dbo].[vw360_Dim_Product]    Script Date: 1/21/2026 2:51:49 PM ******/

--drop view [vw360_Dim_Product]



CREATE            View [dbo].[vw360_Dim_Product] 
	--WITH SCHEMABINDING 
		as



 Select 
         ABS(CAST(CAST(
         HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST([ProductKey] AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS ProductKey,
                '101' AS CMPNY,
                ItemKey as Product_Code, 
                Desc1 as Product_Name, 
                ItemKey AS ProductSearchName,
                Null AS Commercial_Name,
                Null AS Technology,
                Null AS Material,
                Null AS Business_Line,
                Null AS Product_Line,
                Null AS Lifecycle,
                --PackageWeight,
                Null AS Inventory_UoM,
                --Null AS Purchasing_UoM,
                Null AS Sales_UoM,
                Null AS Item_Type,
                --Null AS ProductID,
                NULL PTFE_Flag,
                NULL Reorder_Point,
                PrintableDesc as Product_Description, 
                ProdLineAcctg, 
                PackageType, 
                PackageLiner, 
                PackageTare, 
                LeadTime, 
                st_ProductionStatus, 
                st_ObsoletionStatus, 
                --ProductDescPublic, 
                --ProductDescInternal, 
                --ApplBenefit, 
                --LevelOfAddition, 
                --ExperimentalProductName, 
                --BaseProduct, 
                RecordEffectiveStartDate, 
                RecordEffectiveEndDate, 
               RecordStatus,
                'Legacy' AS SOURCE
               from dbo.legacy_tbl_DIM_Product
                where RecordStatus='1' 
                and ItemKey not in 
                (select coalesce(x.Apollo_ProductID, p.product_id) 
                    FROM [dbo].[tbl_DIM_Product] p
                    left join [dbo].[XREF_Product_ID] X ON p.Product_ID = x.D365_ProductID) 

          Union ALL

  SELECT [ProductKey]
        ,[CMPNY]
         ,coalesce(x.Apollo_ProductID, p.product_id)
        ,[ProductName]
        ,[ProductSearchName]
        ,[Commercial_Name]
        ,[Technology]
        ,[Material]
        ,[Business_Line]
        ,[Product_Line]
        ,[Lifecycle]
        --,[PackageWeight]
        ,[Inventory_UoM]
        --,[Purchasing_UoM]
        ,[Sales_UoM]
        ,[Item_Type]
        --,[ProductID]
        ,[PTFE_Flag]
        ,[Reorder_Point]
        ,NULL as PrintableDesc
        ,NULL as ProdLineAcctg
        ,NULL as PackageType
        ,NULL as PackageLiner
        ,NULL as PackageTare
        ,NULL as LeadTime
        ,NULL as st_ProductionStatus
        ,NULL as st_ObsoletionStatus
        --,NULL as ProductDescPublic
        --,NULL as ProductDescInternal
        --,NULL as ApplBenefit
        --,NULL as LevelOfAddition
        --,NULL as ExperimentalProductName
        --,NULL as BaseProduct
        ,[RecordEffectiveStartDate]
        ,[RecordEffectiveEndDate]
        ,[RecordStatus]
        ,[Source]
    FROM [dbo].[tbl_DIM_Product] p
    left join [dbo].[XREF_Product_ID] X ON p.Product_ID = x.D365_ProductID  
     where RecordStatus='1'