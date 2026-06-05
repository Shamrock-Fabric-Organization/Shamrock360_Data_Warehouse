-- Auto Generated (Do not modify) BC8B5070B9A7897AD1FEC5FF3F48ACCE232A66B3934FCEA87D0904DEF858ACCF

/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_Warehouse_incoming]	

CREATE     VIEW [dbo].[vw_stage_DIM_Warehouse_incoming]			
AS			
SELECT ABS(CAST(CAST(HASHBYTES('SHA2_256', CONCAT (
						CAST(NEWID() AS VARCHAR(36))
						,'|'
						,CAST(SYSDATETIME() AS VARCHAR(30))
						,'|'
						,CAST(NEWID() AS VARCHAR(36))
						,'|'
						-- Add row-specific data for extra uniqueness
						,CAST(l.inventlocationid AS VARCHAR(100))
						)) AS BINARY (8)) AS BIGINT)) AS WarehouseKey
	,l.dataareaid CMPNY
	,l.inventlocationid Warehouse_ID
	,l.Name Warehouse_Name
	,l.inventsiteid Site_ID
	,s.name Site_Name
	,l.inventlocationtype LocationType
	,l.inventlocationtype_$label LocationTypeDesc
	,l.inventlocationlevel LocationLevel
	,'D365FO' Source
	,CONVERT(DATETIME2(3), NULL) RecordEffectiveStartDate
	,CONVERT(DATETIME2(3), NULL) RecordEffectiveEndDate
	,CONVERT(INT, NULL) RecordStatus
FROM WH_Raw.dbo.inventlocation l
JOIN WH_Raw.dbo.inventsite s ON l.dataareaid = s.dataareaid
	AND l.inventsiteid = s.siteid

UNION ALL

SELECT -1 [WarehouseKey]
	,'Unknown' [CMPNY]
	,'Unknown' [Warehouse_ID]
	,'Unknown' [Warehouse_Name]
	,'Unknown' Site_ID
	,'Unknown' Site_Name
	,NULL LocationType
	,NULL LocationTypeDesc
	,NULL LocationLevel
	,'D365FO' [Source]
	,NULL [RecordEffectiveStartDate]
	,NULL [RecordEffectiveEndDate]
	,NULL [RecordStatus]

UNION ALL

SELECT -2 [WarehouseKey]
	,'Unknown' [CMPNY]
	,'Not Applicable' [Warehouse_ID]
	,'Not Applicable' [Warehouse_Name]
	,NULL Site_ID
	,NULL Site_Name
	,NULL LocationType
	,NULL LocationTypeDesc
	,NULL LocationLevel
	,'D365FO' [Source]
	,NULL [RecordEffectiveStartDate]
	,NULL [RecordEffectiveEndDate]
	,NULL [RecordStatus]

UNION ALL

SELECT -3 [WarehouseKey]
	,'Unknown' [CMPNY]
	,'Not Available' [Warehouse_ID]
	,'Not Available' [Warehouse_Name]
	,NULL Site_ID
	,NULL Site_Name
	,NULL LocationType
	,NULL LocationTypeDesc
	,NULL LocationLevel
	,'D365FO' [Source]
	,NULL [RecordEffectiveStartDate]
	,NULL [RecordEffectiveEndDate]
	,NULL [RecordStatus]