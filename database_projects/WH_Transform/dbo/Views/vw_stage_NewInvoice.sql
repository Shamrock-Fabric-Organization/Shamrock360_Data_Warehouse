
    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE OR ALTER VIEW [dbo].[vw_stage_NewInvoice]
AS
SELECT 
	InvoiceKey
	, CMPNY
	, Invoice_ID
	, InvoiceDate
	, Sales_ID
	, Order_Account
	, Invoice_Account
	, CustomerGroup
	, CustomerRef
	, CustomerPONumber
	, DocumentNum
	, BillOfLadingId
	, LedgerVoucher
	, SalesOriginId
	, SalesType
	, SalesTypeDesc
	, ReferenceType
	, ReferenceTypeDesc
	, PostedStateID
	, PostedState
	, IsCorrection
	, IsProforma
	, IsPrepayment
	, CurrencyCode
	, Tax_Group
	, PostingProfile
	, PaymentTermId
	, PaymentTermDescription
	, DocumentDate
	, DueDate
	, DeliveryModeCode
	, DeliveryModeDescription
	, DeliveryTermCode
	, DeliveryTermDescription
	, DeliveryName
	, CreatedDateTime
	, ModifiedDateTime

	, [Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Invoice_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Invoice AS Target
		WHERE Target.CMPNY = Source.CMPNY
			AND Target.Invoice_ID = Source.Invoice_ID
			AND Target.InvoiceDate = Source.InvoiceDate
			AND Target.Sales_ID = Source.Sales_ID
			AND Target.RecordStatus = 1
		);
