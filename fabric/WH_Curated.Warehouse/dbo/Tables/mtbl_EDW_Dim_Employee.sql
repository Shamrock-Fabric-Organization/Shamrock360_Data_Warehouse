CREATE TABLE [dbo].[mtbl_EDW_Dim_Employee] (

	[EmployeeKey] bigint NULL, 
	[Personnel_Number] varchar(8000) NULL, 
	[Employee_Name] varchar(8000) NULL, 
	[Employment_Type] bigint NULL, 
	[Employment_Type_Desc] varchar(10) NULL, 
	[IsPerson] varchar(3) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(6) NULL, 
	[RecordEffectiveEndDate] datetime2(6) NULL, 
	[RecordStatus] int NULL
);