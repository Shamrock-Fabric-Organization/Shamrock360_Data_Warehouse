-- Auto Generated (Do not modify) 89D5393B227809C3171B9746450EAA42B8D48334473515F61818E25F27BF75F1
/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_Legal_Entity_incoming]	

CREATE     VIEW [dbo].[vw_stage_DIM_Legal_Entity_incoming]			
AS			
SELECT 		
	CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())))	 Legal_EntityKey
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