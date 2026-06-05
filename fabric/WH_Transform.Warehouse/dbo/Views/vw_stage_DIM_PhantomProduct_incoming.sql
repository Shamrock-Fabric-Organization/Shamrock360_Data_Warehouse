-- Auto Generated (Do not modify) 87599916A546078082FC93CB69D8A8C9CE936A6A54468B6B423BBD8C526F02A8
/****** Object:  View [dbo].[vw_stage_DIM_Product_incoming]    Script Date: 9/16/2025 1:44:46 PM ******/
--drop  VIEW dbo.vw_stage_DIM_Product_incoming	

CREATE     VIEW [dbo].[vw_stage_DIM_PhantomProduct_incoming]			
AS			
WITH VersionCandidates AS (
  SELECT
        v.RecId               AS BOMVersionRecId,
        v.BOMId,
        v.dataareaid,
        v.ItemId,
        d.InventSiteId,
        v.FromQty,
        v.Active,
        v.Approved,
        v.FromDate,
        v.ToDate,
        v.InventDimId,
        -- prefer exact site match over general/no-site
        CASE WHEN NULLIF(LTRIM(RTRIM(d.InventSiteId)), '') IS NOT NULL THEN 1 ELSE 0 END AS IsSiteSpecific
    FROM WH_Raw.dbo.BOMVersion AS v
    JOIN WH_Raw.dbo.inventtable IT
        ON IT.dataareaid = v.dataareaid
          AND IT.itemid = v.itemid
    LEFT JOIN WH_Raw.dbo.InventDim AS d
        ON d.InventDimId = v.InventDimId
       AND d.dataAreaId  = v.dataAreaId
    WHERE 
      CAST(GETDATE() AS DATE) >= CAST(v.FromDate AS DATE)
      AND CAST(GETDATE() AS DATE) <= CAST(COALESCE(case when v.ToDate='01/01/1900' then '12/31/2154' else v.ToDate end, '2154-12-31') AS DATE)
      AND COALESCE(v.Active,   0) = 1
      AND COALESCE(v.Approved, 0) = 1
      AND IT.phantom=1
),
Ranked AS (
    SELECT
        BOMVersionRecId, BOMId, dataareaid, ItemId, InventSiteId, FromDate, ToDate, FromQty, IsSiteSpecific,
        ROW_NUMBER() OVER (
            PARTITION BY ItemId
            ORDER BY IsSiteSpecific DESC, CAST(FromDate AS DATE) DESC, FromQty DESC
        ) AS rn
    FROM VersionCandidates
)
SELECT 	
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(IT.ItemID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS PhantomProductKey
	,IT.dataareaid	  CMPNY	
	,IT.ItemID	 Product_ID
	,ERPT.name	 Phantom_Product
	,IT.STICommertialName	Commercial_Name
	,r.BOMid	ActiveFormula_ID
			
	,SC_bl.Level3Category	 Business_Line	 --Type 2 from product attributes
	,SC_bl.Level4Category	 Product_Line	 --Type 2 from product attributes
	,SC_t.Level3Category	 Technology	 --Type 2 from product attributes
	,SC_t.Level4Category	 Material	 --Type 2 from product attributes

	,Convert(varchar(500),NULL)	Description_Internal
	,Convert(varchar(500),NULL)	Description_External
	,Convert(varchar(500),NULL)	Application_Benefit

	,NULL	 RecordEffectiveStartDate	 --SCD2 control field
	,NULL	 RecordEffectiveEndDate	 --SCD2 control field
	,NULL	 RecordStatus	 --SCD2 control field
	,'D365FO'	 Source    --	is D365FO the correct value?

FROM WH_Raw.dbo.InventTable IT	
LEFT JOIN Ranked r
    ON IT.dataareaid = r.dataareaid
        AND IT.itemid = r.itemid
        AND r.rn=1
LEFT JOIN WH_Raw.dbo.EcoResProductTranslation ERPT			
	ON IT.product = ERPT.product		
		AND ERPT.languageid = 'en-US'	
LEFT JOIN WH_Raw.dbo.EcoResProduct ERP			
	ON IT.product = ERP.recid		
LEFT JOIN WH_Raw.dbo.vwItemSalesCategories SC_bl
	ON IT.Product = SC_bl.Product
	    AND SC_bl.Level2Category = 'Business Line'
LEFT JOIN WH_Raw.dbo.vwItemSalesCategories SC_t
	ON IT.Product = SC_t.Product
	    AND SC_t.Level2Category = 'Technology'
WHERE ISNULL(IT.phantom,0) = 1

UNION ALL

SELECT -1 [PhantomProductKey]
, 'Unknown' [CMPNY]
, 'Unknown' [Product_ID]
, 'Unknown' [Phantom_Product]
, NULL [Commercial_Name]
, NULL [ActiveFormula_ID]
, NULL [Business_Line]
, NULL [Product_Line]
, NULL [Technology]
, NULL [Material]
, NULL [Description_Internal]
, NULL [Description_External]
, NULL [Application_Benefit]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]
, 'D365FO' [Source]