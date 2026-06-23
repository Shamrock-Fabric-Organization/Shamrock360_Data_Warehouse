-- Auto Generated (Do not modify) AF4CABC8655942F0927E017334587BF9E477C5B0D66B6BE417DAB23E6FA28B5E




/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
----drop  VIEW dbo.[vw_stage_DIM_Site_incoming]	

CREATE   VIEW [dbo].[vw_stage_DIM_Site_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(Site_ID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SiteKey
    , CMPNY
    , Site_ID
    , Site_Name
    , Source
    , RecordEffectiveStartDate
    , RecordEffectiveEndDate
    , RecordStatus
FROM
(
SELECT
	dataareaid	 CMPNY
	, siteid	Site_ID
	, Name	 Site_Name
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus
FROM WH_Raw.dbo.inventsite 

UNION 

select distinct 
    '101' CMPNY
    , p.VALUE  Site_ID
    , dft.description Site_Name
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus
from WH_Raw.dbo.vwStageLedgerDimension p
INNER JOIN WH_Raw.dbo.DimensionFinancialTag dft 
    ON p.entityinstance = dft.RECID
where p.DIMENSIONNAME = 'Site'
) s


UNION ALL

SELECT -1 [SiteKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Site_ID]
, 'Unknown' [Site_Name]
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]