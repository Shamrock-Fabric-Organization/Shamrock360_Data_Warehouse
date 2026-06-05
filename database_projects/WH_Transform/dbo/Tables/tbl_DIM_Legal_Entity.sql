CREATE TABLE [dbo].[tbl_DIM_Legal_Entity] (
    [Legal_EntityKey]          BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [Legal_Entity_Name]        VARCHAR (8000) NULL,
    [accountingcurrency]       VARCHAR (8000) NULL,
    [reportingcurrency]        VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

