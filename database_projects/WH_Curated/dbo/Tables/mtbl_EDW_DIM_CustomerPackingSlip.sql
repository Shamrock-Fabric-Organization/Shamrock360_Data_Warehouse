CREATE TABLE [dbo].[mtbl_EDW_DIM_CustomerPackingSlip] (

	[CustomerPackingSlipKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[CustomerPackingSlipId] varchar(8000) NULL, 
	[SalesId] varchar(8000) NULL, 
	[ShipDate] date NULL, 
	[DocumentDate] date NULL, 
	[CustomerAccount] varchar(8000) NULL, 
	[InvoiceAccount] varchar(8000) NULL, 
	[CustomerPO] varchar(8000) NULL, 
	[ShipToName] varchar(8000) NULL, 
	[DeliveryMode] varchar(8000) NULL, 
	[DeliveryTerms] varchar(8000) NULL, 
	[DeliveryReason] varchar(8000) NULL, 
	[ShipFromWarehouse] varchar(8000) NULL, 
	[CarrierId] varchar(8000) NULL, 
	[CreatedDateTime] datetime2(6) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);