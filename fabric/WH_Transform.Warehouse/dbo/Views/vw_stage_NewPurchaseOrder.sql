-- Auto Generated (Do not modify) ED39E76CB2B960F3C47742C7D2AFC3C96D8591B4D2820E1A57A56C10DCCBC381
/****** Object:  View [dbo].[vw_stage_NewPurchaseOrder]    Script Date: 2/3/2026 1:53:07 PM ******/
/****** Object:  View [dbo].[vw_stage_NewPurchaseOrder]    Script Date: 1/26/2026 12:44:15 PM ******/


CREATE         VIEW [dbo].[vw_stage_NewPurchaseOrder]
AS
SELECT [PurchaseOrderKey]
	, [CMPNY]
	, [PurchaseOrderNumber]
	, [PurchaseOrderName]
	, [VendorAccount]
	, [InvoiceVendorAccount]
	, [PaymentTerms]
	, [PaymentTermsDesc]
	, [PaymentTermsNumOfDays]
	, [VendorReference]
	, [currencycode]
	, [isencumbrancerequired]
	, [EncumberanceRequiredYN]
	, [purchstatus]
	, [PurchStatusDesc]
	, [returnreasoncodeid]
	, [ReturnReasonDesc]
	, [ReturnReasonGroupDesc]
	, [createddatetime]
	, [Warehouse]
	, [SiteID]
	, [deliveryname]
	, [itembuyergroupid]
	, [purchpoolid]
	, [PurchPoolName]
	, [RequestorPersonnelNumber]
	, [RequestorName]
	, [POPlacerPersonnelNumber]
	, [POPlacerName]
    , [dlvterm]
    , [dlvmode]
	, [minDeliveryDate]
	, [maxDeliveryDate]
	, [Source]

	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
FROM [vw_stage_DIM_PurchaseOrder_incoming] AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM [tbl_DIM_PurchaseOrder] AS Target
		WHERE Target.[PurchaseOrderNumber] = Source.[PurchaseOrderNumber]
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);