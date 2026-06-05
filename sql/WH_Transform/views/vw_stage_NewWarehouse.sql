-- Auto Generated (Do not modify) BC8B5070B9A7897AD1FEC5FF3F48ACCE232A66B3934FCEA87D0904DEF858ACCF


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewWarehouse]
AS
SELECT 
	[WarehouseKey]
	,[CMPNY]
	,[Warehouse_ID]
	,[Warehouse_Name]
	,Site_ID
	,Site_Name
	,LocationType
	,LocationTypeDesc
	,LocationLevel
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Warehouse_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Warehouse AS Target
		WHERE Target.Warehouse_ID = Source.Warehouse_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);