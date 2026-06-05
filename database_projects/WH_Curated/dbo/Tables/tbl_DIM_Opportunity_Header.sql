CREATE TABLE [dbo].[tbl_DIM_Opportunity_Header] (
    [Salesman]               VARCHAR (8000) NULL,
    [Customer]               VARCHAR (8000) NULL,
    [StartDate]              DATETIME2 (6)  NULL,
    [CloseByDate]            DATETIME2 (6)  NULL,
    [ActualCloseDate]        DATETIME2 (6)  NULL,
    [OpportunityName]        VARCHAR (8000) NULL,
    [Status]                 VARCHAR (8000) NULL,
    [CYCLE]                  VARCHAR (8000) NULL,
    [Stage]                  VARCHAR (8000) NULL,
    [Source]                 VARCHAR (8000) NULL,
    [Probability]            FLOAT (53)     NULL,
    [EstAnnualVolume]        FLOAT (53)     NULL,
    [EstAnnualRevenue]       FLOAT (53)     NULL,
    [Product]                VARCHAR (8000) NULL,
    [DesiredCharacteristics] VARCHAR (8000) NULL,
    [UEAV]                   FLOAT (53)     NULL,
    [SpecificApplication]    VARCHAR (8000) NULL,
    [TargetPrice]            FLOAT (53)     NULL,
    [UTSPROJID]              VARCHAR (8000) NULL,
    [OPID]                   VARCHAR (8000) NULL,
    [ACCOUNTNO]              VARCHAR (8000) NULL,
    [RECID]                  VARCHAR (8000) NULL
);


GO

