-- Auto Generated (Do not modify) 86319C8D597BA5159BD03776CF86095DB47664C8A3A0EB2ECE8E15F22210BE7F


CREATE view [dbo].[vw360_Dim_CPC_Extended] as

select 
	isNull([CPCID],'n.a.') as CPCID,
	Year(Min([InvoiceDate])) as Cohort
--select *
from vw360_Fact_Sales

left outer join vw360_Dim_Account on
vw360_Fact_Sales.CustomerID = vw360_Dim_Account.CustomerID

left outer join vw360_Dim_Product on
vw360_Fact_Sales.Product = vw360_Dim_Product.ProductSearchName

where 
vw360_Fact_Sales.Product not in ('TFS') 
and isNull(vw360_Fact_Sales.[Invoice No],'') not in ('','0')

group by isNull([CPCID],'n.a.')
--order by isNull([CPCID],'n.a.')