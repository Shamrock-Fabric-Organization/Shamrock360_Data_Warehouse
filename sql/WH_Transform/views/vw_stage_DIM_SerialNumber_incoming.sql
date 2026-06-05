-- Auto Generated (Do not modify) 3EEF590986E903EE7699652963D2F34B400FC02921E3CE2A9CB1A6D5F3B55A25
/****** Object:  View [dbo].[vw_stage_DIM_SerialNumber_incoming]    Script Date: 4/17/2026 2:31:30 PM ******/
/****** Object:  View [dbo].[vw_stage_DIM_SerialNumber_incoming]    Script Date: 3/10/2026 9:55:52 AM ******/
/****** Object:  View [dbo].[vw_stage_DIM_SerialNumber_incoming]    Script Date: 3/9/2026 10:44:31 AM ******/
/****** Object:  View [dbo].[vw_stage_DIM_SerialNumber_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.vw_stage_DIM_SerialNumber_incoming	

CREATE           VIEW [dbo].[vw_stage_DIM_SerialNumber_incoming]			
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
			--,CAST(itemid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SerialNumberKey
	,dataareaid CMPNY
	,inventserialid SerialNumber
	--,itemid ProductID
	,proddate
	,description
	,rfidtagid

	,SerialNumberNoteName
	,SerialNumberNote
	,SeralNumberNoteCreatedBy
	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

FROM 
	( select distinct 	
	s.dataareaid 
	,s.inventserialid 
	--,itemid 
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
	--,itemid 
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
        )
    ) AS BINARY(8)) AS BIGINT)) AS SerialNumberKey
	,dataareaid CMPNY
	,inventserialid SerialNumber
	--,'N/A' ProductID
	,'01/01/1900' proddate
	,NULL description
	,NULL rfidtagid

	, NULL SerialNumberNoteName
	, NULL SerialNumberNote
	, NULL SeralNumberNoteCreatedBy

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus
FROM 
(
	select distinct dataareaid, inventserialid
	from WH_Raw.dbo.inventdim
	where not (inventserialid  in
				(select distinct inventserialid FROM WH_Raw.dbo.inventserial))
				AND inventserialid is not null
) z

UNION ALL

SELECT -1 [SerialNumberKey]
, 'Unknown' CMPNY
, 'Unknown' SerialNumber
--, 'Unknown' ProductID
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