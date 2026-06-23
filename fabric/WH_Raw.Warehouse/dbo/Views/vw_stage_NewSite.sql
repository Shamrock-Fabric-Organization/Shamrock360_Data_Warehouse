-- Auto Generated (Do not modify) AF4CABC8655942F0927E017334587BF9E477C5B0D66B6BE417DAB23E6FA28B5E



    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE   VIEW [dbo].[vw_stage_NewSite]
AS
SELECT 
    SiteKey
	,[CMPNY]
	,[Site_ID]
	,[Site_Name]
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Site_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Site AS Target
		WHERE Target.Site_ID = Source.Site_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);