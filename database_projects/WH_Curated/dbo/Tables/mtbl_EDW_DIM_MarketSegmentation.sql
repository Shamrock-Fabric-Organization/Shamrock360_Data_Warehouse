CREATE TABLE [dbo].[mtbl_EDW_DIM_MarketSegmentation] (
    [MarketSegmentationKey]    BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [CustomerID]               VARCHAR (8000) NULL,
    [ProductID]                VARCHAR (8000) NULL,
    [CPCID]                    VARCHAR (8000) NULL,
    [LegacyCPCID]              VARCHAR (8000) NULL,
    [Industry]                 VARCHAR (8000) NULL,
    [SubIndustry]              VARCHAR (8000) NULL,
    [AccountTranslatedToD365]  VARCHAR (3)    NULL,
    [ProductTranslatedToD365]  VARCHAR (3)    NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL,
    [Source]                   VARCHAR (25)   NOT NULL
);


GO

