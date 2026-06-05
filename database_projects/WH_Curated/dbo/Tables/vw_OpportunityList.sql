CREATE TABLE [dbo].[vw_OpportunityList] (
    [OpportunityID]          VARCHAR (15)   NULL,
    [RecordType]             VARCHAR (3)    NULL,
    [GMAccountno]            VARCHAR (20)   NULL,
    [Manager]                VARCHAR (8)    NULL,
    [Company]                VARCHAR (40)   NULL,
    [Contact]                VARCHAR (40)   NULL,
    [Opportunity]            VARCHAR (50)   NULL,
    [OpportunityStatus]      VARCHAR (50)   NULL,
    [OpportunityStage]       VARCHAR (30)   NULL,
    [OpportunityIndustry]    VARCHAR (30)   NULL,
    [StartDate]              DATETIME2 (3)  NULL,
    [ClosedDate]             DATETIME2 (3)  NULL,
    [CloseByDate]            DATETIME2 (3)  NULL,
    [Probability]            SMALLINT       NULL,
    [Notes]                  VARCHAR (8000) NULL,
    [ProductName]            VARCHAR (50)   NULL,
    [DesiredCharacteristics] VARCHAR (80)   NULL,
    [EstimatedAnnualVolume]  INT            NULL,
    [SpecificApplication]    VARCHAR (80)   NULL,
    [TargetPrice]            FLOAT (53)     NULL,
    [OpportunityPriority]    VARCHAR (20)   NULL,
    [RecordID]               VARCHAR (15)   NULL
);


GO

