-- Auto Generated (Do not modify) D8C1E4A4582EF99E32CED391E632F86572A0CE5E2C5F2C3F4A70A44184EBAFE8

/****** Object:  View [dbo].[vwStageLedgerDimension]    Script Date: 10/30/2025 9:25:05 AM ******/



CREATE   VIEW [dbo].[vwStageLedgerDimension] AS
SELECT DISTINCT
	a.[dimensionattributevaluecombination] as LEDGERDIMENSION 
	, d.[name]                             as DIMENSIONNAME
	, b.[displayvalue]                     as VALUE
FROM
	[DimensionAttributeValueGroupCombination] a
	LEFT OUTER JOIN .[DimensionAttributeLevelValue] b 
		ON a.[dimensionattributevaluegroup] = b.[dimensionattributevaluegroup]
	LEFT OUTER JOIN .[DimensionAttributeValue] c 
		ON b.[dimensionattributevalue] = c.[recid]
	LEFT OUTER JOIN .[DimensionAttribute] d 
		ON c.[dimensionattribute] = d.[recid]