CREATE TABLE [dbo].[mtbl_EDW_Fact_GeneralLedgerBudget] (
    [CMPNY]                     VARCHAR (8000)  NULL,
    [GL_Account]                VARCHAR (8000)  NULL,
    [date]                      DATETIME2 (6)   NULL,
    [BudgetDateKey]             INT             NULL,
    [BudgetModel]               VARCHAR (8000)  NULL,
    [BudgetTypeDesc]            VARCHAR (7)     NULL,
    [CurrencyCode]              VARCHAR (8000)  NULL,
    [BudgetTransactionType]     VARCHAR (18)    NULL,
    [accountingcurrencyamount]  DECIMAL (38, 6) NULL,
    [transactioncurrencyamount] DECIMAL (38, 6) NULL,
    [quantity]                  DECIMAL (38, 6) NULL,
    [Legal_EntityKey]           BIGINT          NOT NULL,
    [BudgetModelKey]            BIGINT          NOT NULL,
    [DepartmentKey]             BIGINT          NOT NULL,
    [SiteKey]                   BIGINT          NOT NULL
);


GO

