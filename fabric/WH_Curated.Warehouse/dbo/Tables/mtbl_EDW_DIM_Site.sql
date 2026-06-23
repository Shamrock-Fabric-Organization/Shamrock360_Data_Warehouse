CREATE TABLE [dbo].[mtbl_EDW_DIM_Site] (

	[SiteKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[Site_ID] varchar(8000) NULL, 
	[Site_Name] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);