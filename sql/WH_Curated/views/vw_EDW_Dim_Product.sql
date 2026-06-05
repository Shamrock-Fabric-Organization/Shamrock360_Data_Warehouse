-- Auto Generated (Do not modify) 4942AC80E165C4B818CE256FA81F40C736C264D524B40C0A69D42A8B317015A6
/****** Object:  View [dbo].[vw_EDW_Dim_Product]    Script Date: 5/4/2026 12:14:39 PM ******/


CREATE             View [dbo].[vw_EDW_Dim_Product] 
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
          ,[MiscRevenue]
          ,[Lifecycle]
          --,[PackageWeight] as Package_Weight
          ,[Inventory_UoM]
          ,[Purchasing_UoM]
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

          ,[RecordEffectiveStartDate] as Start_Date
          ,[RecordEffectiveEndDate] as End_Date
          ,[RecordStatus] as Record_Status
          ,[Source]
      FROM [dbo].[tbl_DIM_Product] 
      --where RecordStatus = '1'

  UNION ALL

SELECT ABS(CAST(CAST(
            HASHBYTES('SHA2_256', 
                CONCAT(
                    CAST(NEWID() AS VARCHAR(36)), '|'
                   ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                   ,CAST(NEWID() AS VARCHAR(36)), '|'
                   ,CAST(l.ItemKey AS VARCHAR(100))
                )
            ) AS BINARY(8)) AS BIGINT))  AS ProductKey
      ,'101' AS [CMPNY]
      ,l.ItemKey AS [Product_ID]
      ,l.ItemKey AS Product_Name
      ,l.ItemKey AS Search_Name
      ,l.Desc1 AS [Commercial_Name]

      ,m.[Technology]     AS [Technology]
      ,m.[Material]       AS [Material]
      ,m.[Business_Line]  AS [Business_Line]
      ,COALESCE(m.[Product_Line], n.ProdLineAcctg_Trim) AS [Product_Line]

      ,'' AS [MiscRevenue]
      ,'' AS [Lifecycle]
      ,'lbs' AS [Inventory_UoM]
      ,NULL AS [Purchasing_UoM]
      ,'lbs' AS [Sales_UoM]
      ,'20' AS [Item_Type]
      ,NULL AS PTFE_Flag
      ,NULL AS Reorder_Point
      ,NULL AS itemmodelgroupid
      ,NULL AS producttype
      ,NULL AS producttype_desc
      ,NULL AS itemgroupid
      ,NULL AS ItemGroupName
      ,NULL AS ItemGroupType
      ,NULL AS ItemGroupTypeName
      ,NULL AS ItemBuyerGroupID
      ,NULL AS ItemBuyerGroupDesc
      ,NULL AS Phantom
      ,NULL AS IsPhantom

      ,NULL AS min_purchase_qty
      ,NULL AS multiple_purchase_qty
      ,NULL AS std_purchase_order_qty
      ,NULL AS max_purchase_order_qty
      ,NULL AS purchase_leadtime

      ,NULL AS min_inventory_qty
      ,NULL AS multiple_inventory_qty
      ,NULL AS std_inventory_order_qty
      ,NULL AS max_inventory_order_qty
      ,NULL AS inventory_leadtime

      ,NULL AS min_sales_qty
      ,NULL AS multiple_sales_qty
      ,NULL AS std_sales_order_qty
      ,NULL AS max_sales_order_qty
      ,NULL AS sales_leadtime
      ,NULL AS BaseSalesPrice
      ,NULL AS BaseSalesPricePerLB

      ,l.[RecordEffectiveStartDate] AS Start_Date
      ,l.[RecordEffectiveEndDate]   AS End_Date
      ,l.[RecordStatus]             AS Record_Status
      ,'Legacy' AS [Source]

FROM [dbo].[legacy_tbl_DIM_Product] l

CROSS APPLY
(
    SELECT
        CASE
            WHEN NULLIF(LTRIM(RTRIM(l.ProdLineAcctg)), '') IS NULL THEN NULL
            WHEN UPPER(LTRIM(RTRIM(l.ProdLineAcctg))) = 'NULL' THEN NULL
            ELSE LTRIM(RTRIM(l.ProdLineAcctg))
        END AS ProdLineAcctg_Trim,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(l.ProdLineAcctg)), '') IS NULL THEN NULL
            WHEN UPPER(LTRIM(RTRIM(l.ProdLineAcctg))) = 'NULL' THEN NULL
            ELSE UPPER(LTRIM(RTRIM(l.ProdLineAcctg)))
        END AS ProdLineAcctg_Norm
) n

LEFT JOIN
(
    VALUES
        ('EMUL'   , 'Wet Products', 'Emulsions'          , NULL                 , NULL),
        ('PWIDS'  , 'Wet Products', 'Dispersions'        , 'Fluoropolymers'     , 'PTFE Blend'),
        ('DIS'    , 'Wet Products', 'Dispersions'        , NULL                 , NULL),
        ('ODIS'   , 'Wet Products', 'Dispersions'        , NULL                 , NULL),
        ('PUVDIS' , 'Wet Products', 'Dispersions'        , 'Fluoropolymers'     , 'PTFE Blend'),
        ('UVDIS'  , 'Wet Products', 'Dispersions'        , NULL                 , NULL),
        ('SDIS'   , 'Wet Products', 'Dispersions'        , NULL                 , NULL),
        ('PWDIS'  , 'Wet Products', 'Dispersions'        , 'Fluoropolymers'     , 'PTFE Blend'),
        ('WDIS'   , 'Wet Products', 'Dispersions'        , NULL                 , NULL),
        ('PODIS'  , 'Wet Products', 'Dispersions'        , 'Fluoropolymers'     , 'PTFE Blend'),

        ('LIQ-PE' , 'Wet Products', 'Other Wet Products' , 'Non-Fluoropolymers' , 'Other Non-Fluoropolymers'),

        ('FP'     , 'Dry Products', 'Powders'            , 'Fluoropolymers'     , 'FEP'),
        ('FT'     , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'Fischer-Tropsch'),
        ('PBLEND' , 'Dry Products', 'Powders'            , 'Fluoropolymers'     , 'PTFE Blend'),
        ('PE'     , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'Polyethylene'),
        ('EBS'    , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'EBS'),
        ('TXTURE' , 'Dry Products', 'Powders'            , NULL                 , NULL),
        ('PIGMEN' , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'Other Non-Fluoropolymers'),
        ('PTFE'   , 'Dry Products', 'Powders'            , NULL                 , NULL),
        ('WAXES'  , 'Dry Products', 'Powders'            , NULL                 , NULL),
        ('TP'     , 'Dry Products', 'Powders'            , NULL                 , NULL),
        ('BLENDS' , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'Blend'),
        ('PP'     , 'Dry Products', 'Powders'            , 'Non-Fluoropolymers' , 'Polypropylene'),

        ('FUNCON' , 'Dry Products', 'Other Dry Products' , 'Fluoropolymers'     , 'PTFE Blend'),
        ('RAW-MAT', 'Dry Products', 'Other Dry Products' , 'Non-Fluoropolymers' , 'Other Non-Fluoropolymers'),

        ('ADDITV' , NULL          , NULL                 , 'Non-Fluoropolymers' , 'Other Non-Fluoropolymers')
) m (ProdLineAcctg, Business_Line, Product_Line, Technology, Material)
    ON n.ProdLineAcctg_Norm = m.ProdLineAcctg

WHERE NOT EXISTS
(
    SELECT 1
    FROM [dbo].[XREF_Product_ID] x
    WHERE x.[Apollo_ProductID] = l.ItemKey
)