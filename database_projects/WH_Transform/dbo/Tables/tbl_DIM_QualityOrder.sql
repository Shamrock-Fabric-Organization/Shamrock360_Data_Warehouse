CREATE TABLE [dbo].[tbl_DIM_QualityOrder] (

	[QualityOrderKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[QualityOrderID] varchar(8000) NULL, 
	[inventrefid] varchar(8000) NULL, 
	[inventreftransid] varchar(8000) NULL, 
	[ProductID] varchar(8000) NULL, 
	[itemsamplingid] varchar(8000) NULL, 
	[oprnum] bigint NULL, 
	[orderstatus] bigint NULL, 
	[orderstatus_$label] varchar(4) NULL, 
	[qty] decimal(38,6) NULL, 
	[referencetype] bigint NULL, 
	[referencetype_$label] varchar(23) NULL, 
	[routeid] varchar(8000) NULL, 
	[testgroupid] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NOT NULL
);