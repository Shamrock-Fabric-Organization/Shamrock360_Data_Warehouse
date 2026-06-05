CREATE TABLE [dbo].[tbl_DIM_CustomerPackingSlip] (
    [CustomerPackingSlipKey]   BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [CustomerPackingSlipId]    VARCHAR (8000) NULL,
    [SalesId]                  VARCHAR (8000) NULL,
    [ShipDate]                 DATE           NULL,
    [DocumentDate]             DATE           NULL,
    [CustomerAccount]          VARCHAR (8000) NULL,
    [InvoiceAccount]           VARCHAR (8000) NULL,
    [CustomerPO]               VARCHAR (8000) NULL,
    [ShipToName]               VARCHAR (8000) NULL,
    [DeliveryMode]             VARCHAR (8000) NULL,
    [DeliveryTerms]            VARCHAR (8000) NULL,
    [DeliveryReason]           VARCHAR (8000) NULL,
    [ShipFromWarehouse]        VARCHAR (8000) NULL,
    [CarrierId]                VARCHAR (8000) NULL,
    [CreatedDateTime]          DATETIME2 (6)  NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

