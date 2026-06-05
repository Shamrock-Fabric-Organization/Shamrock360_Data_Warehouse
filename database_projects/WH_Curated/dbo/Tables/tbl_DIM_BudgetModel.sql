CREATE TABLE [dbo].[tbl_DIM_BudgetModel] (
    [BudgetModelKey]           BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [BudgetModel]              VARCHAR (8000) NULL,
    [BudgetSubmodel]           VARCHAR (8000) NULL,
    [BudgetModelDescription]   VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

