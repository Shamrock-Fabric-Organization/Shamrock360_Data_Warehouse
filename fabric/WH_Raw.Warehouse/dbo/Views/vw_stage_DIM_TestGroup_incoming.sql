-- Auto Generated (Do not modify) 593CDA5BE38D3034B287CEB03899722DB7E8857D2A64A757FA86F1478FFA3DF7

--use WH_Transform

--drop VIEW dbo.[vw_stage_DIM_TestGroup_incoming]

CREATE   VIEW [dbo].[vw_stage_DIM_TestGroup_incoming]
AS
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
             CAST(NEWID()      AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID()      AS VARCHAR(36)), '|'
            ,CAST(tg.[TESTGROUPID] AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT))          AS TestGroupKey
    ,tg.[DATAAREAID]                     AS CMPNY
    ,tg.[TESTGROUPID]                    AS TestGroupId
    ,tg.[DESCRIPTION]                    AS TestGroupDescription
    ,tg.[ACCEPTABLEQUALITYLEVEL]         AS AcceptableQualityLevel
    ,tg.[testdestructive_$label]         AS IsDestructive

    ,'D365FO'                            AS Source
    ,CONVERT(datetime2(3), NULL)         AS RecordEffectiveStartDate
    ,CONVERT(datetime2(3), NULL)         AS RecordEffectiveEndDate
    ,CONVERT(int, NULL)                  AS RecordStatus

FROM [WH_Raw].[dbo].[INVENTTESTGROUP] tg

UNION ALL

SELECT
     -1                                  AS TestGroupKey
    ,'Unknown'                           AS CMPNY
    ,'Unknown'                           AS TestGroupId
    ,NULL                                AS TestGroupDescription
    ,NULL                                AS AcceptableQualityLevel
    ,NULL                                AS IsDestructive
    ,'D365FO'                            AS Source
    ,NULL                                AS RecordEffectiveStartDate
    ,NULL                                AS RecordEffectiveEndDate
    ,NULL                                AS RecordStatus