CREATE TABLE [dbo].[tbl_Reconciliation_Adjustments] (

	[CMPNY] varchar(10) NULL, 
	[Reconciliation_Year] varchar(50) NULL, 
	[Sales_Discounts] decimal(18,2) NULL, 
	[Sales_Rebates] decimal(18,2) NULL, 
	[Tariff_Surcharge_Recovery] decimal(18,2) NULL, 
	[Pallet_Break_Surcharge] decimal(18,2) NULL, 
	[Freight_Billed_Received_From_Customers] decimal(18,2) NULL, 
	[Additional_1] decimal(18,2) NULL, 
	[Additional_1_Desc] varchar(50) NULL, 
	[Additional_2] decimal(18,2) NULL, 
	[Additional_2_Desc] varchar(50) NULL, 
	[Total_Adjustments] decimal(18,2) NULL
);