CREATE TABLE [dbo].[tbl_DIM_Project] (

	[ProjectKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[ProjId] varchar(8000) NULL, 
	[ProjectName] varchar(8000) NULL, 
	[ProjectContractID] varchar(8000) NULL, 
	[ProjectType] varchar(8000) NULL, 
	[ProjectStage] varchar(8000) NULL, 
	[BudgetControlInterval] varchar(8000) NULL, 
	[ProjectedStartDate] datetime2(6) NULL, 
	[ProjectedEndDate] datetime2(6) NULL, 
	[StartDate] datetime2(6) NULL, 
	[EndDate] datetime2(6) NULL, 
	[Status] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);