


-- =============================================================================
--use WH_Transform

CREATE VIEW [dbo].[tbl_Fact_StandardCost]
AS
SELECT
      sc.[CMPNY]
    , sc.[Product_ID]
    , sc.[SiteID]
    , sc.[Costing_Version]
    , sc.[accountingcurrency]
    , sc.[ActivationDate]
    , sc.[EndDate]
    , sc.[CurrentActiveCost] 

    , sc.[Direct_Material_Cost_Standard]
    , sc.[Packaging_Cost_Standard]
    , sc.[Direct_Labor_Cost_Standard]
    , sc.[Direct_Utility_Cost_Standard]
    , sc.[Overhead_Warehouse_Cost_Standard]
    , sc.[Overhead_Indirect_Supervisor_Cost_Standard]
    , sc.[Overhead_Quality_Cost_Standard]
    , sc.[Overhead_Maintenance_Cost_Standard]
    , sc.[Overhead_Manufacturing_Admin_Cost_Standard]
    , sc.[Overhead_Depreciation_Cost_Standard]
    , sc.[Overhead_Miscellaneous_Manufacturing_Cost_Standard]
    , sc.[Outside_Processing_Cost_Standard]

    , sc.[Total_Direct_Cost_Standard]
    , sc.[Total_Overhead_Cost_Standard]
    , sc.[TotalCost]

    , sc.[Source]

    , sc.[StandardCostKey]                                  
    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) HistoricalProductKey
    , ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
    , convert(int, convert(char(8), sc.[ActivationDate],112)) ActivationDateKey

FROM [dbo].[tbl_DIM_StandardCost] AS sc

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON sc.[Product_ID] = dp.Product_ID
		AND sc.[CMPNY] = dp.CMPNY
		AND sc.[ActivationDate] between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON sc.[Product_ID] = dpc.Product_ID
		AND sc.[CMPNY] = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON sc.[CMPNY] = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON sc.[SiteID] = ds.Site_ID
		AND sc.[CMPNY] = ds.CMPNY
		AND ds.RecordStatus=1
where sc.StandardCostKey <> -1

