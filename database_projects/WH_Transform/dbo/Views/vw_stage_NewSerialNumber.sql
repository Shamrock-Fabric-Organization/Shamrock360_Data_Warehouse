
CREATE         VIEW [dbo].[vw_stage_NewSerialNumber]
AS
SELECT [SerialNumberKey]
	,[CMPNY]
	,[SerialNumber]
	--,[ProductID]
	,[proddate]
	,[description]
	,[rfidtagid]
	,SerialNumberNoteName
	,SerialNumberNote
	,SeralNumberNoteCreatedBy
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
FROM vw_stage_DIM_SerialNumber_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_SerialNumber AS Target
		WHERE Target.[SerialNumber] = Source.[SerialNumber]
			AND Target.[CMPNY] = Source.[CMPNY]
			AND Target.RecordStatus = 1
		);
