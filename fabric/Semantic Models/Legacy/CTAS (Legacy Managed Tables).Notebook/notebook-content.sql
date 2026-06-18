-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "sqldatawarehouse"
-- META   },
-- META   "dependencies": {
-- META     "warehouse": {
-- META       "default_warehouse": "e80cf5d2-f264-ac00-472b-838f66bd9948",
-- META       "known_warehouses": [
-- META         {
-- META           "id": "e80cf5d2-f264-ac00-472b-838f66bd9948",
-- META           "type": "Datawarehouse"
-- META         }
-- META       ]
-- META     }
-- META   }
-- META }

-- MARKDOWN ********************

-- # Notebook used to create CTAS that persist legacy tables view logic as a manged table in the gold warehouse

-- MARKDOWN ********************

-- ## Checks that the notebook is connected to the intended warehouse (WH_Curated)

-- CELL ********************

-- SELECT DB_NAME() AS WhereAmI, @@VERSION AS EngineVersion;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## CTAS in Fabric Warehouses creates managed Delta tables, establishing compatibility with Direct Lake.

-- CELL ********************

/*-----------------------------------------------------------
Step A (updated): vw360_Dim_Account logic --> mtbl_LEG_vw360_Dim_Account
 - De-duplicates XREF_Salesman_ID joins (two CTEs)
 - Treats blank CustomerID as NULL
 - Uses NOT EXISTS (null-safe) for anti-join
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_Account;

CREATE TABLE dbo.mtbl_LEG_vw360_Dim_Account
AS
/* ---------- De-fanout CTEs ---------- */
WITH xref_sls_by_name AS (
    SELECT
        Apollo_SalesmanName,
        MIN(D365_SalesmanID) AS D365_SalesmanID   -- deterministic tie-breaker
    FROM dbo.XREF_Salesman_ID
    GROUP BY Apollo_SalesmanName
),
xref_sls_by_id AS (
    SELECT
        D365_SalesmanID,
        MIN(Apollo_SalesmanName) AS Apollo_SalesmanName  -- deterministic tie-breaker
    FROM dbo.XREF_Salesman_ID
    GROUP BY D365_SalesmanID
)

/* ================= LEGACY BRANCH ================= */
SELECT
    /* RECID: nondeterministic hash on CustomerID (mirrors the view) */
    ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                CAST(NEWID() AS varchar(36)),'|',
                CAST(SYSDATETIME() AS varchar(30)),'|',
                CAST(NEWID() AS varchar(36)),'|',
                CAST(l.CustomerID AS varchar(100))
            )
        ) AS binary(8)) AS bigint))                                        AS [RECID],

    NULLIF(LTRIM(RTRIM(l.CustomerID)), '')                                 AS [CustomerID],
    l.[GMAccountno],
    l.[GMRecid],
    l.[CustomerNo],
    l.[ShipToNo],
    l.[NationalOrgID],
    l.[RegionalOrgID],
    l.[GlobalOrgID],
    l.[Source],
    l.[CustomerName],
    l.[Address1],
    l.[Address2],
    l.[Address3],
    l.[Address4],
    l.[City],
    l.[State],
    l.[ZIP],
    l.[Country],
    l.[Contact],
    l.[Phone],
    l.[Fax],
    l.[Salesman],
    CAST(s_name.D365_SalesmanID AS varchar(100))                          AS [Salesman No],
    l.[Sales Channel],
    l.[Bus Unit],
    l.[Industry],
    l.[Industry Mgr],
    l.[Mkt Mgr],
    l.[Application],
    l.[CMPNY],
    l.[Obsoleted],
    l.[ShipToType],
    l.[LocationName],
    l.[Location Type],
    l.[NationalName],
    l.[RegionalName],
    l.[GlobalName],
    l.[EffectiveSalesman],
    l.[EffectiveCountry],
    l.[Tier],
    l.[Contact Type],
    l.[Longitude],
    l.[Latitude],
    l.[GMOwnership],
    l.[RecordCurtainingLevel],
    l.[RowStatus],
    l.[RowChangeReason],
    l.[InitialLoadSystem],
    l.[LastChangeSystem],
    l.[RecordEffectiveStartDate],
    l.[RecordEffectiveEndDate],
    l.[RecordStatus],
    l.[ACC_SID]
FROM dbo.tbl_DIM_Accounts AS l
LEFT JOIN xref_sls_by_name AS s_name
  ON s_name.Apollo_SalesmanName = l.Salesman
WHERE
    l.RecordStatus = '1'
    AND NULLIF(LTRIM(RTRIM(l.CustomerID)), '') IS NOT NULL
    -- Mirror EDW's hard filter (removes AEurope 13× and other known non-keys)
    AND NULLIF(LTRIM(RTRIM(l.[CustomerID])), '') NOT IN ('A201','A101','AEurope')
    AND NOT EXISTS (
        SELECT 1
        FROM dbo.tbl_DIM_Customer AS c
        LEFT JOIN dbo.XREF_Customer_ID AS x
          ON x.D365_CustomerID = c.Customer_ID
        WHERE COALESCE(NULLIF(LTRIM(RTRIM(x.Apollo_CustomerID)), ''), c.Customer_ID)
              = NULLIF(LTRIM(RTRIM(l.CustomerID)), '')
    )

UNION ALL

/* ================= D365 BRANCH ================= */
SELECT
    CAST(c.[CustomerKey] AS bigint)                                         AS [RECID],
    COALESCE(NULLIF(LTRIM(RTRIM(x.Apollo_CustomerID)), ''), c.[Customer_ID]) AS [CustomerID],
    CAST(NULL AS varchar(100))                                             AS [GMAccountno],
    CAST(NULL AS varchar(100))                                             AS [GMRecid],
    c.[Customer_ID]                                                         AS [CustomerNo],
    CAST(NULL AS varchar(50))                                              AS [ShipToNo],
    CAST(NULL AS varchar(50))                                              AS [NationalOrgID],
    CAST(NULL AS varchar(50))                                              AS [RegionalOrgID],
    CAST(NULL AS varchar(50))                                              AS [GlobalOrgID],
    c.[Source]                                                              AS [Source],
    c.[CustomerName]                                                        AS [CustomerName],
    c.[Address]                                                             AS [Address1],
    CAST(NULL AS varchar(200))                                             AS [Address2],
    CAST(NULL AS varchar(200))                                             AS [Address3],
    CAST(NULL AS varchar(200))                                             AS [Address4],
    c.[City]                                                                AS [City],
    c.[State]                                                               AS [State],
    c.[ZIP]                                                                 AS [ZIP],
    c.[Country]                                                             AS [Country],
    CAST(NULL AS varchar(200))                                             AS [Contact],
    CAST(NULL AS varchar(50))                                              AS [Phone],
    CAST(NULL AS varchar(50))                                              AS [Fax],
    s_id.Apollo_SalesmanName                                                AS [Salesman],
    CAST(c.[Salesman_ID] AS varchar(100))                                  AS [Salesman No],
    CAST(NULL AS varchar(100))                                             AS [Sales Channel],
    CAST(NULL AS varchar(100))                                             AS [Bus Unit],
    CAST(NULL AS varchar(100))                                             AS [Industry],
    CAST(NULL AS varchar(100))                                             AS [Industry Mgr],
    CAST(NULL AS varchar(100))                                             AS [Mkt Mgr],
    CAST(NULL AS varchar(100))                                             AS [Application],
    c.[CMPNY]                                                               AS [CMPNY],
    CAST(NULL AS varchar(50))                                              AS [Obsoleted],
    CAST(NULL AS varchar(50))                                              AS [ShipToType],
    CAST(NULL AS varchar(200))                                             AS [LocationName],
    CAST(NULL AS varchar(100))                                             AS [Location Type],
    CAST(NULL AS varchar(200))                                             AS [NationalName],
    CAST(NULL AS varchar(200))                                             AS [RegionalName],
    CAST(NULL AS varchar(200))                                             AS [GlobalName],
    CAST(NULL AS varchar(200))                                             AS [EffectiveSalesman],
    CAST(NULL AS varchar(200))                                             AS [EffectiveCountry],
    c.[Account_Tier]                                                        AS [Tier],
    CAST(NULL AS varchar(100))                                             AS [Contact Type],
    CONVERT(decimal(38,10), c.[Longitude])                                   AS [Longitude],
    CONVERT(decimal(38,10), c.[Latitude])                                    AS [Latitude],
    CAST(NULL AS varchar(50))                                              AS [GMOwnership],
    CAST(NULL AS varchar(50))                                              AS [RecordCurtainingLevel],
    CAST(NULL AS varchar(50))                                              AS [RowStatus],
    CAST(NULL AS varchar(200))                                             AS [RowChangeReason],
    CAST(NULL AS varchar(100))                                             AS [InitialLoadSystem],
    CAST(NULL AS varchar(100))                                             AS [LastChangeSystem],
    c.[RecordEffectiveStartDate]                                            AS [RecordEffectiveStartDate],
    c.[RecordEffectiveEndDate]                                              AS [RecordEffectiveEndDate],
    c.[RecordStatus]                                                        AS [RecordStatus],
    CAST(0 AS int)                                                          AS [ACC_SID]
FROM dbo.tbl_DIM_Customer AS c
LEFT JOIN dbo.XREF_Customer_ID AS x
  ON x.D365_CustomerID = c.Customer_ID
LEFT JOIN xref_sls_by_id AS s_id
  ON s_id.D365_SalesmanID = c.Salesman_ID
WHERE c.RecordStatus = '1';


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step B: vw360_Dim_CPC  -->  mtbl_LEG_vw360_Dim_CPC
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_CPC;

CREATE TABLE dbo.mtbl_LEG_vw360_Dim_CPC
AS
SELECT 
    [CPCID],
    [CustomerID],
    'US'                           AS [Office],
    CUSTNO                         AS [Customer No],
    CAST(ShipTo AS varchar(100))   AS [Ship To No],
    PCode                          AS [ProductCode],
    ''                             AS [ProductName],
    'Active'                       AS [CPCStatus],
    ''                             AS [WonReason],
    ''                             AS [LostReason],
    ''                             AS [CPCClassification],
    ''                             AS [OriginalOPID],
    ''                             AS [CPCStage],
    ''                             AS [CPC Descriptive],
    ''                             AS [CPCType],
    '1/1/2000'                     AS [FirstOrderDate],
    '1/1/2000'                     AS [MostRecentOrderDate],
    '0.00'                         AS [MostRecentPrice],
    ''                             AS [Currency],
    ''                             AS [INCOTerms],
    ''                             AS [Application],
    ''                             AS [ApplicationDefinition],
    ''                             AS [ApplicationDescription],
    ''                             AS [DesiredCharacteristics],
    ''                             AS [RegulatoryRequirements],
    '0.00'                         AS [ListPrice],
    '0.00'                         AS [CurrentPrice],
    'n.a.'                         AS [CPCTier],
    ''                             AS [EstimatedAnnualVolume],
    ''                             AS [EAVUnitOfMeasure],
    ''                             AS [EstimatedAnnualRevenue],
    ''                             AS [EARCurrency],
    [Industry]                     AS [CPCIndustry],
    SubIndustry                    AS [CPCIndustrySubSegment],
    '1/1/2000'                     AS [RecordEffectiveStartDate],
    '12/31/2099'                   AS [RecordEffectiveEndDate],
    'Active'                       AS [RecordStatus],
    ''                             AS [Source],
    'na'                           AS [IsPartOf PLASTICS],
    'na'                           AS [IsPartOf TXTURES],
    'na'                           AS [isPartOf PTFE],
    'na'                           AS [isPartOf_Waxallurgy],
    'na'                           AS [IsPartOf_Emulsions],
    'na'                           AS [isPartOf_Lubricants],
    'na'                           AS [isPartOf_InksAndCoatings]
FROM dbo.tbl_CPCIndustry;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step C: vw_LEG_Dim_Product  -->  mtbl_LEG_Dim_Product
(duplicates removed; legacy rows keep nondeterministic key)
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_Product;

CREATE TABLE dbo.mtbl_LEG_vw360_Dim_Product
AS
/* ---------- Legacy side (unmapped to XREF set) ---------- */
SELECT 
    /* nondeterministic key for legacy rows */
    ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)),'|',
                CAST(SYSDATETIME() AS VARCHAR(30)),'|',
                CAST(NEWID() AS VARCHAR(36)),'|',
                CAST([ProductKey] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))          AS ProductKey,
    '101'                                     AS CMPNY,
    ItemKey                                   AS Product_Code, 
    Desc1                                     AS Product_Name, 
    ItemKey                                   AS ProductSearchName,
    NULL                                      AS Commercial_Name,
    NULL                                      AS Technology,
    NULL                                      AS Material,
    NULL                                      AS Business_Line,
    NULL                                      AS Product_Line,
    NULL                                      AS Lifecycle,
    /* PackageWeight, */
    NULL                                      AS Inventory_UoM,
    /* NULL AS Purchasing_UoM, */
    NULL                                      AS Sales_UoM,
    NULL                                      AS Item_Type,
    /* NULL AS ProductID, */
    NULL                                      AS PTFE_Flag,
    NULL                                      AS Reorder_Point,
    PrintableDesc                             AS Product_Description, 
    ProdLineAcctg, 
    PackageType, 
    PackageLiner, 
    PackageTare, 
    LeadTime, 
    st_ProductionStatus, 
    st_ObsoletionStatus, 
    /* ProductDescPublic, ProductDescInternal, ApplBenefit, LevelOfAddition,
       ExperimentalProductName, BaseProduct, */
    RecordEffectiveStartDate, 
    RecordEffectiveEndDate, 
    RecordStatus,
    'Legacy'                                  AS SOURCE
FROM dbo.legacy_tbl_DIM_Product
WHERE RecordStatus = '1'
  AND ItemKey NOT IN (
        SELECT COALESCE(x.Apollo_ProductID, p.product_id)
        FROM dbo.tbl_DIM_Product AS p
        LEFT JOIN dbo.XREF_Product_ID AS x
          ON p.Product_ID = x.D365_ProductID
  )

UNION ALL

/* ---------------- Current / D365 side ------------------- */
SELECT 
    p.[ProductKey]                            AS ProductKey,
    p.[CMPNY]                                 AS CMPNY,
    COALESCE(x.Apollo_ProductID, p.product_id)/* Product_Code */,
    p.[ProductName]                           AS Product_Name,
    p.[ProductSearchName]                     AS ProductSearchName,
    p.[Commercial_Name]                       AS Commercial_Name,
    p.[Technology]                            AS Technology,
    p.[Material]                              AS Material,
    p.[Business_Line]                         AS Business_Line,
    p.[Product_Line]                          AS Product_Line,
    p.[Lifecycle]                             AS Lifecycle,
    /* p.[PackageWeight], */
    p.[Inventory_UoM]                         AS Inventory_UoM,
    /* p.[Purchasing_UoM], */
    p.[Sales_UoM]                             AS Sales_UoM,
    p.[Item_Type]                             AS Item_Type,
    /* p.[ProductID], */
    p.[PTFE_Flag]                             AS PTFE_Flag,
    p.[Reorder_Point]                         AS Reorder_Point,
    NULL                                      AS Product_Description,
    NULL                                      AS ProdLineAcctg,
    NULL                                      AS PackageType,
    NULL                                      AS PackageLiner,
    NULL                                      AS PackageTare,
    NULL                                      AS LeadTime,
    NULL                                      AS st_ProductionStatus,
    NULL                                      AS st_ObsoletionStatus,
    /* NULLs for unused descriptive columns */
    p.[RecordEffectiveStartDate]              AS RecordEffectiveStartDate,
    p.[RecordEffectiveEndDate]                AS RecordEffectiveEndDate,
    p.[RecordStatus]                          AS RecordStatus,
    p.[Source]                                AS SOURCE
FROM dbo.tbl_DIM_Product AS p
LEFT JOIN dbo.XREF_Product_ID AS x
  ON p.Product_ID = x.D365_ProductID
WHERE p.RecordStatus = '1';

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step D (updated): vw360_Fact_Sales logic --> mtbl_LEG_vw360_Fact_Sales
 - Legacy rows (excluding BRILJANT/TEDA)
 - Current EDW rows from tbl_Fact_Sales (with status → RecordType)
 - BVBA Closed (2024+)
 - TEDA Closed (2024+, valid Invoice No)
 - BVBA Open
 - TEDA Open (Invoice No is null/'Open Order')
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Fact_Sales;

CREATE TABLE dbo.mtbl_LEG_vw360_Fact_Sales
AS

/* ------------------------ 0) Legacy (exclude BRILJANT/TEDA) ------------------------ */
SELECT
    [Cmpny],
    [Order No],
    [Customer PO],
    [Invoice No],
    [IncoTerms],
    [Warehouse],
    [RecordType],
    [OrderDate],
    [InvoiceDate],
    [ShipDate],
    [Customer No],
    [Ship To No],
    [CustomerID],
    [CPCID],
    [CPAID],
    [CostingLinkID],
    [Product],
    [Revenue],
    [Volume],
    [MaterialCostPerPound],
    [DirectCostPerPound],
    [OSProcessingCostPerPound],
    [OverheadCostPerPound],
    [Source]
FROM dbo.legacy_tbl_Fact_Sales
WHERE Source NOT IN ('BRILJANT','TEDA')
AND RecordType <> 'Open Order'

UNION ALL

/* ------------------------ 1) EDW current rows (tbl_Fact_Sales) --------------------- */
SELECT
    CASE WHEN fs.Cmpny = '101' THEN '001' ELSE fs.Cmpny END               AS [Cmpny],
    CAST(fs.Customer_Order_Number AS varchar(50))                         AS [Order No],
    CAST(NULL AS varchar(100))                                            AS [Customer PO],
    CAST(fs.InvoiceNo AS varchar(50))                                     AS [Invoice No],
    CAST(NULL AS varchar(50))                                             AS [IncoTerms],
    CAST(NULL AS varchar(50))                                             AS [Warehouse],
    CASE 
        WHEN fs.SalesLine_Status IN ('Delivered','Invoiced') THEN 'Closed Order'
        WHEN fs.SalesLine_Status = 'Open' THEN 'Open Order'
        ELSE NULL
    END                                                                     AS [RecordType],
    CAST(fs.OrderDate AS date)                                             AS [OrderDate],
    CAST(fs.InvoiceDate AS date)                                           AS [InvoiceDate],
    CAST(fs.SalesLine_ShipDate AS date)                                    AS [ShipDate],
    CAST(fs.CustomerId AS varchar(50))                                    AS [Customer No],
    CAST('0' AS varchar(6))                                               AS [Ship To No],
    CAST(cmap.Apollo_CustomerID AS varchar(200))                          AS [CustomerID],
    CAST('0' AS varchar(400))                                             AS [CPCID],
    CAST('0' AS varchar(400))                                             AS [CPAID],
    CAST('0' AS varchar(400))                                             AS [CostingLinkID],
    CAST(pmap.Apollo_ProductID AS varchar(200))                           AS [Product],
    CAST(fs.Amount AS decimal(19,4))                                      AS [Revenue],
    CAST(fs.Quantity_LBs AS decimal(19,4))                                AS [Volume],
    CAST(0.0 AS decimal(19,4))                                             AS [MaterialCostPerPound],
    CAST(fs.Total_Direct_Cost_Standard AS decimal(19,4))                   AS [DirectCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OSProcessingCostPerPound],
    CAST(fs.Total_Overhead_Cost_Standard AS decimal(19,4))                 AS [OverheadCostPerPound],
    CAST(fs.Source AS varchar(50))                                        AS [Source]
FROM dbo.tbl_Fact_Sales AS fs
LEFT JOIN dbo.XREF_Product_ID  AS pmap ON fs.ProductID  = pmap.D365_ProductID
LEFT JOIN dbo.XREF_Customer_ID AS cmap ON fs.CustomerID = cmap.D365_CustomerID

UNION ALL

/* ------------------------ 2) BVBA Closed (2024+) ----------------------------------- */
SELECT
    b.Cmpny                                                                AS [Cmpny],
    CAST(b.[Order No] AS varchar(50))                                     AS [Order No],
    CAST(b.[Customer PO] AS varchar(100))                                 AS [Customer PO],
    CAST(b.[Invoice No] AS varchar(50))                                   AS [Invoice No],
    CAST(b.[FOB Terms] AS varchar(50))                                    AS [IncoTerms],
    CAST(b.Warehouse AS varchar(50))                                      AS [Warehouse],
    CAST('Closed Order' AS varchar(20))                                   AS [RecordType],
    CAST(b.[Ord Date] AS date)                                             AS [OrderDate],
    CAST(b.[Invoice Date] AS date)                                         AS [InvoiceDate],
    CAST(b.[Ship Date] AS date)                                            AS [ShipDate],
    CAST(b.[Customer No] AS varchar(50))                                  AS [Customer No],
    RIGHT('000000' + CAST(b.[Ship To No] AS varchar(6)), 6)                AS [Ship To No],
    'A'+b.Cmpny + b.[Customer No] + RIGHT('000000'+CAST(b.[Ship To No] AS varchar(6)),6) AS [CustomerID],
    'A'+LTRIM(RTRIM(b.Cmpny))+LTRIM(RTRIM(b.[Customer No]))+LTRIM(RTRIM(b.[Ship To No]))+'---'+LTRIM(RTRIM(b.Product)) AS [CPCID],
    ISNULL(a.GlobalName,'missing Customer name')+' --- '+ISNULL(p.Product_Name,'missing ProductName') AS [CPAID],
    'A'+b.Cmpny+b.[Customer No]+b.[Ship To No]+'---'+b.Product+'---'+b.[Invoice No]+'---'+b.[Invoice Date] AS [CostingLinkID],
    CAST(b.Product AS varchar(200))                                       AS [Product],
    CAST(CAST(b.[Extension] AS decimal(19,4)) * 1.077372 AS decimal(19,4)) AS [Revenue],
    CAST(b.[Lbs Shipped] AS decimal(19,4))                                 AS [Volume],
    CAST(0.0 AS decimal(19,4))                                             AS [MaterialCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [DirectCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OSProcessingCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OverheadCostPerPound],
    CAST('BRILJANT' AS varchar(20))                                       AS [Source]
FROM dbo.tbl_RESULTSSLSBYYR_BVBA AS b
LEFT JOIN dbo.vw360_Dim_Account AS a
  ON 'A'+b.Cmpny+b.[Customer No]+b.[Ship To No] = a.CustomerID
LEFT JOIN dbo.vw360_Dim_Product AS p
  ON b.Product = p.Product_Code
WHERE b.[Customer No] NOT LIKE 'SHAM%'
  AND CAST(b.[Invoice Date] AS date) >= '2024-01-01'

UNION ALL

/* ------------------------ 3) TEDA Closed (2024+, valid Invoice) -------------------- */
SELECT
    CAST('201' AS varchar(3))                                             AS [Cmpny],
    CAST(t.[Order No] AS varchar(50))                                     AS [Order No],
    CAST('' AS varchar(100))                                              AS [Customer PO],
    CAST(t.[Invoice No] AS varchar(50))                                   AS [Invoice No],
    CAST('' AS varchar(50))                                               AS [IncoTerms],
    CAST('201' AS varchar(50))                                            AS [Warehouse],
    CAST('Closed Order' AS varchar(20))                                   AS [RecordType],
    CAST(t.[Order Date] AS date)                                           AS [OrderDate],
    CAST(t.[Invoice Date] AS date)                                         AS [InvoiceDate],
    CAST(t.[Invoice Date] AS date)                                         AS [ShipDate],
    CAST(t.[Customer No] AS varchar(50))                                  AS [Customer No],
    CAST('000000' AS varchar(6))                                          AS [Ship To No],
    'A201'+t.[Customer No]+'000000'                                        AS [CustomerID],
    'A201'+LTRIM(RTRIM(t.[Customer No]))+'000000'+'---'+LTRIM(RTRIM(t.[Product Name])) AS [CPCID],
    ISNULL(a.GlobalName,'missing Customer name')+' --- '+ISNULL(p.Product_Name,'missing ProductName') AS [CPAID],
    CAST('' AS varchar(400))                                              AS [CostingLinkID],
    CAST(t.[Product Name] AS varchar(200))                                AS [Product],
    CAST(t.[Net Amount] AS decimal(19,4))                                  AS [Revenue],
    CAST(t.[Net Weight LBS] AS decimal(19,4))                              AS [Volume],
    CAST(0.0 AS decimal(19,4))                                             AS [MaterialCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [DirectCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OSProcessingCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OverheadCostPerPound],
    CAST('TEDA' AS varchar(20))                                           AS [Source]
FROM dbo.tbl_RESULTSSLSBYYR_TEDA AS t
LEFT JOIN dbo.vw360_Dim_Account AS a
  ON 'A201'+t.[Customer No]+'000000' = a.CustomerID
LEFT JOIN dbo.vw360_Dim_Product AS p
  ON t.[Product Name] = p.Product_Code
WHERE t.[Customer No] NOT IN ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
  AND ISNULL(t.[Invoice No],'0') <> '0'
  AND CAST(t.[Invoice Date] AS date) >= '2024-01-01'

UNION ALL

/* ------------------------ 4) BVBA Open -------------------------------------------- */
SELECT
    bo.Cmpny                                                               AS [Cmpny],
    CAST(bo.[Order No] AS varchar(50))                                    AS [Order No],
    CAST(bo.[Customer PO] AS varchar(100))                                AS [Customer PO],
    CAST(bo.[Invoice No] AS varchar(50))                                  AS [Invoice No],
    CAST(bo.[FOB Terms] AS varchar(50))                                   AS [IncoTerms],
    CAST(bo.Warehouse AS varchar(50))                                     AS [Warehouse],
    CAST('Open Order' AS varchar(20))                                     AS [RecordType],
    CAST(bo.[Ord Date] AS date)                                            AS [OrderDate],
    CAST(bo.[Ship Date] AS date)                                           AS [InvoiceDate],
    CAST(bo.[Ship Date] AS date)                                           AS [ShipDate],
    CAST(bo.[Customer No] AS varchar(50))                                 AS [Customer No],
    RIGHT('000000' + CAST(bo.[Ship To No] AS varchar(6)), 6)               AS [Ship To No],
    'A'+bo.Cmpny+RTRIM(bo.[Customer No])+RIGHT('000000'+CAST(bo.[Ship To No] AS varchar(6)),6) AS [CustomerID],
    'A'+LTRIM(RTRIM(bo.Cmpny))+LTRIM(RTRIM(bo.[Customer No]))+LTRIM(RTRIM(bo.[Ship To No]))+'---'+LTRIM(RTRIM(bo.Product)) AS [CPCID],
    ISNULL(a.GlobalName,'missing Customer name')+' --- '+ISNULL(p.Product_Name,'missing ProductName') AS [CPAID],
    'A'+bo.Cmpny+bo.[Customer No]+bo.[Ship To No]+'---'+bo.Product+'---'+bo.[Invoice No]+'---'+bo.[Invoice Date] AS [CostingLinkID],
    CAST(bo.Product AS varchar(200))                                      AS [Product],
    CAST(CAST(bo.[Extension] AS decimal(19,4)) * 1.077372 AS decimal(19,4)) AS [Revenue],
    CAST(bo.[Lbs Ordered] AS decimal(19,4))                                AS [Volume],
    CAST(0.0 AS decimal(19,4))                                             AS [MaterialCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [DirectCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OSProcessingCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OverheadCostPerPound],
    CAST('BRILJANT' AS varchar(20))                                       AS [Source]
FROM dbo.tbl_RESULTSSLSBYYR_BVBA_Open AS bo
LEFT JOIN dbo.vw360_Dim_Account AS a
  ON 'A'+bo.Cmpny+bo.[Customer No]+bo.[Ship To No] = a.CustomerID
LEFT JOIN dbo.vw360_Dim_Product AS p
  ON bo.Product = p.Product_Code
WHERE bo.[Customer No] NOT LIKE '%SHAM%'

UNION ALL

/* ------------------------ 5) TEDA Open -------------------------------------------- */
SELECT
    CAST('201' AS varchar(3))                                             AS [Cmpny],
    CAST(to1.[Order No] AS varchar(50))                                   AS [Order No],
    CAST('' AS varchar(100))                                              AS [Customer PO],
    CAST(to1.[Invoice No] AS varchar(50))                                 AS [Invoice No],
    CAST('' AS varchar(50))                                               AS [IncoTerms],
    CAST('201' AS varchar(50))                                            AS [Warehouse],
    CAST('Open Order' AS varchar(20))                                     AS [RecordType],
    CAST(to1.[Order Date] AS date)                                         AS [OrderDate],
    CAST(to1.[expected Ship Date] AS date)                                 AS [InvoiceDate],
    CAST(to1.[expected Ship Date] AS date)                                 AS [ShipDate],
    CAST(to1.[Customer No] AS varchar(50))                                AS [Customer No],
    CAST('000000' AS varchar(6))                                          AS [Ship To No],
    'A201'+to1.[Customer No]+'000000'                                      AS [CustomerID],
    'A201'+LTRIM(RTRIM(to1.[Customer No]))+'000000'+'---'+LTRIM(RTRIM(to1.[Product Name])) AS [CPCID],
    ISNULL(a.GlobalName,'missing Customer name')+' --- '+ISNULL(p.Product_Name,'missing ProductName') AS [CPAID],
    CAST('' AS varchar(400))                                              AS [CostingLinkID],
    CAST(to1.[Product Name] AS varchar(200))                              AS [Product],
    CAST(to1.[Net Amount] AS decimal(19,4))                                AS [Revenue],
    CAST(to1.[Net Weight LBS] AS decimal(19,4))                            AS [Volume],
    CAST(0.0 AS decimal(19,4))                                             AS [MaterialCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [DirectCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OSProcessingCostPerPound],
    CAST(0.0 AS decimal(19,4))                                             AS [OverheadCostPerPound],
    CAST('TEDA' AS varchar(20))                                           AS [Source]
FROM dbo.tbl_RESULTSSLSBYYR_TEDA AS to1
LEFT JOIN dbo.vw360_Dim_Account AS a
  ON 'A201'+to1.[Customer No]+'000000' = a.CustomerID
LEFT JOIN dbo.vw360_Dim_Product AS p
  ON to1.[Product Name] = p.Product_Code
WHERE to1.[Customer No] NOT IN ('C1E101','C1E201')
  AND ISNULL(to1.[Invoice No], 'Open Order') = 'Open Order';


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step E: vw360_Opportunity_OppType  -->  mtbl_LEG_vw360_Opportunity_OppType
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Opportunity_OppType;
CREATE TABLE dbo.mtbl_LEG_vw360_Opportunity_OppType
AS
SELECT LOPID,
       FVALUE AS OpportunityType
FROM dbo.tbl_OPMGRFLD
WHERE RECTYPE = 'X'
  AND FNAME  = 'OppType';


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step F: vw_Opportunity_Header  -->  mtbl_LEG_vw_Opportunity_Header
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw_Opportunity_Header;
CREATE TABLE dbo.mtbl_LEG_vw_Opportunity_Header
AS
SELECT
    [OpportunityID],[RecordType],[GMAccountno],[Manager],[Company],[Contact],
    [Opportunity],[OpportunityStatus],[OpportunityStage],[OpportunityIndustry],
    [StartDate],[ClosedDate],[CloseByDate],[Probability],[Notes],[ProductName],
    [DesiredCharacteristics],[EstimatedAnnualVolume],[SpecificApplication],
    [TargetPrice],[OpportunityPriority],[RecordID],[RecordEffectiveStartDate],
    [RecordEffectiveEndDate],[RecordStatus],[Source],[OPP_SID],[cloudCRMLink]
FROM dbo.tbl_OpportunityList 
WHERE RecordStatus = '1'
  AND Manager IN ('RLEVITT','CWANSAW','JSANKOVI','JOES','NTURPIN','JWITTIG','JWOLFE',
                  'MARKV','MVITRONE','CMOSELEY','SKWAN','JVERA','VYU','MCHONG',
                  'LLUO','SLIN','AYUAN','WKANG','JWANG')

UNION ALL

SELECT
    [OpportunityID],[RecordType],[GMAccountno],[Manager],[Company],[Contact],
    [Opportunity],[OpportunityStatus],[OpportunityStage],[OpportunityIndustry],
    [StartDate],[ClosedDate],[CloseByDate],[Probability],[Notes],[ProductName],
    [DesiredCharacteristics],
    [EstimatedAnnualVolume]*2.2046                 AS [EstimatedAnnualVolume],
    [SpecificApplication],
    [TargetPrice]* 1.078786/2.2046                 AS [TargetPrice],
    [OpportunityPriority],[RecordID],[RecordEffectiveStartDate],
    [RecordEffectiveEndDate],[RecordStatus],[Source],[OPP_SID],[cloudCRMLink]
FROM dbo.tbl_OpportunityList 
WHERE RecordStatus = '1'
  AND Manager IN ('WKUIPERS','ECAMGOZ','JSTEMMLE','LGIANZIN','JRODRIGU');


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step G: vw360_Dim_InvoiceDate  -->  mtbl_LEG_vw360_Dim_InvoiceDate
(“current” columns are volatile — expect to refresh this daily if needed)
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_InvoiceDate;
CREATE TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate
AS
SELECT
    d.*,
    (
        SELECT [Fiscal_Day_#]
        FROM dbo.tbl_Dim_Date 
        WHERE CONVERT(VARCHAR(10), GETDATE(), 101) = CONVERT(VARCHAR(10), [Date], 101)
    ) AS [CurrentFiscalDay#],
    (
        SELECT [Fiscal_Yr]
        FROM dbo.tbl_Dim_Date 
        WHERE CONVERT(VARCHAR(10), GETDATE(), 101) = CONVERT(VARCHAR(10), [Date], 101)
    ) AS [Current Fiscal Yr]
FROM dbo.tbl_Dim_Date AS d;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step H: vw360_Salesman_Hierarchy  -->  mtbl_LEG_vw360_Salesman_Hierarchy
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Salesman_Hierarchy;
CREATE TABLE dbo.mtbl_LEG_vw360_Salesman_Hierarchy
AS
SELECT [GMUserID],[Salesteam],[AssignedSalesman],[RegionalSalesman],
       [RegionalSalesDirector],[GlobalSalesDirector],[RecordStatus]
FROM dbo.legacy_tbl_DIM_Salesman_Heirarchy
WHERE RecordStatus = 'Active';


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step I: vw360_Dim_CPC_Extended  -->  mtbl_LEG_vw360_Dim_CPC_Extended
(uses the new managed tables instead of views)
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_CPC_Extended;
CREATE TABLE dbo.mtbl_LEG_vw360_Dim_CPC_Extended
AS
SELECT 
    ISNULL(fs.[CPCID],'n.a.')             AS CPCID,
    YEAR(MIN(fs.[InvoiceDate]))           AS Cohort
FROM dbo.mtbl_LEG_vw360_Fact_Sales   AS fs
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Account  AS a
       ON fs.CustomerID = a.CustomerID
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Product  AS p
       ON fs.Product    = p.ProductSearchName
WHERE fs.Product NOT IN ('TFS')
  AND ISNULL(fs.[Invoice No],'') NOT IN ('','0')
GROUP BY ISNULL(fs.[CPCID],'n.a.');


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step J: vw360_Dim_CPC_BusinessUnit_Indicator  
         -->  mtbl_LEG_vw360_Dim_CPC_BusinessUnit_Indicator
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_vw360_Dim_CPC_BusinessUnit_Indicator;
CREATE TABLE dbo.mtbl_LEG_vw360_Dim_CPC_BusinessUnit_Indicator
AS
SELECT 
    ISNULL(a.CustomerID + '---' + p.ProductSearchName,'n.a.') AS [CPCID],
    MAX(fs.Cmpny)                                             AS Office,
    a.CustomerID,
    p.ProductSearchName,
    [IsPartOf_PLASTICS] = CASE a.Industry
                            WHEN 'THERMPLASTIC' THEN 'Yes'
                            ELSE 'No' END,
    [IsPartOf_TXTURES]  = CASE p.Product_Line
                            WHEN ' TXTURES' THEN 'Yes'
                            ELSE 'No' END,
    '' AS [isPartOf_PTFE],
    '' AS [isPartOf_Waxallurgy],
    [IsPartOf_Emulsions] = CASE p.Product_Line
                             WHEN 'AUX' THEN 'Yes'
                             WHEN 'DIS' THEN 'Yes'
                             WHEN 'EMUL' THEN 'Yes'
                             WHEN 'PIGMEN' THEN 'Yes'
                             WHEN 'RAW-MAT' THEN 'Yes'
                             ELSE 'No' END,
    '' AS isPartOf_Lubricants,
    isPartOf_InksAndCoatings = CASE a.Industry
                                  WHEN 'INKS' THEN 'Yes'
                                  WHEN 'COATINGS' THEN 'Yes'
                                  ELSE 'No' END
FROM dbo.mtbl_LEG_vw360_Fact_Sales  AS fs
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Account AS a
       ON TRIM(fs.CustomerID) = TRIM(a.CustomerID)
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Product AS p
       ON fs.Product = p.ProductSearchName
WHERE fs.Source <> 'Imputed Data'
  AND ISNULL(a.CustomerID + '---' + p.ProductSearchName,'n.a.') <> 'n.a.'
GROUP BY 
    ISNULL(a.CustomerID + '---' + p.ProductSearchName,'n.a.'),
    fs.Product, a.Industry, p.Product_Line, a.CustomerID, p.ProductSearchName;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

/*-----------------------------------------------------------
Step K: BIDataSet_Opportunity  -->  mtbl_LEG_BIDataSet_Opportunity
         (points to managed header + opp type)
-----------------------------------------------------------*/

DROP TABLE IF EXISTS dbo.mtbl_LEG_BIDataSet_Opportunity;
CREATE TABLE dbo.mtbl_LEG_BIDataSet_Opportunity
AS
SELECT
    /* IDs / codes / dates unchanged */
    h.[OpportunityID],
    CAST(h.[RecordType] AS VARCHAR(20))              AS [RecordType],
    h.[GMAccountno],
    CAST(h.[Manager] AS VARCHAR(100))                AS [Manager],
    CAST(h.[Company] AS VARCHAR(200))                AS [Company],
    CAST(h.[Contact] AS VARCHAR(200))                AS [Contact],

    /* medium strings */
    CAST(h.[Opportunity] AS VARCHAR(200))            AS [Opportunity],
    CAST(h.[OpportunityStatus] AS VARCHAR(50))       AS [OpportunityStatus],
    CAST(h.[OpportunityStage] AS VARCHAR(50))        AS [OpportunityStage],
    CAST(h.[OpportunityIndustry] AS VARCHAR(100))    AS [OpportunityIndustry],

    h.[StartDate],
    h.[ClosedDate],
    h.[CloseByDate],
    h.[Probability],

    /* the big boys — make them variable-length */
    CAST(h.[Notes] AS VARCHAR(2000))                 AS [Notes],
    CAST(h.[ProductName] AS VARCHAR(200))            AS [ProductName],
    CAST(h.[DesiredCharacteristics] AS VARCHAR(1000))AS [DesiredCharacteristics],
    CAST(h.[EstimatedAnnualVolume] AS VARCHAR(100))  AS [EstimatedAnnualVolume],
    CAST(h.[SpecificApplication] AS VARCHAR(1000))   AS [SpecificApplication],
    CAST(h.[TargetPrice] AS VARCHAR(100))            AS [TargetPrice],

    CAST(h.[OpportunityPriority] AS VARCHAR(50))     AS [OpportunityPriority],
    h.[RecordID],
    h.[RecordEffectiveStartDate],
    h.[RecordEffectiveEndDate],
    CAST(h.[RecordStatus] AS VARCHAR(20))            AS [RecordStatus],
    CAST(h.[Source] AS VARCHAR(50))                  AS [Source],
    h.[OPP_SID],
    CAST(h.[cloudCRMLink] AS VARCHAR(500))           AS [cloudCRMLink],

    /* from opp type table */
    CAST(t.[LOPID] AS VARCHAR(100))                  AS [LOPID],
    CAST(t.[OpportunityType] AS VARCHAR(100))        AS [OpportunityType]
FROM dbo.mtbl_LEG_vw_Opportunity_Header          AS h
LEFT JOIN dbo.mtbl_LEG_vw360_Opportunity_OppType AS t
  ON h.OpportunityID = t.LOPID;



-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Derived columns section - inherited calculated columns
-- The first cell is to create the columns, the second is to populate them.

-- MARKDOWN ********************

-- ### Adding shell columns first

-- CELL ********************

SET NOCOUNT ON;

-- =======================
-- A) InvoiceDate columns
-- =======================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='MonthName'     AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD MonthName varchar(3) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='MyMonth'       AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD MyMonth varchar(8) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='YYYYMM'        AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD YYYYMM char(6) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='YYYYMM_Fiscal' AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD YYYYMM_Fiscal char(6) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='FYTDIndicator' AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD FYTDIndicator varchar(3) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='TodaysDate'    AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD TodaysDate date NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='MonthStartDate'    AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_InvoiceDate'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_InvoiceDate ADD MonthStartDate date NULL;

-- ==================
-- B) Fact_Sales cols
-- ==================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='AvgPrice'          AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD AvgPrice decimal(18,6) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Today'             AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD Today date NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Salesperson'       AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD Salesperson varchar(128) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Location'          AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD Location varchar(256) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='RecTypeLong'       AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD RecTypeLong varchar(32) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='RecTypeLong2'      AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD RecTypeLong2 varchar(32) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Budget2024Revenue' AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD Budget2024Revenue decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='BudgetRevenue'     AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD BudgetRevenue decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='BudgetVolume'      AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD BudgetVolume decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='CYTDRevenue'       AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD CYTDRevenue decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='CYTDVolume'        AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD CYTDVolume decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='LFYTDRevenue'      AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD LFYTDRevenue decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='LFYTDVolume'       AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD LFYTDVolume decimal(18,2) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='ClusterColumn'     AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Fact_Sales'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Fact_Sales ADD ClusterColumn varchar(32) NULL;

-- =====================
-- C) Dim_Account cols
-- =====================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Location'  AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_Account'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_Account ADD Location varchar(256) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name='Salesteam' AND object_id=OBJECT_ID('dbo.mtbl_LEG_vw360_Dim_Account'))
    ALTER TABLE dbo.mtbl_LEG_vw360_Dim_Account ADD Salesteam varchar(64) NULL;

-- Optional: quick verify
SELECT t.name AS TableName, c.name AS ColumnName
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name IN ('mtbl_LEG_vw360_Dim_InvoiceDate','mtbl_LEG_vw360_Fact_Sales','mtbl_LEG_vw360_Dim_Account')
  AND c.name IN ('MonthName','MyMonth','YYYYMM','YYYYMM_Fiscal','FYTDIndicator','TodaysDate', 'MonthStartDate',
                 'AvgPrice','Today','Salesperson','Location','RecTypeLong','RecTypeLong2',
                 'Budget2024Revenue','BudgetRevenue','BudgetVolume','CYTDRevenue','CYTDVolume',
                 'LFYTDRevenue','LFYTDVolume','ClusterColumn','Salesteam')
ORDER BY t.name, c.column_id;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

SET NOCOUNT ON;

-- 1) EstimatedAnnualrevenue (decimal)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.mtbl_LEG_BIDataSet_Opportunity')
      AND name = 'EstimatedAnnualrevenue'
)
    ALTER TABLE dbo.mtbl_LEG_BIDataSet_Opportunity
    ADD EstimatedAnnualrevenue decimal(18,2) NULL;

-- 2) Office (text)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.mtbl_LEG_BIDataSet_Opportunity')
      AND name = 'Office'
)
    ALTER TABLE dbo.mtbl_LEG_BIDataSet_Opportunity
    ADD Office varchar(16) NULL;

-- 3) Probable Value (decimal)  -- note the space; brackets are required when referencing it
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.mtbl_LEG_BIDataSet_Opportunity')
      AND name = 'Probable Value'
)
    ALTER TABLE dbo.mtbl_LEG_BIDataSet_Opportunity
    ADD [Probable Value] decimal(18,2) NULL;

-- Optional: quick verify that columns now exist
SELECT c.name AS NewColumn
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID('dbo.mtbl_LEG_BIDataSet_Opportunity')
  AND c.name IN ('EstimatedAnnualrevenue','Office','Probable Value')
ORDER BY c.name;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ### Next, populate column shells

-- CELL ********************

SET NOCOUNT ON;

-- =========== InvoiceDate ===========
UPDATE d
SET
  MonthName = CASE MONTH([Date])
                WHEN 1 THEN 'Jan' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar' WHEN 4 THEN 'Apr'
                WHEN 5 THEN 'May' WHEN 6 THEN 'Jun' WHEN 7 THEN 'Jul' WHEN 8 THEN 'Aug'
                WHEN 9 THEN 'Sep' WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dec'
              END,
  MyMonth   = RIGHT('0'+CAST(MONTH([Date]) AS varchar(2)),2) + ' ' +
              CASE MONTH([Date])
                WHEN 1 THEN 'Jan' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar' WHEN 4 THEN 'Apr'
                WHEN 5 THEN 'May' WHEN 6 THEN 'Jun' WHEN 7 THEN 'Jul' WHEN 8 THEN 'Aug'
                WHEN 9 THEN 'Sep' WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dec'
              END,
  MonthStartDate = DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1)
FROM dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS d;

UPDATE dbo.mtbl_LEG_vw360_Dim_InvoiceDate
SET YYYYMM = CAST(YEAR([Date]) AS varchar(4)) + RIGHT('0'+CAST(MONTH([Date]) AS varchar(2)),2);

UPDATE dbo.mtbl_LEG_vw360_Dim_InvoiceDate
SET YYYYMM_Fiscal = CAST([FISCAL_YR] AS varchar(4)) + RIGHT('0'+CAST([FISCAL_PERIOD] AS varchar(2)),2);

UPDATE dbo.mtbl_LEG_vw360_Dim_InvoiceDate
SET FYTDIndicator = CASE WHEN [FISCAL_DAY_#] <= [CurrentFiscalDay#] THEN 'yes' ELSE 'no' END;

UPDATE dbo.mtbl_LEG_vw360_Dim_InvoiceDate
SET TodaysDate = CAST(GETDATE() AS date);

-- =========== Fact_Sales ===========

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET AvgPrice = CASE WHEN NULLIF(Volume,0) IS NULL THEN NULL
                    ELSE CAST(Revenue AS decimal(18,6))/CAST(NULLIF(Volume,0) AS decimal(18,6)) END;

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales SET Today = CAST(GETDATE() AS date);

UPDATE f
SET f.Salesperson = a.[Salesman]
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Account AS a
  ON a.[CustomerID] = f.[CustomerID];

UPDATE f
SET f.Location = CONCAT(a.[City],
                        CASE WHEN a.[State] IS NULL OR a.[State] = '' THEN '' ELSE ', ' + a.[State] END,
                        ' - ',
                        f.[Product])
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_Account AS a
  ON a.[CustomerID] = f.[CustomerID];

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET RecTypeLong = LEFT([RecordType],6) + '-' + CAST(YEAR([InvoiceDate]) AS varchar(4));

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET RecTypeLong2 =
    CASE WHEN [RecordType] = 'Budget 2024'
         THEN 'x' + LEFT([RecordType],6) + '-' + CAST(YEAR([InvoiceDate]) AS varchar(4))
         ELSE      LEFT([RecordType],6) + '-' + CAST(YEAR([InvoiceDate]) AS varchar(4))
    END;

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET Budget2024Revenue = CASE WHEN [RecordType] = 'Budget 2024' THEN [Revenue] ELSE 0 END;

UPDATE f
SET BudgetRevenue =
    CASE WHEN di.[FISCAL_YR] = di.[Current Fiscal Yr]
           AND LEFT(f.[RecordType],6) = 'Budget'
         THEN f.[Revenue] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE f
SET BudgetVolume =
    CASE WHEN di.[FISCAL_YR] = di.[Current Fiscal Yr]
           AND LEFT(f.[RecordType],6) = 'Budget'
         THEN f.[Volume] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE f
SET CYTDRevenue =
    CASE WHEN di.[FISCAL_YR] = di.[Current Fiscal Yr]
           AND f.[RecordType] = 'Closed Order'
           AND di.[FISCAL_DAY_#] <= di.[CurrentFiscalDay#]
         THEN f.[Revenue] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE f
SET CYTDVolume =
    CASE WHEN di.[FISCAL_YR] = di.[Current Fiscal Yr]
           AND f.[RecordType] = 'Closed Order'
           AND di.[FISCAL_DAY_#] <= di.[CurrentFiscalDay#]
         THEN f.[Volume] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE f
SET LFYTDRevenue =
    CASE WHEN di.[Current Fiscal Yr] - 1 = di.[FISCAL_YR]
           AND di.[FISCAL_DAY_#] <= di.[CurrentFiscalDay#]
         THEN f.[Revenue] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE f
SET LFYTDVolume =
    CASE WHEN di.[Current Fiscal Yr] - 1 = di.[FISCAL_YR]
           AND di.[FISCAL_DAY_#] <= di.[CurrentFiscalDay#]
         THEN f.[Volume] ELSE 0 END
FROM dbo.mtbl_LEG_vw360_Fact_Sales AS f
LEFT JOIN dbo.mtbl_LEG_vw360_Dim_InvoiceDate AS di
  ON CAST(f.[InvoiceDate] AS date) = CAST(di.[Date] AS date);

UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET ClusterColumn = CASE WHEN [RecordType] = 'Budget 2025' THEN 'Budget' ELSE 'Actual Revenue' END;

-- =========== Dim_Account ===========
UPDATE dbo.mtbl_LEG_vw360_Dim_Account
SET Location = CONCAT([City], CASE WHEN [State] IS NULL OR [State] = '' THEN '' ELSE ', ' + [State] END);

-- Simple team mapping placeholder (extend):
UPDATE a
SET a.Salesteam =
    CASE
      WHEN a.[Salesman] IN ('Joe Sankovic','Mark Vitrone','CHRIS MOSELEY','JONATAN VERA','JAMES WITTIG') THEN 'Americas Salesteam'
      WHEN a.[Salesman] IN ('WILSON HO','JACKY YEH','VIRGIL YU','STEVE LIN') THEN 'APAC Salesteam'
      ELSE 'Other'
    END
FROM dbo.mtbl_LEG_vw360_Dim_Account AS a;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

SET NOCOUNT ON;

-- 1) EstimatedAnnualrevenue = EstimatedAnnualVolume * TargetPrice
UPDATE dbo.mtbl_LEG_BIDataSet_Opportunity
SET EstimatedAnnualrevenue =
    TRY_CONVERT(decimal(18,6), [EstimatedAnnualVolume]) * TRY_CONVERT(decimal(18,6), [TargetPrice]);

-- 2) Office classification from Manager
UPDATE dbo.mtbl_LEG_BIDataSet_Opportunity
SET Office =
    CASE
      WHEN UPPER([Manager]) IN ('WKUIPERS','JSTEMMLE','ECAMGOZ','LGIANZIN','JRODRIGU','MTRAN','JHENSKEN','DDEWULF')
           THEN 'BVBA'
      WHEN UPPER([Manager]) IN ('SLIN','WKANG','AYUAN','VYU','JWANG','LLUO','MCHONG','SKWAN')
           THEN 'TEDA'
      ELSE 'US'
    END;

-- 3) Probable Value = Probability * EstimatedAnnualrevenue / 100
UPDATE dbo.mtbl_LEG_BIDataSet_Opportunity
SET [Probable Value] =
    TRY_CONVERT(decimal(18,6), [Probability]) * TRY_CONVERT(decimal(18,6), EstimatedAnnualrevenue) / 100.0;

-- Optional: sanity checks
SELECT
    SUM(CASE WHEN EstimatedAnnualrevenue IS NULL THEN 1 ELSE 0 END) AS Null_EstAnnualRev,
    SUM(CASE WHEN Office                 IS NULL THEN 1 ELSE 0 END) AS Null_Office,
    SUM(CASE WHEN [Probable Value]       IS NULL THEN 1 ELSE 0 END) AS Null_ProbValue
FROM dbo.mtbl_LEG_BIDataSet_Opportunity;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Bad DATE Nullification

-- CELL ********************

-- Transport limits Power BI can serialize
DECLARE @min date = '1899-12-30';
DECLARE @max date = '9999-12-31';

-- One row per field you care about
SELECT
    'Dim_Account.RecordEffectiveStartDate' AS Field,
    'dbo.mtbl_LEG_vw360_Dim_Account'       AS TableName,
    MIN(RecordEffectiveStartDate)          AS MinValue,
    MAX(RecordEffectiveStartDate)          AS MaxValue,
    SUM(CASE WHEN RecordEffectiveStartDate < @min OR RecordEffectiveStartDate > @max THEN 1 ELSE 0 END) AS OutOfRange,
    SUM(CASE WHEN RecordEffectiveStartDate IS NULL THEN 1 ELSE 0 END) AS Nulls
FROM dbo.mtbl_LEG_vw360_Dim_Account

UNION ALL
SELECT
    'Dim_Account.RecordEffectiveEndDate',
    'dbo.mtbl_LEG_vw360_Dim_Account',
    MIN(RecordEffectiveEndDate),
    MAX(RecordEffectiveEndDate),
    SUM(CASE WHEN RecordEffectiveEndDate < @min OR RecordEffectiveEndDate > @max THEN 1 ELSE 0 END),
    SUM(CASE WHEN RecordEffectiveEndDate IS NULL THEN 1 ELSE 0 END)
FROM dbo.mtbl_LEG_vw360_Dim_Account

UNION ALL
SELECT
    'Dim_InvoiceDate.DATE',
    'dbo.mtbl_LEG_vw360_Dim_InvoiceDate',
    MIN([DATE]),
    MAX([DATE]),
    SUM(CASE WHEN [DATE] < @min OR [DATE] > @max THEN 1 ELSE 0 END),
    SUM(CASE WHEN [DATE] IS NULL THEN 1 ELSE 0 END)
FROM dbo.mtbl_LEG_vw360_Dim_InvoiceDate

UNION ALL
SELECT
    'Fact_Sales.ShipDate',
    'dbo.mtbl_LEG_vw360_Fact_Sales',
    MIN(ShipDate),
    MAX(ShipDate),
    SUM(CASE WHEN ShipDate < @min OR ShipDate > @max THEN 1 ELSE 0 END),
    SUM(CASE WHEN ShipDate IS NULL THEN 1 ELSE 0 END)
FROM dbo.mtbl_LEG_vw360_Fact_Sales

UNION ALL
SELECT
    'Fact_Sales.OrderDate',
    'dbo.mtbl_LEG_vw360_Fact_Sales',
    MIN(OrderDate),
    MAX(OrderDate),
    SUM(CASE WHEN OrderDate < @min OR OrderDate > @max THEN 1 ELSE 0 END),
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END)
FROM dbo.mtbl_LEG_vw360_Fact_Sales

UNION ALL
SELECT
    'Fact_Sales.InvoiceDate',
    'dbo.mtbl_LEG_vw360_Fact_Sales',
    MIN(InvoiceDate),
    MAX(InvoiceDate),
    SUM(CASE WHEN InvoiceDate < @min OR InvoiceDate > @max THEN 1 ELSE 0 END),
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END)
FROM dbo.mtbl_LEG_vw360_Fact_Sales;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Transport range that Power BI can serialize
DECLARE @min date = '1899-12-30';
DECLARE @max date = '9999-12-31';

-- 0) Quick audit BEFORE
SELECT
  SUM(CASE WHEN InvoiceDate < @min OR InvoiceDate > @max THEN 1 ELSE 0 END) AS OutOfRange_InvoiceDate,
  SUM(CASE WHEN ShipDate    < @min OR ShipDate    > @max THEN 1 ELSE 0 END) AS OutOfRange_ShipDate
FROM dbo.mtbl_LEG_vw360_Fact_Sales;

-- 1) Null out out-of-range dates (both columns in one pass)
UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
SET
  InvoiceDate = CASE
                  WHEN InvoiceDate IS NULL THEN NULL
                  WHEN InvoiceDate < @min OR InvoiceDate > @max THEN NULL
                  ELSE InvoiceDate
                END,
  ShipDate    = CASE
                  WHEN ShipDate IS NULL THEN NULL
                  WHEN ShipDate < @min OR ShipDate > @max THEN NULL
                  ELSE ShipDate
                END;

-- 2) Optional: also clamp any "nonsense" that slipped in as strings and got cast to 0001-01-01 elsewhere
-- (Uncomment if you suspect bad casts)
-- UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
-- SET InvoiceDate = NULL
-- WHERE TRY_CAST(InvoiceDate AS date) IS NULL;
-- UPDATE dbo.mtbl_LEG_vw360_Fact_Sales
-- SET ShipDate = NULL
-- WHERE TRY_CAST(ShipDate AS date) IS NULL;

-- 3) Quick audit AFTER
SELECT
  SUM(CASE WHEN InvoiceDate < @min OR InvoiceDate > @max THEN 1 ELSE 0 END) AS OutOfRange_InvoiceDate,
  SUM(CASE WHEN ShipDate    < @min OR ShipDate    > @max THEN 1 ELSE 0 END) AS OutOfRange_ShipDate
FROM dbo.mtbl_LEG_vw360_Fact_Sales;

-- 4) Show the new min/max (sanity)
SELECT
  MIN(InvoiceDate) AS MinInvoiceDate,
  MAX(InvoiceDate) AS MaxInvoiceDate,
  MIN(ShipDate)    AS MinShipDate,
  MAX(ShipDate)    AS MaxShipDate
FROM dbo.mtbl_LEG_vw360_Fact_Sales;


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
