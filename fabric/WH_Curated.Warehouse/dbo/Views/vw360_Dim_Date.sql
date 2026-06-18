-- Auto Generated (Do not modify) 8B01A13F1974E6135EE8F869F134C5E1665953DF357645A2A67178A0678708B7
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