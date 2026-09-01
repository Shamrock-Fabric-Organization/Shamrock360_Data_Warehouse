

CREATE TABLE [dbo].[tbl_Fact_TradeAgreementDetails](
	[CMPNY] [varchar](8000) NULL,
	[AgreementId] [varchar](8000) NULL,
	[Posted] [varchar](3) NULL,
	[Price] [decimal](38, 6) NULL,
	[Currency] [varchar](8000) NULL,
	[PriceUnit] [decimal](38, 12) NULL,
	[Unit] [varchar](8000) NULL,
	[ValidFrom] [datetime2](6) NULL,
	[ValidTo] [datetime2](6) NULL,
	[QtyFrom] [decimal](38, 6) NULL,
	[QtyTo] [decimal](38, 6) NULL,
	[PostedDateKey] [int] NULL,
	[IsRecent] [int] NOT NULL,
	[InvoiceCustomerAccount] [varchar](8000) NULL,
	[InvoiceCustomerKey] [bigint] NOT NULL,
	[CustomerAccount] [varchar](8000) NULL,
	[CustomerKey] [bigint] NULL,
	[CompanyChain] [varchar](1000) NULL,
	[ItemNumber] [varchar](8000) NULL,
	[ProductKey] [bigint] NOT NULL,
	[Legal_EntityKey] [bigint] NOT NULL,
	[TradeAgreementKey] [bigint] NOT NULL,
	[CustAcct_EmployeeKey] [bigint] NOT NULL,
	[Txn_Source_Currency] [varchar](8000) NULL,
	[Price_USD] [numeric](38, 6) NULL,
	[Price_EUR] [numeric](38, 6) NULL,
	[Price_CNY] [numeric](38, 6) NULL,
	[Txn_USD_Rate_Missing] [int] NOT NULL,
	[Txn_EUR_Rate_Missing] [int] NOT NULL,
	[Txn_CNY_Rate_Missing] [int] NOT NULL
)
GO



