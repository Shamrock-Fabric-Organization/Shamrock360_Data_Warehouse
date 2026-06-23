CREATE TABLE [dbo].[tbl_DIM_TestGroup] (

	[TestGroupKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[TestGroupId] varchar(8000) NULL, 
	[TestGroupDescription] varchar(8000) NULL, 
	[AcceptableQualityLevel] decimal(38,6) NULL, 
	[IsDestructive] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);