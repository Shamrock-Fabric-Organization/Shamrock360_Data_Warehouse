-- Auto Generated (Do not modify) 8E9CE925924DF3D33D72223E7CBB94F83260593748FC0730146DC71FDEAF942E
--use WH_transform
--go


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewWorkCenter]
AS
SELECT 
	[WorkCenterKey]
	, [CMPNY]
	, [WorkCenterID]
	, [WorkCenterName]
	, [WorkCenterIDandName]
	, [wrkctrtype]
	, [wrkctrtype_$label]
	, [effectivitypct]
	, [errorpct]
	, [operationschedpct]
	, [processcategoryid]
	, [routegroupid]
	, [ResourceGroup]
	, [ResourceGroupName]
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_WorkCenter_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_WorkCenter AS Target
		WHERE Target.WorkCenterID = Source.WorkCenterID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);