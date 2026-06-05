-- Auto Generated (Do not modify) F3382C7414B68A365A32A73CC395664D9D47C51479F7087FB3C870655A3555D8


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewDepartment]
AS
SELECT 
    DepartmentKey
	,[Department]
	,[Department_Name]
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Department_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Department AS Target
		WHERE Target.Department = Source.Department
			AND Target.RecordStatus = 1
		);