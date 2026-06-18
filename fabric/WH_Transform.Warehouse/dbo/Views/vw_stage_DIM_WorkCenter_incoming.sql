-- Auto Generated (Do not modify) 8E9CE925924DF3D33D72223E7CBB94F83260593748FC0730146DC71FDEAF942E
--use WH_transform
--go



/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
----drop  VIEW dbo.[vw_stage_DIM_WorkCenter_incoming]	

CREATE       VIEW [dbo].[vw_stage_DIM_WorkCenter_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(wct.wrkctrid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS WorkCenterKey
, wct.dataareaid CMPNY
, wct.wrkctrid WorkCenterID
, wct.name WorkCenterName
, wct.wrkctrid +': '+ wct.name WorkCenterIDandName
, wct.wrkctrtype
, wct.wrkctrtype_$label
, wct.effectivitypct
, wct.errorpct
, wct.operationschedpct
, wct.processcategoryid
, wct.routegroupid
, case when wct.wrkctrtype=5 then wct.wrkctrid else isnull(rg.ResourceGroup, 'None') end ResourceGroup
, case when wct.wrkctrtype=5 then wct.name else isnull(rg.ResourceGroupName, 'None') end ResourceGroupName
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus
from WH_Raw.dbo.wrkctrtable wct
left join WH_Raw.dbo.wrkctrresourcegroupresource wcrgr
  on wct.dataareaid = wcrgr.dataareaid
    and wct.wrkctrid = wcrgr.wrkctrid
    and wcrgr.validto = '12/31/2154'
left join (select wcrg.recid, wcrg.dataareaid, wcrg.wrkctrid ResourceGroup, w.name ResourceGroupName
            from WH_Raw.dbo.wrkctrresourcegroup wcrg
              join WH_Raw.dbo.wrkctrtable w
                on wcrg.dataareaid = w.dataareaid
                  and wcrg.wrkctrid = w.wrkctrid) rg
  on wcrgr.resourcegroup = rg.recid

UNION ALL

SELECT -1 [WorkCenterKey]
, 'Unknown' [CMPNY]
, 'Unknown' [WorkCenterID]
, 'Unknown' [WorkCenterName]
, 'Unknown: Unknown' WorkCenterIDandName
, NULL wrkctrtype
, NULL wrkctrtype_$label
, NULL effectivitypct
, NULL errorpct
, NULL operationschedpct
, NULL processcategoryid
, NULL routegroupid
, 'Unknown' ResourceGroup
, 'Unknown' ResourceGroupName
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]