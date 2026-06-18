CREATE TABLE [dbo].[mtbl_EDW_DIM_MarketSegmentation] (

	[MarketSegmentationKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[CustomerID] varchar(8000) NULL, 
	[ProductID] varchar(8000) NULL, 
	[CPCID] varchar(8000) NULL, 
	[LegacyCPCID] varchar(8000) NULL, 
	[Industry] varchar(8000) NULL, 
	[SubIndustry] varchar(8000) NULL, 
	[AccountTranslatedToD365] varchar(3) NULL, 
	[ProductTranslatedToD365] varchar(3) NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL, 
	[Source] varchar(25) NOT NULL
);