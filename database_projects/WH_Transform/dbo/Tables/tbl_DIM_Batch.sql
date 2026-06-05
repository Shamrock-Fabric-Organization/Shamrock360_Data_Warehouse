CREATE TABLE [dbo].[tbl_DIM_Batch] (
    [BatchKey]                 BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [BatchID]                  VARCHAR (8000) NULL,
    [ProductID]                VARCHAR (8000) NULL,
    [CountryOfOrigin]          VARCHAR (8000) NULL,
    [DispositionCode]          VARCHAR (8000) NULL,
    [ProductionDate]           DATETIME2 (6)  NULL,
    [FGTestedDate]             DATETIME2 (6)  NULL,
    [ExpirationDate]           DATETIME2 (6)  NULL,
    [BestBeforeDate]           DATETIME2 (6)  NULL,
    [ShelfAdviceDate]          DATETIME2 (6)  NULL,
    [VendorBatchDate]          DATETIME2 (6)  NULL,
    [VendorExpirationDate]     DATETIME2 (6)  NULL,
    [VendorBatchID]            VARCHAR (8000) NULL,
    [BatchNoteName]            VARCHAR (8000) NULL,
    [BatchNote]                VARCHAR (8000) NULL,
    [BatchNoteCreatedBy]       VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

