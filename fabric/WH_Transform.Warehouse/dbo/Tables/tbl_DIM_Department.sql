CREATE TABLE [dbo].[tbl_DIM_Department] (

	[DepartmentKey] bigint NULL, 
	[Department] varchar(8000) NULL, 
	[Department_Name] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);