CREATE   view [dbo].[vw360_Dim_Date] as
select RECID
      ,[Fiscal_Qtr]
      ,[Fiscal_Yr]
      ,[Fiscal_Period]
      ,[Weeks_In_Period]
      ,[Fiscal_Week_#]
      ,[Year]
      ,[Qtr]
      ,[Month]
      ,[Day]
      ,[Weekday]
      ,[Week_#]
      ,[Date]
      ,[Day_#]
      ,[Fiscal_Day_#]
      ,'1' as [US_Working_Day]
      ,'1' as [BVBA_Working_Day]
      ,'1' as[TEDA_Working_Day]
from tbl_Dim_Date

GO

