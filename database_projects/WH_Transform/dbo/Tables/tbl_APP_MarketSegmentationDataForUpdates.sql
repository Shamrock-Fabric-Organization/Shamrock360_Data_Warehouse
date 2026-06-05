CREATE TABLE [dbo].[tbl_APP_MarketSegmentationDataForUpdates] (
    [MarketSegmentationKey] BIGINT         NULL,
    [CMPNY]                 VARCHAR (8000) NULL,
    [CustomerID]            VARCHAR (8000) NULL,
    [ProductID]             VARCHAR (8000) NULL,
    [CPCID]                 VARCHAR (8000) NULL,
    [LegacyCPCID]           VARCHAR (8000) NULL,
    [Industry]              VARCHAR (8000) NULL,
    [IndustryIsOverride]    BIT            NOT NULL,
    [SubIndustry]           VARCHAR (8000) NULL,
    [SubIndustryIsOverride] BIT            NOT NULL
);


GO

