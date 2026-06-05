CREATE TABLE [dbo].[mtbl_EDW_Dim_QualityOrder] (
    [QualityOrderKey]          BIGINT          NULL,
    [CMPNY]                    VARCHAR (8000)  NULL,
    [QualityOrderID]           VARCHAR (8000)  NULL,
    [inventrefid]              VARCHAR (8000)  NULL,
    [inventreftransid]         VARCHAR (8000)  NULL,
    [ProductID]                VARCHAR (8000)  NULL,
    [itemsamplingid]           VARCHAR (8000)  NULL,
    [oprnum]                   BIGINT          NULL,
    [orderstatus]              BIGINT          NULL,
    [orderstatus_$label]       VARCHAR (4)     NULL,
    [qty]                      DECIMAL (38, 6) NULL,
    [referencetype]            BIGINT          NULL,
    [referencetype_$label]     VARCHAR (23)    NULL,
    [routeid]                  VARCHAR (8000)  NULL,
    [testgroupid]              VARCHAR (8000)  NULL,
    [Source]                   VARCHAR (6)     NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)   NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)   NULL,
    [RecordStatus]             INT             NOT NULL
);


GO

