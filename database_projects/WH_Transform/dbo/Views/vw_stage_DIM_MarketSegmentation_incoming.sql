/****** Object:  View [dbo].[vw_stage_DIM_MarketSegmentation_incoming]    Script Date: 6/2/2026 9:31:10 AM ******/

----select * from vw_stage_DIM_MarketSegmentation_incoming

CREATE     VIEW [dbo].[vw_stage_DIM_MarketSegmentation_incoming]
AS

-- ============================================================
-- Branch 1: Legacy records (source = wh_raw.marketsegmentation)
-- ============================================================
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(
                CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
                     WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
                     WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
                     WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
                     else substring(m.CustomerID,2,3) end
                + '-' + COALESCE(m.D365_CustomerID, m.CustomerID, 'UnknownCustomer')
                + '-' + COALESCE(m.D365_ProductID,  m.ProductID,  'UnknownProduct')
                AS VARCHAR(200))
        )
    ) AS BINARY(8)) AS BIGINT)) AS MarketSegmentationKey

,CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
      WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
      WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
      WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
      else substring(m.CustomerID,2,3) end  CMPNY

,COALESCE(m.D365_CustomerID, m.CustomerID) AS CustomerID
,COALESCE(m.D365_ProductID,  m.ProductID)  AS ProductID

,CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
      WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
      WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
      WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
      else substring(m.CustomerID,2,3) end
 + '-' + COALESCE(m.D365_CustomerID, m.CustomerID, 'UnknownCustomer')
 + '-' + COALESCE(m.D365_ProductID,  m.ProductID,  'UnknownProduct')  CPCID

,m.[Legacy]  LegacyCPCID

-- Industry: user override wins when IndustryIsOverride = 1; marketsegmentation is live fallback otherwise
,CASE WHEN u.IndustryIsOverride    = 1 THEN u.Industry    ELSE m.Industry    END  Industry
,CASE WHEN u.SubIndustryIsOverride = 1 THEN u.SubIndustry ELSE m.SubIndustry END  SubIndustry

,CASE WHEN m.D365_CustomerID IS NULL THEN 'No' ELSE 'Yes' END  AccountTranslatedToD365
,CASE WHEN m.D365_ProductID  IS NULL THEN 'No' ELSE 'Yes' END  ProductTranslatedToD365

,CONVERT([datetime2](3), NULL)  RecordEffectiveStartDate  --SCD2 control field
,CONVERT([datetime2](3), NULL)  RecordEffectiveEndDate    --SCD2 control field
,CONVERT(int, NULL)             RecordStatus              --SCD2 control field
,'Legacy'                       Source

FROM
(
    SELECT *
    FROM
    (
        SELECT
             ms.*
            ,ROW_NUMBER() OVER (
                PARTITION BY
                    CASE WHEN substring(CustomerID,2,3) in ('001','002') then '101'
                         WHEN substring(CustomerID,2,3) = '101' THEN '301'
                         WHEN substring(CustomerID,2,3) = '201' THEN '501'
                         WHEN substring(CustomerID,2,3) = '999' THEN '301'
                         else substring(CustomerID,2,3) end,
                    COALESCE(lc.D365_CustomerID, ms.CustomerID),
                    COALESCE(lp.D365_ProductID,  ms.ProductID)
                ORDER BY
                    CASE WHEN substring(CustomerID,2,3) in ('001','002') then '101'
                         WHEN substring(CustomerID,2,3) = '101' THEN '301'
                         WHEN substring(CustomerID,2,3) = '201' THEN '501'
                         WHEN substring(CustomerID,2,3) = '999' THEN '301'
                         else substring(CustomerID,2,3) end,
                    COALESCE(lc.D365_CustomerID, ms.CustomerID),
                    COALESCE(lp.D365_ProductID,  ms.ProductID),
                    ms.ProductID
            ) AS dedup_rn
            ,lc.D365_CustomerID
            ,lp.D365_ProductID
            ,CASE WHEN substring(ms.CustomerID,2,3) in ('001','002') then '101'
                  WHEN substring(ms.CustomerID,2,3) = '101' THEN '301'
                  WHEN substring(ms.CustomerID,2,3) = '201' THEN '501'
                  WHEN substring(ms.CustomerID,2,3) = '999' THEN '301'
                  else substring(ms.CustomerID,2,3) end  CMPNY
        FROM wh_raw.[dbo].[marketsegmentation] ms
        LEFT JOIN WH_Curated.[dbo].[XREF_Customer_ID] lc
            ON ms.customerid = lc.Apollo_CustomerID
        LEFT JOIN WH_Curated.[dbo].[XREF_Product_ID] lp
            ON ms.productid = lp.Apollo_ProductID
    ) prelim1
    WHERE dedup_rn = 1
) m

LEFT JOIN [dbo].[tbl_APP_MarketSegmentationDataForUpdates] u
    ON  CASE WHEN LEFT(m.CustomerID,1) <> 'C'
                THEN CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
                          WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
                          WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
                          WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
                          else substring(m.CustomerID,2,3) end
                ELSE m.CMPNY
            END = u.CMPNY
    AND COALESCE(m.D365_CustomerID, m.CustomerID) = u.CustomerID
    AND COALESCE(m.D365_ProductID,  m.ProductID)  = u.ProductID
-- Outer XREF joins removed (v4): D365_CustomerID / D365_ProductID resolved inside prelim1.

--where CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
--		 WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
--		 WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
--		 WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
--		 else substring(m.CustomerID,2,3) end
--	+ '-' + COALESCE(m.D365_CustomerID, m.CustomerID, 'UnknownCustomer')
--	+ '-' + COALESCE(m.D365_ProductID,  m.ProductID,  'UnknownProduct')  = '101-C000232-10519'


UNION ALL

-- ============================================================
-- Branch 2: D365FO records (SalesTable/SalesLine + missing records)
-- Industry/SubIndustry: user override only when IsOverride = 1.
-- No marketsegmentation fallback — these records are NOT in
-- marketsegmentation (excluded via NOT EXISTS). Intentional by design.
-- ============================================================
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(CPCID AS VARCHAR(200))
        )
    ) AS BINARY(8)) AS BIGINT)) AS MarketSegmentationKey
    ,CMPNY
    ,CustomerID
    ,ProductID
    ,CPCID
    ,LegacyCPCID
    ,Industry
    ,SubIndustry
    ,AccountTranslatedToD365
    ,ProductTranslatedToD365
    ,CONVERT([datetime2](3), NULL)  RecordEffectiveStartDate  --SCD2 control field
    ,CONVERT([datetime2](3), NULL)  RecordEffectiveEndDate    --SCD2 control field
    ,CONVERT(int, NULL)             RecordStatus              --SCD2 control field
    ,'D365FO'                       Source

FROM
(
    -- Sub-branch 2a: records in D365 SalesTable/SalesLine not already in Branch 1
    SELECT DISTINCT
         ST.dataareaid                                CMPNY
        ,ST.custaccount                               CustomerID
        ,SL.itemid                                    ProductID
        ,ST.dataareaid + '-' + ST.custaccount + '-' + SL.itemid  CPCID
        ,CONVERT(varchar(8000), NULL)                 LegacyCPCID
        -- Industry: user override only; NULL when IsOverride = 0/NULL (no marketsegmentation fallback)
        ,CASE WHEN u.IndustryIsOverride    = 1 THEN u.Industry    END  Industry
        ,CASE WHEN u.SubIndustryIsOverride = 1 THEN u.SubIndustry END  SubIndustry
        ,'Yes'                                        AccountTranslatedToD365
        ,'Yes'                                        ProductTranslatedToD365
    FROM WH_Raw.dbo.salestable ST
    JOIN WH_Raw.dbo.SalesLine SL
        ON  ST.salesid     = SL.salesid
        AND ST.dataareaid  = SL.dataareaid
    JOIN WH_Raw.dbo.custtable CT
        ON  ST.custaccount = CT.accountnum
        AND ST.dataareaid  = CT.dataareaid
        AND NOT(CT.custgroup IN ('800','999'))
    LEFT JOIN [dbo].[tbl_APP_MarketSegmentationDataForUpdates] u
        ON  ST.dataareaid  = u.CMPNY
        AND ST.custaccount = u.CustomerID
        AND SL.itemid      = u.ProductID

    WHERE NOT (ST.dataareaid + '-' + ST.custaccount + '-' + SL.itemid IN
                (
                SELECT DISTINCT
                    CASE WHEN substring(m.CustomerID,2,3) in ('001','002') then '101'
                             WHEN substring(m.CustomerID,2,3) = '101' THEN '301'
                             WHEN substring(m.CustomerID,2,3) = '201' THEN '501'
                             WHEN substring(m.CustomerID,2,3) = '999' THEN '301'
                             else substring(m.CustomerID,2,3) end
                    + '-' + COALESCE(lc.D365_CustomerID, m.CustomerID, 'UnknownCustomer')
                    + '-' + COALESCE(lp.D365_ProductID,  m.ProductID,  'UnknownProduct')  CPCID
                FROM
                (
                    SELECT *
                    FROM
                    (
                        SELECT ms.*, ROW_NUMBER() OVER (
                            PARTITION BY
                                CASE WHEN substring(CustomerID,2,3) in ('001','002') then '101'
                                     WHEN substring(CustomerID,2,3) = '101' THEN '301'
                                     WHEN substring(CustomerID,2,3) = '201' THEN '501'
                                     WHEN substring(CustomerID,2,3) = '999' THEN '301'
                                     else substring(CustomerID,2,3) end,
                                COALESCE(lc.D365_CustomerID, ms.CustomerID),
                                COALESCE(lp.D365_ProductID,  ms.ProductID)
                            ORDER BY
                                CASE WHEN substring(CustomerID,2,3) in ('001','002') then '101'
                                     WHEN substring(CustomerID,2,3) = '101' THEN '301'
                                     WHEN substring(CustomerID,2,3) = '201' THEN '501'
                                     WHEN substring(CustomerID,2,3) = '999' THEN '301'
                                     else substring(CustomerID,2,3) end,
                                COALESCE(lc.D365_CustomerID, ms.CustomerID),
                                COALESCE(lp.D365_ProductID,  ms.ProductID),
                                ms.ProductID
                        ) AS dedup_rn
                        FROM wh_raw.[dbo].[marketsegmentation] ms
                        LEFT JOIN WH_Curated.[dbo].[XREF_Customer_ID] lc
                            ON ms.customerid = lc.Apollo_CustomerID
                        LEFT JOIN WH_Curated.[dbo].[XREF_Product_ID] lp
                            ON ms.productid = lp.Apollo_ProductID
                    ) prelim1
                    WHERE dedup_rn = 1
                ) m
                LEFT JOIN WH_Curated.[dbo].[XREF_Customer_ID] lc
                    ON m.customerid = lc.Apollo_CustomerID
                LEFT JOIN WH_Curated.[dbo].[XREF_Product_ID] lp
                    ON m.productid = lp.Apollo_ProductID
                )
              )

    UNION

    -- Sub-branch 2b: records from tbl_missing_MarketSegmentationRecords
    SELECT
         mms.cmpny
        ,mms.customerid
        ,mms.ProductID
        ,mms.cpcid
        ,NULL                                                              LegacyCPCID
        ,CASE WHEN u.IndustryIsOverride    = 1 THEN u.Industry    END     Industry
        ,CASE WHEN u.SubIndustryIsOverride = 1 THEN u.SubIndustry END     SubIndustry
        ,CASE WHEN left(mms.customerid,1)  = 'C' then 'Yes' ELSE 'No' end AccountTranslatedToD365
        ,CASE WHEN upper(left(mms.productID,1)) >= 'A' then 'No' ELSE 'Yes' end ProductTranslatedToD365
    FROM tbl_missing_MarketSegmentationRecords mms
    LEFT JOIN [dbo].[tbl_APP_MarketSegmentationDataForUpdates] u
        ON  mms.CMPNY      = u.CMPNY
        AND mms.CustomerID = u.CustomerID
        AND mms.ProductID  = u.ProductID
      WHERE NOT EXISTS (
          SELECT 1
          FROM (
              SELECT
                   CASE WHEN substring(ms.CustomerID,2,3) IN ('001','002') THEN '101'
                        WHEN substring(ms.CustomerID,2,3) = '101' THEN '301'
                        WHEN substring(ms.CustomerID,2,3) = '201' THEN '501'
                        WHEN substring(ms.CustomerID,2,3) = '999' THEN '301'
                        ELSE substring(ms.CustomerID,2,3) END              AS CMPNY
                  ,COALESCE(lc.D365_CustomerID, ms.CustomerID)             AS CustomerID
                  ,COALESCE(lp.D365_ProductID,  ms.ProductID)              AS ProductID
              FROM wh_raw.[dbo].[marketsegmentation] ms
              LEFT JOIN WH_Curated.[dbo].[XREF_Customer_ID] lc
                  ON ms.customerid = lc.Apollo_CustomerID
              LEFT JOIN WH_Curated.[dbo].[XREF_Product_ID] lp
                  ON ms.productid  = lp.Apollo_ProductID
          ) legacy
          WHERE legacy.CMPNY      = mms.cmpny
            AND legacy.CustomerID = mms.customerid
            AND legacy.ProductID  = mms.productid
      )

) D365

UNION ALL

-- ============================================================
-- Branch 3: Unknown sentinel row
-- ============================================================
SELECT
     -1         [MarketSegmentationKey]
    ,'Unknown'  [CMPNY]
    ,'Unknown'  [CustomerID]
    ,'Unknown'  [ProductID]
    ,'Unknown'  [CPCID]
    ,'Unknown'  [LegacyCPCID]
    ,NULL       [Industry]
    ,NULL       [SubIndustry]
    ,NULL       AccountTranslatedToD365
    ,NULL       ProductTranslatedToD365
    ,NULL       [RecordEffectiveStartDate]
    ,NULL       [RecordEffectiveEndDate]
    ,NULL       [RecordStatus]
    ,'D365FO'   [Source]

GO

