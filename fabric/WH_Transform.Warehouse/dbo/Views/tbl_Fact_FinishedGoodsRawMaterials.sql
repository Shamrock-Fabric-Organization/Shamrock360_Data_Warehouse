-- Auto Generated (Do not modify) 5EEFADCCA14DAB1F7A77EBF6A0A1D6F8511720BE8BE152C90C3566709BAA86B7
/****** Object:  View [dbo].[tbl_Fact_FinishedGoodsRawMaterials]    Script Date: 5/27/2026 2:12:04 PM ******/
/****** Object:  View [dbo].[tbl_Fact_FinishedGoodsRawMaterials]    Script Date: 5/1/2026 9:10:30 AM ******/


CREATE        VIEW [dbo].[tbl_Fact_FinishedGoodsRawMaterials] as
SELECT [ExplodedFormulaKey]
	,[DataAreaId]
	,[FgItemId]
	,[FgSiteId]
	,[FgBomId]
	,[RmItemId]  RawMaterialProductID
	,[RmSiteId]
	----,[LbsPerLbFG]
	,[NativeLbsPerLbFG]  RawMaterialAmtPerLbFG
	--,[RmNativeUomId]
	--,[UomConverted]
	--,[UomConversionMissing]
	,[BomPath]
	,[BomLevel]
	--,[FgFormulaUomId]
	--,[FgFormulaQtyLbs]
	--,[FgItemName]
	--,[FgItemGroupId]
	--,[RmItemName]
	--,[RmItemGroupId]
	,[PeriodFromDate]
	,[PeriodToDate]
	, [PercentControlled]
	, [Percent]
	,[IsCurrentPeriod]  IsCurrent
	--,[LoadedAtUtc]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dp.ProductKey, -1) FinishedGoodProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, CONVERT(INT, CONVERT(CHAR(8), PeriodFromDate, 112) ) FromDateKey
	, CONVERT(INT, CONVERT(CHAR(8), PeriodToDate, 112) ) ToDateKey
	, ISNULL(rmdp.ProductKey, -1) RawMaterialProductKey
	, ISNULL(rmds.SiteKey, -1) RawMaterialSiteKey

FROM tbl_ExplodedFormula_ByVersion  f

LEFT JOIN tbl_DIM_Legal_Entity dle
  ON f.DataAreaId = dle.CMPNY

LEFT JOIN tbl_DIM_Product dp
  ON f.DataAreaId = dp.CMPNY
    AND f.FgItemId = dp.Product_ID
	AND dp.RecordStatus = 1

LEFT JOIN tbl_DIM_Site ds
  ON f.DataAreaId = ds.CMPNY
    AND f.FgSiteId = ds.Site_ID
	AND ds.RecordStatus = 1

LEFT JOIN tbl_DIM_Product rmdp
  ON f.DataAreaId = rmdp.CMPNY
    AND f.RmItemId = rmdp.Product_ID
	AND rmdp.RecordStatus = 1

LEFT JOIN tbl_DIM_Site rmds
  ON f.DataAreaId = rmds.CMPNY
    AND f.RmSiteId = rmds.Site_ID
	AND rmds.RecordStatus = 1

WHERE [IsCurrentPeriod] = 1

/*
select distinct FgItemId
FROM tbl_ExplodedFormula_ByVersion  f
where bomlevel = 10



select *
FROM tbl_ExplodedFormula_ByVersion  f
WHERE FGitemid in
(
'11334',
'11427',
'11802',
'11339'
)
order by 2,3,4,6
*/