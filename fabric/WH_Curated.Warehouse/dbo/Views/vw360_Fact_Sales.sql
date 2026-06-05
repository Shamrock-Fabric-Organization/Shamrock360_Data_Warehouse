-- Auto Generated (Do not modify) 25CA1AA6082BE5A932333A1B714D273BB6EFC04F7B6E4A6C822F236016C888A5









/****** Object:  View [dbo].[vw360_Fact_Sales]    Script Date: 9/14/2025 5:35:25 PM ******/
CREATE      view [dbo].[vw360_Fact_Sales] as
--------------------------------------------------------------------------------
-- Section 0: Impute Zero Sales US/Tolling/BVBA/TEDA [ Closed Order]
--------------------------------------------------------------------------------
SELECT [Cmpny]
      ,[Order No]
      ,[Customer PO]
      ,[Invoice No]
      ,[IncoTerms]
      ,[Warehouse]
      ,[RecordType]
      ,[OrderDate]
      ,[InvoiceDate]
      ,[ShipDate]
      ,[Customer No]
      ,[Ship To No]
      ,[CustomerID]
      ,[CPCID]
      ,[CPAID]
      ,[CostingLinkID]
      ,[Product]
      ,[Revenue]
      ,[Volume]
      ,[MaterialCostPerPound]
      ,[DirectCostPerPound]
      ,[OSProcessingCostPerPound]
      ,[OverheadCostPerPound]
      ,[Source]
  FROM [dbo].[legacy_tbl_Fact_Sales] s
  WHERE s.Source NOT IN ('BRILJANT', 'TEDA', 'Imputed Data') --Exclude these sources entirely
    AND NOT (s.RecordType = 'Open Order' AND s.Source = 'US (Core) RESULTS') --Exclude Open Orders from US Core

--select distinct source from legacy_tbl_Fact_Sales where source not in ('BRILJANT', 'TEDA')
--select distinct source from vw_EDW_FACT_SALes

UNION ALL

Select
CASE WHEN Cmpny='101' then '001' else Cmpny end AS CMPNY
,[Customer_Order_Number] as	 [Order No]
,Null as	 [Customer PO]
,InvoiceNo as	 [Invoice No]
,Null as	 IncoTerms
,Null as	Warehouse
,CASE WHEN ([SalesLine_Status] = 'Delivered' OR [SalesLine_Status] =  'Invoiced') THEN 'Closed Order' 
WHEN ([SalesLine_Status] = 'Open' ) THEN 'Open Order' END as RecordType
,Orderdate as	OrderDate
,InvoiceDate as	InvoiceDate
,SalesLine_ShipDate as	ShipDate
,CustomerId as	[Customer No]
,Null as	[Ship To No]
,CustomerID
,Null as	CPCID
,Null as	CPAID
,Null as	CostingLinkID
,ProductID
,[Amount] as	Revenue
,[Quantity_LBs] as	Volume
,Null as	MaterialCostPerPound
,Total_Direct_Cost_Standard as	DirectCostPerPound
,Null as	OSProcessingCostPerPound
,Total_Overhead_Cost_Standard as	OverheadCostPerPound
,Source as	Source
from tbl_Fact_Sales
 --left join [dbo].[XREF_Product_ID] X ON ProductID = D365_ProductID  
 --left join [dbo].[XREF_Customer_ID] y ON CustomerID = D365_CustomerID 
 
----------
union all
----------

-----------------------------------------------------------------------------
-- Section 1A: Current Year - BVBA [Closed Order]
-----------------------------------------------------------------------------

select 
tbl_RESULTSSLSBYYR_BVBA.Cmpny,
[Order No],
[Customer PO],
[Invoice No],
[FOB Terms] as IncoTerms,
Warehouse,
'Closed Order' as RecordType,
Cast([Ord Date] as date) as OrderDate,
Cast([Invoice Date]as date) as InvoiceDate,
--CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2)as date)as InvoiceDate,
Cast([Ship Date] as date) as ShipDate,
[Customer No],
RIGHT('000000'+CAST([Ship To No]as varchar(6)),6) as [Ship To No],
'A'+tbl_RESULTSSLSBYYR_BVBA.Cmpny+[Customer No]+RIGHT('000000'+CAST([Ship To No]as varchar(6)),6) as CustomerID,
'A'+Trim(tbl_RESULTSSLSBYYR_BVBA.Cmpny)+Trim([Customer No])+Trim([Ship To No])+'---'+Trim(Product) as CPCID,
isNull(GlobalName,'missing Customer name')+' --- '+ isNull(vw360_Dim_Product.Product_Name,'missing ProductName') as CPAID,
'A'+tbl_RESULTSSLSBYYR_BVBA.Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]as CostingLinkID,
Product,
Cast([Extension]as float)*1.077372 as Revenue,
Cast([Lbs Shipped] as float) as Volume,
0 as MaterialCostPerPound,
0 as DirectCostPerPound,
0 as OSProcessingCostPerPound,
0 as OverheadCostPerPound,
'BRILJANT' as Source
from tbl_RESULTSSLSBYYR_BVBA

--left outer join vw360_CostByInvoice on
--'A'+Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]=LinkID

left outer join vw360_Dim_Account on
'A'+tbl_RESULTSSLSBYYR_BVBA.Cmpny+tbl_RESULTSSLSBYYR_BVBA.[Customer No]+tbl_RESULTSSLSBYYR_BVBA.[Ship To No]  = vw360_Dim_Account.CustomerID

left outer join vw360_Dim_Product on
tbl_RESULTSSLSBYYR_BVBA.Product= vw360_Dim_Product.Product_Code

where 
[Customer No] not like 'SHAM%'
--and isNull([Invoice No],'0')<>'0'
and Cast([Invoice Date]as date) >= '01/01/2024'
--and tbl_RESULTSSLSBYYR_BVBA.Cmpny in ('101')

--order by Cast([Invoice Date]as date)
----------
union all
----------

-----------------------------------------------------------------------------
-- Section 1B: Current Year - TEDA [Closed Order]
-----------------------------------------------------------------------------
--select * from tbl_RESULTSSLSBYYR_TEDA order by [Invoice Date] desc
select 
'201' as Cmpny,
[Order No],
'' as [Customer PO],
[Invoice No],
'' as IncoTerms,
'201' as Warehouse,
'Closed Order' as RecordType,
Cast([Order Date] as date) as OrderDate,
Cast([Invoice Date]as date) as InvoiceDate,
--CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2)as date)as InvoiceDate,
Cast([Invoice Date] as date) as ShipDate,
[Customer No],
'000000' as [Ship To No],
'A201'+[Customer No]+'000000' CustomerID,
'A201'+Trim([Customer No])+'000000'+'---'+Trim([Product Name]) as CPCID,
isNull(GlobalName,'missing Customer name')+' --- '+ isNull(vw360_Dim_Product.Product_Name,'missing ProductName') as CPAID,
--'A201'+[Customer No]+'000000'+'---'+[Product Name]+'---'+[Invoice No]+'---'+[Invoice Date]as CostingLinkID,
'' as CostingLinkID,
[Product Name] as Product,
Cast([Net Amount]as float)*1 as Revenue,
Cast([Net Weight LBS] as float) as Volume,
0 as MaterialCostPerPound,
0 as DirectCostPerPound,
0 as OSProcessingCostPerPound,
0 as OverheadCostPerPound,
'TEDA' as Source
from tbl_RESULTSSLSBYYR_TEDA

--left outer join vw360_CostByInvoice on
--'A'+Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]=LinkID

left outer join vw360_Dim_Account on
'A201'+tbl_RESULTSSLSBYYR_TEDA.[Customer No]+'000000'  = vw360_Dim_Account.CustomerID

left outer join vw360_Dim_Product on
tbl_RESULTSSLSBYYR_TEDA.[Product Name]= vw360_Dim_Product.Product_Code

where 
[Customer No] not in ('68600F','68700F','69600F','N06044','N08032','N09900','C1E201')
and isNull([Invoice No],'0')<>'0'
--and CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2) as date)>= '01/01/2024'
and CAST([Invoice Date] as date)>= '01/01/2024'
----------
union all
----------

----------------------------------------------------------------------------------
---- Section 2: Archive Sales - US + Tolling +  TEDA + BVBA [ Closed Order]
----------------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Section 3A: Open Orders BVBA
------------------------------------------------------------------------------

select 
tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny,
[Order No],
[Customer PO],
[Invoice No],
[FOB Terms] as IncoTerms,
Warehouse,
'Open Order' as RecordType,
Cast([Ord Date] as date) as OrderDate,
Cast([Ship Date] as date) as InvoiceDate,
--CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2)as date)as InvoiceDate,
Cast([Ship Date] as date) as ShipDate,
[Customer No],
RIGHT('000000'+CAST([Ship To No]as varchar(6)),6) as [Ship To No],
'A'+tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny+rtrim([Customer No])+RIGHT('000000'+CAST([Ship To No]as varchar(6)),6) as CustomerID,
'A'+Trim(tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny)+Trim([Customer No])+Trim([Ship To No])+'---'+Trim(Product) as CPCID,
isNull(GlobalName,'missing Customer name')+' --- '+ isNull(vw360_Dim_Product.Product_Name,'missing ProductName') as CPAID,
'A'+tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]as CostingLinkID,
Product,
Cast([Extension]as float)*1.077372 as Revenue,
Cast([Lbs Ordered] as float) as Volume,
0 as MaterialCostPerPound,
0 as DirectCostPerPound,
0 as OSProcessingCostPerPound,
0 as OverheadCostPerPound,
'BRILJANT' as Source
from tbl_RESULTSSLSBYYR_BVBA_Open

--left outer join vw360_CostByInvoice on
--'A'+Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]=LinkID

left outer join vw360_Dim_Account on
'A'+tbl_RESULTSSLSBYYR_BVBA_Open.Cmpny+tbl_RESULTSSLSBYYR_BVBA_Open.[Customer No]+tbl_RESULTSSLSBYYR_BVBA_Open.[Ship To No]  = vw360_Dim_Account.CustomerID

left outer join vw360_Dim_Product on
tbl_RESULTSSLSBYYR_BVBA_Open.Product= vw360_Dim_Product.Product_Code

where 
[Customer No] not like ('%SHAM%')

--and CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2) as date)>= '01/01/2024'
--and tbl_RESULTSSLSBYYR_BVBA.Cmpny in ('101')


-------------
union all
-------------
-----------------------------------------------------------------------------
-- Section 3B: Current Year - TEDA [Open Order]
-----------------------------------------------------------------------------
--select * from tbl_RESULTSSLSBYYR_TEDA order by [Invoice Date] desc
select 
'201' as Cmpny,
[Order No],
'' as [Customer PO],
[Invoice No],
'' as IncoTerms,
'201' as Warehouse,
'Open Order' as RecordType,
Cast([Order Date] as date) as OrderDate,
Cast([expected Ship Date] as date) as InvoiceDate,
--CAST(SUBSTRING([Invoice Date],1,4)+'-'+SUBSTRING([Invoice Date],6,2)+'-'+SUBSTRING([Invoice Date],9,2)as date)as InvoiceDate,
Cast([expected Ship Date] as date) as ShipDate,
[Customer No],
'000000' as [Ship To No],
'A201'+[Customer No]+'000000' CustomerID,
'A201'+Trim([Customer No])+'000000'+'---'+Trim([Product Name]) as CPCID,
isNull(GlobalName,'missing Customer name')+' --- '+ isNull(vw360_Dim_Product.Product_Name,'missing ProductName') as CPAID,
--'A201'+[Customer No]+'000000'+'---'+[Product Name]+'---'+[Invoice No]+'---'+[Invoice Date]as CostingLinkID,
'' as CostingLinkID,
[Product Name] as Product,
Cast([Net Amount]as float)*1 as Revenue,
Cast([Net Weight LBS] as float) as Volume,
0 as MaterialCostPerPound,
0 as DirectCostPerPound,
0 as OSProcessingCostPerPound,
0 as OverheadCostPerPound,
'TEDA' as Source
from tbl_RESULTSSLSBYYR_TEDA

--left outer join vw360_CostByInvoice on
--'A'+Cmpny+[Customer No]+[Ship To No]+'---'+Product+'---'+[Invoice No]+'---'+[Invoice Date]=LinkID

left outer join vw360_Dim_Account on
'A201'+tbl_RESULTSSLSBYYR_TEDA.[Customer No]+'000000'  = vw360_Dim_Account.CustomerID

left outer join vw360_Dim_Product on
tbl_RESULTSSLSBYYR_TEDA.[Product Name]= vw360_Dim_Product.Product_Code

where 
[Customer No] not in ('C1E101','C1E201')
and isNull([Invoice No],'Open Order')='Open Order'