-- Auto Generated (Do not modify) 484D308AC6D79AD044C66BFD198EC8BB8F39AAF4AF26E8B13931E18001E04D8B
/****** Object:  View [dbo].[vw_EDW_Dim_StandardCost]    Script Date: 5/28/2026 10:58:48 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_StandardCost]    Script Date: 5/20/2026 11:39:49 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_StandardCost]    Script Date: 4/3/2026 9:03:31 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_StandardCost]    Script Date: 3/13/2026 3:29:38 PM ******/

CREATE           VIEW [dbo].[vw_EDW_Dim_StandardCost]
AS
with stdcost as
(
SELECT distinct  s.[PRODUCT CODE]
      ,convert(decimal(38,6), s.[MATERIAL COST/LB]) [MATERIAL COST/LB]
      ,convert(decimal(38,6), s.[LABOR COST/LB]) [LABOR COST/LB]
      ,convert(decimal(38,6), s.[UTILITY COST/LB]) [UTILITY COST/LB]
      ,convert(decimal(38,6), s.[OS PROCESSING COST/LB]) [OS PROCESSING COST/LB]
      ,convert(decimal(38,6), s.[PACKAGING COST/LB]) [PACKAGING COST/LB]
      ,convert(decimal(38,6), s.[OVERHEAD COST/LB]) [OVERHEAD COST/LB]
FROM [dbo].[legacy_tbl_Dim_StandardCost]  s
)

select StandardCostKey
, CMPNY
, Product_ID
, NULL LegacyProductCode
, SiteID
, ActivationDate
, EndDate
, Costing_Version
, CurrentActiveCost
, ProductName
, ProductSearchName
, Direct_Material_Cost_Standard
, Packaging_Cost_Standard
, Direct_Labor_Cost_Standard
, Direct_Utility_Cost_Standard
, Overhead_Warehouse_Cost_Standard
, Overhead_Indirect_Supervisor_Cost_Standard
, Overhead_Quality_Cost_Standard
, Overhead_Maintenance_Cost_Standard
, Overhead_Manufacturing_Admin_Cost_Standard
, Overhead_Depreciation_Cost_Standard
, Overhead_Miscellaneous_Manufacturing_Cost_Standard
, Outside_Processing_Cost_Standard
, Total_Direct_Cost_Standard
, Total_Overhead_Cost_Standard
, TotalCost
, accountingcurrency
, RecordEffectiveStartDate
, RecordEffectiveEndDate
, RecordStatus
, Source 
from tbl_DIM_StandardCost

UNION ALL

--with stdcost as
--(
--SELECT distinct  s.[PRODUCT CODE]
--      ,convert(decimal(38,6), s.[MATERIAL COST/LB]) [MATERIAL COST/LB]
--      ,convert(decimal(38,6), s.[LABOR COST/LB]) [LABOR COST/LB]
--      ,convert(decimal(38,6), s.[UTILITY COST/LB]) [UTILITY COST/LB]
--      ,convert(decimal(38,6), s.[OS PROCESSING COST/LB]) [OS PROCESSING COST/LB]
--      ,convert(decimal(38,6), s.[PACKAGING COST/LB]) [PACKAGING COST/LB]
--      ,convert(decimal(38,6), s.[OVERHEAD COST/LB]) [OVERHEAD COST/LB]
--FROM [dbo].[legacy_tbl_Dim_StandardCost]  s
--)

SELECT  
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(s.[PRODUCT CODE] AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS StandardCostKey
    , '101' CMPNY
    , x.D365_ProductID ProductID
    ,s.[PRODUCT CODE]  LegacyProductCode
    , null SiteId
    , null ActivationDate
    , null EndDate
    , null Costing_Version
    , 1 CurrentActiveCost
    , p.Product_Name
    , p.Search_Name
    ,s.[MATERIAL COST/LB]       Direct_Material_Cost_Standard
    ,s.[PACKAGING COST/LB]      Packaging_Cost_Standard
    ,s.[LABOR COST/LB]          Direct_Labor_Cost_Standard
    ,s.[UTILITY COST/LB]        Direct_Utility_Cost_Standard
    ,s.[OVERHEAD COST/LB]       Overhead_Warehouse_Cost_Standard
    , NULL Overhead_Indirect_Supervisor_Cost_Standard
    , NULL Overhead_Quality_Cost_Standard
    , NULL Overhead_Maintenance_Cost_Standard
    , NULL Overhead_Manufacturing_Admin_Cost_Standard
    , NULL Overhead_Depreciation_Cost_Standard
    , NULL Overhead_Miscellaneous_Manufacturing_Cost_Standard
    ,s.[OS PROCESSING COST/LB]  Outside_Processing_Cost_Standard

    , (s.[MATERIAL COST/LB] + s.[LABOR COST/LB] + s.[UTILITY COST/LB]) Total_Direct_Cost_Standard
    , (s.[OVERHEAD COST/LB] + s.[OS PROCESSING COST/LB]) Total_Overhead_Cost_Standard
    , (s.[MATERIAL COST/LB] + s.[LABOR COST/LB] + s.[UTILITY COST/LB] + s.[OVERHEAD COST/LB] + s.[OS PROCESSING COST/LB] + s.[PACKAGING COST/LB]) TotalCost
    ,'USD' accountingcurrency
    ,convert(datetime2(3), '01/01/1900') RecordEffectiveStartDate
    ,convert(datetime2(3), '12/31/2099') RecordEffectiveEndDate
    ,convert(int, 1) RecordStatus
    ,'Legacy' Source

  FROM stdcost  s

 left join [dbo].[XREF_Product_ID] X 
	ON s.[PRODUCT CODE] = x.Apollo_ProductID  
	  --AND case when s.Cmpny = '002' then '001' else s.Cmpny end = X.Company  --case statement not used as the XRef has the legacy company values = X.Company
    LEFT JOIN mtbl_EDW_DIM_Product p
        ON  x.D365_ProductID = p.Product_ID
          AND '101'      = p.CMPNY
          AND p.record_status = 1

--order by source desc, cmpny, Product_ID