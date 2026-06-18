-- Auto Generated (Do not modify) B0327BEA38C7DF65BCFBAE263F04B7B6A2EB563F6684760F2AA45EDD51C23164


/****** Object:  View [dbo].[vwUnitOfMeasureConversion]    Script Date: 10/30/2025 9:25:18 AM ******/
CREATE   VIEW [dbo].[vwUnitOfMeasureConversion] -- This populates UNITOFMEASURECONVERSION used in the UDF
AS
SELECT UMC.product
	, umfrom.symbol SYMBOLFROM
	, umto.symbol SYMBOLTO
	, (UMC.factor * UMC.numerator / UMC.denominator) Numerator
	, 1 Denominator
	, ( (UMC.factor * UMC.numerator / UMC.denominator) / 1 ) UOMConversionFactor

FROM UNITOFMEASURECONVERSION UMC
INNER JOIN UNITOFMEASURE umfrom
	ON UMC.fromunitofmeasure = umfrom.recid
INNER JOIN UNITOFMEASURE umto
	ON UMC.tounitofmeasure = umto.recid
WHERE NOT EXISTS (
		SELECT 1
		FROM UNITOFMEASURECONVERSION C
		WHERE C.fromunitofmeasure = UMC.fromunitofmeasure
			AND C.tounitofmeasure = UMC.tounitofmeasure
			AND C.product = '0'
			AND UMC.product != '0'
		)

UNION ALL --Unit of measures for which conversion exists in opposite direction

SELECT UMC.product
	, umto.symbol SYMBOLFROM
	, --TO will become From since reciprocal is used
	umfrom.symbol SYMBOLTO
	, 1 Numerator
	, (UMC.factor * UMC.numerator / UMC.denominator) Denominator
	, ( 1 / (UMC.factor * UMC.numerator / UMC.denominator) ) UOMConversionFactor
FROM UNITOFMEASURECONVERSION UMC
INNER JOIN UNITOFMEASURE umfrom
	ON UMC.fromunitofmeasure = umfrom.recid
INNER JOIN UNITOFMEASURE umto
	ON UMC.tounitofmeasure = umto.recid
WHERE NOT EXISTS (
		SELECT 1
		FROM UNITOFMEASURECONVERSION C
		WHERE C.fromunitofmeasure = UMC.tounitofmeasure
			AND C.tounitofmeasure = UMC.fromunitofmeasure
			AND (
				C.product = UMC.product
				OR (
					C.product = '0'
					AND UMC.product != '0'
					)
				)
		)