/****** Object:  View [dbo].[vw_EDW_Dim_Warehouse]    Script Date: 5/4/2026 10:30:55 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Warehouse]    Script Date: 5/1/2026 3:22:37 PM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Warehouse]    Script Date: 1/22/2026 9:55:18 AM ******/

--drop view [vw_EDW_Dim_Warehouse]


CREATE         View [dbo].[vw_EDW_Dim_Warehouse] 
	--WITH SCHEMABINDING 
		as
SELECT [WarehouseKey]
	,[CMPNY]
	,[Warehouse_ID]
	,[Warehouse_Name]
	,[Site_ID]
	,[Site_Name]
	,[LocationType]
	,[LocationTypeDesc]
	,[LocationLevel]
	,[Source]
	,[RecordEffectiveStartDate]
	,[RecordEffectiveEndDate]
	,[RecordStatus]
FROM [dbo].[tbl_DIM_Warehouse]

UNION ALL

SELECT ABS(CAST(CAST(HASHBYTES('SHA2_256', CONCAT (
						CAST(NEWID() AS VARCHAR(36))
						,'|'
						,CAST(SYSDATETIME() AS VARCHAR(30))
						,'|'
						,CAST(NEWID() AS VARCHAR(36))
						,'|'
						-- Add row-specific data for extra uniqueness
						,CAST(lw.Warehouse AS VARCHAR(100))
						)) AS BINARY (8)) AS BIGINT)) AS ProductKey
	,lw.CMPNY
	,lw.Warehouse [Warehouse_ID]
	,lw.Warehouse [Warehouse_Name]
	,'UNKNOWN' [Site_ID]
	,'UNKNOWN' [Site_Name]
	,NULL [LocationType]
	,NULL [LocationTypeDesc]
	,NULL [LocationLevel]
	,'Legacy' [Source]
	,CONVERT(DATETIME2(6), '01/01/1900') [RecordEffectiveStartDate]
	,CONVERT(DATETIME2(6), '12/31/2099') [RecordEffectiveEndDate]
	,1 [RecordStatus]
FROM (
	SELECT DISTINCT Warehouse
		--,CASE WHEN Cmpny = '001' THEN '101' ELSE Cmpny END Cmpny
		,CASE WHEN Cmpny in ('001','002') then '101' 
		 WHEN Cmpny = '101' THEN '301'  
		 WHEN Cmpny = '201' THEN '501'
		 WHEN CMPNY = '999' THEN '301'
		 else Cmpny end  Cmpny

	FROM dbo.legacy_tbl_Fact_Sales
	WHERE NOT (
			CASE 
				WHEN Warehouse IN ('','n.a.','Not Applicable','Not Available') THEN 'UNKNOWN'
				----WHEN Cmpny = '001' THEN '101'
				WHEN Cmpny in ('001','002') then '101' 
				WHEN Cmpny = '101' THEN '301'  
				WHEN Cmpny = '201' THEN '501'
				WHEN CMPNY = '999' THEN '301'
				ELSE Cmpny 
			END 
			+ '=' + 
			CASE 
				WHEN Warehouse IN ('','n.a.') THEN 'not applicable'
				ELSE Warehouse
			END 
				IN 
					(
					SELECT Cmpny + '=' + Warehouse_ID
					FROM dbo.tbl_DIM_Warehouse
					)
			)
	) lw

GO

