
CREATE TABLE [dbo].[tbl_Fact_Customer_Invoice_Charges] (

	[CMPNY] varchar(8000) NULL, 
	[Invoice_ID] varchar(8000) NULL, 
	[InvoiceDate] datetime2(6) NULL, 
	[InvoiceDateKey] int NULL, 
	[Sales_ID] varchar(8000) NULL, 
	[MarkupCode] varchar(8000) NULL, 
	[LineNum] decimal(38,16) NULL, 
	[TransRecId] bigint NULL, 
	[CalculatedAmount] decimal(38,6) NULL, 
	[CurrencyCode] varchar(8000) NULL, 
	[CalculatedAmount_USD] decimal(38,6) NULL, 
	[CalculatedAmount_EUR] decimal(38,6) NULL, 
	[CalculatedAmount_CNY] decimal(38,6) NULL, 
	[Source] varchar(6) NOT NULL, 
	[InvoiceKey] bigint NOT NULL, 
	[InvoiceChargeKey] bigint NOT NULL, 
	[CustomerKey] bigint NOT NULL, 
	[InvoiceCustomerKey] bigint NOT NULL, 
	[Legal_EntityKey] bigint NOT NULL, 
	[SalesOrderKey] bigint NOT NULL, 
	[DeliveryAddressKey] bigint NOT NULL, 
	[CustAcct_EmployeeKey] bigint NOT NULL, 
	[Txn_USD_Rate_Missing] int NULL, 
	[Txn_EUR_Rate_Missing] int NULL, 
	[Txn_CNY_Rate_Missing] int NULL 
);
