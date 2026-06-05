-- Auto Generated (Do not modify) 098CF9686B92F884E69EF9A4116F2804CE230602546E79B67A5BBA7DF2400E41
/****** Object:  View [dbo].[vw_EDW_Fact_SalesBudget]    Script Date: 2/2/2026 1:21:38 PM ******/
/****** Object:  View [dbo].[vw_EDW_Fact_SalesBudget]    Script Date: 1/26/2026 9:48:20 AM ******/




CREATE                view [dbo].[vw_EDW_Fact_SalesBudget] as  

SELECT [CMPNY]
	, [SalesLine_Status]
	, [DATE]
	, [DATEKey]
	, [CustomerID]
	, [ProductID]
	, [CPCID]
	, [CPCID_Legacy]
	, [Quantity_LBs]
	, [Amount]
	, [LegalEntityTranslatedToD365]
	, [AccountTranslatedToD365]
	, [ProductTranslatedToD365]
	, [Source]
	, [CustomerKey]
	, [ProductKey]
	, [Legal_EntityKey]
	, [EmployeeKey]
	, [MarketSegmentationKey]
FROM tbl_legacy_budget_data

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
	, b.Quantity_LBs
	, b.Amount
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

 left join [dbo].[XREF_Product_ID] X 
	ON b.ProductID = x.Apollo_ProductID  
	  --AND case when b.Cmpny = '002' then '001' else b.Cmpny end = X.Company  --case statement not used as the XRef has the legacy company values = X.Company

 left join [dbo].[XREF_Customer_ID] y 
	ON b.CustomerID = y.Apollo_CustomerID 
	  AND b.Cmpny = CASE WHEN y.Company in ('001','002') then '101' 
						 WHEN y.Company = '101' THEN '301'  
						 WHEN y.Company = '201' THEN '501'
						 WHEN y.Company = '999' THEN '301'
						 else y.Company end

LEFT JOIN mtbl_EDW_DIM_Account dcc
	ON coalesce(y.D365_CustomerID, b.[CustomerID])  = dcc.Customer_ID
		AND b.Cmpny = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dpc
	ON coalesce(x.D365_ProductID, b.ProductID) = dpc.Product_ID
		--AND b.Cmpny = dpc.CMPNY
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON b.Cmpny = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON dcc.Salesman_ID = de.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON coalesce(y.D365_CustomerID, b.[CustomerID]) = dmsc.CustomerID
		AND coalesce(x.D365_ProductID, b.ProductID) = dmsc.ProductID
		AND b.Cmpny = dmsc.CMPNY
		AND dmsc.RecordStatus=1


--order by 1,2,5,6,4