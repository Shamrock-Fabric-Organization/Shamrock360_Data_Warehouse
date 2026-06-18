CREATE TABLE [dbo].[tbl_SampleDashboardData] (

	[ContactID] varchar(20) NULL, 
	[SampleRecid] varchar(15) NULL, 
	[CallReportLink] varchar(20) NULL, 
	[ClosedSampleRECID] varchar(20) NULL, 
	[OppportunityID] varchar(15) NULL, 
	[Requester] varchar(8) NULL, 
	[RequestDate] datetime2(6) NULL, 
	[Sample] varchar(35) NULL, 
	[Company] varchar(40) NULL, 
	[Opportunity] varchar(50) NULL, 
	[ProcessedBy] varchar(8) NULL, 
	[ProcessedOn] datetime2(6) NULL, 
	[SnapShotDate] varchar(100) NULL, 
	[DataUpdateDate] varchar(100) NULL, 
	[Source] varchar(10) NULL
);