CREATE TABLE [dbo].[tbl_Fact_SupplyChain_RAF] (
    [CMPNY]                   VARCHAR (8000)  NULL,
    [ProdId]                  VARCHAR (8000)  NULL,
    [ItemId]                  VARCHAR (8000)  NULL,
    [JournalId]               VARCHAR (8000)  NULL,
    [journalnameid]           VARCHAR (8000)  NULL,
    [description]             VARCHAR (8000)  NULL,
    [posteddatetime]          DATETIME2 (6)   NULL,
    [PostedDateKey]           INT             NULL,
    [QTYGood]                 DECIMAL (38, 6) NULL,
    [qtyerror]                DECIMAL (38, 6) NULL,
    [transdate]               DATETIME2 (6)   NULL,
    [TransDateKey]            INT             NULL,
    [voucher]                 VARCHAR (8000)  NULL,
    [prodfinished]            BIGINT          NULL,
    [prodfinished_$label]     VARCHAR (3)     NULL,
    [journaltype_$Label]      VARCHAR (24)    NULL,
    [wrkctrid]                VARCHAR (8000)  NULL,
    [inventsiteid]            VARCHAR (8000)  NULL,
    [inventlocationid]        VARCHAR (8000)  NULL,
    [inventbatchid]           VARCHAR (8000)  NULL,
    [inventserialid]          VARCHAR (8000)  NULL,
    [Legal_EntityKey]         BIGINT          NOT NULL,
    [ProductKey]              BIGINT          NOT NULL,
    [ProductionBatchOrderKey] BIGINT          NOT NULL,
    [SiteKey]                 BIGINT          NOT NULL,
    [WarehouseKey]            BIGINT          NOT NULL,
    [BatchKey]                BIGINT          NOT NULL,
    [RouteKey]                BIGINT          NOT NULL,
    [WorkCenterKey]           BIGINT          NOT NULL,
    [SerialNumberKey]         BIGINT          NOT NULL,
    [QRankTestResult]         VARCHAR (8000)  NULL,
    [QuaityOrderStatus]       VARCHAR (4)     NULL
);


GO

