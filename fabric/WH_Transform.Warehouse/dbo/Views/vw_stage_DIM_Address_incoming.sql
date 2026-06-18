-- Auto Generated (Do not modify) 918D09B14DE89A64A917CC35FBE604093D910CDE2A076072F7E4F3C94488DD11
/****** Object:  View [dbo].[vw_stage_DIM_Address_incoming]    Script Date: 5/11/2026 4:02:13 PM ******/
/****** Object:  View [dbo].[vw_stage_DIM_Address_incoming]    Script Date: 4/27/2026 3:52:33 PM ******/

--use WH_Transform

/****** Object:  View [dbo].[vw_stage_DIM_Address_incoming] ******/
--DROP VIEW IF EXISTS [dbo].[vw_stage_DIM_Address_incoming]

CREATE       VIEW [dbo].[vw_stage_DIM_Address_incoming]
AS
WITH legacy_addresses
AS
(
select Distinct 
ISNULL(COALESCE(Address1 + ' ', '') + 
       COALESCE(Address2 + ' ', '') + 
       COALESCE(Address3, '') +
       COALESCE(Address4, ''),'')  AS   Street
      ,isnull([City],'')                City
      ,isnull([State],'')               State
      ,isnull([ZIP],'')                 Zip
      ,isnull([Country],'')             Country

from WH_Curated.dbo.tbl_dim_accounts
)
, country_initcap AS 
(
      SELECT
          Street, City, State, Zip, Country
          , STRING_AGG(
              CAST(
                  CASE
                      WHEN sc.value = '' THEN ''
                      ELSE UPPER(LEFT(sc.value, 1)) + LOWER(SUBSTRING(sc.value, 2, LEN(sc.value)))
                  END
              AS VARCHAR(MAX)),
              ' '
            ) WITHIN GROUP (ORDER BY sc.ordinal) AS Country2
      FROM legacy_addresses t
      CROSS APPLY STRING_SPLIT(t.Country, ' ', 1) sc
      GROUP BY Street, City, State, Zip, Country
  )
  , state_initcap AS (
      SELECT
          Street, City, State, Zip, Country, Country2
          , STRING_AGG(
              CAST(
                  CASE
                      WHEN ss.value = '' THEN ''
                      ELSE UPPER(LEFT(ss.value, 1)) + LOWER(SUBSTRING(ss.value, 2, LEN(ss.value)))
                  END
              AS VARCHAR(MAX)),
              ' '
            ) WITHIN GROUP (ORDER BY ss.ordinal) AS State2
      FROM country_initcap t
      CROSS APPLY STRING_SPLIT(t.State, ' ', 1) ss
      GROUP BY Street, City, State, Zip, Country, Country2
  )

SELECT
     ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                 CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(a.[RECID]     AS VARCHAR(20))
            )
        ) AS BINARY(8)) AS BIGINT))         AS AddressKey
    ,a.[RECID]                              AS AddressRecId
    ,a.[LOCATION]                           AS Location
    ,isnull(a.[STREET],'')                             AS Street
    ,isnull(a.[CITY],'')                               AS City
    ,isnull(a.[STATE],'')                              AS State
    ,isnull(a.[ZIPCODE],'')                            AS ZipCode
    ,isnull(lacrt.[SHORTNAME],'')                      AS Country
    ,a.[VALIDFROM]                          AS ValidFrom
    ,a.[VALIDTO]                            AS ValidTo
    ,a.[LOCATIONNAME]                       AS LocationName

    ,'D365FO'                               AS Source
    ,CONVERT(datetime2(3), NULL)            AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)            AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)                     AS RecordStatus

FROM WH_Raw.dbo.[LOGISTICSPOSTALADDRESSVIEW] a
LEFT JOIN WH_Raw.dbo.[LOGISTICSADDRESSCOUNTRYREGIONTRANSLATION] lacrt
    ON  lacrt.[COUNTRYREGIONID] = a.[COUNTRYREGIONID]
    AND lacrt.[LANGUAGEID]      = 'en-US'

UNION ALL

SELECT
     -1                                     AS AddressKey
    ,-1                                   AS AddressRecId
    ,-1                                   AS Location
    ,'Unknown'                                   AS Street
    ,'Unknown'                                   AS City
    ,'Unknown'                                   AS State
    ,'Unknown'                                   AS ZipCode
    ,'Unknown'                                   AS Country
    ,NULL                                   AS ValidFrom
    ,NULL                                   AS ValidTo
    ,NULL                                   AS LocationName
    ,'D365FO'                               AS Source
    ,NULL                                   AS RecordEffectiveStartDate
    ,NULL                                   AS RecordEffectiveEndDate
    ,NULL                                   AS RecordStatus

UNION ALL

SELECT 
     ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                 CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(leg_addresses.Street+leg_addresses.city+leg_addresses.state+leg_addresses.zip+leg_addresses.country     AS VARCHAR(4000))
            )
        ) AS BINARY(8)) AS BIGINT))         AS AddressKey
    ,-2                                   AS AddressRecId       --Legacy Address
    ,-2                                   AS Location           --Legacy Address
    ,Street
    ,City
    ,State
    ,Zip
    ,Country
    ,NULL                                   AS ValidFrom
    ,NULL                                   AS ValidTo
    ,NULL                                   AS LocationName
    ,'Legacy'                               AS Source
    ,NULL                                   AS RecordEffectiveStartDate
    ,NULL                                   AS RecordEffectiveEndDate
    ,NULL                                   AS RecordStatus
FROM
(
select Distinct 
       ISNULL(Street,'')  AS   Street
      ,isnull([City],'')                City
      ,isnull([State2],'')               State
      ,isnull([ZIP],'')                 Zip
      ,isnull([Country2],'')             Country

from state_initcap  --WH_Curated.dbo.tbl_dim_accounts

except
(
select distinct street, city, state, zipcode, country
from tbl_DIM_Address
union 
select distinct street, city, state, zipcode, country
FROM
(
SELECT
     ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                 CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID()       AS VARCHAR(36)), '|'
                ,CAST(a.[RECID]     AS VARCHAR(20))
            )
        ) AS BINARY(8)) AS BIGINT))         AS AddressKey
    ,a.[RECID]                              AS AddressRecId
    ,a.[LOCATION]                           AS Location
    ,isnull(a.[STREET],'')                             AS Street
    ,isnull(a.[CITY],'')                               AS City
    ,isnull(a.[STATE],'')                              AS State
    ,isnull(a.[ZIPCODE],'')                            AS ZipCode
    ,isnull(lacrt.[SHORTNAME],'')                      AS Country
    ,a.[VALIDFROM]                          AS ValidFrom
    ,a.[VALIDTO]                            AS ValidTo
    ,a.[LOCATIONNAME]                       AS LocationName

    ,'D365FO'                               AS Source
    ,CONVERT(datetime2(3), NULL)            AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)            AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)                     AS RecordStatus

FROM WH_Raw.dbo.[LOGISTICSPOSTALADDRESSVIEW] a
LEFT JOIN WH_Raw.dbo.[LOGISTICSADDRESSCOUNTRYREGIONTRANSLATION] lacrt
    ON  lacrt.[COUNTRYREGIONID] = a.[COUNTRYREGIONID]
    AND lacrt.[LANGUAGEID]      = 'en-US'
) D365Addresses


)
) leg_addresses

;