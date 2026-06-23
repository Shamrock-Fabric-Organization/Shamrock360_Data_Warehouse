-- Auto Generated (Do not modify) A251754DDD6AE6EC882121427AF175F9ACE58FD686EF00948A41B80D699C78F1

--use WH_Transform


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE   VIEW [dbo].[vw_stage_NewRoute]
AS
SELECT 
	[RouteKey]
	, [CMPNY]
	, [RouteID]
	, [RouteName]
	, [ApproverPersonnelNumber]
	, [ApproverName]
	, [Approved]
	, [CheckRoute]
	, [RouteType]
	, [Source]
	
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Route_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Route AS Target
		WHERE Target.RouteID = Source.RouteID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);