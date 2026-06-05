CREATE TABLE [dbo].[mtbl_EDW_DIM_Site] (
    [SiteKey]                  BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [Site_ID]                  VARCHAR (8000) NULL,
    [Site_Name]                VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

