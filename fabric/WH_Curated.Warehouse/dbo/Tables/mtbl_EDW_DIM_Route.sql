CREATE TABLE [dbo].[mtbl_EDW_DIM_Route] (

	[RouteKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[RouteID] varchar(8000) NULL, 
	[RouteName] varchar(8000) NULL, 
	[ApproverPersonnelNumber] varchar(8000) NULL, 
	[ApproverName] varchar(8000) NULL, 
	[Approved] varchar(3) NULL, 
	[CheckRoute] varchar(3) NULL, 
	[RouteType] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);