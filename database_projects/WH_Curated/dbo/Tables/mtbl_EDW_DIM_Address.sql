CREATE TABLE [dbo].[mtbl_EDW_DIM_Address] (
    [AddressKey]               BIGINT         NULL,
    [AddressRecId]             BIGINT         NULL,
    [Location]                 BIGINT         NULL,
    [Street]                   VARCHAR (8000) NULL,
    [City]                     VARCHAR (8000) NULL,
    [State]                    VARCHAR (8000) NULL,
    [ZipCode]                  VARCHAR (8000) NULL,
    [Country]                  VARCHAR (8000) NULL,
    [ValidFrom]                DATETIME2 (6)  NULL,
    [ValidTo]                  DATETIME2 (6)  NULL,
    [LocationName]             VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

