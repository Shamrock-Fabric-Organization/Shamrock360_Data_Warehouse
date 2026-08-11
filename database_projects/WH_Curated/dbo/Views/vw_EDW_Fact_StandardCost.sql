

CREATE  OR ALTER         VIEW [dbo].[vw_EDW_Fact_StandardCost]
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

select CMPNY
, Product_ID
, NULL LegacyProductCode
, SiteID
, ActivationDate
, EndDate
, Costing_Version
, CurrentActiveCost
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
, Source
, StandardCostKey
, Legal_EntityKey
, HistoricalProductKey
, ProductKey
, SiteKey
, ActivationDateKey

from tbl_Fact_StandardCost

UNION ALL

SELECT  '101' CMPNY
    , x.D365_ProductID ProductID
    , s.[PRODUCT CODE]  LegacyProductCode
    , null SiteId
    , null ActivationDate
    , null EndDate
    , null Costing_Version
    , 1 CurrentActiveCost
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
    ,'Legacy' Source

	, ISNULL(dsc.StandardCostKey, -1) as StandardCostKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dp.ProductKey, -1) HistoricProductKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
    , -1 SiteKey
    , 19000101 ActivationDateKey

  FROM stdcost  s

 left join [dbo].[XREF_Product_ID] X 
	ON s.[PRODUCT CODE] = x.Apollo_ProductID  
	  --AND case when s.Cmpny = '002' then '001' else s.Cmpny end = X.Company  --case statement not used as the XRef has the legacy company values = X.Company

LEFT JOIN mtbl_EDW_DIM_Product p
    ON  x.D365_ProductID = p.Product_ID
        AND '101'      = p.CMPNY
        AND p.record_status = 1

LEFT JOIN mtbl_EDW_DIM_Product dp
        ON  x.D365_ProductID = dp.Product_ID
          AND '101'      = dp.CMPNY
          AND dp.record_status = 1

LEFT JOIN mtbl_EDW_DIM_Product dpc
        ON  x.D365_ProductID = dpc.Product_ID
          AND '101'      = dpc.CMPNY
          AND dpc.record_status = 1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON '101' = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_StandardCost dsc
	ON s.[PRODUCT CODE] = dsc.LegacyProductCode
		--AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		-- WHEN s.Cmpny = '101' THEN '301'  
		-- WHEN s.Cmpny = '201' THEN '501'
		-- WHEN s.CMPNY = '999' THEN '301'
		-- else s.Cmpny end = dsc.CMPNY
		AND dsc.RecordStatus=1



