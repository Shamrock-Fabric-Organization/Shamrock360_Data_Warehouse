--USE WH_Transform

CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimAddress]
AS
BEGIN

    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Append;


    -- --------------------------------------------------------
    -- Step 1: Net-new records
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Address_New AS
    SELECT *
    FROM vw_stage_NewAddress;


    -- --------------------------------------------------------
    -- Step 2: (SCD Type 2 — expire changed records)
    -- Commented out — Type 1 only for this dimension.
    -- --------------------------------------------------------
    --CREATE TABLE stage_tbl_DIM_Address_Expired AS
    --SELECT Target.*
    --FROM tbl_DIM_Address AS Target
    --JOIN vw_stage_DIM_Address_incoming AS Source
    --    ON  Target.[AddressRecId] = Source.[AddressRecId]
    --WHERE Target.RecordStatus = 1
    --    AND (
    --        ISNULL(Target.[Location],     '') <> ISNULL(Source.[Location],     '')
    --        OR ISNULL(Target.[Street],    '') <> ISNULL(Source.[Street],       '')
    --        OR ISNULL(Target.[City],      '') <> ISNULL(Source.[City],         '')
    --        OR ISNULL(Target.[State],     '') <> ISNULL(Source.[State],        '')
    --        OR ISNULL(Target.[ZipCode],   '') <> ISNULL(Source.[ZipCode],      '')
    --        OR ISNULL(Target.[Country],   '') <> ISNULL(Source.[Country],      '')
    --        OR ISNULL(Target.[ValidFrom],  '1900-01-01') <> ISNULL(Source.[ValidFrom],  '1900-01-01')
    --        OR ISNULL(Target.[ValidTo],    '1900-01-01') <> ISNULL(Source.[ValidTo],    '1900-01-01')
    --        OR ISNULL(Target.[LocationName], '') <> ISNULL(Source.[LocationName], '')
    --        );


    -- --------------------------------------------------------
    -- Step 3: Type 1 changes — overwrite in place
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Address_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_Address AS Target
    JOIN vw_stage_DIM_Address_incoming AS Source
        ON  Target.[AddressRecId] = Source.[AddressRecId]
            AND Source.[Source]='D365FO'
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.[Location],      0) <> ISNULL(Source.[Location],      0)
            OR ISNULL(Target.[Street],     '') <> ISNULL(Source.[Street],        '')
            OR ISNULL(Target.[City],       '') <> ISNULL(Source.[City],          '')
            OR ISNULL(Target.[State],      '') <> ISNULL(Source.[State],         '')
            OR ISNULL(Target.[ZipCode],    '') <> ISNULL(Source.[ZipCode],       '')
            OR ISNULL(Target.[Country],    '') <> ISNULL(Source.[Country],       '')
            OR ISNULL(Target.[ValidFrom],  '1900-01-01') <> ISNULL(Source.[ValidFrom],  '1900-01-01')
            OR ISNULL(Target.[ValidTo],    '1900-01-01') <> ISNULL(Source.[ValidTo],    '1900-01-01')
            OR ISNULL(Target.[LocationName], '') <> ISNULL(Source.[LocationName], '')
            )

    -- Build updated record set (target keys preserved, source attribute values)
    CREATE TABLE stage_tbl_DIM_Address_Type1_OnlyUpdatedRecords AS
    SELECT
         Target.[AddressKey]
        ,Target.[AddressRecId]
        ,Source.[Location]
        ,Source.[Street]
        ,Source.[City]
        ,Source.[State]
        ,Source.[ZipCode]
        ,Source.[Country]
        ,Source.[ValidFrom]
        ,Source.[ValidTo]
        ,Source.[LocationName]
        ,Target.[Source]
        ,Target.[RecordEffectiveStartDate]
        ,Target.[RecordEffectiveEndDate]
        ,Target.[RecordStatus]
    FROM stage_tbl_DIM_Address_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_Address_incoming AS Source
        ON  Target.[AddressRecId] = Source.[AddressRecId]
          AND Source.[Source]='D365FO'

    -- --------------------------------------------------------
    -- Step 4: Deleted records (in DIM, no longer in source)
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Address_Deleted AS
    SELECT *
    FROM tbl_DIM_Address AS Target
    WHERE Target.RecordStatus = 1
        AND Target.Source = 'D365FO'
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_Address_incoming AS Source
            WHERE Source.[AddressRecId] = Target.[AddressRecId]
              AND Source.[Source] = 'D365FO'
        );


    -- --------------------------------------------------------
    -- Step 5: Assemble Final set
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Address_Final AS

        -- Unchanged active records
        SELECT *
        FROM tbl_DIM_Address
        WHERE RecordStatus = 1
            AND [Source] = 'D365FO'
            AND [AddressRecId] NOT IN (
                SELECT [AddressRecId] FROM stage_tbl_DIM_Address_Deleted
                UNION
                SELECT [AddressRecId] FROM stage_tbl_DIM_Address_Type1_UpdatesNeeded
            )
        ----UNION ALL
        ----SELECT *
        ----FROM tbl_DIM_Address
        ----WHERE RecordStatus = 1
        ----    AND [Source] <> 'D365FO'

        --UNION ALL
        ---- Expire old versions (SCD2 — commented out)
        --SELECT
        --     [AddressKey], [AddressRecId], [Location], [Street], [City], [State]
        --    ,[ZipCode], [Country], [ValidFrom], [ValidTo], [LocationName]
        --    ,[Source], [RecordEffectiveStartDate]
        --    ,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
        --    ,0 AS RecordStatus
        --FROM stage_tbl_DIM_Address_Expired

        --UNION ALL
        ---- New versions of changed records (SCD2 — commented out)
        --SELECT
        --     s.[AddressKey], s.[AddressRecId], s.[Location], s.[Street], s.[City], s.[State]
        --    ,s.[ZipCode], s.[Country], s.[ValidFrom], s.[ValidTo], s.[LocationName]
        --    ,s.[Source]
        --    ,CAST(GETDATE() AS DATETIME2(3))              AS RecordEffectiveStartDate
        --    ,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
        --    ,1 AS RecordStatus
        --FROM vw_stage_DIM_Address_incoming s
        --JOIN stage_tbl_DIM_Address_Expired e
        --    ON s.[AddressRecId] = e.[AddressRecId]

        UNION ALL

        -- Net-new records
        SELECT * FROM stage_tbl_DIM_Address_New

        UNION ALL

        -- Type 1 updated records (attribute values replaced)
        SELECT * FROM stage_tbl_DIM_Address_Type1_OnlyUpdatedRecords

        UNION ALL

        -- Expire deleted records
        SELECT
             [AddressKey]
            ,[AddressRecId]
            ,[Location]
            ,[Street]
            ,[City]
            ,[State]
            ,[ZipCode]
            ,[Country]
            ,[ValidFrom]
            ,[ValidTo]
            ,[LocationName]
            ,[Source]
            ,[RecordEffectiveStartDate]
            ,GETDATE()  AS RecordEffectiveEndDate
            ,0          AS RecordStatus
        FROM stage_tbl_DIM_Address_Deleted;


    -- --------------------------------------------------------
    -- Step 6: Build Append table (historical + Final)
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Append;

    CREATE TABLE stage_tbl_DIM_Address_Append AS
    SELECT *
    FROM tbl_DIM_Address f
    WHERE Source = 'D365FO'
        AND NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_Address_Final d
        WHERE d.[AddressRecId]             = f.[AddressRecId]
          AND d.[RecordEffectiveStartDate] = f.[RecordEffectiveStartDate]
          AND d.source='D365FO'
    )

    UNION ALL

    SELECT *
    FROM tbl_DIM_Address
    WHERE RecordStatus = 1
        AND [Source] <> 'D365FO'


    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_Address_Final
    ORDER BY
         [AddressRecId]
        ,[RecordEffectiveStartDate];


    -- --------------------------------------------------------
    -- Step 7: Replace dimension table
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS tbl_DIM_Address;

    CREATE TABLE tbl_DIM_Address AS
    SELECT *
    FROM stage_tbl_DIM_Address_Append;


    -- --------------------------------------------------------
    -- Step 8: Clean up staging tables
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_Address_Type1_OnlyUpdatedRecords;

    ---- Step 9: Drop incoming view (not needed when using a view)
    --DROP VIEW IF EXISTS vw_stage_DIM_Address_incoming;

END;