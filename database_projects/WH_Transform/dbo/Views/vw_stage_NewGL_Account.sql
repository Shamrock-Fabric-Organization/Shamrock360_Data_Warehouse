

CREATE     VIEW [dbo].[vw_stage_NewGL_Account]
AS
SELECT [GL_AccountKey]
	,[GL_Account_Number]
	,[GL_Account_Name]
	,[accountcategoryref]
	,[Account_Category]
	,[Account_Category_Name]
	,[Account_Type]
	,[Account_Type_Description]
	,[Category_Account_Type]
	,[Category_Account_Type_Description]
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
FROM vw_stage_DIM_GL_Account_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_GL_Account AS Target
		WHERE Target.[GL_Account_Number] = Source.[GL_Account_Number]
			AND Target.RecordStatus = 1
		);

GO

