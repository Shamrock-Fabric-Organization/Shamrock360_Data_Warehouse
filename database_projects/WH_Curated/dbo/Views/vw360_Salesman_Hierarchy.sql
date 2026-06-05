
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

GO

