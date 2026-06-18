CREATE TABLE [dbo].[mtbl_EDW_DIM_BudgetModel] (

	[BudgetModelKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[BudgetModel] varchar(8000) NULL, 
	[BudgetSubmodel] varchar(8000) NULL, 
	[BudgetModelDescription] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);