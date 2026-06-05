CREATE TABLE [dbo].[tbl_DIM_TradeAgreement] (
    [TradeAgreementKey]        BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [AgreementID]              VARCHAR (8000) NULL,
    [JournalName]              VARCHAR (8000) NULL,
    [AgreementName]            VARCHAR (8000) NULL,
    [PostedDate]               DATETIME2 (6)  NULL,
    [Posted]                   VARCHAR (8000) NULL,
    [DefaultRelation]          VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

