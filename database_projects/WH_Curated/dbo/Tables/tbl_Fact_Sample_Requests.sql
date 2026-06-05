CREATE TABLE [dbo].[tbl_Fact_Sample_Requests] (
    [RequestDate]              DATE            NULL,
    [Company]                  VARCHAR (40)    NULL,
    [City]                     VARCHAR (30)    NULL,
    [State]                    VARCHAR (20)    NULL,
    [Country]                  VARCHAR (20)    NULL,
    [Region]                   VARCHAR (20)    NULL,
    [Customer #]               VARCHAR (20)    NULL,
    [Salesman]                 VARCHAR (20)    NULL,
    [Industry]                 VARCHAR (20)    NULL,
    [LocationApplication]      VARCHAR (20)    NULL,
    [Sample Request]           VARCHAR (35)    NULL,
    [ProductLine]              VARCHAR (20)    NULL,
    [Opportunity]              VARCHAR (50)    NULL,
    [OpportunityType]          VARCHAR (80)    NULL,
    [Stage]                    VARCHAR (40)    NULL,
    [EstimatedAnnualVolume]    INT             NULL,
    [TargetPrice]              DECIMAL (19, 4) NULL,
    [SampleRequestApplication] VARCHAR (40)    NULL,
    [SnapShotDate]             DATETIME2 (6)   NULL,
    [DataUpdateDate]           DATETIME2 (6)   NULL,
    [Source]                   VARCHAR (10)    NULL,
    [SAM_SID]                  INT             NULL
);


GO

