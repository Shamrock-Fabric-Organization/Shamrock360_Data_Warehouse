
CREATE TABLE [dbo].[mtbl_EDW_DIM_InvoiceCharge] (

	[InvoiceChargeKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[MarkupCode] varchar(8000) NULL, 
	[ChargeDescription] varchar(8000) NULL, 
	[TaxItemGroup] varchar(8000) NULL, 
	[MaxAmount] decimal(38,6) NULL, 
	[IsShipping] bigint NULL, 
	[IsRefundable] bigint NULL, 
	[InMarkupTable] int NULL, 
	[Source] varchar(6) NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);
