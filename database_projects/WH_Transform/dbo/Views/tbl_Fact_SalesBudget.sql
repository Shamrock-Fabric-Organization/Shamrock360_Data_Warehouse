

CREATE OR ALTER  view [dbo].[tbl_Fact_SalesBudget] as  

SELECT b.[CMPNY]
	, b.[SalesLine_Status]
	, b.[DATE]
	, b.[DATEKey]
	, b.[CustomerID]
	, b.[ProductID]
	, b.[CPCID]
	, b.[CPCID_Legacy]

	,'LB' as [Quantity_UoM]
	, b.[Quantity_LBs]  Quantity
	,CONVERT(decimal(38,6), b.[Quantity_LBs]) as [Quantity_LBs]
	,CONVERT(decimal(38,6), b.[Quantity_LBs]) * 0.45359237 as [Quantity_KGs]

	,'USD' as [Currency]
	, b.[Amount]
	, CONVERT(decimal(38,6), b.[Amount])                           as [Amount_USD]
	, erTxnEUR.ExchangeRate * CONVERT(decimal(38,6), b.[Amount])   as [Amount_EUR]
	, erTxnCNY.ExchangeRate * CONVERT(decimal(38,6), b.[Amount])   as [Amount_CNY]

	-- Rate-missing flags (1 = real conversion needed but no rate row found)
	, 0                                                          as [Txn_USD_Rate_Missing]
	, CASE WHEN erTxnEUR.ExchangeRate  IS NULL THEN 1 ELSE 0 END as [Txn_EUR_Rate_Missing]
	, CASE WHEN erTxnCNY.ExchangeRate  IS NULL THEN 1 ELSE 0 END as [Txn_CNY_Rate_Missing]

	, b.[LegalEntityTranslatedToD365]
	, b.[AccountTranslatedToD365]
	, b.[ProductTranslatedToD365]
	, b.[Source]
	, b.[CustomerKey]
	, b.[ProductKey]
	, b.[Legal_EntityKey]
	, b.[EmployeeKey]
	, b.[MarketSegmentationKey]
FROM WH_Curated.dbo.tbl_legacy_budget_data b

---- ---- TXN-BASIS RATE JOINS (FROM SL.currencycode) ---- ----
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = 'USD'
		AND erTxnEUR.tocurrencycode   = 'EUR'
		AND erTxnEUR.exchangeratetype = 'Default global rate'
		AND b.[DATE] between erTxnEUR.validfrom and erTxnEUR.validto

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = 'USD'
		AND erTxnCNY.tocurrencycode   = 'CNY'
		AND erTxnCNY.exchangeratetype = 'Default global rate'
		AND b.[DATE] between erTxnCNY.validfrom and erTxnCNY.validto


union all

SELECT CONVERT(varchar(20), b.CMPNY) CMPNY
	, 'Budget 2026' SalesLine_Status
	, CONVERT(datetime2(3),convert(char(8), b.DateKey),112) as DATE
	, b.DATEKey
	--, b.CustomerID
	--, b.ProductID

	,COALESCE(y.D365_CustomerID, b.CustomerID)  as CustomerID

	,COALESCE(x.D365_ProductID, case when trim(b.ProductID)='NULL' then NULL ELSE b.ProductID end) as [ProductID]

	, b.Cmpny 
			+'-'+ COALESCE(y.D365_CustomerID, b.CustomerID, 'UnknownCustomer')
			+'-'+ COALESCE(x.D365_ProductID/*, b.Product*/, case when trim(b.ProductID)='NULL' then NULL ELSE b.ProductID end, 'Unknown Product') 	CPCID
	, b.CPCID CPCID_Legacy

	,'LB' as [Quantity_UoM]
	, b.[Quantity_LBs]  Quantity
	,CONVERT(decimal(38,6), b.[Quantity_LBs]) as [Quantity_LBs]
	,CONVERT(decimal(38,6), b.[Quantity_LBs]) * 0.45359237 as [Quantity_KGs]

	,'USD' as [Currency]
	, b.[Amount]
	, CONVERT(decimal(38,6), b.[Amount])                           as [Amount_USD]
	, erTxnEUR.ExchangeRate * CONVERT(decimal(38,6), b.[Amount])   as [Amount_EUR]
	, erTxnCNY.ExchangeRate * CONVERT(decimal(38,6), b.[Amount])   as [Amount_CNY]

	-- Rate-missing flags (1 = real conversion needed but no rate row found)
	, 0                                                          as [Txn_USD_Rate_Missing]
	, CASE WHEN erTxnEUR.ExchangeRate  IS NULL THEN 1 ELSE 0 END as [Txn_EUR_Rate_Missing]
	, CASE WHEN erTxnCNY.ExchangeRate  IS NULL THEN 1 ELSE 0 END as [Txn_CNY_Rate_Missing]

	, CASE WHEN dle.Legal_EntityKey = -1 THEN 'No' ELSE 'Yes' END LegalEntityTranslatedToD365
	, CASE WHEN y.D365_CustomerID is null THEN 'No' ELSE 'Yes' END AccountTranslatedToD365
	, CASE WHEN x.D365_ProductID is null THEN 'No' ELSE 'Yes' END ProductTranslatedToD365
	, 'Budget 2026' Source
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, COALESCE(/*de2.EmployeeKey,*/ de.EmployeeKey, -1) as EmployeeKey
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey

FROM WH_Raw.dbo.Budget_2026 b

 left join WH_Curated.[dbo].[XREF_Product_ID] X 
	ON b.ProductID = x.Apollo_ProductID  
	  --AND case when b.Cmpny = '002' then '001' else b.Cmpny end = X.Company  --case statement not used as the XRef has the legacy company values = X.Company

 left join WH_Curated.[dbo].[XREF_Customer_ID] y 
	ON b.CustomerID = y.Apollo_CustomerID 
	  AND b.Cmpny = CASE WHEN y.Company in ('001','002') then '101' 
						 WHEN y.Company = '101' THEN '301'  
						 WHEN y.Company = '201' THEN '501'
						 WHEN y.Company = '999' THEN '301'
						 else y.Company end

LEFT JOIN WH_Curated.dbo.mtbl_EDW_DIM_Account dcc
	ON coalesce(y.D365_CustomerID, b.[CustomerID])  = dcc.Customer_ID
		AND b.Cmpny = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN WH_Curated.dbo.mtbl_EDW_DIM_Product dpc
	ON coalesce(x.D365_ProductID, b.ProductID) = dpc.Product_ID
		--AND b.Cmpny = dpc.CMPNY
		AND dpc.Record_Status=1

LEFT JOIN WH_Curated.dbo.mtbl_EDW_DIM_Legal_Entity dle
	ON b.Cmpny = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Curated.dbo.mtbl_EDW_DIM_Employee de
	ON dcc.Salesman_ID = de.Personnel_Number

LEFT JOIN WH_Curated.dbo.mtbl_EDW_DIM_MarketSegmentation dmsc
	ON coalesce(y.D365_CustomerID, b.[CustomerID]) = dmsc.CustomerID
		AND coalesce(x.D365_ProductID, b.ProductID) = dmsc.ProductID
		AND b.Cmpny = dmsc.CMPNY
		AND dmsc.RecordStatus=1

---- ---- TXN-BASIS RATE JOINS (FROM SL.currencycode) ---- ----
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
	ON erTxnEUR.fromcurrencycode = 'USD'
		AND erTxnEUR.tocurrencycode   = 'EUR'
		AND erTxnEUR.exchangeratetype = 'Default global rate'
		AND CONVERT(datetime2(3),convert(char(8), b.DateKey),112) between erTxnEUR.validfrom and erTxnEUR.validto

LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
	ON erTxnCNY.fromcurrencycode = 'USD'
		AND erTxnCNY.tocurrencycode   = 'CNY'
		AND erTxnCNY.exchangeratetype = 'Default global rate'
		AND CONVERT(datetime2(3),convert(char(8), b.DateKey),112) between erTxnCNY.validfrom and erTxnCNY.validto
