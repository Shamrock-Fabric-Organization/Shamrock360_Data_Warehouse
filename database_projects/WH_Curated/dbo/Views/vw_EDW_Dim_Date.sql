-- Auto Generated (Do not modify) ED32015109BFF752B7B66BA04E12967A5E722DB96BE0FFA592157CFE7FB4A20C
/****** Object:  View [dbo].[vw_EDW_Dim_Date]    Script Date: 5/12/2026 8:50:21 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Date]    Script Date: 2/24/2026 3:34:39 PM ******/

CREATE         VIEW [dbo].[vw_EDW_Dim_Date] AS

-- ===============================================================
-- Create NEW View vw_EDW_Dim_Date
-- ===============================================================


SELECT
    CONVERT(INT, CONVERT(CHAR(8), [DATE], 112)) AS DateKey
	  ,[RecId]
      ,[FiscalQuarterNum]
      ,[FiscalYear]
      ,CONVERT(int, [FiscalPeriodNum]) [FiscalPeriodNum]  --RIGHT('00' + CAST([FiscalPeriodNum] AS VARCHAR(2)), 2) AS [FiscalPeriodNum]
      , FLOOR((DAY([DATE])-1) / 7) + 1  [WeeksInPeriod]
      ,CONVERT(int, [FiscalWeekNum]) [FiscalWeekNum]  --RIGHT('00' + CAST([FiscalWeekNum] AS VARCHAR(2)), 2) AS [FiscalWeekNum]
      ,[CalendarYear]
      ,[CalendarQuarterNum]
      ,[MonthNameShort]
      ,[WeekdayNameLong]
      ,CONVERT(int, [WeekOfYearNum]) [WeekOfYearNum]  --RIGHT('00' + CAST([WeekOfYearNum] AS VARCHAR(2)), 2) AS [WeekOfYearNum]
      ,[Date]
      ,CONVERT(int, [DayOfMonthNum]) [DayOfMonthNum]  --RIGHT('00' + CAST([DayOfMonthNum] AS VARCHAR(2)), 2) AS [DayOfMonthNum]
      ,[FiscalDayNum]
      ,[IsWorkingDayUs]
      ,[IsWorkingDayBvba]
      ,[IsWorkingDayTeda],
         -- Week starting Monday
    DATEADD(DAY, -((DATEPART(WEEKDAY, [DATE]) + @@DATEFIRST - 2) % 7), [DATE]) AS WeekStartDate,
         -- Week starting Sunday
    DATEADD(DAY, -((DATEPART(WEEKDAY, [DATE]) + @@DATEFIRST - 1) % 7), [DATE]) AS WeekStartDateSunday,

    -- Month starting first day
    DATEFROMPARTS(YEAR([DATE]), MONTH([DATE]), 1) AS MonthStartDate,

    [FiscalDayNum] AS [CurrentFiscalDayNum],

    (
        SELECT [FiscalYear]
        FROM tbl_Dim_Date
        WHERE CONVERT(VARCHAR(10), GETDATE(), 101) = CONVERT(VARCHAR(10), DATE, 101)
    ) AS [CurrentFiscalYear]
      ,CONVERT(int, MonthNum) MonthNum  --RIGHT('00' + CAST([MonthNum] AS VARCHAR(2)), 2) AS MonthNum
      ,CONVERT(VARCHAR(30), DATENAME(month, [date])) [MonthNameLong]

      ,CONCAT(CalendarYear, RIGHT('00' + CAST([MonthNum] AS VARCHAR(2)), 2)) as YearMonthNum
      ,CONVERT(Char(4), YEAR([Date]))+'-'+RIGHT('00'+convert(varchar(2),MONTH([Date])),2)   [YearMonthLabel]

      ,[CalendarQuarterLabel]
      ,[CalendarYearQuarterNum]

      , 'FY'+convert(char(4),[FiscalYear]) +' Q'+ convert(char(1),[FiscalQuarterNum]) [FiscalQuarterLabel]
      , [FiscalYear]*10 + [FiscalQuarterNum] [FiscalYearQuarterNum]

      , (DATEPART(dw, [DATE]) + @@DATEFIRST - 2) % 7 + 1 [WeekdayNum]

      ,[WeekdayNameShort]
      ,[YearWeekNum]
      , [FiscalYear]*100 + [FiscalWeekNum]   [FiscalYearWeekNum]

      ,[DayOfYearNum]
      ,[IsWeekend]
      ,IsToday = CASE WHEN CAST(Date AS DATE) = CAST(GETDATE() AS DATE) THEN 1  ELSE 0 END
	  ,[IsCurrentMonth] =     
	    CASE
			WHEN Date >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)
			 AND Date < DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0)
			THEN CAST(1 AS BIT) -- True
			ELSE CAST(0 AS BIT) -- False
		END 

        --start here
	   ,[IsCurrentFiscalYear] =     
	 --   CASE
		--	WHEN FiscalYear >= DATEADD(year, DATEDIFF(year, 0, GETDATE()), 0)
		--	 AND FiscalYear < DATEADD(year, DATEDIFF(year, 0, GETDATE()) + 1, 0)
		--	THEN CAST(1 AS BIT) -- True
		--	ELSE CAST(0 AS BIT) -- False
		--END 
	    CASE
			WHEN FiscalYear = YEAR(GETDATE())
			THEN CAST(1 AS BIT) -- True
			ELSE CAST(0 AS BIT) -- False
		END 
      , 'P'+RIGHT('00' + CAST([FiscalPeriodNum] AS VARCHAR(2)), 2)  [FiscalPeriodLabel]
      ,[Original FISCAL YR]
      ,[Original FISCAL PERIOD]
      ,[Reconciliation Year]
  FROM [dbo].[tbl_DIM_Date] --order by Istoday desc --order by Istoday desc