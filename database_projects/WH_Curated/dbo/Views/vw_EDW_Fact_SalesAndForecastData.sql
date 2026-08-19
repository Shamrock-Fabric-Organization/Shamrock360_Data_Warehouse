
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
FROM tbl_Fact_DemandForecastDetails AS f
where f.Model = 'Forecast'

UNION ALL

SELECT
      s.CMPNY
    , 'SalesActual'                   AS ModelID          -- fixed label for sales rows
    , CAST(s.[DATE] AS date)          AS [Date]
    , s.DATEKey
    , s.CustomerID
    , s.ProductID
    ----, s.Quantity
    ----, s.Quantity_UoM
    ----, s.Quantity_LBs
    ----, s.Quantity_KGs
    ----, s.Currency
    ----, s.Amount
    ----, s.Amount_USD
    ----, s.Amount_EUR
    ----, s.Amount_CNY

    , s.InvoiceQty
    , s.InvoiceSalesUnit InvoiceQuantity_UoM
    , s.InvoiceQuantity_LBs
    , s.InvoiceQuantity_KGs
    , s.InvoiceCurrency_Code
    , s.InvoiceLineAmount
    , s.InvoiceLineAmount_USD
    , s.InvoiceLineAmount_EUR
    , s.InvoiceLineAmount_CNY

    , s.Price
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
    --, s.Txn_USD_Rate_Missing
    --, s.Txn_EUR_Rate_Missing
    --, s.Txn_CNY_Rate_Missing
    , s.InvoiceTxn_USD_Rate_Missing
    , s.InvoiceTxn_EUR_Rate_Missing
    , s.InvoiceTxn_CNY_Rate_Missing
FROM mtbl_EDW_Fact_Sales AS s
WHERE SalesLine_Status = 'Invoiced'
;
