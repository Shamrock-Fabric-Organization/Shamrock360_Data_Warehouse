-- Auto Generated (Do not modify) 76AFADA59C41C3F0DCCB0647D5C8B6B9FF8984491EA9C350B39BEDFAAAE50434
/*
================================================================================
  Script  : DIM_SurrogateKey_DuplicateCheck.sql
  Purpose : Verifies that no surrogate key column contains duplicate values
            across all WH_Transform dimension tables.
            Returns one summary row per table.
            DuplicateKeyCount = 0 means the table is clean.

  Result columns:
    SchemaName       - schema of the table checked
    TableName        - dimension table name
    SKColumn         - surrogate key column checked
    DuplicateKeyCount - number of distinct key VALUES that appear more than once
    MaxOccurrences    - highest row count for any single duplicate key value
    Status            - PASS (0 duplicates) or FAIL (duplicates found)
================================================================================
*/
CREATE   VIEW vwDIM_SurrogateKey_DuplicateCheck AS
SELECT *
FROM (
    SELECT
         SchemaName
        ,TableName
        ,SKColumn
        ,DuplicateKeyCount
        ,MaxOccurrences
        ,CASE WHEN DuplicateKeyCount = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
    FROM (

        SELECT 'dbo' AS SchemaName, 'tbl_DIM_Address' AS TableName, 'AddressKey' AS SKColumn
            ,COUNT(1)   AS DuplicateKeyCount
            ,ISNULL(MAX(cnt), 0) AS MaxOccurrences
        FROM (SELECT AddressKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Address GROUP BY AddressKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_AgingBuckets', 'AgingBucketKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT AgingBucketKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_AgingBuckets GROUP BY AgingBucketKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Batch', 'BatchKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT BatchKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Batch GROUP BY BatchKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_BudgetModel', 'BudgetModelKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT BudgetModelKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_BudgetModel GROUP BY BudgetModelKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Customer', 'CustomerKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT CustomerKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Customer GROUP BY CustomerKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_CustomerPackingSlip', 'CustomerPackingSlipKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT CustomerPackingSlipKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_CustomerPackingSlip GROUP BY CustomerPackingSlipKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Department', 'DepartmentKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT DepartmentKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Department GROUP BY DepartmentKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Employee', 'EmployeeKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT EmployeeKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Employee GROUP BY EmployeeKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_GL_Account', 'GL_AccountKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT GL_AccountKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_GL_Account GROUP BY GL_AccountKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Legal_Entity', 'Legal_EntityKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT Legal_EntityKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Legal_Entity GROUP BY Legal_EntityKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_MarketSegmentation', 'MarketSegmentationKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT MarketSegmentationKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_MarketSegmentation GROUP BY MarketSegmentationKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_dim_PhantomProduct', 'PhantomProductKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT PhantomProductKey, COUNT(1) AS cnt FROM dbo.tbl_dim_PhantomProduct GROUP BY PhantomProductKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Product', 'ProductKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT ProductKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Product GROUP BY ProductKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_ProductionBatchOrder', 'ProductionBatchOrderKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT ProductionBatchOrderKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_ProductionBatchOrder GROUP BY ProductionBatchOrderKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Project', 'ProjectKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT ProjectKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Project GROUP BY ProjectKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_PurchaseOrder', 'PurchaseOrderKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT PurchaseOrderKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_PurchaseOrder GROUP BY PurchaseOrderKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_QualityOrder', 'QualityOrderKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT QualityOrderKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_QualityOrder GROUP BY QualityOrderKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Route', 'RouteKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT RouteKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Route GROUP BY RouteKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_SalesOrder', 'SalesOrderKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT SalesOrderKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_SalesOrder GROUP BY SalesOrderKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_SerialNumber', 'SerialNumberKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT SerialNumberKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_SerialNumber GROUP BY SerialNumberKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Site', 'SiteKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT SiteKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Site GROUP BY SiteKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_StandardCost', 'StandardCostKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT StandardCostKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_StandardCost GROUP BY StandardCostKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_TradeAgreement', 'TradeAgreementKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT TradeAgreementKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_TradeAgreement GROUP BY TradeAgreementKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Vendor', 'VendorKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT VendorKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Vendor GROUP BY VendorKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_Warehouse', 'WarehouseKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT WarehouseKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_Warehouse GROUP BY WarehouseKey HAVING COUNT(1) > 1) x

        UNION ALL

        SELECT 'dbo', 'tbl_DIM_WorkCenter', 'WorkCenterKey'
            ,COUNT(1), ISNULL(MAX(cnt), 0)
        FROM (SELECT WorkCenterKey, COUNT(1) AS cnt FROM dbo.tbl_DIM_WorkCenter GROUP BY WorkCenterKey HAVING COUNT(1) > 1) x

        ------UNION ALL

        ------SELECT 'dbo', 'testerror', 'testerrorkey', 99, 15

    ) summary
) results
WHERE Status = 'FAIL'