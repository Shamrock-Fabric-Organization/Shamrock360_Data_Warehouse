


CREATE TABLE [dbo].[mtbl_EDW_Fact_SalesAndForecastData](
	[CMPNY] [varchar](8000) NULL,
	[ModelID] [varchar](8000) NULL,
	[Date] [date] NULL,
	[DateKey] [int] NULL,
	[Customer_Account] [varchar](8000) NULL,
	[Item_Number] [varchar](8000) NULL,
	[Sales_Quantity] [float] NULL,
	[Unit] [varchar](8000) NULL,
	[Sales_Quantity_LBs] [decimal](38, 6) NULL,
	[Sales_Quantity_KGs] [decimal](38, 6) NULL,
	[Sales_Currency] [varchar](8000) NULL,
	[Amount] [decimal](38, 2) NULL,
	[Amount_USD] [numeric](38, 6) NULL,
	[Amount_EUR] [numeric](38, 2) NULL,
	[Amount_CNY] [numeric](38, 6) NULL,
	[Sales_Price] [decimal](38, 6) NULL,
	[SalesPrice_USD] [numeric](38, 6) NULL,
	[SalesPrice_EUR] [numeric](38, 6) NULL,
	[SalesPrice_CNY] [numeric](38, 6) NULL,
	[Source] [varchar](50) NULL,
	[Legal_EntityKey] [bigint] NOT NULL,
	[HistoricCustomerKey] [bigint] NOT NULL,
	[CustomerKey] [bigint] NOT NULL,
	[HistoricInvoiceCustomerKey] [bigint] NOT NULL,
	[InvoiceCustomerKey] [bigint] NOT NULL,
	[HistoricProductKey] [bigint] NULL,
	[ProductKey] [bigint] NULL,
	[SiteKey] [bigint] NOT NULL,
	[WarehouseKey] [bigint] NOT NULL,
	[Txn_USD_Rate_Missing] [int] NOT NULL,
	[Txn_EUR_Rate_Missing] [int] NOT NULL,
	[Txn_CNY_Rate_Missing] [int] NOT NULL
) 
GO



