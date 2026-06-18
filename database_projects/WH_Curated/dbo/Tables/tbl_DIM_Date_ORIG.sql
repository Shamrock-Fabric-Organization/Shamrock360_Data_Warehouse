CREATE TABLE [dbo].[tbl_DIM_Date_ORIG] (

	[RECID] float NULL, 
	[Fiscal_Qtr] float NULL, 
	[Fiscal_Yr] float NULL, 
	[Fiscal_Period] varchar(8000) NULL, 
	[Weeks_In_Period] float NULL, 
	[Fiscal_Week_#] float NULL, 
	[Year] float NULL, 
	[Qtr] float NULL, 
	[Month] varchar(8000) NULL, 
	[Day] float NULL, 
	[Weekday] varchar(8000) NULL, 
	[Week_#] float NULL, 
	[Date] datetime2(6) NULL, 
	[Day_#] int NULL, 
	[Fiscal_Day_#] int NULL, 
	[US_Working_Day] float NULL, 
	[BVBA_Working_Day] float NULL, 
	[TEDA_Working_Day] float NULL
);