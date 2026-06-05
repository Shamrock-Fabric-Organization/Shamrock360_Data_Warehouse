-- Auto Generated (Do not modify) BB0539C1F9CD8E1061880825EF966A88F2932E2D99D9120AE6FA398D47BAB9D4
/****** Object:  View [dbo].[vw_EDW_Dim_Account]    Script Date: 5/4/2026 10:20:39 AM ******/
/****** Object:  View [dbo].[vw_EDW_Dim_Account]    Script Date: 5/1/2026 3:19:05 PM ******/
--drop view [vw_EDW_Dim_Account]


CREATE                        View [dbo].[vw_EDW_Dim_Account] 
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
      ,COALESCE([City], 'No City') + ', ' + COALESCE([State], 'No State') CityState
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
      ,[PaymentTerms]
	  ,[PhoneNumber]
	  ,[PurchasingEmail]
      ,[InvoicingEmail]
      ,[customergroup]
      ,[customer_currency]
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

      --, CASE WHEN Cmpny='001' then '101' else Cmpny end  CMPNY
      , CASE WHEN Cmpny in ('001','002') then '101' 
		 WHEN Cmpny = '101' THEN '301'  
		 WHEN Cmpny = '201' THEN '501'
		 WHEN CMPNY = '999' THEN '301'
		 else Cmpny end  CMPNY
      ,CustomerID
      ,'' as Invoice_Account
      ,0                  -- int in D365 
      ,0                  -- int in D365 
      ,0                  -- int in D365 
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
       ,COALESCE([City], 'No City') + ', ' + COALESCE([State], 'No State') CityState
     ,'' as Territory_ID
      ,[Salesman]
      ,[Sales Channel]
      ,[Industry]
      ,[Bus Unit]
      ,'' as Status
      ,0                    -- int in D365   Effective_Country
      ,[Tier]
      ,convert(decimal(38,10), [Longitude]) [Longitude]
      ,convert(decimal(38,10), [Latitude]) [Latitude]
	  ,NULL as PaymentTerms
	  ,NULL as PhoneNumber
	  ,NULL as [PurchasingEmail]
      ,NULL as [InvoicingEmail]
      , CASE WHEN Cmpny = '002' THEN '800'
            WHEN UPPER([CustomerName]) like '%SHAMROCK%' THEN '999'
            ELSE '100' END as [customergroup]
      ,'USD' as [customer_currency]
      ,'legacy' as Source
      ,[RecordEffectiveStartDate]
      ,[RecordEffectiveEndDate]
      ,[RecordStatus]
from dbo.tbl_DIM_Accounts
 ----left join [dbo].[XREF_Customer_ID] y ON CustomerID = Apollo_CustomerID 
where 
--RecordStatus='1' 
--and 
isNull(CustomerID,'') not in ('A201','A101','AEurope','')
and NOT(CustomerID in (select [Apollo_CustomerID] from [dbo].[XREF_Customer_ID]))
--and RecordStatus=1