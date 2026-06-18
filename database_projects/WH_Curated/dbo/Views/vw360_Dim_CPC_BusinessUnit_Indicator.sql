-- Auto Generated (Do not modify) 7DBABE904831139B9D574FAF2D106C3EC1FA42743ECD01AE7B7BCF71C143CD97

CREATE    view [dbo].[vw360_Dim_CPC_BusinessUnit_Indicator] as
select 
--	vw360_Fact_Sales.CPCID as FactCPID,
	isNull(vw360_Dim_Account.CustomerID+'---'+ vw360_Dim_Product.ProductSearchName,'n.a.') as [CPCID],
	Max(vw360_Fact_Sales.Cmpny) as Office,
	vw360_Dim_Account.CustomerID,
	vw360_Dim_Product.ProductSearchName,
    [IsPartOf_PLASTICS] = Case vw360_Dim_Account.Industry
	WHEN 'THERMPLASTIC' THEN 'Yes'
	ELSE 'No'
	END,
    
	[IsPartOf_TXTURES] = Case vw360_Dim_Product.ProdLineAcctg
	WHEN ' TXTURES' THEN 'Yes'
	Else 'No'
	End,
    
	'' as [isPartOf_PTFE],
	'' as [isPartOf_Waxallurgy],
	[IsPartOf_Emulsions] = CASE vw360_Dim_Product.ProdLineAcctg
	WHEN 'AUX' THEN 'Yes'
	WHEN 'DIS' THEN 'Yes'
	WHEN 'EMUL' THEN 'Yes'
	WHEN 'PIGMEN' THEN 'Yes'
	WHEN 'RAW-MAT' THEN 'Yes'
	Else 'No'
	End,
	'' as isPartOf_Lubricants,
	
	isPartOf_InksAndCoatings = Case vw360_Dim_Account.Industry
	WHEN 'INKS' THEN 'Yes'
	WHEN 'COATINGS' THEN 'Yes'
	ELSE 'No'
END	   

from vw360_Fact_Sales

left outer join vw360_Dim_Account on
trim(vw360_Fact_Sales.CustomerID) = trim(vw360_Dim_Account.CustomerID)

left outer join vw360_Dim_Product on
vw360_Fact_Sales.Product = vw360_Dim_Product.ProductSearchName

where
vw360_Fact_Sales.Source <>'Imputed Data' and
isNull(vw360_Dim_Account.CustomerID+'---'+ vw360_Dim_Product.ProductSearchName,'n.a.')<>'n.a.'

group by 
isNull(vw360_Dim_Account.CustomerID+'---'+ vw360_Dim_Product.ProductSearchName,'n.a.'), 
Product, Industry, ProdLineAcctg, vw360_Dim_Account.CustomerID, vw360_Dim_Product.ProductSearchName
--, 
--vw360_Fact_Sales.CPCID,
--vw360_Fact_Sales.cmpny