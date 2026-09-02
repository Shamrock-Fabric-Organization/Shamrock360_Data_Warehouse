



CREATE OR ALTER VIEW [dbo].[tbl_Fact_DemandForecastDetails]
AS
SELECT
	fs.Snapshot_Date
	, fs.Snapshot_Date_Key
    , CAST(NULL AS VARCHAR(100)) AS Task_Name          -- display: wbsTaskName() -> ProjWBSEstimatesView (an AOT VIEW, not extracted to the lake). 
            --NULL for all non-project forecast lines (empty ProjId/ActivityNumber). 
            --Reconstruct from the view definition only if project forecasts are needed.
    , fs.Dataareaid            AS CMPNY
    , fs.[ModelId]             AS Model
    , CAST(fs.[StartDate] AS date) AS [Date]           -- grid "Date" = StartDate
	, convert(int, convert(char(8),fs.[StartDate],112))	DateKey
    , fs.[CustAccountId]       AS Customer_Account
    --, fs.[CustGroupId]         AS Customer_Group
    --, fs.[ItemGroupId]         AS Item_Group
    , fs.[ItemId]              AS Item_Number
    --, ept.[Name]               AS Product_Name          
    , id.[InventSiteId]        AS Site                  
    , id.[InventLocationId]    AS Warehouse             
    , fs.[ItemAllocateId]      AS Item_Allocation_Key
    , fs.[SalesQty]            AS Sales_Quantity
    , fs.[SalesUnitId]         AS Unit

     , CASE
         WHEN fs.salesunitid = 'lb' THEN 1                                               -- already in LB
         WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor  -- direct sales-unit -> LB conversion
         ELSE (case when fs.salesunitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) * 2.20462262185 -- fallback: convert KG -> LB (1 / 0.45359237)
       END * fs.salesqty      Sales_Quantity_LBs

     , CASE
         WHEN fs.salesunitid = 'kg' THEN 1                                               -- already in KG
         WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor  -- direct sales-unit -> KG conversion
         ELSE (case when fs.salesunitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end ) * 0.45359237  -- fallback: convert LBs -> KG
       END * fs.salesqty      Sales_Quantity_KGs

    , fs.[Currency]            AS Sales_Currency
	---- ---- TXN BASIS: Price (FROM fs.Currency) ---- ----
    , fs.[Amount]              AS Amount               
	, CASE WHEN fs.Currency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * fs.Amount   Amount_USD
	, CASE WHEN fs.Currency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * fs.Amount   Amount_EUR
	, CASE WHEN fs.Currency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * fs.Amount   Amount_CNY

	---- ---- TXN BASIS: Price (FROM fs.Currency) ---- ----
    , fs.[SalesPrice]          AS Sales_Price
	, CASE WHEN fs.Currency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * fs.salesprice   SalesPrice_USD
	, CASE WHEN fs.Currency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * fs.salesprice   SalesPrice_EUR
	, CASE WHEN fs.Currency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * fs.salesprice   SalesPrice_CNY
	,'D365FO'		Source

	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dm.ForecastModelKey, -1) ForecastModelKey
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, ISNULL(dic.CustomerKey, -1) HistoricInvoiceCustomerKey
	, ISNULL(dicc.CustomerKey, -1) InvoiceCustomerKey
	, ISNULL(dp.ProductKey, -1) HistoricProductKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey

	---- ---- RATE_MISSING FLAGS (1 = real conversion needed but no rate row found) ---- ----
	, CASE WHEN fs.Currency      <> 'USD' AND erTxnUSD.ExchangeRate  IS NULL THEN 1 ELSE 0 END  Txn_USD_Rate_Missing
	, CASE WHEN fs.Currency      <> 'EUR' AND erTxnEUR.ExchangeRate  IS NULL THEN 1 ELSE 0 END  Txn_EUR_Rate_Missing
	, CASE WHEN fs.Currency      <> 'CNY' AND erTxnCNY.ExchangeRate  IS NULL THEN 1 ELSE 0 END  Txn_CNY_Rate_Missing


FROM WH_Transform.dbo.tbl_forecastsales_snapshot AS fs

LEFT JOIN WH_Raw.dbo.inventdim AS id
    ON  id.[inventdimid] = fs.[InventDimId]
    AND id.[dataareaid]  = fs.[dataareaid]

LEFT JOIN WH_Raw.dbo.inventtable AS it
    ON  it.[itemid]     = fs.[ItemId]
    AND it.[dataareaid] = fs.[dataareaid]
LEFT JOIN WH_Raw.dbo.ecoresproducttranslation AS ept
    ON  ept.[product]    = it.[product]
    AND ept.[languageid] = 'en-us'
-- NOTE: Task_Name (wbsTaskName -> ProjWBSEstimatesView) is intentionally NULL.
-- ProjWBSEstimatesView is an AOT view (not a base table) and is not extracted to the
-- lake; it contributes nothing for non-project forecast lines. If project forecasts
-- must show Task name, add the AxView_ProjWBSEstimatesView definition 

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND fs.salesunitid = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'
 
 LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
     ON IT.product = UOMC_kg.product
         AND fs.salesunitid = UOMC_kg.SYMBOLFROM
         AND UOMC_kg.SYMBOLTO = 'kg'




LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON fs.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_ForecastModel dm
	ON fs.[ModelID] = dm.ModelID
		AND fs.dataareaid = dm.CMPNY
		AND fs.[StartDate] between dm.RecordEffectiveStartDate and dm.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
	ON fs.[CustAccountId] = dc.Customer_ID
		AND fs.dataareaid = dc.CMPNY
		AND fs.[StartDate] between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dcc
	ON fs.[CustAccountId] = dcc.Customer_ID
		AND fs.dataareaid = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dic
	ON dc.invoice_account = dic.Customer_ID
		AND fs.dataareaid = dic.CMPNY
		AND fs.[StartDate] between dic.RecordEffectiveStartDate and dic.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dicc
	ON dc.invoice_account = dicc.Customer_ID
		AND fs.dataareaid = dicc.CMPNY
		AND dicc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON fs.itemid = dp.Product_ID
		AND fs.dataareaid = dp.CMPNY
		AND fs.[StartDate] between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON fs.itemid = dpc.Product_ID
		AND fs.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON id.inventsiteid = ds.Site_ID
		AND fs.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON fs.dataareaid = dw.CMPNY
		AND id.inventlocationid = dw.Warehouse_ID
		AND fs.[StartDate] between dw.RecordEffectiveStartDate and dw.RecordEffectiveEndDate


---- ---- TXN-BASIS RATE JOINS (FROM fs.currency) ---- ----
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
	ON erTxnUSD.fromcurrencycode = fs.currency
		AND erTxnUSD.tocurrencycode   = 'USD'
		AND erTxnUSD.exchangeratetype = 'Default global rate'
		AND fs.[StartDate] between erTxnUSD.validfrom and erTxnUSD.validto

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = fs.currency
		AND erTxnEUR.tocurrencycode   = 'EUR'
		AND erTxnEUR.exchangeratetype = 'Default global rate'
		AND fs.[StartDate] between erTxnEUR.validfrom and erTxnEUR.validto

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = fs.currency
		AND erTxnCNY.tocurrencycode   = 'CNY'
		AND erTxnCNY.exchangeratetype = 'Default global rate'
		AND fs.[StartDate] between erTxnCNY.validfrom and erTxnCNY.validto
--WHERE fs.modelid = 'Forecast'
