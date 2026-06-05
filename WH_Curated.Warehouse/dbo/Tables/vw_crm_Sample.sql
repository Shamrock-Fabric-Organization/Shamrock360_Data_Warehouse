CREATE TABLE [dbo].[vw_crm_Sample] (

	[RequestDate] date NULL, 
	[Company] varchar(8000) NULL, 
	[City] varchar(8000) NULL, 
	[State] varchar(8000) NULL, 
	[Country] varchar(8000) NULL, 
	[Region] varchar(1) NULL, 
	[Customer #] varchar(8000) NULL, 
	[Salesman] varchar(8000) NULL, 
	[Industry] varchar(8000) NULL, 
	[LocationApplication] varchar(8000) NULL, 
	[Sample Request] varchar(35) NULL, 
	[ProductLine] varchar(20) NULL, 
	[Opportunity] varchar(50) NULL, 
	[OpportunityType] varchar(80) NULL, 
	[Stage] varchar(30) NULL, 
	[EstimatedAnnualVolume] int NULL, 
	[TargetPrice] decimal(19,4) NULL, 
	[SampleRequestApplication] varchar(40) NULL
);