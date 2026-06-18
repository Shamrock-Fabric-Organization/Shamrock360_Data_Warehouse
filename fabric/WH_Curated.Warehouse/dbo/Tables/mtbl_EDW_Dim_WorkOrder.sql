CREATE TABLE [dbo].[mtbl_EDW_Dim_WorkOrder] (

	[WorkOrderKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[WorkId] varchar(8000) NULL, 
	[WorkCancelledUTC] datetime2(6) NULL, 
	[WorkStartedUTC] datetime2(6) NULL, 
	[WorkClosedUTC] datetime2(6) NULL, 
	[CreatedDateTime] datetime2(6) NULL, 
	[ModifiedDateTime] datetime2(6) NULL, 
	[CountWorkStatus] varchar(8000) NULL, 
	[WorkCreatedBy] varchar(8000) NULL, 
	[IsPartialCount] varchar(8000) NULL, 
	[WorkTransType] varchar(8000) NULL, 
	[WorkPriority] bigint NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);