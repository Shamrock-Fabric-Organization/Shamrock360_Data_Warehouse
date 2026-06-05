CREATE TABLE [dbo].[tbl_Fact_CustTrans] (
    [Company]                      VARCHAR (8000)  NULL,
    [voucher]                      VARCHAR (8000)  NULL,
    [Customer_ID]                  VARCHAR (8000)  NULL,
    [TransactionDate]              DATETIME2 (6)   NULL,
    [TransactionDateKey]           INT             NULL,
    [GL_TransType]                 BIGINT          NULL,
    [GLTransTypeDesc]              VARCHAR (49)    NULL,
    [currencycode]                 VARCHAR (8000)  NULL,
    [Invoice_ID]                   VARCHAR (8000)  NULL,
    [closed]                       DATETIME2 (6)   NULL,
    [ClosedDateKey]                INT             NULL,
    [duedate]                      DATETIME2 (6)   NULL,
    [DueDateKey]                   INT             NULL,
    [OpenID]                       INT             NOT NULL,
    [DaysOverdue]                  INT             NULL,
    [AgingBucketKey]               INT             NULL,
    [Description]                  VARCHAR (10)    NULL,
    [amountcur]                    DECIMAL (38, 6) NULL,
    [amountmst]                    DECIMAL (38, 6) NULL,
    [custexchadjustmentrealized]   DECIMAL (38, 6) NULL,
    [custexchadjustmentunrealized] DECIMAL (38, 6) NULL,
    [settleamountmst]              DECIMAL (38, 6) NULL,
    [Amount]                       DECIMAL (38, 6) NULL,
    [DaysOutstanding]              INT             NULL,
    [lastsettledate]               DATETIME2 (6)   NULL,
    [CustomerKey]                  BIGINT          NOT NULL,
    [Legal_EntityKey]              BIGINT          NOT NULL
);


GO

