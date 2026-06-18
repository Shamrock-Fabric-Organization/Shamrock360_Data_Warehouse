-- Auto Generated (Do not modify) 918D09B14DE89A64A917CC35FBE604093D910CDE2A076072F7E4F3C94488DD11

--use WH_Transform
--select count(1) from [vw_stage_NewAddress]

/****** Object:  View [dbo].[vw_stage_NewAddress] ******/
--DROP VIEW IF EXISTS [dbo].[vw_stage_NewAddress]

CREATE   VIEW [dbo].[vw_stage_NewAddress]
AS

SELECT
     Source.[AddressKey]
    ,Source.[AddressRecId]
    ,Source.[Location]
    ,Source.[Street]
    ,Source.[City]
    ,Source.[State]
    ,Source.[ZipCode]
    ,Source.[Country]
    ,Source.[ValidFrom]
    ,Source.[ValidTo]
    ,Source.[LocationName]
    ,Source.[Source]
    ,CAST('1900-01-01'              AS DATETIME2(3)) AS RecordEffectiveStartDate
    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
    ,1                                               AS RecordStatus

FROM [dbo].[vw_stage_DIM_Address_incoming] Source
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[tbl_DIM_Address] Target
    WHERE Target.[AddressRecId] = Source.[AddressRecId]
        AND Target.Source='D365FO'
    UNION
     SELECT 1
    FROM [dbo].[tbl_DIM_Address] Target
    WHERE Target.[Street] = Source.[Street]
        AND Target.[City] = Source.[City]
        AND Target.[State] = Source.[State]
        AND Target.[ZipCode] = Source.[ZipCode]
        AND Target.[Country] = Source.[Country]
        AND Target.Source<>'D365FO'
)
;