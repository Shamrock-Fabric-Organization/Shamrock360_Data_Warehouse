CREATE TABLE [dbo].[mtbl_EDW_Fact_ProjectPostedTransactions] (

	[CMPNY] varchar(8000) NULL, 
	[ProjId] varchar(8000) NULL, 
	[TransactionDate] datetime2(6) NULL, 
	[TransactionDateKey] int NULL, 
	[CategoryId] varchar(8000) NULL, 
	[ResourceName] varchar(8000) NULL, 
	[ItemId] varchar(8000) NULL, 
	[TotalSalesAmount] decimal(38,6) NULL, 
	[AmountInTransaction] decimal(38,6) NULL, 
	[TotalCostAmount] numeric(38,6) NULL, 
	[InvoiceStatus] varchar(27) NOT NULL, 
	[TransType] varchar(17) NULL, 
	[TransCurrencyCode] varchar(8000) NULL, 
	[LegalEntityCurrencyCode] varchar(8000) NULL, 
	[TransId] varchar(8000) NULL, 
	[Qty] decimal(38,6) NULL, 
	[Legal_EntityKey] bigint NOT NULL, 
	[ProjectKey] bigint NOT NULL, 
	[ProductKey] bigint NOT NULL, 
	[WorkCenterKey] bigint NOT NULL, 
	[VendorKey] bigint NOT NULL
);