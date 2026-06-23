-- Auto Generated (Do not modify) 03507983082C89750846408A8504EC1F887EFE673070F20B98F2B8BD1F5DABF8

/****** Object:  View [dbo].[vw_stage_DIM_StandardCost_incoming]    Script Date: 5/19/2026 4:04:15 PM ******/
-- =============================================================================
-- vw_stage_DIM_StandardCost_incoming v10
-- Object:  View [dbo].[vw_stage_DIM_StandardCost_incoming]
-- Changes from v9:
--   1. expBOM_data: removed Snapshot_Date_Key = today filter — ALL activation
--      dates are now included (delta guard is in the snapshot proc, not here).
--      Added ACTIVATIONDATE to GROUP BY, SELECT, and HASHBYTES input.
--   2. IIP path: replaced BasePrice + LatestActivation CTEs with
--      vwInventItemPriceAgg (already deduplicated by MAX(createddatetime)).
--      All activation dates included — LatestActivation restriction removed.
--      Added ActivationDate to SELECT.
--   3. IIP_only_costs EXCEPT: uses CMPNY + Product_ID + ActivationDate.
--      SiteID intentionally excluded — IIP fallback applies when there is no
--      BOM data for that CMPNY + Product_ID + ActivationDate regardless of site.
--   4. Unknown/default row: NULL ActivationDate added to maintain column parity.
-- Natural key downstream: CMPNY + Product_ID + SiteID + ActivationDate
-- =============================================================================

CREATE   VIEW [dbo].[vw_stage_DIM_StandardCost_incoming]
AS
WITH expBOM_data AS (
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
        ,   CAST(SYSDATETIME() AS VARCHAR(30)), '|'
        ,   CAST(NEWID() AS VARCHAR(36)), '|'
        ,   CAST(dataareaid AS VARCHAR(100))
        ,   CAST(itemid AS VARCHAR(100))
        ,   CAST(inventsiteid AS VARCHAR(100))
        ,   CAST(CONVERT(char(8), ACTIVATIONDATE, 112) AS VARCHAR(8))
        )
    ) AS BINARY(8)) AS BIGINT)) AS StandardCostKey
,   dataareaid                                  CMPNY
,   itemid                                      Product_ID
,   inventsiteid                                SiteID
,   CAST(ACTIVATIONDATE AS DATETIME2(3))        ActivationDate
,   EndDate
,   versionid                                   Costing_Version
,   CurrentActiveCost

,   SUM(CASE WHEN CostGroup = 'Direct_Material_Cost_Standard'                      THEN CostPerUnit ELSE 0 END) Direct_Material_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Packaging_Cost_Standard'                            THEN CostPerUnit ELSE 0 END) Packaging_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Direct_Labor_Cost_Standard'                         THEN CostPerUnit ELSE 0 END) Direct_Labor_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Direct_Utility_Cost_Standard'                       THEN CostPerUnit ELSE 0 END) Direct_Utility_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Warehouse_Cost_Standard'                   THEN CostPerUnit ELSE 0 END) Overhead_Warehouse_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Indirect_Supervisor_Cost_Standard'         THEN CostPerUnit ELSE 0 END) Overhead_Indirect_Supervisor_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Quality_Cost_Standard'                     THEN CostPerUnit ELSE 0 END) Overhead_Quality_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Maintenance_Cost_Standard'                 THEN CostPerUnit ELSE 0 END) Overhead_Maintenance_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Manufacturing_Admin_Cost_Standard'         THEN CostPerUnit ELSE 0 END) Overhead_Manufacturing_Admin_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Depreciation_Cost_Standard'                THEN CostPerUnit ELSE 0 END) Overhead_Depreciation_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Overhead_Miscellaneous_Manufacturing_Cost_Standard' THEN CostPerUnit ELSE 0 END) Overhead_Miscellaneous_Manufacturing_Cost_Standard
,   SUM(CASE WHEN CostGroup = 'Outside_Processing_Cost_Standard'                   THEN CostPerUnit ELSE 0 END) Outside_Processing_Cost_Standard

,   SUM(CASE WHEN CostGroup IN (
        'Direct_Material_Cost_Standard','Direct_Labor_Cost_Standard','Direct_Utility_Cost_Standard'
    ) THEN CostPerUnit ELSE 0 END) Total_Direct_Cost_Standard
,   SUM(CASE WHEN CostGroup IN (
        'Overhead_Warehouse_Cost_Standard','Overhead_Indirect_Supervisor_Cost_Standard',
        'Overhead_Quality_Cost_Standard','Overhead_Maintenance_Cost_Standard',
        'Overhead_Manufacturing_Admin_Cost_Standard','Overhead_Depreciation_Cost_Standard',
        'Overhead_Miscellaneous_Manufacturing_Cost_Standard','Outside_Processing_Cost_Standard'
    ) THEN CostPerUnit ELSE 0 END) Total_Overhead_Cost_Standard

,   SUM(CostPerUnit)                            TotalCost
,   accountingcurrency
,   CAST(NULL AS DATETIME2(3))                  AS RecordEffectiveStartDate
,   CAST(NULL AS DATETIME2(3))                  AS RecordEffectiveEndDate
,   CAST(NULL AS INT)                           AS RecordStatus
,   'D365FO'                                    Source

FROM [dbo].[tbl_ExplodedBOM_StandardCost_Snapshot]
-- v10 change: Snapshot_Date_Key = today filter removed.
-- All activation dates are now carried; delta guard lives in sp_Process_Exploded_BOM_Costing_Snapshot.
WHERE NOT ( calctype IN (0, 2, 9) )
GROUP BY dataareaid
,   itemid
,   inventsiteid
,   ACTIVATIONDATE           -- v10 change: added to GROUP BY
,   EndDate
,   versionid
,   CurrentActiveCost
,   accountingcurrency
),

-- -- IIP path: items not covered by the exploded BOM -------------------------
-- v10 change: replaces BasePrice + LatestActivation CTEs.
-- vwInventItemPriceAgg already deduplicates to MAX(createddatetime) per
-- dataareaid + itemid + inventsiteid + activationdate + todate + pricetype.
-- All historical activation dates are included (no LatestActivation restriction).
IIP_Data AS (
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256',
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
        ,   CAST(SYSDATETIME() AS VARCHAR(30)), '|'
        ,   CAST(NEWID() AS VARCHAR(36)), '|'
        ,   CAST(CMPNY AS VARCHAR(100))
        ,   CAST(Product_ID AS VARCHAR(100))
        ,   CAST(SiteID AS VARCHAR(100))
        ,   CAST(CONVERT(char(8), activationdate, 112) AS VARCHAR(8))
        )
    ) AS BINARY(8)) AS BIGINT)) AS StandardCostKey
    , *
    FROM (
        SELECT DISTINCT
                agg.dataareaid                              CMPNY
            ,   agg.itemid                                  Product_ID
            ,   agg.inventsiteid                            SiteID
            ,   CAST(agg.activationdate AS DATETIME2(3))    ActivationDate   -- v10 change: added
            ,   CAST(agg.ToDate AS DATETIME2(3))            EndDate   -- v10 change: added
            ,   iip.versionid                               Costing_Version
            ,   iip.CurrentActiveCost
            ,   agg.PricePerUnit                            Direct_Material_Cost_Standard
            ,   0                                           Packaging_Cost_Standard
            ,   0                                           Direct_Labor_Cost_Standard
            ,   0                                           Direct_Utility_Cost_Standard
            ,   0                                           Overhead_Warehouse_Cost_Standard
            ,   0                                           Overhead_Indirect_Supervisor_Cost_Standard
            ,   0                                           Overhead_Quality_Cost_Standard
            ,   0                                           Overhead_Maintenance_Cost_Standard
            ,   0                                           Overhead_Manufacturing_Admin_Cost_Standard
            ,   0                                           Overhead_Depreciation_Cost_Standard
            ,   0                                           Overhead_Miscellaneous_Manufacturing_Cost_Standard
            ,   0                                           Outside_Processing_Cost_Standard
            ,   agg.PricePerUnit                            Total_Direct_Cost_Standard
            ,   0                                           Total_Overhead_Cost_Standard
            ,   agg.PricePerUnit                            TotalCost
            ,   NULL                                        accountingcurrency
            ,   CAST(NULL AS DATETIME2(3))                  AS RecordEffectiveStartDate
            ,   CAST(NULL AS DATETIME2(3))                  AS RecordEffectiveEndDate
            ,   CAST(NULL AS INT)                           AS RecordStatus
            ,   'D365FO'                                    Source

            FROM WH_Raw.dbo.vwInventItemPriceAgg agg
            JOIN WH_Raw.dbo.vwInventItemPrice iip
                ON  agg.dataareaid    = iip.dataareaid
                AND agg.itemid        = iip.itemid
                AND agg.inventsiteid  = iip.inventsiteid
                AND agg.activationdate = iip.activationdate
                AND agg.todate        = iip.todate
                AND ISNULL(agg.pricecalcid,'')   = ISNULL(iip.pricecalcid,'')
            WHERE agg.pricetype = 0
            ) iipdataforquery
),

-- -- Items that have IIP prices but NO BOM explosion data --------------------
-- v10 change: CMPNY + Product_ID + ActivationDate (no SiteID).
-- A product falls through to IIP only if there is no BOM data for that
-- company + item + activation date combination, regardless of site.
IIP_only_costs AS (
SELECT DISTINCT CMPNY, Product_ID, ActivationDate
FROM IIP_Data
EXCEPT
SELECT DISTINCT CMPNY, Product_ID, ActivationDate
FROM expBOM_data
)

-- -- Final output -------------------------------------------------------------
SELECT *
FROM expBOM_data

UNION ALL

SELECT i.*
FROM IIP_Data i
JOIN IIP_only_costs o
    ON  i.CMPNY          = o.CMPNY
    AND i.Product_ID     = o.Product_ID
    AND i.ActivationDate = o.ActivationDate   -- v10 change: added

UNION ALL

-- Unknown / default member
SELECT -1              [StandardCostKey]
,   'Unknown'          [CMPNY]
,   'Unknown'          [Product_ID]
,   'Unknown'          [SiteID]
,   CONVERT(Datetime2(3), '01/01/1900')  [ActivationDate]       -- v10 change: added
,   CONVERT(Datetime2(3), '12/31/2154')  [EndDate]      
,   'Unknown'          [Costing_Version]
,   NULL               [CurrentActiveCost]
,   NULL               [Direct_Material_Cost_Standard]
,   NULL               [Packaging_Cost_Standard]
,   NULL               [Direct_Labor_Cost_Standard]
,   NULL               [Direct_Utility_Cost_Standard]
,   NULL               [Overhead_Warehouse_Cost_Standard]
,   NULL               [Overhead_Indirect_Supervisor_Cost_Standard]
,   NULL               [Overhead_Quality_Cost_Standard]
,   NULL               [Overhead_Maintenance_Cost_Standard]
,   NULL               [Overhead_Manufacturing_Admin_Cost_Standard]
,   NULL               [Overhead_Depreciation_Cost_Standard]
,   NULL               [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
,   NULL               [Outside_Processing_Cost_Standard]
,   NULL               [Total_Direct_Cost_Standard]
,   NULL               [Total_Overhead_Cost_Standard]
,   NULL               [TotalCost]
,   NULL               [accountingcurrency]
,   NULL               [RecordEffectiveStartDate]
,   NULL               [RecordEffectiveEndDate]
,   NULL               [RecordStatus]
,   'D365FO'           [Source]