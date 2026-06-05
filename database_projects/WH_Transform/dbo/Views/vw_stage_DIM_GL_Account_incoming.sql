/****** Object:  View [dbo].[vw_stage_DIM_GL_Account_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.vw_stage_DIM_GL_Account_incoming	

CREATE     VIEW [dbo].[vw_stage_DIM_GL_Account_incoming]			
AS			
SELECT 			
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(m.mainaccountid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS GL_AccountKey
	, m.mainaccountid  GL_Account_Number
	, m.name GL_Account_Name
	--, m.accountcategoryref Account_Category
 	, m.accountcategoryref    --******************
    , c.accountcategory  Account_Category    --******************
   , c.description Account_Category_Name
	, m.type  Account_Type
	, m.type_$label Account_Type_Description
    , c.accounttype  Category_Account_Type    --******************
    , c.accounttype_$label Category_Account_Type_Description    --******************

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

FROM WH_Raw.dbo.mainaccount m	
  LEFT JOIN WH_Raw.dbo.mainaccountcategory c
    ON m.accountcategoryref = c.accountcategoryref

UNION ALL

SELECT -1 [GL_AccountKey]
, 'Unknown' GL_Account_Number
, 'Unknown' GL_Account_Name
, NULL accountcategoryref
, NULL Account_Category
, NULL Account_Category_Name
, NULL Account_Type
, NULL Account_Type_Description
, NULL Category_Account_Type
, NULL Category_Account_Type_Description
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]

GO

