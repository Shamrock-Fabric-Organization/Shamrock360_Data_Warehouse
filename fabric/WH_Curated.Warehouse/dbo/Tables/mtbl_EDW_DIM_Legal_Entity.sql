CREATE TABLE [dbo].[mtbl_EDW_DIM_Legal_Entity] (

	[Legal_EntityKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[Legal_Entity_Name] varchar(8000) NULL, 
	[accountingcurrency] varchar(8000) NULL, 
	[reportingcurrency] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);