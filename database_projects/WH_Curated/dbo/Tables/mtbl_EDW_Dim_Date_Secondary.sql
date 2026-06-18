CREATE TABLE [dbo].[mtbl_EDW_Dim_Date_Secondary] (

	[DateKey] int NULL, 
	[Date] date NULL, 
	[YearMonthNum] varchar(10) NOT NULL, 
	[YearMonthLabel] varchar(9) NULL, 
	[FiscalPeriodNum] int NULL, 
	[FiscalYear] smallint NULL, 
	[FiscalPeriodLabel] varchar(5) NULL, 
	[MonthStartDate] date NULL, 
	[MonthNameShort] varchar(3) NULL, 
	[WeekdayNameLong] varchar(9) NULL, 
	[IsToday] int NOT NULL, 
	[IsCurrentMonth] bit NULL, 
	[IsCurrentFiscalYear] bit NULL
);