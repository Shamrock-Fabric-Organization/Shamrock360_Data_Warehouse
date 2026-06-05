CREATE TABLE [dbo].[tbl_Mo_Dim_Date] (
    [RECID]               BIGINT         NULL,
    [FISCAL QTR]          BIGINT         NULL,
    [FISCAL YR]           BIGINT         NULL,
    [FISCAL PERIOD]       BIGINT         NULL,
    [WEEKS IN PERIOD]     FLOAT (53)     NULL,
    [FISCAL WEEK #]       BIGINT         NULL,
    [YEAR]                BIGINT         NULL,
    [QTR]                 BIGINT         NULL,
    [MONTH]               BIGINT         NULL,
    [DAY]                 BIGINT         NULL,
    [WEEKDAY]             VARCHAR (8000) NULL,
    [WEEK #]              BIGINT         NULL,
    [DATE]                DATE           NULL,
    [DAY #]               BIGINT         NULL,
    [FISCAL DAY #]        BIGINT         NULL,
    [Reconciliation Year] VARCHAR (8000) NULL
);


GO

