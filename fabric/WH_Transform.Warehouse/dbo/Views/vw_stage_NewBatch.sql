-- Auto Generated (Do not modify) B28F5D7CF38D99DFA9CCAEFEF5178D1819E6990B4F6472D66C2CF2DCE16EFD32

/****** Object:  View [dbo].[vw_stage_NewBatch]    Script Date: 4/17/2026 1:45:13 PM ******/


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE   VIEW [dbo].[vw_stage_NewBatch]
AS
SELECT 
	[BatchKey]
	, CMPNY
	, BatchID
	, ProductID
	, CountryOfOrigin
	, DispositionCode
	, ProductionDate
	, FGTestedDate
	, ExpirationDate
	, BestBeforeDate
	, ShelfAdviceDate
	, VendorBatchDate
	, VendorExpirationDate
	, VendorBatchID

	, BatchNoteName
	, BatchNote
	, BatchNoteCreatedBy


	, [Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Batch_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Batch AS Target
		WHERE Target.BatchID = Source.BatchID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);