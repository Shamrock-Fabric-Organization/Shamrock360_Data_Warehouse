-- Auto Generated (Do not modify) 89D5393B227809C3171B9746450EAA42B8D48334473515F61818E25F27BF75F1


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewLegal_Entity]
AS
SELECT 
    Legal_EntityKey
	,[CMPNY]
	,[Legal_Entity_Name]
	,[accountingcurrency]
	,[reportingcurrency]
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Legal_Entity_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Legal_Entity AS Target
		WHERE Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);