CREATE TABLE [dbo].[tbl_DIM_SerialNumber] (
    [SerialNumberKey]          BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [SerialNumber]             VARCHAR (8000) NULL,
    [ProdDate]                 DATETIME2 (6)  NULL,
    [Description]              VARCHAR (8000) NULL,
    [RFIDTagID]                VARCHAR (8000) NULL,
    [SerialNumberNoteName]     VARCHAR (8000) NULL,
    [SerialNumberNote]         VARCHAR (8000) NULL,
    [SeralNumberNoteCreatedBy] VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

