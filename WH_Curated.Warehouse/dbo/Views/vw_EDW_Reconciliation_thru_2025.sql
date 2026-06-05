-- Auto Generated (Do not modify) 244909CBBF945B52B251692DB9983D3977B1F145454CE8345F87FA1E1C0895EC
-- ===============================================================
-- Create View template for Azure Synapse SQL Analytics on-demand
-- ===============================================================


CREATE VIEW [dbo].[vw_EDW_Reconciliation_thru_2025] AS
--select [Reconciliation Year], cmpny, sum(amount) as '$$$', sum([Quantity_LBs]) as 'Qty Lbs.'
--from
--(
select
f.Cmpny,
Office =
Case f.Cmpny
WHEN '101' THEN 'US'
WHEN '301' THEN 'BVBA'
WHEN '501' THEN 'Tianjin'
ELSE 'Not defined'
END,
[SalesLine_Status],
[InvoiceNo],
f.Date,     
--d.[Original FISCAL YR],
d.[Reconciliation Year],
a.[Harmonized_Name],
a.[Country],
a.[EffectiveCountry]  as DestinationCountry,
a.City,
a.State,
a.[Customer_ID],
--[Ship To No],
Salesman_ID,
cpc.[Industry] as [Market Segment],
ProductID,
p.[Product_Name],
p.Product_Line,
cpc.SubIndustry as [Market SubSegment],
pl.[Business Line],
pl.[Material Type],
pl.[Old Product Line],
pl.[Old Product Line Description],
pl.[Product Line],
pl.[Product Line Description],
pl.[Product Type],
pl.Technology,
--Amount,       --Revenue,
CONVERT(decimal(38,2), Amount) as Amount
--Volume,
,CONVERT(decimal(38,0), [Volume]) as Volume,
[Quantity_LBs]
from
dbo.[vw_EDW_Fact_Sales_Thru2025]  f
left outer join [dbo].[tbl_Dim_Date] d on
f.DATE = d.Date
left outer join [dbo].[mtbl_EDW_Dim_Account] a on
f.CustomerKey =a.CustomerKey
left outer join[dbo].[mtbl_EDW_Dim_Product] p on
f.ProductKey = p.ProductKey
left outer join [dbo].[tbl_NewProductLine2025_Temp] pl on
f.ProductID = pl.[Product Code]
left outer join tbl_CPCIndustry cpc on
cpc.CPCID = 'A'+rtrim(f.Cmpny)+rtrim(f.[CustomerID])    --+rtrim(vw_EDW_Fact_Sales.[Ship To No])+'---'+rtrim(vw_EDW_Fact_Sales.ProductID)
where 
           --f.Cmpny in ('501') and
            --  d.FiscalYear in ('2022', '2023','2024','2025','2026') and
               f.Salesline_Status = 'Invoiced' and
               isNull(a.CustomerName,'') not like '%Sham%'
and 
f.Date between  '2022-01-01' and '2025-12-31'   -- order by date asc
--) a
--group by [Reconciliation Year], cmpny
--order by 1 desc,2 asc