CREATE TABLE [dbo].[tbl_DIM_Warehouse] (
    [WarehouseKey]             BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [Warehouse_ID]             VARCHAR (8000) NULL,
    [Warehouse_Name]           VARCHAR (8000) NULL,
    [Site_ID]                  VARCHAR (8000) NULL,
    [Site_Name]                VARCHAR (8000) NULL,
    [LocationType]             BIGINT         NULL,
    [LocationTypeDesc]         VARCHAR (15)   NULL,
    [LocationLevel]            BIGINT         NULL,
    [Source]                   VARCHAR (25)   NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

