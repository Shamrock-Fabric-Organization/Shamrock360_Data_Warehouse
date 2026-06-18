CREATE TABLE [dbo].[tbl_SampleDashboardData] (
    [ContactID]         VARCHAR (20)  NULL,
    [SampleRecid]       VARCHAR (15)  NULL,
    [CallReportLink]    VARCHAR (20)  NULL,
    [ClosedSampleRECID] VARCHAR (20)  NULL,
    [OppportunityID]    VARCHAR (15)  NULL,
    [Requester]         VARCHAR (8)   NULL,
    [RequestDate]       DATETIME2 (6) NULL,
    [Sample]            VARCHAR (35)  NULL,
    [Company]           VARCHAR (40)  NULL,
    [Opportunity]       VARCHAR (50)  NULL,
    [ProcessedBy]       VARCHAR (8)   NULL,
    [ProcessedOn]       DATETIME2 (6) NULL,
    [SnapShotDate]      VARCHAR (100) NULL,
    [DataUpdateDate]    VARCHAR (100) NULL,
    [Source]            VARCHAR (10)  NULL
);
GO

