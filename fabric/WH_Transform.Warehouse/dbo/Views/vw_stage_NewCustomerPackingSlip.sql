-- Auto Generated (Do not modify) 99BF34920BC503195DC0D7F9DC620A9191A1139A2F0DFFD76358665A9FADD974

--drop   VIEW [dbo].[vw_stage_NewCustomerPackingSlip]

    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewCustomerPackingSlip]
AS
SELECT 
	CustomerPackingSlipKey
	, CMPNY
	, CustomerPackingSlipId
	, SalesId
	, ShipDate
	, DocumentDate
	, CustomerAccount
	, InvoiceAccount
	, CustomerPO
	, ShipToName
	, DeliveryMode
	, DeliveryTerms
	, DeliveryReason
	, ShipFromWarehouse
	, CarrierId
	, CreatedDateTime

	, [Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_CustomerPackingSlip_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_CustomerPackingSlip AS Target
		WHERE Target.CustomerPackingSlipID = Source.CustomerPackingSlipID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);