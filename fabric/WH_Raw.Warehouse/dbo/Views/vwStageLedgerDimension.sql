-- Auto Generated (Do not modify) E9C71FD6E38AD6E450AEFC16570B7AA82B0C8F4C9B433CAD93E35133C748DF3E
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