CREATE TABLE [dbo].[tbl_Mo_Dim_Date] (

	[RECID] bigint NULL, 
	[FISCAL QTR] bigint NULL, 
	[FISCAL YR] bigint NULL, 
	[FISCAL PERIOD] bigint NULL, 
	[WEEKS IN PERIOD] float NULL, 
	[FISCAL WEEK #] bigint NULL, 
	[YEAR] bigint NULL, 
	[QTR] bigint NULL, 
	[MONTH] bigint NULL, 
	[DAY] bigint NULL, 
	[WEEKDAY] varchar(8000) NULL, 
	[WEEK #] bigint NULL, 
	[DATE] date NULL, 
	[DAY #] bigint NULL, 
	[FISCAL DAY #] bigint NULL, 
	[Reconciliation Year] varchar(8000) NULL
);