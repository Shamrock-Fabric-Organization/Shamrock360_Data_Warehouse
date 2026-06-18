CREATE TABLE [dbo].[mtbl_EDW_DIM_Warehouse] (

	[WarehouseKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[Warehouse_ID] varchar(8000) NULL, 
	[Warehouse_Name] varchar(8000) NULL, 
	[Site_ID] varchar(8000) NULL, 
	[Site_Name] varchar(8000) NULL, 
	[LocationType] bigint NULL, 
	[LocationTypeDesc] varchar(15) NULL, 
	[LocationLevel] bigint NULL, 
	[Source] varchar(25) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(6) NULL, 
	[RecordEffectiveEndDate] datetime2(6) NULL, 
	[RecordStatus] int NULL
);