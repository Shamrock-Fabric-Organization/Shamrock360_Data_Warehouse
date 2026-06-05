CREATE TABLE [dbo].[tbl_legacy_budget_data] (
    [CMPNY]                       VARCHAR (8000)  NULL,
    [SalesLine_Status]            VARCHAR (12)    NULL,
    [DATE]                        DATE            NULL,
    [DATEKey]                     INT             NULL,
    [CustomerID]                  VARCHAR (8000)  NULL,
    [ProductID]                   VARCHAR (8000)  NULL,
    [CPCID]                       VARCHAR (8000)  NULL,
    [CPCID_Legacy]                VARCHAR (8000)  NULL,
    [Quantity_LBs]                DECIMAL (38, 6) NULL,
    [Amount]                      DECIMAL (38, 6) NULL,
    [LegalEntityTranslatedToD365] VARCHAR (3)     NOT NULL,
    [AccountTranslatedToD365]     VARCHAR (3)     NOT NULL,
    [ProductTranslatedToD365]     VARCHAR (3)     NOT NULL,
    [Source]                      VARCHAR (50)    NULL,
    [CustomerKey]                 BIGINT          NOT NULL,
    [ProductKey]                  BIGINT          NOT NULL,
    [Legal_EntityKey]             BIGINT          NOT NULL,
    [EmployeeKey]                 BIGINT          NULL,
    [MarketSegmentationKey]       BIGINT          NOT NULL
);


GO

