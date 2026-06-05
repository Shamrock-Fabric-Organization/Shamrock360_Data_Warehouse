CREATE TABLE [dbo].[tbl_OpportunityList] (
    [OpportunityID]            VARCHAR (50)   NULL,
    [RecordType]               VARCHAR (50)   NULL,
    [GMAccountno]              VARCHAR (50)   NULL,
    [Manager]                  VARCHAR (50)   NULL,
    [Company]                  VARCHAR (50)   NULL,
    [Contact]                  VARCHAR (50)   NULL,
    [Opportunity]              VARCHAR (150)  NULL,
    [OpportunityStatus]        VARCHAR (50)   NULL,
    [OpportunityStage]         VARCHAR (50)   NULL,
    [OpportunityIndustry]      VARCHAR (50)   NULL,
    [StartDate]                DATETIME2 (6)  NULL,
    [ClosedDate]               DATETIME2 (6)  NULL,
    [CloseByDate]              DATETIME2 (6)  NULL,
    [Probability]              SMALLINT       NULL,
    [Notes]                    VARCHAR (8000) NULL,
    [ProductName]              VARCHAR (50)   NULL,
    [DesiredCharacteristics]   VARCHAR (80)   NULL,
    [EstimatedAnnualVolume]    INT            NULL,
    [SpecificApplication]      VARCHAR (80)   NULL,
    [TargetPrice]              FLOAT (53)     NULL,
    [OpportunityPriority]      VARCHAR (20)   NULL,
    [RecordID]                 VARCHAR (15)   NULL,
    [RecordEffectiveStartDate] DATETIME2 (6)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (6)  NULL,
    [RecordStatus]             INT            NULL,
    [Source]                   VARCHAR (10)   NULL,
    [OPP_SID]                  INT            NULL,
    [cloudCRMLink]             VARCHAR (50)   NULL
);


GO

