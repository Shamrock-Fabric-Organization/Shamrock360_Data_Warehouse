CREATE TABLE [dbo].[tbl_DIM_ProductionBatchOrder] (
    [ProductionBatchOrderKey]     BIGINT         NULL,
    [CMPNY]                       VARCHAR (8000) NULL,
    [ProductionBatchOrder]        VARCHAR (8000) NULL,
    [Product_ID]                  VARCHAR (8000) NULL,
    [name]                        VARCHAR (8000) NULL,
    [PBOStatus]                   BIGINT         NULL,
    [PBOStatusDesc]               VARCHAR (16)   NULL,
    [PBOCreatedDate]              DATETIME2 (6)  NULL,
    [PBOModifiedDateTime]         DATETIME2 (6)  NULL,
    [collectrefprodid]            VARCHAR (8000) NULL,
    [RemainStatus]                BIGINT         NULL,
    [RemainStatusDescription]     VARCHAR (9)    NULL,
    [SchedulingStatus]            BIGINT         NULL,
    [SchedulingStatusDescription] VARCHAR (18)   NULL,
    [Source]                      VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate]    DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]      DATETIME2 (3)  NULL,
    [RecordStatus]                INT            NULL
);


GO

