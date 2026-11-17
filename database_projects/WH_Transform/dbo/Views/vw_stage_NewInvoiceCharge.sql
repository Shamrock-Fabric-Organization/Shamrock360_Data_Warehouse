

    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE OR ALTER VIEW [dbo].[vw_stage_NewInvoiceCharge]
AS
SELECT 
	InvoiceChargeKey
	, CMPNY
	, MarkupCode
	, ChargeDescription
	, TaxItemGroup
	, MaxAmount
	, IsShipping
	, IsRefundable
	, InMarkupTable

	, [Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_InvoiceCharge_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_InvoiceCharge AS Target
		WHERE Target.CMPNY = Source.CMPNY
			AND Target.MarkupCode = Source.MarkupCode
			AND Target.RecordStatus = 1
		);
