CREATE TABLE [dbo].[mtbl_EDW_DIM_PhantomProduct] (

	[PhantomProductKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[Product_ID] varchar(8000) NULL, 
	[Phantom_Product] varchar(8000) NULL, 
	[Commercial_Name] varchar(8000) NULL, 
	[ActiveFormula_ID] varchar(8000) NULL, 
	[Business_Line] varchar(8000) NULL, 
	[Product_Line] varchar(8000) NULL, 
	[Technology] varchar(8000) NULL, 
	[Material] varchar(8000) NULL, 
	[Description_Internal] varchar(500) NULL, 
	[Description_External] varchar(500) NULL, 
	[Application_Benefit] varchar(500) NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL, 
	[Source] varchar(6) NOT NULL
);