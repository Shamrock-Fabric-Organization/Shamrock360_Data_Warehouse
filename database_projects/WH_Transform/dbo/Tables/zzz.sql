CREATE TABLE [dbo].[zzz] (

	[MarketSegmentationKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[CustomerID] varchar(8000) NULL, 
	[ProductID] varchar(8000) NULL, 
	[CPCID] varchar(8000) NULL, 
	[LegacyCPCID] varchar(8000) NULL, 
	[Industry] varchar(8000) NULL, 
	[IndustryIsOverride] bit NOT NULL, 
	[SubIndustry] varchar(8000) NULL, 
	[SubIndustryIsOverride] bit NOT NULL
);