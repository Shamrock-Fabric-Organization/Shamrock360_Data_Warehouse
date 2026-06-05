

CREATE     VIEW [dbo].[vw_stage_NewQualityOrder]
AS
SELECT [QualityOrderKey]
	,[CMPNY]
	,[QualityOrderID]
	,[inventrefid]
	,[inventreftransid]
	,[ProductID]
	,[itemsamplingid]
	,[oprnum]
	,[orderstatus]
	,[orderstatus_$label]
	,[qty]
	,[referencetype]
	,[referencetype_$label]
	,[routeid]
	,[testgroupid]

	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
FROM vw_stage_DIM_QualityOrder_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_QualityOrder AS Target
		WHERE Target.[QualityOrderID] = Source.[QualityOrderID]
			AND Target.[CMPNY] = Source.[CMPNY]
			AND Target.RecordStatus = 1
		);

GO

