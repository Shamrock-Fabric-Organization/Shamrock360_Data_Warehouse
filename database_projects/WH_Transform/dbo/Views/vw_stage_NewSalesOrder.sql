

    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewSalesOrder]
AS
SELECT 
	SalesOrderKey
	, CMPNY
	, SalesOrderId
	, SalesType
	, SalesTypeDesc
	, SalesStatus
	, SalesStatusDesc
	, DocumentStatus
	, DocumentStatusDesc
	, SalesOriginId
	, SalesPoolId
	, DeliveryModeCode
	, DeliveryModeDescription
	, DeliveryTermCode
	, DeliveryTermDescription
	, DeliveryName
	, DeliveryReason
	, SiteId
	, WarehouseId
	, PaymentTermId
	, PaymentTermDescription
	, CurrencyCode
	, SalesResponsiblePersonnelNo
	, SalesResponsibleName
	, SalesTakerPersonnelNo
	, SalesTakerName
	, CustomerPONumber
	, QuotationId
	, ProjectId
	, ReturnItemNum
	, OrderCreatedDate
	, ShippingDateRequested
	, ShippingDateConfirmed
	, ReceiptDateRequested
	, ReceiptDateConfirmed
	, CreatedDateTime
	, ModifiedDateTime

	, [Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_SalesOrder_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_SalesOrder AS Target
		WHERE Target.SalesOrderID = Source.SalesOrderID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);

GO

