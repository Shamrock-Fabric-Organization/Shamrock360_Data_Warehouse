CREATE TABLE [dbo].[tbl_inventory] (

	[PRODUCT CODE] varchar(8000) NULL, 
	[PRODUCT NAME] varchar(8000) NULL, 
	[PRODUCT TYPE] varchar(8000) NULL, 
	[PRODUCT LINE] varchar(8000) NULL, 
	[PRODUCT GRADE] varchar(8000) NULL, 
	[WHSE CODE] varchar(8000) NULL, 
	[WHSE NAME] varchar(8000) NULL, 
	[WHSE ON-HAND] varchar(8000) NULL, 
	[WHSE MIN] varchar(8000) NULL, 
	[SnapShotDate] datetime2(6) NULL, 
	[DataUpdateDate] datetime2(6) NULL, 
	[Source] varchar(10) NULL
);