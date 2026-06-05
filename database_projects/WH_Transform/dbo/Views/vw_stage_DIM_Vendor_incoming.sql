
--drop  VIEW dbo.[vw_stage_DIM_Vendor_incoming]	

CREATE       VIEW [dbo].[vw_stage_DIM_Vendor_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(V.accountnum AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS VendorKey
	,V.dataareaid	 CMPNY
	,V.accountnum	Vendor_ID
	,DPT.Name	 Vendor_Name
	,V.itembuyergroupid Vendor_Type
	,AV.StreetAddress	 Address
	,AV.city	City
	,AV.STATE	State
	,AV.zipcode	 ZIP
	,LACRT.shortname	 Country
	,V.Currency
	,V.vendgroup
	,VG.name VendGroupName
	,V.segmentid
	,V.subsegmentid

	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus


FROM WH_Raw.dbo.VENDTABLE V		
JOIN WH_Raw.dbo.DirPartyTable DPT		
	ON V.party = DPT.RECID	
LEFT JOIN WH_Raw.dbo.DirPartyPostalAddressView AV		
	ON V.party = AV.party	
	    AND AV.isprimary = 1
		AND GETDATE() between AV.validfrom and AV.validto
LEFT JOIN WH_Raw.dbo.logisticsaddresscountryregiontranslation LACRT		
	ON AV.CountryRegionID = LACRT.countryregionid	
		AND LACRT.languageid = 'en-US'

LEFT JOIN WH_Raw.dbo.vendgroup vg		
	ON V.dataareaid = VG.dataareaid
	    AND V.vendgroup = VG.vendgroup

UNION ALL

SELECT -1 [VendorKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Vendor_ID]
, 'Unknown' [Vendor_Name]
, NULL [Vendor_Type]
, NULL [Address]
, NULL [City]
, NULL [State]
, NULL [ZIP]
, NULL [Country]
, NULL [Currency]
, NULL vendgroup
, NULL VendGroupName
, NULL segmentid
, NULL subsegmentid
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]

GO

