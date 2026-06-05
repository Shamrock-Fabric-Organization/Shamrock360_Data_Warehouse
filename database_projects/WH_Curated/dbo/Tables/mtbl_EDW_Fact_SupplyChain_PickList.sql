CREATE TABLE [dbo].[mtbl_EDW_Fact_SupplyChain_PickList] (
    [CMPNY]                   VARCHAR (8000)  NULL,
    [ProdId]                  VARCHAR (8000)  NULL,
    [itemid]                  VARCHAR (8000)  NULL,
    [JournalId]               VARCHAR (8000)  NULL,
    [LotID]                   VARCHAR (8000)  NULL,
    [transdate]               DATETIME2 (6)   NULL,
    [resource]                VARCHAR (8000)  NULL,
    [bomproposal]             DECIMAL (38, 6) NULL,
    [bomconsump]              DECIMAL (38, 6) NULL,
    [bomunitid]               VARCHAR (8000)  NULL,
    [endconsump]              BIGINT          NULL,
    [endconsump_$label]       VARCHAR (3)     NULL,
    [matchid]                 VARCHAR (8000)  NULL,
    [voucher]                 VARCHAR (8000)  NULL,
    [bomscrap]                DECIMAL (38, 6) NULL,
    [errorcause]              BIGINT          NULL,
    [errorcause_$label]       VARCHAR (14)    NULL,
    [inventproposal]          DECIMAL (38, 6) NULL,
    [inventconsump]           DECIMAL (38, 6) NULL,
    [InventoryNumber]         VARCHAR (8000)  NULL,
    [oprnum]                  BIGINT          NULL,
    [position]                VARCHAR (8000)  NULL,
    [inventdimid]             VARCHAR (8000)  NULL,
    [journaltype_$Label]      VARCHAR (24)    NULL,
    [Legal_EntityKey]         BIGINT          NOT NULL,
    [ProductKey]              BIGINT          NOT NULL,
    [ProductionBatchOrderKey] BIGINT          NOT NULL,
    [SiteKey]                 BIGINT          NOT NULL,
    [WarehouseKey]            BIGINT          NOT NULL,
    [BatchKey]                BIGINT          NOT NULL,
    [RouteKey]                BIGINT          NOT NULL
);


GO

