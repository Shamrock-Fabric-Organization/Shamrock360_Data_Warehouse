CREATE TABLE [dbo].[tbl_DIM_Date_ORIG] (
    [RECID]            FLOAT (53)     NULL,
    [Fiscal_Qtr]       FLOAT (53)     NULL,
    [Fiscal_Yr]        FLOAT (53)     NULL,
    [Fiscal_Period]    VARCHAR (8000) NULL,
    [Weeks_In_Period]  FLOAT (53)     NULL,
    [Fiscal_Week_#]    FLOAT (53)     NULL,
    [Year]             FLOAT (53)     NULL,
    [Qtr]              FLOAT (53)     NULL,
    [Month]            VARCHAR (8000) NULL,
    [Day]              FLOAT (53)     NULL,
    [Weekday]          VARCHAR (8000) NULL,
    [Week_#]           FLOAT (53)     NULL,
    [Date]             DATETIME2 (6)  NULL,
    [Day_#]            INT            NULL,
    [Fiscal_Day_#]     INT            NULL,
    [US_Working_Day]   FLOAT (53)     NULL,
    [BVBA_Working_Day] FLOAT (53)     NULL,
    [TEDA_Working_Day] FLOAT (53)     NULL
);


GO

