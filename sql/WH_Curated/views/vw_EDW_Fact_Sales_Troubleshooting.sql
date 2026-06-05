-- Auto Generated (Do not modify) 56ECE0F12C7EE1C6638DB86B2AF06D00019622FD802E58776C52D599612493FD




/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 4/1/2026 10:33:39 AM ******/
/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 4/1/2026 9:06:49 AM ******/


/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 3/30/2026 9:26:11 AM ******/

/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 3/11/2026 4:19:02 PM ******/



/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 2/24/2026 12:56:24 PM ******/
/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 2/24/2026 12:34:07 PM ******/

/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 2/5/2026 9:39:22 AM ******/
/****** Object:  View [dbo].[vw_EDW_Fact_Sales]    Script Date: 2/2/2026 12:32:26 PM ******/

--select distinct SalesLine_Status
--from [vw_EDW_Fact_Sales]


--select cmpny
--, date
--, CustomerID
--, Customer_Salesman_ID
--, SalesLine_Salesman_ID
--, CustAcct_EmployeeKey
--, SalesLine_EmployeeKey
--,'@@@@@'
--, *

------select *
--from
--(

CREATE   view [dbo].[vw_EDW_Fact_Sales_Troubleshooting] as  
SELECT 
	'US D365' as Fact_Section
	,[RecordID]
	,[CMPNY]
	,[SalesLine_Status]
	,[DATE]
	,[DATEKey]
	,[OrderDate]
	,[OrderDateKey]
	,[SalesLine_RequestedShipDate]
	,[SalesLine_RequestedShipDateKey]
	,[SalesLine_ShipDate]
	,[SalesLine_ShipDateKey]
	,[SalesLine_DeliveryDate]
	,[SalesLine_DeliveryDateKey]

	,[InvoiceDate]
	,[InvoiceDateKey]
	,[Legal_Entity_ID]
	,[CustomerID]
	,[InvoiceAccount]
	,[ProductID]

	,[CPCID]
	,[InvoiceNo]
	,[Customer_Order_Number]
	,[Quantity]
	,[Quantity_UoM]
	,[Quantity_LBs]
	,[Volume]
	,[Volume_UoM]
	,[Price]
	,[Currency]
	,[Amount]
	,[Amount_Currency]
	,[Returned_Quantity]
	,[Returned_Amount]
	,[SalesLine_Salesman_ID]
	,[Customer_Salesman_ID]
	--,[Total_Direct_Cost_Standard]
	--,[Total_Overhead_Cost_Standard]
	--,[Packaging_Cost_Standard]
	--,[TotalCost]
	,CONVERT(varchar(50), [Source]) AS [Source]
	,[HistoricCustomerKey]
	,[CustomerKey]
	,[HistoricProductKey]
	,[ProductKey]
	,[StandardCostKey]
	,[Legal_EntityKey]
	,[SiteKey]
	,[SalesLine_EmployeeKey]
	,[CustAcct_EmployeeKey]
	,[SalesTaker_EmployeeKey]
	,[WarehouseKey]
	,[SalesOrderKey]
	,[OnHold]
	,[OrderOnHold]
	,[HoldCode]
	,[HoldReasonCode]
	,[SalesOrderLineNumber]
	,[SalesLineCreatedDate]
	,[SalesLineCreatedDateKey]
	--,[HistoricMarketSegmentationKey]  --Per Kevin Y 2026-02-02 historic value not needed
	,[MarketSegmentationKey]
	,[PurchaseOrderFormNumber]

FROM [dbo].[tbl_Fact_Sales]

Union ALL

     SELECT
	 'US RESULTS Legacy' as Fact_Section
	 ,ABS(CAST(CAST(
                HASHBYTES('SHA2_256', 
                    CONCAT(
                        CAST(NEWID() AS VARCHAR(36)), '|'
                        ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                        ,CAST(NEWID() AS VARCHAR(36)), '|'
                        -- Add row-specific data for extra uniqueness
                        ,CAST(s.CMPNY AS VARCHAR(100))
                    )
                ) AS BINARY(8)) AS BIGINT))  AS ID
	,CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end AS CMPNY
	--,CASE WHEN s.Cmpny in ('001','002') then '101' 
	--	 WHEN s.Cmpny = '101' THEN '301'  
	--	 --WHEN s.CMPNY = '999' THEN 'need mapping'
	--	 else s.Cmpny end AS CMPNY

	,CASE WHEN RecordType = 'Open Order' then 'Open' WHEN RecordType = 'Closed Order' then 'Invoiced' else RecordType end as [SalesLine_Status]
	,COALESCE(case when [InvoiceDate]<'01/01/1900' then '01/01/1900' else [InvoiceDate] end, /*SL.shippingdaterequested,*/ [OrderDate]) 	DATE
	,convert(int, convert(char(8),COALESCE([InvoiceDate], /*SL.shippingdaterequested,*/ [OrderDate]),112))	DATEKey
	,[OrderDate]
	,convert(int, convert(char(8),[OrderDate],112)) as [OrderDateKey]
	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	,convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	,isnull(case when ShipDate<'01/01/1900' then '01/01/1900' else ShipDate end, '01/01/1900') as [SalesLine_ShipDate]
	,convert(int, convert(char(8),case when ShipDate<'01/01/1900' then '01/01/1900' else ShipDate end,112)) as [SalesLine_ShipDateKey]

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	,isnull(case when [InvoiceDate]<'01/01/1900' then '01/01/1900' else [InvoiceDate] end, '01/01/1900') AS [InvoiceDate]
	,convert(int, convert(char(8),case when [InvoiceDate]<'01/01/1900' then '01/01/1900' else [InvoiceDate] end,112)) as [InvoiceDateKey]
	,CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end as [Legal_Entity_ID]
	,COALESCE(y.D365_CustomerID, s.CustomerID)  as CustomerID
	,null as [InvoiceAccount]
	----,x.D365_ProductID as [ProductID]  ----replaced with coalesce code below
	,COALESCE(x.D365_ProductID, s.Product) as [ProductID]

	----,[CPCID]  ----replaced with CASE logic code below
	,CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end
			+'-'+ COALESCE(y.D365_CustomerID, s.CustomerID, 'UnknownCustomer')
			+'-'+ COALESCE(x.D365_ProductID, s.Product, 'UnknownProduct') 	CPCID
		 --,CASE WHEN s.Cmpny in ('001','002') then '101' 
		 --WHEN s.Cmpny = '101' THEN '301'  
		 --else s.Cmpny end
			--+'-'+ COALESCE(y.D365_CustomerID, s.CustomerID, 'UnknownCustomer')
			--+'-'+ COALESCE(x.D365_ProductID, s.Product, 'UnknownProduct') 	CPCID
	,[Invoice No] as [InvoiceNo]
	,[Order No] as [Customer_Order_Number]
	,null as [Quantity]
	,null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Volume]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Revenue]) AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), DirectCostPerPound) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), OverheadCostPerPound) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), DirectCostPerPound) + CONVERT(decimal(38,4), OverheadCostPerPound) as [TotalCost]
	,CONVERT(varchar(50), s.[Source]) AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, ISNULL(dp.ProductKey, -1) HistoricProductKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(dsc.StandardCostKey, -1) as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, -1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	,[OrderDate] [SalesLineCreatedDate]
	,convert(int, convert(char(8),[OrderDate],112)) as [SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

FROM [dbo].[legacy_tbl_Fact_Sales] s
 left join [dbo].[XREF_Product_ID] X 
	ON s.Product = x.Apollo_ProductID  
	  --AND case when s.Cmpny = '002' then '001' else s.Cmpny end = X.Company  --case statement not used as the XRef has the legacy company values = X.Company

 left join [dbo].[XREF_Customer_ID] y 
	ON s.CustomerID = y.Apollo_CustomerID 
	  AND s.Cmpny = y.Company



LEFT JOIN mtbl_EDW_DIM_Account dc
	ON coalesce(y.D365_CustomerID, s.[CustomerID])  = dc.Customer_ID
		--AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dc.CMPNY
		AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end = dc.CMPNY
		AND s.[OrderDate] between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	ON coalesce(y.D365_CustomerID, s.[CustomerID])  = dcc.Customer_ID
		--AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dc.CMPNY
		AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
		--AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		-- WHEN s.Cmpny = '101' THEN '301'  
		-- WHEN s.Cmpny = '201' THEN '501'
		-- WHEN s.CMPNY = '999' THEN '301'
		-- else s.Cmpny end = dp.CMPNY
		AND s.[OrderDate] between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
		--AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		-- WHEN s.Cmpny = '101' THEN '301'  
		-- WHEN s.Cmpny = '201' THEN '501'
		-- WHEN s.CMPNY = '999' THEN '301'
		-- else s.Cmpny end = dpc.CMPNY
		AND dpc.Record_Status=1
		 
--LEFT JOIN mtbl_EDW_DIM_Account dc
--	ON coalesce(y.D365_CustomerID, s.[CustomerID])  = dc.Customer_ID
--		AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dc.CMPNY
--		AND s.[OrderDate] between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

--LEFT JOIN mtbl_EDW_DIM_Account dcc
--	ON coalesce(y.D365_CustomerID, s.[CustomerID])  = dcc.Customer_ID
--		AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dcc.CMPNY
--		AND dcc.RecordStatus=1

--LEFT JOIN mtbl_EDW_DIM_Product dp
--	ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
--		AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dp.CMPNY
--		AND s.[OrderDate] between dp.Start_Date and dp.End_Date

--LEFT JOIN mtbl_EDW_DIM_Product dpc
--	ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
--		AND CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end = dpc.CMPNY
--		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON CASE 
				WHEN s.Warehouse IN ('','n.a.','Not Applicable','Not Available') THEN 'UNKNOWN'
				WHEN s.Cmpny in ('001','002') then '101' 
				WHEN s.Cmpny = '101' THEN '301'  
				WHEN s.Cmpny = '201' THEN '501'
				WHEN s.CMPNY = '999' THEN '301'
				else s.Cmpny 
		end  = dw.CMPNY
		AND CASE 
				WHEN Warehouse IN ('','n.a.') THEN 'not applicable'
				ELSE Warehouse
			END = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON s.[CustomerID] = lda.CustomerID
		--AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		-- WHEN s.Cmpny = '101' THEN '301'  
		-- WHEN s.Cmpny = '201' THEN '501'
		-- WHEN s.CMPNY = '999' THEN '301'
		-- else s.Cmpny end = lda.CMPNY
		AND s.Cmpny = lda.CMPNY
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number



LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number



--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON coalesce(y.D365_CustomerID, s.[CustomerID]) = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND coalesce(x.D365_ProductID, s.Product) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CASE WHEN s.Cmpny in ('001','002') then '101'   --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN s.Cmpny = '101' THEN '301'    --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN s.Cmpny = '201' THEN '501'  --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN s.CMPNY = '999' THEN '301'  --Per Kevin Y 2026-02-02 historic value not needed
--		 else s.Cmpny end = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND [OrderDate] between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON coalesce(y.D365_CustomerID, s.[CustomerID]) = dmsc.CustomerID
		AND coalesce(x.D365_ProductID, s.Product) = dmsc.ProductID
		AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end = dmsc.CMPNY
		AND dmsc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_StandardCost dsc
	ON s.Product = dsc.LegacyProductCode
		--AND CASE WHEN s.Cmpny in ('001','002') then '101' 
		-- WHEN s.Cmpny = '101' THEN '301'  
		-- WHEN s.Cmpny = '201' THEN '501'
		-- WHEN s.CMPNY = '999' THEN '301'
		-- else s.Cmpny end = dsc.CMPNY
		AND dsc.RecordStatus=1

WHERE s.Source NOT IN ('BRILJANT', 'TEDA', 'Imputed Data','tbl_Archive_Fact_Sales') --Exclude these sources entirely   --  'tbl_Archive_Fact_Sales'   Corby 1/23
    AND NOT (s.RecordType = 'Open Order' AND s.Source = 'US (Core) RESULTS') --Exclude Open Orders from US Core
	AND NOT (s.RecordType IN ('Budget 2024','Budget 2025') )

----------
union all
----------

-----------------------------------------------------------------------------
-- Section 1A: Current Year - BVBA [Closed Order]
-----------------------------------------------------------------------------

SELECT  
	'BVBA Closed Order CY' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end  Cmpny
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Invoiced' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])),112))	DATEKey
	, CONVERT(datetime2(6), [Ord Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end AS ShipDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end,112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end AS InvoiceDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end,112))	InvoiceDateDateKey

	

	,CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end as [Legal_Entity_ID]
--	, 'A'+f.Cmpny+trim([Customer No])+'000000' as CustomerID

	, 'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6) as CustomerID
	
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.Product)  ProductID
	, 'A' + Trim(f.Cmpny) + Trim([Customer No]) + Trim([Ship To No]) + '---' + Trim(f.Product) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Lbs Shipped]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Extension])     --* 1.17157 AS [Amount]    -- * 1.077372 AS [Amount]  Corby 04/06/2026
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'BRILJANT') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), [Ord Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

FROM tbl_RESULTSSLSBYYR_BVBA f
 left join [dbo].[XREF_Product_ID] X 
	ON f.Product = x.Apollo_ProductID  
	  --AND f.Cmpny = X.Company
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
--	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dc.Customer_ID
	ON 'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No]  as varchar(6)),6) = dc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dc.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
--	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dcc.Customer_ID
	ON'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6) = dcc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp.Product_ID
		----AND f.Cmpny = dp.CMPNY
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dp.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp2.Search_Name
----		AND f.Cmpny = dp2.CMPNY
--		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
--		 WHEN f.Cmpny = '101' THEN '301'  
--		 WHEN f.Cmpny = '201' THEN '501'
--		 WHEN f.CMPNY = '999' THEN '301'
--		 else f.Cmpny end = dp2.CMPNY
		AND CONVERT(datetime2(6), f.[Ord Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc.Product_ID
----		AND f.Cmpny = dpc.CMPNY
--		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
--		 WHEN f.Cmpny = '101' THEN '301'  
--		 WHEN f.Cmpny = '201' THEN '501'
--		 WHEN f.CMPNY = '999' THEN '301'
--		 else f.Cmpny end = dpc.CMPNY
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc2.Search_Name
		----AND f.Cmpny = dpc2.CMPNY
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dpc2.CMPNY
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dle.CMPNY
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON CASE 
				WHEN f.Warehouse IN ('','n.a.','Not Applicable','Not Available') THEN 'UNKNOWN'
				WHEN f.Cmpny in ('001','002') then '101' 
				WHEN f.Cmpny = '101' THEN '301'  
				WHEN f.Cmpny = '201' THEN '501'
				WHEN f.CMPNY = '999' THEN '301'
				ELSE f.Cmpny 
			END  = dw.CMPNY
		AND CASE 
				WHEN f.Warehouse IN ('','n.a.') THEN 'not applicable'
				ELSE f.Warehouse
			END = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON 'A'+f.Cmpny+[Customer No]+'000000' = lda.CustomerID
		AND f.Cmpny = lda.CMPNY
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.Product) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CASE WHEN f.Cmpny in ('001','002') then '101'   --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '101' THEN '301'    --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '201' THEN '501'  --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.CMPNY = '999' THEN '301'  --Per Kevin Y 2026-02-02 historic value not needed
--		 else f.Cmpny end = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CONVERT(datetime2(6), [Ord Date] ) between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.Product) = dmsc.ProductID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dmsc.CMPNY
		AND dmsc.RecordStatus=1


--LEFT OUTER JOIN vw360_Dim_Account
--	ON 'A' + f.Cmpny + f.[Customer No] + f.[Ship To No] = vw360_Dim_Account.CustomerID
--LEFT OUTER JOIN vw360_Dim_Product
--	ON f.Product = vw360_Dim_Product.Product_Code

WHERE [Customer No] NOT LIKE 'SHAM%'
	AND Cast([Invoice Date] AS DATE) >= '2026-01-01'  -- and [Invoice No] = '20260018'   -- Corby update 2-27-26 '01/01/2023'

----------
union all
----------

-----------------------------------------------------------------------------
-- Section 1B: Current Year - TEDA [Closed Order]
-----------------------------------------------------------------------------

SELECT  
	'TEDA Closed Order CY' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, '501' Cmpny  --Changed from 201 to 501 for D365
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Invoiced' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(f.[Invoice Date], f.[Order Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(f.[Invoice Date], f.[Order Date])),112))	DATEKey
	, CONVERT(datetime2(6), f.[Order Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, CONVERT(datetime2(6), f.[Invoice Date] ) AS ShipDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Invoice Date] ),112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, CONVERT(datetime2(6), f.[Invoice Date] ) AS InvoiceDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Invoice Date] ),112))	InvoiceDateDateKey
	, '501' as [Legal_Entity_ID]  --Changed from 201 to 501 for D365

	, 'A201'+Trim(f.[Customer No])+'000000'  CustomerID
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.[Product Name])  ProductID
	, 'A201'+Trim(f.[Customer No])+'000000'+'---'+Trim(f.[Product Name]) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Net Weight LBS]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Net Amount]) AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'TEDA') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), f.[Order Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

from tbl_RESULTSSLSBYYR_TEDA f
left join [dbo].[XREF_Product_ID] X 
	ON f.[Product Name] = x.Apollo_ProductID  
	  --AND '101' = case when X.Company='001' then '101' else X.Company end
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dc.Customer_ID
		AND '501' = dc.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dcc.Customer_ID
		AND '501' = dcc.CMPNY  --Changed from 201 to 501 for D365
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp.Product_ID
		--AND '501' = dp.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp2.Search_Name
		--AND '501' = dp2.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc.Product_ID
		--AND '501' = dpc.CMPNY  --Changed from 201 to 501 for D365
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc2.Search_Name
		--AND '501' = dpc2.CMPNY  --Changed from 201 to 501 for D365
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON '501' = dle.CMPNY  --Changed from 201 to 501 for D365
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON '201' = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON 'A201'+Trim(f.[Customer No])+'000000' = lda.CustomerID
		AND '201' = lda.CMPNY  --Changed from 201 to 501 for D365 -- need to use the legacy company of 201
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A201'+Trim(f.[Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND '501' = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND f.[Order Date] between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A201'+Trim(f.[Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dmsc.ProductID
		AND '501' = dmsc.CMPNY
		AND dmsc.RecordStatus=1

--left outer join vw360_Dim_Account on
--'A201'+tbl_RESULTSSLSBYYR_TEDA.[Customer No]+'000000'  = vw360_Dim_Account.CustomerID

--left outer join vw360_Dim_Product on
--tbl_RESULTSSLSBYYR_TEDA.[Product Name]= vw360_Dim_Product.Product_Code

--where 
--[Customer No] not in ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
--and isNull([Invoice No],'0')<>'0'
--and CAST([Invoice Date] as date)>= '01/01/2023'

where 
[Customer No] not in ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
and [Customer Name] not like '%SHAM%'
and isNull([Invoice No],'0')<>'0'
and CAST([Invoice Date] as date)>= '2026-01-01'



----------
union all
----------


-----------------------------------------------------------------------------
-- Section 3A: Open Orders BVBA
------------------------------------------------------------------------------

SELECT  	
	'BVBA Open Order CY' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end Cmpny
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Open' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])),112))	DATEKey
	, CONVERT(datetime2(6), [Ord Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end AS ShipDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end,112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end AS InvoiceDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end,112))	InvoiceDateDateKey
	,CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end as [Legal_Entity_ID]
--	, 'A'+f.Cmpny+trim([Customer No])+'000000' as CustomerID

	, 'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6) as CustomerID
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.Product)  ProductID
	, 'A'+Trim(f.Cmpny)+Trim([Customer No])+Trim([Ship To No])+'---'+Trim(Product) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Lbs Ordered]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Extension]) * 1.077372 AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'BRILJANT') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), [Ord Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

from tbl_RESULTSSLSBYYR_BVBA_Open f
 left join [dbo].[XREF_Product_ID] X 
	ON f.Product = x.Apollo_ProductID  
	--  AND case when f.Cmpny='201' then '101' else f.Cmpny end = X.Company
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dc.Customer_ID
		--'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6)  = dc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dc.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dcc.Customer_ID
		--'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6)  = dcc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp.Product_ID
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dp.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp2.Search_Name
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dp2.CMPNY
		AND CONVERT(datetime2(6), f.[Ord Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc.Product_ID
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dpc.CMPNY
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc2.Search_Name
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dpc2.CMPNY
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dle.CMPNY
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON CASE 
				WHEN f.Warehouse IN ('','n.a.','Not Applicable','Not Available') THEN 'UNKNOWN'
				WHEN f.Cmpny in ('001','002') then '101' 
				WHEN f.Cmpny = '101' THEN '301'  
				WHEN f.Cmpny = '201' THEN '501'
				WHEN f.CMPNY = '999' THEN '301'
				ELSE f.Cmpny 
			END  = dw.CMPNY
		AND CASE 
				WHEN f.Warehouse IN ('','n.a.') THEN 'not applicable'
				ELSE f.Warehouse
			END = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON f.[Customer No] = lda.CustomerID
		AND f.Cmpny = lda.CMPNY
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.Product) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CASE WHEN f.Cmpny in ('001','002') then '101'   --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '101' THEN '301'    --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '201' THEN '501'  --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.CMPNY = '999' THEN '301'  --Per Kevin Y 2026-02-02 historic value not needed
--		 else f.Cmpny end = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CONVERT(datetime2(6), [Ord Date] ) between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.Product) = dmsc.ProductID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dmsc.CMPNY
		AND dmsc.RecordStatus=1

--left outer join vw360_Dim_Account on
--'A'+tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny+tbl_RESULTSSLSBYYR_BVBA_Open.[Customer No]+tbl_RESULTSSLSBYYR_BVBA_Open.[Ship To No]  = vw360_Dim_Account.CustomerID

--left outer join vw360_Dim_Product on
--tbl_RESULTSSLSBYYR_BVBA_Open.Product= vw360_Dim_Product.Product_Code

where 
[Customer No] not like ('%SHAM%')


-------------
union all
-------------

-----------------------------------------------------------------------------
-- Section 3B: Current Year - TEDA [Open Order]
-----------------------------------------------------------------------------

SELECT  
	'TEDA Open Order CY' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, '501' Cmpny  --Changed from 201 to 501 for D365
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Open' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(f.[expected Ship Date], f.[Order Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(f.[expected Ship Date], f.[Order Date])),112))	DATEKey
	, CONVERT(datetime2(6), f.[Order Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, CONVERT(datetime2(6), f.[expected Ship Date] ) AS ShipDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[expected Ship Date] ),112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, CONVERT(datetime2(6), f.[expected Ship Date] ) AS InvoiceDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[expected Ship Date] ),112))	InvoiceDateDateKey
	, '501' as [Legal_Entity_ID]  --Changed from 201 to 501 for D365

	, 'A201'+Trim(f.[Customer No])+'000000' CustomerID
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.[Product Name])  ProductID
	, 'A201'+Trim([Customer No])+'000000'+'---'+Trim([Product Name]) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Net Weight LBS]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Net Amount]) AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'TEDA') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), f.[Order Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

from tbl_RESULTSSLSBYYR_TEDA f
left join [dbo].[XREF_Product_ID] X 
	ON f.[Product Name] = x.Apollo_ProductID  
--	  AND '101' = case when X.Company='001' then '101' else X.Company end
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dc.Customer_ID
		AND '501' = dc.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dcc.Customer_ID
		AND '501' = dcc.CMPNY  --Changed from 201 to 501 for D365
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp.Product_ID
		--AND '501' = dp.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp2.Search_Name
		--AND '501' = dp2.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc.Product_ID
		--AND '501' = dpc.CMPNY  --Changed from 201 to 501 for D365
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc2.Search_Name
		--AND '501' = dpc2.CMPNY  --Changed from 201 to 501 for D365
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON '501' = dle.CMPNY  --Changed from 201 to 501 for D365
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON '201' = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON 'A201'+Trim(f.[Customer No])+'000000' = lda.CustomerID
		AND '201' = lda.CMPNY  --Changed from 201 to 501 for D365 -- need to use the legacy company of 201
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A201'+Trim(f.[Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND '501' = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CONVERT(datetime2(6), f.[Order Date] ) between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A201'+Trim(f.[Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dmsc.ProductID
		AND '501' = dmsc.CMPNY
		AND dmsc.RecordStatus=1

--left outer join vw360_Dim_Account on
--'A201'+tbl_RESULTSSLSBYYR_TEDA.[Customer No]+'000000'  = vw360_Dim_Account.CustomerID

--left outer join vw360_Dim_Product on
--tbl_RESULTSSLSBYYR_TEDA.[Product Name]= vw360_Dim_Product.Product_Code

where 
[Customer No] not in ('C1E101','C1E201')
and [Customer Name] not like '%SHAM%'
and isNull([Invoice No],'Open Order')='Open Order'

UNION ALL
-------------------------------------------------------------------------------------------
--  Section 4A
-- Reconciliation Amount per Mohamed
-------------------------------------------------------------------------------------------

     SELECT Top 1 
	 'BVBA Reconciliation' as Fact_Section
	,ABS(CAST(CAST(
                HASHBYTES('SHA2_256', 
                    CONCAT(
                        CAST(NEWID() AS VARCHAR(36)), '|'
                        ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                        ,CAST(NEWID() AS VARCHAR(36)), '|'
                        -- Add row-specific data for extra uniqueness
                        ,CAST(s.CMPNY AS VARCHAR(100))
                    )
                ) AS BINARY(8)) AS BIGINT))  AS ID
	,CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end AS CMPNY
	,'Invoiced' as [SalesLine_Status]
	,d.Date as 	DATE
	,d.DateKey	DATEKey
	,'01/01/1900' as [OrderDate]
	,19000101 as [OrderDateKey]
	,'01/01/1900' as [SalesLine_RequestedShipDate]
	,19000101 as [SalesLine_RequestedShipDateKey]
	,'01/01/1900' as [SalesLine_ShipDate]
	,19000101 as [SalesLine_ShipDateKey]
	,'01/01/1900' as [SalesLine_DeliveryDate]
	,19000101 as [SalesLine_DeliveryDateKey]
	,'01/01/1900' AS [InvoiceDate]
	,19000101 as [InvoiceDateKey]
	,CASE WHEN s.Cmpny='001' then '101' else s.Cmpny end as [Legal_Entity_ID]
	,null as CustomerID
	,s.[Reconciliation_Year]  as [InvoiceAccount]
	,null as [ProductID]
	,CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end
			+'-'+  'ADJUSTMENT' as CPCID
	,null as [InvoiceNo]
	,null as [Customer_Order_Number]
	,null as [Quantity]
	,null as [Quantity_UoM]
	,0 as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,s.[Total_Adjustments] AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	,'ADJUSTMENTS' AS [Source]
	,-1 as HistoricCustomerKey
	, -1 as CustomerKey
	,-1 as HistoricProductKey
	, -1 as ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) as  Legal_EntityKey
	,-1 as [SiteKey]
	,-1 as  [SalesLine_EmployeeKey]
	, -1 as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, -1 as WarehouseKey
	, -1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	,'01/01/1900' as [SalesLineCreatedDate]
	,19000101 as [SalesLineCreatedDateKey]
	,-1 as MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]
FROM [dbo].[tbl_Reconciliation_Adjustments] s
left outer join (select [Reconciliation Year], min(date) Date, min(datekey) DateKey FROM [dbo].[tbl_Dim_Date] group by [Reconciliation Year]) d on
d.[Reconciliation Year] = s.[Reconciliation_Year]

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON CASE WHEN s.Cmpny in ('001','002') then '101' 
		 WHEN s.Cmpny = '101' THEN '301'  
		 WHEN s.Cmpny = '201' THEN '501'
		 WHEN s.CMPNY = '999' THEN '301'
		 else s.Cmpny end = dle.CMPNY  --Changed from 201 to 501 for D365
		AND dle.RecordStatus=1


----------
union all
----------


-----------------------------------------------------------------------------------
---  Begin STATIC TABLES    Data Through  12/31/2025
---  BVBA   and   TEDA
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Section S1: Thru_2025 - BVBA [Closed Order]
-----------------------------------------------------------------------------

SELECT  
	'BVBA Closed Order Legacy' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end  Cmpny
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Invoiced' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<='01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(
					case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then NULL else CONVERT(datetime2(6), [Invoice Date] ) end
					,case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then NULL else CONVERT(datetime2(6), [Ship Date] ) end 
					, [Ord Date])),112))	DATEKey
	, CONVERT(datetime2(6), [Ord Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end AS ShipDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Ship Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Ship Date] ) end,112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end AS InvoiceDate
	, convert(int, convert(char(8), case when CONVERT(datetime2(6), [Invoice Date] )<'01/01/1900' then '01/01/1900' else CONVERT(datetime2(6), [Invoice Date] ) end,112))	InvoiceDateDateKey

	

	,CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end as [Legal_Entity_ID]
--	, 'A'+f.Cmpny+trim([Customer No])+'000000' as CustomerID

	, 'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6) as CustomerID
	
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.Product)  ProductID
	, 'A' + Trim(f.Cmpny) + Trim([Customer No]) + Trim([Ship To No]) + '---' + Trim(f.Product) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Lbs Shipped]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Extension]) * 1.077372 AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'BRILJANT') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), [Ord Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), [Ord Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

FROM tbl_RESULTSSLSBYYR_BVBA_Thru2025 f
 left join [dbo].[XREF_Product_ID] X 
	ON f.Product = x.Apollo_ProductID  
	  --AND f.Cmpny = X.Company
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dc.Customer_ID
		--'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No]  as varchar(6)),6) = dc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dc.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
--	ON f.[Customer No]  = dc.Customer_ID
	ON 'A'+f.Cmpny+trim([Customer No])+'000000'  = dcc.Customer_ID
		--'A'+f.Cmpny+trim([Customer No])+RIGHT('000000'+CAST([Ship To No] as varchar(6)),6) = dcc.Customer_ID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp.Product_ID
		----AND f.Cmpny = dp.CMPNY
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dp.CMPNY
		AND CONVERT(datetime2(6), [Ord Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dp2.Search_Name
----		AND f.Cmpny = dp2.CMPNY
--		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
--		 WHEN f.Cmpny = '101' THEN '301'  
--		 WHEN f.Cmpny = '201' THEN '501'
--		 WHEN f.CMPNY = '999' THEN '301'
--		 else f.Cmpny end = dp2.CMPNY
		AND CONVERT(datetime2(6), f.[Ord Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc.Product_ID
----		AND f.Cmpny = dpc.CMPNY
--		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
--		 WHEN f.Cmpny = '101' THEN '301'  
--		 WHEN f.Cmpny = '201' THEN '501'
--		 WHEN f.CMPNY = '999' THEN '301'
--		 else f.Cmpny end = dpc.CMPNY
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.Product) = dpc2.Search_Name
		----AND f.Cmpny = dpc2.CMPNY
		--AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		-- WHEN f.Cmpny = '101' THEN '301'  
		-- WHEN f.Cmpny = '201' THEN '501'
		-- WHEN f.CMPNY = '999' THEN '301'
		-- else f.Cmpny end = dpc2.CMPNY
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dle.CMPNY
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON CASE 
				WHEN f.Warehouse IN ('','n.a.','Not Applicable','Not Available') THEN 'UNKNOWN'
				WHEN f.Cmpny in ('001','002') then '101' 
				WHEN f.Cmpny = '101' THEN '301'  
				WHEN f.Cmpny = '201' THEN '501'
				WHEN f.CMPNY = '999' THEN '301'
				ELSE f.Cmpny 
			END  = dw.CMPNY
		AND CASE 
				WHEN f.Warehouse IN ('','n.a.') THEN 'not applicable'
				ELSE f.Warehouse
			END = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON 'A'+f.Cmpny+[Customer No]+'000000' = lda.CustomerID
		AND f.Cmpny = lda.CMPNY
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.Product) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CASE WHEN f.Cmpny in ('001','002') then '101'   --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '101' THEN '301'    --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.Cmpny = '201' THEN '501'  --Per Kevin Y 2026-02-02 historic value not needed
--		 WHEN f.CMPNY = '999' THEN '301'  --Per Kevin Y 2026-02-02 historic value not needed
--		 else f.Cmpny end = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND CONVERT(datetime2(6), [Ord Date] ) between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A'+f.Cmpny+trim([Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.Product) = dmsc.ProductID
		AND CASE WHEN f.Cmpny in ('001','002') then '101' 
		 WHEN f.Cmpny = '101' THEN '301'  
		 WHEN f.Cmpny = '201' THEN '501'
		 WHEN f.CMPNY = '999' THEN '301'
		 else f.Cmpny end = dmsc.CMPNY
		AND dmsc.RecordStatus=1


--LEFT OUTER JOIN vw360_Dim_Account
--	ON 'A' + f.Cmpny + f.[Customer No] + f.[Ship To No] = vw360_Dim_Account.CustomerID
--LEFT OUTER JOIN vw360_Dim_Product
--	ON f.Product = vw360_Dim_Product.Product_Code

WHERE [Customer No] NOT LIKE 'SHAM%'
--	AND Cast([Invoice Date] AS DATE) >= '2026-01-01'       -- Corby Static update 2-27-26 '01/01/2023'

----------
union all
----------

-----------------------------------------------------------------------------
-- Section S2: Thru_2025 - TEDA [Closed Order]
-----------------------------------------------------------------------------

SELECT  
	'TEDA Closed Order Legacy' as Fact_Section
	,ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(f.[Order No] AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))  AS ID
	, '501' Cmpny  --Changed from 201 to 501 for D365
	--, CASE WHEN f.RecordType = 'Open Order' then 'Open' WHEN f.RecordType = 'Closed Order' then 'Invoiced' else f.RecordType end as [SalesLine_Status]
	, 'Invoiced' AS [SalesLine_Status]
	, CONVERT(datetime2(6), COALESCE(f.[Invoice Date], f.[Order Date])) 	DATE
	, convert(int, convert(char(8), CONVERT(datetime2(6), COALESCE(f.[Invoice Date], f.[Order Date])),112))	DATEKey
	, CONVERT(datetime2(6), f.[Order Date] ) AS OrderDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	OrderDateKey
	, CONVERT(datetime2(6), '01/01/1900') as [SalesLine_RequestedShipDate]
	, convert(int, 19000101) as [SalesLine_RequestedShipDateKey]
	, CONVERT(datetime2(6), f.[Invoice Date] ) AS ShipDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Invoice Date] ),112))	ShipDateKey

	,CONVERT(datetime2(6), '01/01/1900') as [SalesLine_DeliveryDate]
	,convert(int, 19000101) as [SalesLine_DeliveryDateKey]

	, CONVERT(datetime2(6), f.[Invoice Date] ) AS InvoiceDate
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Invoice Date] ),112))	InvoiceDateDateKey
	, '501' as [Legal_Entity_ID]  --Changed from 201 to 501 for D365

	, 'A201'+Trim(f.[Customer No])+'000000'  CustomerID
	, null as [InvoiceAccount]
	, COALESCE(x.D365_ProductID, f.[Product Name])  ProductID
	, 'A201'+Trim(f.[Customer No])+'000000'+'---'+Trim(f.[Product Name]) AS CPCID
	, [Invoice No]  InvoiceNo
	, [Order No]  Customer_Order_Number
	, null as [Quantity]
	, null as [Quantity_UoM]
	,CONVERT(decimal(38,6), [Net Weight LBS]) as [Quantity_LBs]
	,null AS [Volume]
	,null as [Volume_UoM]
	,null as [Price]
	,null as [Currency]
	,CONVERT(decimal(38,6), [Net Amount]) AS [Amount]
	,null as [Amount_Currency]
	,null as [Returned_Quantity]
	,null as [Returned_Amount]
	,null as [SalesLine_Salesman_ID]
	,null as [Customer_Salesman_ID]
	--,CONVERT(decimal(38,4), 0) as [Total_Direct_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Total_Overhead_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [Packaging_Cost_Standard]
	--,CONVERT(decimal(38,4), 0) as [TotalCost]
	,CONVERT(varchar(50),'TEDA') AS [Source]
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, COALESCE(dp.ProductKey, dp2.ProductKey, -1) HistoricProductKey
	, COALESCE(dpc.ProductKey, dpc2.ProductKey, -1) ProductKey
	,-1 as [StandardCostKey]
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	,-1 as [SiteKey]
	, ISNULL(de.EmployeeKey, -1) as [SalesLine_EmployeeKey]
	--, COALESCE(de2.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, COALESCE(de2.EmployeeKey, de3.EmployeeKey, de.EmployeeKey, -1) as [CustAcct_EmployeeKey]
	, -1 as [SalesTaker_EmployeeKey]
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	,-1 as [SalesOrderKey]
	,null as [OnHold]
	,null as [OrderOnHold]
	,null as [HoldCode]
	,null as [HoldReasonCode]
	,null as [SalesOrderLineNumber]
	, CONVERT(datetime2(6), f.[Order Date] ) AS [SalesLineCreatedDate]
	, convert(int, convert(char(8), CONVERT(datetime2(6), f.[Order Date] ),112))	[SalesLineCreatedDateKey]
	--, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	,NULL [PurchaseOrderFormNumber]

from tbl_RESULTSSLSBYYR_TEDA_Thru2025 f
left join [dbo].[XREF_Product_ID] X 
	ON f.[Product Name] = x.Apollo_ProductID  
	  --AND '101' = case when X.Company='001' then '101' else X.Company end
	  
LEFT JOIN mtbl_EDW_DIM_Account dc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dc.Customer_ID
		AND '501' = dc.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN mtbl_EDW_DIM_Account dcc
	--ON coalesce(y.D365_CustomerID, f.[Customer No])  = dc.Customer_ID
	ON 'A201'+Trim(f.[Customer No])+'000000'  = dcc.Customer_ID
		AND '501' = dcc.CMPNY  --Changed from 201 to 501 for D365
		AND dcc.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Product dp
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp.Product_ID
		--AND '501' = dp.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp.Start_Date and dp.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dp2
	--ON coalesce(x.D365_ProductID, s.Product) = dp.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dp2.Search_Name
		--AND '501' = dp2.CMPNY  --Changed from 201 to 501 for D365
		AND CONVERT(datetime2(6), f.[Order Date] ) between dp2.Start_Date and dp2.End_Date

LEFT JOIN mtbl_EDW_DIM_Product dpc
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc.Product_ID
		--AND '501' = dpc.CMPNY  --Changed from 201 to 501 for D365
		AND dpc.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Product dpc2
	--ON coalesce(x.D365_ProductID, s.Product) = dpc.Product_ID
	ON COALESCE(x.D365_ProductID, f.[Product Name]) = dpc2.Search_Name
		--AND '501' = dpc2.CMPNY  --Changed from 201 to 501 for D365
		AND dpc2.Record_Status=1

LEFT JOIN mtbl_EDW_DIM_Legal_Entity dle
	ON '501' = dle.CMPNY  --Changed from 201 to 501 for D365
		AND dle.RecordStatus=1


LEFT JOIN mtbl_EDW_DIM_Warehouse dw
	ON '201' = dw.Warehouse_ID

LEFT JOIN [dbo].[tbl_DIM_Accounts] lda --Legacy Account data with Salesman needed
	ON 'A201'+Trim(f.[Customer No])+'000000' = lda.CustomerID
		AND '201' = lda.CMPNY  --Changed from 201 to 501 for D365 -- need to use the legacy company of 201
		AND lda.RecordStatus=1

LEFT JOIN mtbl_EDW_DIM_Employee de
	ON lda.Salesman = de.Employee_Name

--LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
--	ON xrs.Apollo_SalesmanName = lda.Salesman

--LEFT JOIN mtbl_EDW_DIM_Employee de2
--	ON xrs.D365_SalesmanID = de2.Personnel_Number

LEFT JOIN mtbl_EDW_DIM_Employee de2
	--ON xrs.D365_SalesmanID = de2.Personnel_Number
	ON dcc.Salesman_ID = de2.Personnel_Number
	  AND de2.RecordStatus = 1

LEFT JOIN [dbo].[XREF_Salesman_ID] xrs
	ON xrs.Apollo_SalesmanName = lda.Salesman

LEFT JOIN mtbl_EDW_DIM_Employee de3
	ON xrs.D365_SalesmanID = de3.Personnel_Number

--LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON 'A201'+Trim(f.[Customer No])+'000000' = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND '501' = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND f.[Order Date] between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN mtbl_EDW_DIM_MarketSegmentation dmsc
	ON 'A201'+Trim(f.[Customer No])+'000000' = dmsc.CustomerID
		AND COALESCE(x.D365_ProductID, f.[Product Name]) = dmsc.ProductID
		AND '501' = dmsc.CMPNY
		AND dmsc.RecordStatus=1

--left outer join vw360_Dim_Account on
--'A201'+tbl_RESULTSSLSBYYR_TEDA.[Customer No]+'000000'  = vw360_Dim_Account.CustomerID

--left outer join vw360_Dim_Product on
--tbl_RESULTSSLSBYYR_TEDA.[Product Name]= vw360_Dim_Product.Product_Code

--where 
--[Customer No] not in ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
--and isNull([Invoice No],'0')<>'0'
--and CAST([Invoice Date] as date)>= '01/01/2023'

where 
[Customer No] not in ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
and isNull([Invoice No],'0')<>'0'
--and CAST([Invoice Date] as date)>= '2026-01-01'                     -- Corby Static update 2-27-26 '01/01/2023'