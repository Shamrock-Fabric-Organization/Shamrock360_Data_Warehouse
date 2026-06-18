CREATE TABLE [dbo].[vw_crm_Sample_Activity] (

	[ContactID] varchar(20) NULL, 
	[SampleRecid] varchar(15) NULL, 
	[CallReportLink] varchar(20) NULL, 
	[ClosedSampleRECID] varchar(20) NULL, 
	[OppportunityID] varchar(15) NULL, 
	[Requester] varchar(8) NULL, 
	[RequestDate] datetime2(3) NULL, 
	[Sample] varchar(35) NULL, 
	[Company] varchar(40) NULL, 
	[Opportunity] varchar(50) NULL, 
	[ProcessedBy] varchar(8) NULL, 
	[ProcessedOn] datetime2(3) NULL
);