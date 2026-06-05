CREATE TABLE [dbo].[vw_crm_Sample] (
    [RequestDate]              DATE            NULL,
    [Company]                  VARCHAR (8000)  NULL,
    [City]                     VARCHAR (8000)  NULL,
    [State]                    VARCHAR (8000)  NULL,
    [Country]                  VARCHAR (8000)  NULL,
    [Region]                   VARCHAR (1)     NULL,
    [Customer #]               VARCHAR (8000)  NULL,
    [Salesman]                 VARCHAR (8000)  NULL,
    [Industry]                 VARCHAR (8000)  NULL,
    [LocationApplication]      VARCHAR (8000)  NULL,
    [Sample Request]           VARCHAR (35)    NULL,
    [ProductLine]              VARCHAR (20)    NULL,
    [Opportunity]              VARCHAR (50)    NULL,
    [OpportunityType]          VARCHAR (80)    NULL,
    [Stage]                    VARCHAR (30)    NULL,
    [EstimatedAnnualVolume]    INT             NULL,
    [TargetPrice]              DECIMAL (19, 4) NULL,
    [SampleRequestApplication] VARCHAR (40)    NULL
);


GO

