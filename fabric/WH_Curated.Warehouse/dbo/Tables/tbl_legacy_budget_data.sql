CREATE TABLE [dbo].[tbl_legacy_budget_data] (

	[CMPNY] varchar(8000) NULL, 
	[SalesLine_Status] varchar(12) NULL, 
	[DATE] date NULL, 
	[DATEKey] int NULL, 
	[CustomerID] varchar(8000) NULL, 
	[ProductID] varchar(8000) NULL, 
	[CPCID] varchar(8000) NULL, 
	[CPCID_Legacy] varchar(8000) NULL, 
	[Quantity_LBs] decimal(38,6) NULL, 
	[Amount] decimal(38,6) NULL, 
	[LegalEntityTranslatedToD365] varchar(3) NOT NULL, 
	[AccountTranslatedToD365] varchar(3) NOT NULL, 
	[ProductTranslatedToD365] varchar(3) NOT NULL, 
	[Source] varchar(50) NULL, 
	[CustomerKey] bigint NOT NULL, 
	[ProductKey] bigint NOT NULL, 
	[Legal_EntityKey] bigint NOT NULL, 
	[EmployeeKey] bigint NULL, 
	[MarketSegmentationKey] bigint NOT NULL
);