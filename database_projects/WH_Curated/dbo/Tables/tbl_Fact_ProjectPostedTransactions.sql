CREATE TABLE [dbo].[tbl_Fact_ProjectPostedTransactions] (
    [CMPNY]                   VARCHAR (8000)  NULL,
    [ProjId]                  VARCHAR (8000)  NULL,
    [TransactionDate]         DATETIME2 (6)   NULL,
    [TransactionDateKey]      INT             NULL,
    [CategoryId]              VARCHAR (8000)  NULL,
    [ResourceName]            VARCHAR (8000)  NULL,
    [ItemId]                  VARCHAR (8000)  NULL,
    [TotalSalesAmount]        DECIMAL (38, 6) NULL,
    [AmountInTransaction]     DECIMAL (38, 6) NULL,
    [TotalCostAmount]         NUMERIC (38, 6) NULL,
    [InvoiceStatus]           VARCHAR (27)    NOT NULL,
    [TransType]               VARCHAR (17)    NULL,
    [TransCurrencyCode]       VARCHAR (8000)  NULL,
    [LegalEntityCurrencyCode] VARCHAR (8000)  NULL,
    [TransId]                 VARCHAR (8000)  NULL,
    [Qty]                     DECIMAL (38, 6) NULL,
    [Legal_EntityKey]         BIGINT          NOT NULL,
    [ProjectKey]              BIGINT          NOT NULL,
    [ProductKey]              BIGINT          NOT NULL,
    [WorkCenterKey]           BIGINT          NOT NULL,
    [VendorKey]               BIGINT          NOT NULL
);


GO

