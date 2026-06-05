/****** Object:  View [dbo].[vw_EDW_Dim_Customer]    Script Date: 5/4/2026 10:21:26 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Customer]    Script Date: 5/1/2026 3:19:43 PM ******/


/****** Object:  View [dbo].[vw_EDW_Dim_Customer]    Script Date: 12/19/2025 3:08:17 PM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Customer]    Script Date: 12/19/2025 2:33:16 PM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Customer]    Script Date: 12/19/2025 1:42:03 PM ******/

--drop   View [dbo].[vw_EDW_Dim_Customer] 


CREATE               View [dbo].[vw_EDW_Dim_Customer] 
	--WITH SCHEMABINDING 
		as

SELECT [CustomerKey]
      ,[CMPNY]
      ,[Customer_ID]
      ,[Invoice_Account]
      ,[Legacy_Customer_ID]
      ,[GMAccountNo]
      ,[GMRecID]
      ,[CustomerName]
      ,[Harmonized_Name]
      ,[Address]
      ,[City]
      ,[State]
      ,[ZIP]
      ,[Country]
      ,[Territory_ID]
      ,[Salesman_ID]
      ,[SalesChannel]
      ,[Industry_Segment]
      ,[Subsegment]
      ,[Status]
      ,[EffectiveCountry]
      ,[Account_Tier]
      ,[Longitude]
      ,[Latitude]
      ,[Source]
      ,[RecordEffectiveStartDate]
      ,[RecordEffectiveEndDate]
      ,[RecordStatus]
  FROM [dbo].[tbl_Dim_CUstomer]

  Union All

  SELECT 
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST([CustomerID] AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS CustomerKey
      ,'101'
      ,[CustomerID]
      ,'' as Invoice_Account
      ,0                  -- int in D365 [Legacy_Customer_ID]
      ,0                  -- int in D365 [Legacy_Customer_ID]
      ,0                  -- int in D365 [Legacy_Customer_ID]
      ,[CustomerName]
      ,[CustomerName]
      ,COALESCE(Address1 + ' ', '') + 
       COALESCE(Address2 + ' ', '') + 
       COALESCE(Address3, '') +
       COALESCE(Address4, '')  AS Address_1
      ,[City]
      ,[State]
      ,[ZIP]
      ,[Country]
      ,'' as Territory_ID
      ,[EffectiveSalesman]
      ,[Sales Channel]
      ,[Industry]
      ,[Bus Unit]
      ,'' as Status
      ,0                    -- int in D365   Effective_Country
      ,[Tier]
      ,[Longitude]
      ,[Latitude]
      ,'legacy' as Source
      ,[RecordEffectiveStartDate]
      ,[RecordEffectiveEndDate]
      ,[RecordStatus]
from dbo.tbl_DIM_Accounts
where RecordStatus='1' 
and isNull(CustomerID,'') not in ('A201','A101','AEurope','')
and NOT( [CustomerID] in (SELECT [Apollo_CustomerID] FROM [dbo].[XREF_Customer_ID]) )

GO

