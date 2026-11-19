CREATE OR ALTER VIEW vw_EDW_Fact_SalesAndForecastData
as
SELECT
      f.CMPNY
    , f.Model                         AS ModelID
    , f.[Date]
    , f.DateKey
    , f.Customer_Account
    , f.Item_Number
    , f.Sales_Quantity
    , f.Unit
    , f.Sales_Quantity_LBs
    , f.Sales_Quantity_KGs
    , f.Sales_Currency
    , f.Amount
    , f.Amount_USD
    , f.Amount_EUR
    , f.Amount_CNY
    , f.Sales_Price
    , f.SalesPrice_USD
    , f.SalesPrice_EUR
    , f.SalesPrice_CNY
    , f.[Source]
    , f.Legal_EntityKey
    , f.HistoricCustomerKey
    , f.CustomerKey
    , f.HistoricInvoiceCustomerKey
    , f.InvoiceCustomerKey
    , f.HistoricProductKey
    , f.ProductKey
    , f.SiteKey
    , f.WarehouseKey
    , f.Txn_USD_Rate_Missing
    , f.Txn_EUR_Rate_Missing
    , f.Txn_CNY_Rate_Missing
FROM tbl_ForecastSales AS f
where f.Model = 'Forecast'

UNION ALL

-- As of 2026-11-18, removed due to duplicates when combining invoice and sales data.
-- Replaced below by the customer invoices fact (one row per invoice line).
-- SELECT
--       s.CMPNY
--     , 'SalesActual'                   AS ModelID          -- fixed label for sales rows
--     , CAST(s.[DATE] AS date)          AS [Date]
--     , s.DATEKey
--     , s.CustomerID
--     , s.ProductID
--     ----, s.Quantity
--     ----, s.Quantity_UoM
--     ----, s.Quantity_LBs
--     ----, s.Quantity_KGs
--     ----, s.Currency
--     ----, s.Amount
--     ----, s.Amount_USD
--     ----, s.Amount_EUR
--     ----, s.Amount_CNY
--
--     , s.InvoiceQty
--     , s.InvoiceSalesUnit InvoiceQuantity_UoM
--     , s.InvoiceQuantity_LBs
--     , s.InvoiceQuantity_KGs
--     , s.InvoiceCurrency_Code
--     , s.InvoiceLineAmount
--     , s.InvoiceLineAmount_USD
--     , s.InvoiceLineAmount_EUR
--     , s.InvoiceLineAmount_CNY
--
--     , s.Price
--     , s.SalesPrice_USD
--     , s.SalesPrice_EUR
--     , s.SalesPrice_CNY
--     , s.[Source]
--     , s.Legal_EntityKey
--     , s.HistoricCustomerKey
--     , s.CustomerKey
--     , s.HistoricInvoiceCustomerKey
--     , s.InvoiceCustomerKey
--     , s.HistoricProductKey
--     , s.ProductKey
--     , s.SiteKey
--     , s.WarehouseKey
--     --, s.Txn_USD_Rate_Missing
--     --, s.Txn_EUR_Rate_Missing
--     --, s.Txn_CNY_Rate_Missing
--     , s.InvoiceTxn_USD_Rate_Missing
--     , s.InvoiceTxn_EUR_Rate_Missing
--     , s.InvoiceTxn_CNY_Rate_Missing
-- FROM mtbl_EDW_Fact_Sales AS s
-- WHERE SalesLine_Status = 'Invoiced'

SELECT
      i.CMPNY
    , 'SalesActual'                   AS ModelID          -- fixed label for sales rows
    , CAST(i.InvoiceDate AS date)     AS [Date]
    , i.InvoiceDateKey                AS DateKey
    , i.Order_Account                 AS Customer_Account
    , i.Product_ID                    AS Item_Number
    , i.Qty                           AS Sales_Quantity
    , i.salesunit                     AS Unit
    , i.Quantity_LBs                  AS Sales_Quantity_LBs
    , i.Quantity_KGs                  AS Sales_Quantity_KGs
    , i.Currency_Code                 AS Sales_Currency
    , i.LineAmount                    AS Amount
    , i.LineAmount_USD                AS Amount_USD
    , i.LineAmount_EUR                AS Amount_EUR
    , i.LineAmount_CNY                AS Amount_CNY
    , i.SalesPrice                    AS Sales_Price
    , i.SalesPrice_USD
    , i.SalesPrice_EUR
    , i.SalesPrice_CNY
    , i.[Source]
    , i.Legal_EntityKey
    , i.CustomerKey                   AS HistoricCustomerKey          -- invoice fact key is the version in effect when the invoice line was created
    , ISNULL(dcc.CustomerKey, -1)     AS CustomerKey                  -- current version of the order account
    , i.InvoiceCustomerKey            AS HistoricInvoiceCustomerKey   -- version in effect when the invoice line was created
    , ISNULL(dicc.CustomerKey, -1)    AS InvoiceCustomerKey           -- current version of the invoice account
    , i.ProductKey                    AS HistoricProductKey           -- version in effect when the invoice line was created
    , ISNULL(dpc.ProductKey, -1)      AS ProductKey                   -- current version of the product
    , i.SiteKey
    , ISNULL(dw.WarehouseKey, -1)     AS WarehouseKey                 -- invoice fact carries Warehouse_ID only
    , i.Txn_USD_Rate_Missing
    , i.Txn_EUR_Rate_Missing
    , i.Txn_CNY_Rate_Missing
FROM mtbl_EDW_Fact_Customer_Invoices AS i
LEFT JOIN mtbl_EDW_DIM_Account dcc
    ON i.Order_Account = dcc.Customer_ID
        AND i.CMPNY = dcc.CMPNY
        AND dcc.RecordStatus = 1
LEFT JOIN mtbl_EDW_DIM_Account dicc
    ON i.Invoice_Account = dicc.Customer_ID
        AND i.CMPNY = dicc.CMPNY
        AND dicc.RecordStatus = 1
LEFT JOIN mtbl_EDW_DIM_Product dpc
    ON i.Product_ID = dpc.Product_ID
        AND i.CMPNY = dpc.CMPNY
        AND dpc.Record_Status = 1
LEFT JOIN mtbl_EDW_DIM_Warehouse dw
    ON i.CMPNY = dw.CMPNY
        AND i.Warehouse_ID = dw.Warehouse_ID
        AND i.InvoiceDate BETWEEN dw.RecordEffectiveStartDate AND dw.RecordEffectiveEndDate
-- As of 2026-11-19, D365 invoices dated before the company's D365 go-live are excluded; the legacy branch already reports those months. Add a row when another company goes live.
LEFT JOIN (VALUES ('101', CAST('2025-11-01' AS date)), ('301', CAST('2026-10-01' AS date))) AS gl (CMPNY, GoLiveDate)
    ON i.CMPNY = gl.CMPNY
WHERE gl.GoLiveDate IS NULL
    OR CAST(i.InvoiceDate AS date) >= gl.GoLiveDate

UNION ALL

-- Branch 3: legacy actuals (Source other than D365FO). The customer invoices fact above holds D365 only.
-- The sales fact no longer has the Invoice* columns. For every legacy source the surviving columns hold the same
-- values the Invoice* columns held (vw_EDW_Fact_Sales sets both from the same source expression).
SELECT
      s.CMPNY
    , 'SalesActual'                   AS ModelID          -- fixed label for sales rows
    , CAST(s.[DATE] AS date)          AS [Date]
    , s.DATEKey
    , s.CustomerID
    , s.ProductID
    , s.Quantity                      AS Sales_Quantity
    , s.Quantity_UoM                  AS Unit
    , s.Quantity_LBs
    , s.Quantity_KGs
    , s.Currency                      AS Sales_Currency
    , s.Amount
    , s.Amount_USD
    , s.Amount_EUR
    , s.Amount_CNY
    , s.Price                         AS Sales_Price
    , s.SalesPrice_USD
    , s.SalesPrice_EUR
    , s.SalesPrice_CNY
    , s.[Source]
    , s.Legal_EntityKey
    , s.HistoricCustomerKey
    , s.CustomerKey
    , s.HistoricInvoiceCustomerKey
    , s.InvoiceCustomerKey
    , s.HistoricProductKey
    , s.ProductKey
    , s.SiteKey
    , s.WarehouseKey
    , s.Txn_USD_Rate_Missing
    , s.Txn_EUR_Rate_Missing
    , s.Txn_CNY_Rate_Missing
FROM mtbl_EDW_Fact_Sales AS s
WHERE s.SalesLine_Status = 'Invoiced'
    AND s.[Source] <> 'D365FO'
;
