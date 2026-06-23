-- Auto Generated (Do not modify) A251754DDD6AE6EC882121427AF175F9ACE58FD686EF00948A41B80D699C78F1


--use WH_Transform

/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_Route_incoming]	

CREATE   VIEW [dbo].[vw_stage_DIM_Route_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(r.routeid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS RouteKey
    , r.dataareaid CMPNY
    , r.routeid RouteID
    , r.name  RouteName
    --, r.approver
    , w.personnelnumber ApproverPersonnelNumber
    , dpt.name ApproverName
    --, r.approved
    , r.approved_$label Approved
    --, r.checkroute
    , r.checkroute_$label CheckRoute
    , coalesce(rt.routetype, 'Other') RouteType

	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus

  FROM WH_Raw.dbo.routetable r
    LEFT JOIN WH_Raw.dbo.HCMWorker w		
	    ON r.approver = w.recid	
    LEFT JOIN WH_Raw.dbo.DirPartyTable DPT		
	    ON w.person = DPT.recid	
    LEFT JOIN WH_Raw.dbo.EDW_RouteType rt
        ON r.routeid = rt.routeno

UNION ALL

SELECT -1 [RouteKey]
, 'Unknown' CMPNY
, 'Unknown' RouteID
, NULL RouteName
, NULL ApproverPersonnelNumber
, NULL ApproverName
, NULL approved
, NULL checkroute
, 'Other' RouteType

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]