CREATE OR ALTER VIEW [dbo].[vw_stage_DIM_SerialNumber_incoming]
AS
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(inventserialid AS VARCHAR(100))
            ,CAST(itemid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SerialNumberKey
    ,dataareaid CMPNY
    ,inventserialid SerialNumber
    ,itemid ProductID
    ,proddate
    ,description
    ,rfidtagid

    ,SerialNumberNoteName
    ,SerialNumberNote
    ,SeralNumberNoteCreatedBy
    ,'D365FO'    Source
    ,NULL    RecordEffectiveStartDate
    ,NULL    RecordEffectiveEndDate
    ,NULL    RecordStatus

FROM
    ( select distinct
    s.dataareaid
    ,s.inventserialid
    ,s.itemid
    ,max(s.proddate) proddate
    ,s.description
    ,s.rfidtagid
    , dr.name SerialNumberNoteName
    , dr.NOTES SerialNumberNote
    , dr.createdby SeralNumberNoteCreatedBy

    FROM WH_Raw.dbo.inventserial s
        LEFT JOIN (SELECT REFRECID
                , STRING_AGG(NOTES, ' === ') NOTES
                , STRING_AGG(NAME, ' === ') NAME
                , STRING_AGG(CREATEDBY, ' === ') CREATEDBY
                FROM WH_Raw.dbo.DOCUREF
                WHERE REFTABLEID = 29060 --INVENTSERIAL
                  AND TYPEID='Note'
                GROUP BY REFRECID) dr
        ON dr.REFRECID = s.RECID

    group by s.dataareaid
    ,s.inventserialid
    ,s.itemid
    ,s.description
    ,s.rfidtagid
    , dr.name
    , dr.NOTES
    , dr.createdby  ) a

UNION ALL

select distinct
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(inventserialid AS VARCHAR(100))
            ,CAST(itemid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SerialNumberKey
    ,dataareaid CMPNY
    ,inventserialid SerialNumber
    ,itemid ProductID
    ,'01/01/1900' proddate
    ,NULL description
    ,NULL rfidtagid

    , NULL SerialNumberNoteName
    , NULL SerialNumberNote
    , NULL SeralNumberNoteCreatedBy

    ,'D365FO'    Source
    ,NULL    RecordEffectiveStartDate
    ,NULL    RecordEffectiveEndDate
    ,NULL    RecordStatus
FROM
(
    -- Serial numbers used on an inventory dimension that have no InventSerial
    -- master row for that item. InventDim carries no ItemId, so the item is
    -- taken from the records that reference the same InventDimId. The four
    -- sources are exactly the paths by which the four consuming facts reach a
    -- serial -- see section 4.2.3.
    select distinct id.dataareaid, id.inventserialid, x.itemid
    from WH_Raw.dbo.inventdim id
    join (
            select dataareaid, inventdimid, itemid from WH_Raw.dbo.inventsum
            union
            select dataareaid, inventdimid, itemid from WH_Raw.dbo.inventtrans
            union
            select dataareaid, inventdimid, itemid from WH_Raw.dbo.inventqualityordertable
            union
            select dataareaid, inventdimid, itemid from WH_Raw.dbo.whsworklinecyclecount
         ) x
        on  x.inventdimid = id.inventdimid
        and x.dataareaid  = id.dataareaid
    where id.inventserialid is not null
      and id.inventserialid <> ''
      and not exists (
            select 1
            from WH_Raw.dbo.inventserial s
            where s.inventserialid = id.inventserialid
              and s.dataareaid     = id.dataareaid
              and s.itemid         = x.itemid)
) z

UNION ALL

-- Serials in use on an inventory dimension whose item cannot be resolved from
-- any of the four sources in branch two. Kept with an explicit 'Unknown' marker
-- rather than dropped, so the fact-side fallback in 4.2.5 has a row to find.
-- 'Unknown' matches the existing platform convention for unresolvable members.
select distinct
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(inventserialid AS VARCHAR(100))
            ,CAST(itemid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SerialNumberKey
    ,dataareaid CMPNY
    ,inventserialid SerialNumber
    ,itemid ProductID
    ,'01/01/1900' proddate
    ,NULL description
    ,NULL rfidtagid

    , NULL SerialNumberNoteName
    , NULL SerialNumberNote
    , NULL SeralNumberNoteCreatedBy

    ,'D365FO'    Source
    ,NULL    RecordEffectiveStartDate
    ,NULL    RecordEffectiveEndDate
    ,NULL    RecordStatus
FROM
(
    select distinct id.dataareaid, id.inventserialid, 'Unknown' itemid
    from WH_Raw.dbo.inventdim id
    where id.inventserialid is not null
      and id.inventserialid <> ''
      and not exists (
            select 1
            from WH_Raw.dbo.inventserial s
            where s.inventserialid = id.inventserialid
              and s.dataareaid     = id.dataareaid)
      and not exists (
            select 1
            from (
                    select dataareaid, inventdimid from WH_Raw.dbo.inventsum
                    union
                    select dataareaid, inventdimid from WH_Raw.dbo.inventtrans
                    union
                    select dataareaid, inventdimid from WH_Raw.dbo.inventqualityordertable
                    union
                    select dataareaid, inventdimid from WH_Raw.dbo.whsworklinecyclecount
                 ) r
            where r.inventdimid = id.inventdimid
              and r.dataareaid  = id.dataareaid)
) w

UNION ALL

SELECT -1 [SerialNumberKey]
, 'Unknown' CMPNY
, 'Unknown' SerialNumber
, 'Unknown' ProductID
, NULL proddate
, NULL description
, NULL rfidtagid

, NULL SerialNumberNoteName
, NULL SerialNumberNote
, NULL SeralNumberNoteCreatedBy

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]