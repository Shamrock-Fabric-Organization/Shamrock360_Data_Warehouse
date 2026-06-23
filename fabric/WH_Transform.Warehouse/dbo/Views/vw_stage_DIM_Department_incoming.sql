-- Auto Generated (Do not modify) F3382C7414B68A365A32A73CC395664D9D47C51479F7087FB3C870655A3555D8

/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_Department_incoming]	

CREATE   VIEW [dbo].[vw_stage_DIM_Department_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST([value] AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS DepartmentKey
	, value	Department
	, Name	 Department_Name
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus
FROM WH_Raw.dbo.DIMATTRIBUTEOMDEPARTMENT 

UNION ALL

SELECT -1 [DepartmentKey]
, 'Unknown' [Department_ID]
, 'Unknown' [Department_Name]
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]