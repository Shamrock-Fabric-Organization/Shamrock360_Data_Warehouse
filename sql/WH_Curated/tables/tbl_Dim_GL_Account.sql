CREATE TABLE [dbo].[tbl_Dim_GL_Account] (

	[GL_AccountKey] bigint NULL, 
	[GL_Account_Number] varchar(8000) NULL, 
	[GL_Account_Name] varchar(8000) NULL, 
	[accountcategoryref] bigint NULL, 
	[Account_Category] varchar(8000) NULL, 
	[Account_Category_Name] varchar(8000) NULL, 
	[Account_Type] bigint NULL, 
	[Account_Type_Description] varchar(13) NULL, 
	[Category_Account_Type] bigint NULL, 
	[Category_Account_Type_Description] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);