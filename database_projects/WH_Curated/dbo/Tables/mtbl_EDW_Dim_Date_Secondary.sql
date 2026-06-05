CREATE TABLE [dbo].[mtbl_EDW_Dim_Date_Secondary] (
    [DateKey]             INT          NULL,
    [Date]                DATE         NULL,
    [YearMonthNum]        VARCHAR (10) NOT NULL,
    [YearMonthLabel]      VARCHAR (9)  NULL,
    [FiscalPeriodNum]     INT          NULL,
    [FiscalYear]          SMALLINT     NULL,
    [FiscalPeriodLabel]   VARCHAR (5)  NULL,
    [MonthStartDate]      DATE         NULL,
    [MonthNameShort]      VARCHAR (3)  NULL,
    [WeekdayNameLong]     VARCHAR (9)  NULL,
    [IsToday]             INT          NOT NULL,
    [IsCurrentMonth]      BIT          NULL,
    [IsCurrentFiscalYear] BIT          NULL
);


GO

