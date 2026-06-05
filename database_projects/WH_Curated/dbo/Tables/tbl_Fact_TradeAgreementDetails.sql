CREATE TABLE [dbo].[tbl_Fact_TradeAgreementDetails] (
    [Company]              VARCHAR (8000)   NULL,
    [AgreementId]          VARCHAR (8000)   NULL,
    [Posted]               VARCHAR (3)      NULL,
    [Price]                DECIMAL (38, 6)  NULL,
    [Currency]             VARCHAR (8000)   NULL,
    [PriceUnit]            DECIMAL (38, 12) NULL,
    [Unit]                 VARCHAR (8000)   NULL,
    [ValidFrom]            DATETIME2 (6)    NULL,
    [ValidTo]              DATETIME2 (6)    NULL,
    [QtyFrom]              DECIMAL (38, 6)  NULL,
    [QtyTo]                DECIMAL (38, 6)  NULL,
    [PostedDateKey]        INT              NULL,
    [IsRecent]             INT              NOT NULL,
    [CustomerAccount]      VARCHAR (8000)   NULL,
    [CustomerKey]          BIGINT           NOT NULL,
    [CompanyChain]         VARCHAR (1000)   NULL,
    [ItemNumber]           VARCHAR (8000)   NULL,
    [ProductKey]           BIGINT           NOT NULL,
    [Legal_EntityKey]      BIGINT           NOT NULL,
    [TradeAgreementKey]    BIGINT           NOT NULL,
    [CustAcct_EmployeeKey] BIGINT           NOT NULL
);


GO

