CREATE TABLE [dbo].[mtbl_EDW_Fact_CustomerPackingSlipTransactions] (
    [CMPNY]                          VARCHAR (8000)   NULL,
    [SALESID]                        VARCHAR (8000)   NULL,
    [ITEMID]                         VARCHAR (8000)   NULL,
    [LINENUM]                        DECIMAL (38, 16) NULL,
    [PACKINGSLIPID]                  VARCHAR (8000)   NULL,
    [CustomerId]                     VARCHAR (8000)   NULL,
    [SalesCategory]                  VARCHAR (8000)   NULL,
    [SiteID]                         VARCHAR (8000)   NULL,
    [Warehouse]                      VARCHAR (8000)   NULL,
    [inventbatchid]                  VARCHAR (8000)   NULL,
    [ActualShipDate]                 DATETIME2 (6)    NULL,
    [EstimatedDate]                  DATETIME2 (6)    NULL,
    [Delivered]                      DECIMAL (38, 6)  NULL,
    [DayVariance]                    INT              NULL,
    [SALESLINESHIPPINGDATECONFIRMED] DATETIME2 (6)    NULL,
    [SALESLINESHIPPINGDATEREQUESTED] DATETIME2 (6)    NULL,
    [SalesOrderCreatedDateTime]      DATETIME2 (6)    NULL,
    [HistoricCustomerKey]            BIGINT           NOT NULL,
    [CustomerKey]                    BIGINT           NOT NULL,
    [HistoricProductKey]             BIGINT           NOT NULL,
    [ProductKey]                     BIGINT           NOT NULL,
    [Legal_EntityKey]                BIGINT           NOT NULL,
    [SiteKey]                        BIGINT           NOT NULL,
    [WarehouseKey]                   BIGINT           NOT NULL,
    [SalesOrderKey]                  BIGINT           NOT NULL,
    [CustomerPackingSlipKey]         BIGINT           NOT NULL
);


GO

