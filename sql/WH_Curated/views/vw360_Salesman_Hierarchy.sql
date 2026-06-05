-- Auto Generated (Do not modify) F68EEC160AE45059B7588B846D0F776042068B1597E67C8CF5DF7CAB2A79980A

CREATE   view [dbo].[vw360_Salesman_Hierarchy] as

SELECT [GMUserID]
      ,[Salesteam]
      ,[AssignedSalesman]
      ,[RegionalSalesman]
      ,[RegionalSalesDirector]
      ,[GlobalSalesDirector]
      ,[RecordStatus]
  FROM [dbo].[legacy_tbl_DIM_Salesman_Heirarchy]
where RecordStatus = 'Active'