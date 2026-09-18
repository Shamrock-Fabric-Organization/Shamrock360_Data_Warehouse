
CREATE OR ALTER    VIEW [dbo].[vw_stage_DIM_Legal_Entity_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(d.fno_id AS VARCHAR(20))

     ) ) AS BINARY(8)) AS BIGINT))     AS Legal_EntityKey

	,d.fno_id	 CMPNY
	,d.Name	 Legal_Entity_Name
	, l.accountingcurrency 
	, l.reportingcurrency
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus

FROM WH_Raw.dbo.dataarea 	d
LEFT JOIN WH_Raw.dbo.ledger  l
  ON d.fno_id = l.name

UNION ALL

SELECT -1 [Legal_EntityKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Legal_Entity_Name]
, 'Unknown' [accountingcurrency]
, 'Unknown' [reportingcurrency]
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]
