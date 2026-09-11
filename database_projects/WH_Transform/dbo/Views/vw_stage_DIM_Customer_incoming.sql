
CREATE OR ALTER      VIEW [dbo].[vw_stage_DIM_Customer_incoming]			
AS			
with emails as
(
  SELECT Company
        , CustomerAccount
        ----, ContactType
        , ContactDescription
        , STRING_AGG(ContactValue,';') eMail
  FROM (
  SELECT DISTINCT 
       CT.DATAAREAID               AS Company
      ,CT.ACCOUNTNUM               AS CustomerAccount
      ,DPT.NAME                    AS CustomerName
      ----,CASE EA.TYPE
      ----    WHEN 1 THEN 'Phone'
      ----    WHEN 2 THEN 'Email'
      ----    WHEN 3 THEN 'URL'
      ----    WHEN 4 THEN 'Telex'
      ----    WHEN 5 THEN 'Fax'
      ----    WHEN 6 THEN 'Facebook'
      ----    WHEN 7 THEN 'Twitter'
      ----    WHEN 8 THEN 'LinkedIn'
      ----    ELSE 'Unknown'
      ---- END                         AS ContactType
      ,EA.LOCATOR                  AS ContactValue
      ,CASE WHEN lower(EA.DESCRIPTION) like '%purch%' THEN 'Purchasing'
            WHEN lower(EA.DESCRIPTION) like '%invoi%' THEN 'Invoicing' END AS ContactDescription
      --,DPL.ISPRIMARY               AS IsPrimaryLocation
      --,EA.ISPRIMARY                AS IsPrimaryContact
  FROM WH_Raw.dbo.CUSTTABLE CT
  LEFT JOIN WH_Raw.dbo.DIRPARTYTABLE DPT
      ON DPT.RECID = CT.PARTY
  LEFT JOIN WH_Raw.dbo.DIRPARTYLOCATION DPL
      ON DPL.PARTY = DPT.RECID
  LEFT JOIN WH_Raw.dbo.LOGISTICSLOCATION LL
      ON LL.RECID = DPL.LOCATION
  LEFT JOIN WH_Raw.dbo.LOGISTICSELECTRONICADDRESS EA
      ON EA.LOCATION = LL.RECID
  WHERE EA.TYPE = 2              -- 2 = Email; remove to get all types
    AND
  ( lower(EA.DESCRIPTION) like '%purch%'
  OR
   lower(EA.DESCRIPTION) like '%invoi%' )
  ) cust
GROUP BY Company
        , CustomerAccount
        ----, ContactType
        , ContactDescription
)
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(Customer_ID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS CustomerKey
, [CMPNY]
, [Customer_ID]
, [Invoice_Account]
, [Legacy_Customer_ID]
, [GMAccountNo]
, [GMRecID]
, [CustomerName]
, [Harmonized_Name]
, [Address]
, [City]
, [State]
, [ZIP]
, [Country]
, [Territory_ID]
, [Salesman_ID]
, [SalesChannel]
, [Industry_Segment]
, [Subsegment]
, [Status]
, [EffectiveCountry]
, [Account_Tier]
, [Longitude]
, [Latitude]
, [PaymentTerms]
, [PhoneNumber]
, [PurchasingEmail]
, [InvoicingEmail]
, [customergroup]
, [customer_currency]
, [Source]
, [RecordEffectiveStartDate]
, [RecordEffectiveEndDate]
, [RecordStatus]

FROM
(
SELECT 	DISTINCT	C.dataareaid	 CMPNY
	,C.accountnum	 Customer_ID
	,coalesce(C.invoiceaccount, C.accountnum)	 Invoice_Account
	,NULL Legacy_Customer_ID			--map TBD, might be from legacy table
	,NULL	 GMAccountNo				--leave null for now
	,NULL	 GMRecID					--leave null for now
	,DPT.Name	 CustomerName
	,case when ISNULL(C.companychainID,'X') = 'X' then DPT.Name +' - not harmonized' else C.companychainID end	 Harmonized_Name
	--,COALESCE(AV.StreetAddress, AV2.StreetAddress)	 Address
	--,COALESCE(AV.city, AV2.city) 	City
	--,COALESCE(AV.STATE, AV2.STATE) 	State
	--,COALESCE(AV.zipcode, AV2.zipcode) 	 ZIP
	--,COALESCE(LACRT.shortname, LACRT2.shortname) 	 Country

	,CASE WHEN ISNULL(AV.StreetAddress, '') + ISNULL(AV.city,  '') + ISNULL(AV.STATE,  '') 
		+ ISNULL(AV.zipcode,  '') + ISNULL(LACRT.shortname,  '') <> ''
		THEN AV.StreetAddress
		ELSE AV2.StreetAddress
		END Address
	,CASE WHEN ISNULL(AV.StreetAddress, '') + ISNULL(AV.city,  '') + ISNULL(AV.STATE,  '') 
		+ ISNULL(AV.zipcode,  '') + ISNULL(LACRT.shortname,  '') <> ''
		THEN AV.city
		ELSE AV2.city
		END City
	,CASE WHEN ISNULL(AV.StreetAddress, '') + ISNULL(AV.city,  '') + ISNULL(AV.STATE,  '') 
		+ ISNULL(AV.zipcode,  '') + ISNULL(LACRT.shortname,  '') <> ''
		THEN AV.STATE
		ELSE AV2.STATE
		END State
	,CASE WHEN ISNULL(AV.StreetAddress, '') + ISNULL(AV.city,  '') + ISNULL(AV.STATE,  '') 
		+ ISNULL(AV.zipcode,  '') + ISNULL(LACRT.shortname,  '') <> ''
		THEN AV.zipcode
		ELSE AV2.zipcode
		END ZIP
	,CASE WHEN ISNULL(AV.StreetAddress, '') + ISNULL(AV.city,  '') + ISNULL(AV.STATE,  '') 
		+ ISNULL(AV.zipcode,  '') + ISNULL(LACRT.shortname,  '') <> ''
		THEN LACRT.shortname
		ELSE LACRT2.shortname
		END Country
	,C.salesdistrictid Territory_ID		--Is this the correct mapping
	,SP.personnelnumber	 Salesman_ID	--this is the personnelnumber, would they rather have the RECID?
	,C.lineofbusinessID	 SalesChannel	--Is this the correct mapping
	,C.segmentID	 Industry_Segment	--Check mapping
	,C.subsegmentID Subsegment					--mapping??
	,NULL Status						--mapping??
	,NULL EffectiveCountry				--mapping??
	,NULL Account_Tier					--mapping??
	,AV.Longitude	Longitude
	,AV.Latitude	Latitude
	,C.paymtermid  PaymentTerms
	,LEAph.locator PhoneNumber
	--,LEAemail.locator eMail
	, e_pur.eMail PurchasingEmail
	, e_inv.eMail InvoicingEmail
	,C.custgroup customergroup
	,C.currency  customer_currency
	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

FROM WH_Raw.dbo.CUSTTABLE C		
JOIN WH_Raw.dbo.DirPartyTable DPT		
	ON C.party = DPT.RECID	
LEFT JOIN WH_Raw.dbo.DirPartyPostalAddressView AV		
	ON C.party = AV.party	
	    AND AV.isprimary = 1
		AND GETDATE() between AV.validfrom and AV.validto
LEFT JOIN WH_Raw.dbo.logisticsaddresscountryregiontranslation LACRT		
	ON AV.CountryRegionID = LACRT.countryregionid	
		AND LACRT.languageid = 'en-US'

LEFT JOIN 
	( WH_Raw.dbo.DirPartyPostalAddressView AV2
	 JOIN 
				(select party, COUNT(1) numofaddresses
				from WH_Raw.dbo.DirPartyPostalAddressView
				where  GETDATE() between validfrom and validto
				and isprimary = 0
				group by party
				having COUNT(1) = 1) AD1
		ON AV2.party = AD1.party
	) 
	ON C.party = AV2.party	
		AND GETDATE() between AV2.validfrom and AV2.validto
LEFT JOIN WH_Raw.dbo.logisticsaddresscountryregiontranslation LACRT2	
	ON AV2.CountryRegionID = LACRT2.countryregionid	
		AND LACRT2.languageid = 'en-US'

LEFT JOIN WH_Raw.dbo.DirPartyLocation DPL		
	ON C.Party = DPL.Party	
		AND DPL.isprimary =1
LEFT JOIN WH_Raw.dbo.LogisticsLocation LL		
	ON DPL.Location = LL.RecId	
LEFT JOIN WH_Raw.dbo.LogisticsElectronicAddress LEAph		
	ON LL.RecId = LEAph.Location	
		AND LEAph.type_$label = 'Phone'
LEFT JOIN WH_Raw.dbo.HCMWorker sp		
	ON C.maincontactworker = SP.recid	
LEFT JOIN WH_Raw.dbo.DirPartyTable DPTSP		
	ON SP.person = DPTSP.recid	
LEFT JOIN WH_Raw.dbo.LogisticsElectronicAddress LEAfax		
	ON LL.RecId = LEAfax.Location	
		AND LEAfax.type_$label = 'Fax'

------LEFT JOIN WH_Raw.dbo.LogisticsElectronicAddress LEAemail		
------	ON LL.RecId = LEAemail.Location	
------		AND LEAemail.type_$label = 'Email'

LEFT JOIN emails e_pur		
	ON C.dataareaid = e_pur.Company
		AND C.accountnum = e_pur.CustomerAccount
		AND e_pur.ContactDescription = 'Purchasing'

LEFT JOIN emails e_inv		
	ON C.dataareaid = e_inv.Company
		AND C.accountnum = e_inv.CustomerAccount
		AND e_inv.ContactDescription = 'Invoicing'

) c

UNION ALL   --Legacy Goldmine data 

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
      ,0                  [Legacy_Customer_ID]
      ,0                  [GMAccountNo]
      ,0                  [GMRecID] 

      ,[CustomerName]
      ,[GlobalName]
      ,COALESCE(Address1 + ' ', '') + 
       COALESCE(Address2 + ' ', '') + 
       COALESCE(Address3, '') +
       COALESCE(Address4, '')  AS Address_1
      ,[City]
      ,[State]
      ,[ZIP]
      ,[Country]
       ----,COALESCE([City], 'No City') + ', ' + COALESCE([State], 'No State') CityState
     ,'' as Territory_ID
      ,[Salesman]
      ,[Sales Channel]
      ,[Industry]
      ,[Bus Unit]
      ,'' as Status
      , EffectiveCountry        
      ,[Tier]      [Account_Tier]
      ,convert(decimal(38,10), [Longitude]) [Longitude]
      ,convert(decimal(38,10), [Latitude]) [Latitude]
	  ,NULL as PaymentTerms
	  ,Phone as PhoneNumber
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
  FROM WH_Raw.[dbo].[tbl_DIM_Accounts]
where 
isNull(CustomerID,'') not in ('A201','A101','AEurope','')
and NOT(isNull(CustomerID,'') in (select [Apollo_CustomerID] from WH_Curated.[dbo].[XREF_Customer_ID]))

UNION ALL

SELECT -1 [CustomerKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Customer_ID]
, 'Unknown' [Invoice_Account]
, NULL [Legacy_Customer_ID]
, NULL [GMAccountNo]
, NULL [GMRecID]
, NULL [CustomerName]
, NULL [Harmonized_Name]
, NULL [Address]
, NULL [City]
, NULL [State]
, NULL [ZIP]
, NULL [Country]
, NULL [Territory_ID]
, NULL [Salesman_ID]
, NULL [SalesChannel]
, NULL [Industry_Segment]
, NULL [Subsegment]
, NULL [Status]
, NULL [EffectiveCountry]
, NULL [Account_Tier]
, NULL [Longitude]
, NULL [Latitude]
, NULL [PaymentTerms]
, NULL [PhoneNumber]
, NULL [PurchasingEmail]
, NULL [InvoicingEmail]
, NULL [customergroup]
, NULL [customer_currency]
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]
