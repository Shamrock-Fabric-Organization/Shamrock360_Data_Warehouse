CREATE TABLE [dbo].[mtbl_EDW_DIM_ProductionBatchOrder] (

	[ProductionBatchOrderKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[ProductionBatchOrder] varchar(8000) NULL, 
	[Product_ID] varchar(8000) NULL, 
	[name] varchar(8000) NULL, 
	[PBOStatus] bigint NULL, 
	[PBOStatusDesc] varchar(16) NULL, 
	[PBOCreatedDate] datetime2(6) NULL, 
	[PBOModifiedDateTime] datetime2(6) NULL, 
	[collectrefprodid] varchar(8000) NULL, 
	[RemainStatus] bigint NULL, 
	[RemainStatusDescription] varchar(9) NULL, 
	[SchedulingStatus] bigint NULL, 
	[SchedulingStatusDescription] varchar(18) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);