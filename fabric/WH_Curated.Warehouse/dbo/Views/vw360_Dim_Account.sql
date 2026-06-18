-- Auto Generated (Do not modify) CE175AB05553D0D8829CCD54CF44A82AF977F1CF1685CD98E5EEE78D76C14E82
/****** Object:  View [dbo].[vw360_Dim_Account]    Script Date: 5/4/2026 10:21:53 AM ******/
/****** Object:  View [dbo].[vw360_Dim_Account]    Script Date: 5/1/2026 3:20:03 PM ******/
--drop view [vw360_Dim_Account]

CREATE                View [dbo].[vw360_Dim_Account] 
	--WITH SCHEMABINDING 
		as
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT         ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST([CustomerID] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT)) AS RECID
      ,[CustomerID]
      ,[GMAccountno]
      ,[GMRecid]
      ,[CustomerNo]
      ,[ShipToNo]
      ,[NationalOrgID]
      ,[RegionalOrgID]
      ,[GlobalOrgID]
      ,[Source]
      ,[CustomerName]
      ,[Address1]
      ,[Address2]
      ,[Address3]
      ,[Address4]
      ,[City]
      ,[State]
      ,[ZIP]
      ,[Country]
      ,[Contact]
      ,[Phone]
      ,[Fax]
      ,[Salesman]
      ,s.D365_SalesmanID
      ,[Sales Channel]
      ,[Bus Unit]
      ,[Industry]
      ,[Industry Mgr]
      ,[Mkt Mgr]
      ,[Application]
      ,[CMPNY]
      ,[Obsoleted]
      ,[ShipToType]
      ,[LocationName]
      ,[Location Type]
      ,[NationalName]
      ,[RegionalName]
      ,[GlobalName]
      ,[EffectiveSalesman]
      ,[EffectiveCountry]
      ,[Tier]
      ,[Contact Type]
      ,[Longitude]
      ,[Latitude]
      ,[GMOwnership]
      ,[RecordCurtainingLevel]
      ,[RowStatus]
      ,[RowChangeReason]
      ,[InitialLoadSystem]
      ,[LastChangeSystem]
      ,[RecordEffectiveStartDate]
      ,[RecordEffectiveEndDate]
      ,[RecordStatus]
      ,[ACC_SID]
  FROM [dbo].[tbl_DIM_Accounts] l
      	left join [dbo].[XREF_Salesman_ID] S ON S.Apollo_SalesmanName = l.Salesman where RecordStatus='1' 
		and CustomerId not in 
                (select coalesce(x.Apollo_CustomerID, c.Customer_id) 
                    FROM [dbo].[tbl_DIM_Customer] c
                    left join [dbo].[XREF_Customer_ID] X ON c.Customer_ID = x.D365_CustomerID) 

Union All

SELECT [CustomerKey] as Recid
      ,coalesce(x.Apollo_CustomerID, c.Customer_id)
	  ,Null as [GMAccountno]
      ,Null as [GMRecid]
      ,[Customer_ID] as CustomerNo
	   ,Null as [ShipToNo]
      ,Null as [NationalOrgID]
      ,Null as [RegionalOrgID]
      ,Null as [GlobalOrgID]
      ,[Source]
      ,[CustomerName]
      ,Address as [Address1]
      ,Null as [Address2]
      ,Null as [Address3]
      ,Null as [Address4]
      ,[City]
      ,[State]
      ,[ZIP]
      ,[Country]
	  ,Null as [Contact]
      ,Null as [Phone]
      ,Null as [Fax]
	  ,s.Apollo_SalesmanName as Salesman
	  ,[Salesman_ID] as [Salesman No]
      ,Null as [Sales Channel]
      ,Null as [Bus Unit]
      ,Null as [Industry]
      ,Null as [Industry Mgr]
      ,Null as [Mkt Mgr]
      ,Null as [Application]
      ,[CMPNY]
      ,Null as [Obsoleted]
      ,Null as [ShipToType]
      ,Null as [LocationName]
      ,Null as [Location Type]
      ,Null as [NationalName]
      ,Null as [RegionalName]
      ,Null as [GlobalName]
      ,Null as [EffectiveSalesman]
      ,NUll as [EffectiveCountry]
      ,Account_Tier as [Tier]
      ,Null as [Contact Type]
      ,convert(decimal(38,10), [Longitude]) [Longitude]
      ,convert(decimal(38,10), [Latitude]) [Latitude]
      ,Null as [GMOwnership]
      ,Null as [RecordCurtainingLevel]
      ,Null as [RowStatus]
      ,Null as [RowChangeReason]
      ,Null as [InitialLoadSystem]
      ,Null as [LastChangeSystem]
      ,[RecordEffectiveStartDate]
      ,[RecordEffectiveEndDate]
      ,[RecordStatus]
      ,0 as [ACC_SID]
    FROM [dbo].[tbl_Dim_CUstomer]  c
	left join [dbo].[XREF_Customer_ID] X ON c.Customer_ID = x.D365_CustomerID  

	left join [dbo].[XREF_Salesman_ID] S ON S.D365_SalesmanID = c.Salesman_ID 
     where RecordStatus='1'