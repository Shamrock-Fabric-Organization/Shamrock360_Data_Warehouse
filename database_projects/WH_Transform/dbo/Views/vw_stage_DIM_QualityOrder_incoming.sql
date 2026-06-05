/****** Object:  View [dbo].[vw_stage_DIM_QualityOrder_incoming]    Script Date: 5/27/2026 8:28:07 AM ******/

CREATE       VIEW [dbo].[vw_stage_DIM_QualityOrder_incoming]			
AS			
SELECT 			
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(iqot.qualityorderid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS QualityOrderKey
	, iqot.dataareaid CMPNY
	, isnull(iqot.qualityorderid,'') QualityOrderID
	--, iqot.accountrelation
	, iqot.inventrefid
	, iqot.inventreftransid
	, iqot.itemid  ProductID
	, iqot.itemsamplingid
	, iqot.oprnum
	, iqot.orderstatus
	, iqot.orderstatus_$label
	, iqot.qty
	, iqot.referencetype
	, iqot.referencetype_$label
	, iqot.routeid
	, iqot.testgroupid

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

from WH_Raw.dbo.inventqualityordertable iqot


UNION ALL

SELECT -1 [QualityOrderKey]
, 'Unknown' CMPNY
, 'Unknown' QualityOrderID

	, NULL inventrefid
	, NULL inventreftransid
	, NULL ProductID
	, NULL itemsamplingid
	, NULL oprnum
	, NULL orderstatus
	, NULL orderstatus_$label
	, NULL qty
	, NULL referencetype
	, NULL referencetype_$label
	, NULL routeid
	, NULL testgroupid

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]

GO

