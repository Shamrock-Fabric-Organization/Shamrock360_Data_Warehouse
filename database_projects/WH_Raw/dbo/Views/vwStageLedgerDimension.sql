CREATE   VIEW [dbo].[vwStageLedgerDimension] AS
SELECT DISTINCT
	a.[dimensionattributevaluecombination] as LEDGERDIMENSION 
	, d.[name]                             as DIMENSIONNAME
	, b.[displayvalue]                     as VALUE
	, c.entityinstance
FROM
	[DimensionAttributeValueGroupCombination] a
	LEFT OUTER JOIN [DimensionAttributeLevelValue] b 
		ON a.[dimensionattributevaluegroup] = b.[dimensionattributevaluegroup]
	LEFT OUTER JOIN [DimensionAttributeValue] c 
		ON b.[dimensionattributevalue] = c.[recid]
	LEFT OUTER JOIN [DimensionAttribute] d 
		ON c.[dimensionattribute] = d.[recid]

GO

