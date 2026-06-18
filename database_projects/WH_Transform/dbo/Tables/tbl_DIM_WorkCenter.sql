CREATE TABLE [dbo].[tbl_DIM_WorkCenter] (

	[WorkCenterKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[WorkCenterID] varchar(8000) NULL, 
	[WorkCenterName] varchar(8000) NULL, 
	[WorkCenterIDandName] varchar(8000) NULL, 
	[wrkctrtype] bigint NULL, 
	[wrkctrtype_$label] varchar(9) NULL, 
	[effectivitypct] decimal(38,6) NULL, 
	[errorpct] decimal(38,6) NULL, 
	[operationschedpct] decimal(38,6) NULL, 
	[processcategoryid] varchar(8000) NULL, 
	[routegroupid] varchar(8000) NULL, 
	[ResourceGroup] varchar(8000) NULL, 
	[ResourceGroupName] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);