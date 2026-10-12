CREATE OR ALTER VIEW vwUnitOfMeasureConversion -- This populates UNITOFMEASURECONVERSION used in the UDF
AS
WITH Candidate
AS (
	-- Every candidate conversion with its precedence: 1 product direct, 2 product reverse, 3 generic direct, 4 generic reverse.
	SELECT UMC.product
		,umfrom.symbol SYMBOLFROM
		,umto.symbol SYMBOLTO
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE (UMC.factor * UMC.numerator / UMC.denominator)
			END Numerator
		,1 Denominator -- A zero denominator returns NULL instead of a divide error.
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE ((UMC.factor * UMC.numerator / UMC.denominator) / 1)
			END UOMConversionFactor
		,CASE 
			WHEN UMC.product = '0'
				THEN 3
			ELSE 1
			END PrecedenceRank -- A product-specific rule outranks a generic (product 0) rule.
		,UMC.recid ConversionRecId
	FROM UNITOFMEASURECONVERSION UMC
	INNER JOIN UNITOFMEASURE umfrom ON UMC.fromunitofmeasure = umfrom.recid
	INNER JOIN UNITOFMEASURE umto ON UMC.tounitofmeasure = umto.recid
	
	UNION ALL --Unit of measures for which conversion exists in opposite direction
	
	SELECT UMC.product
		,umto.symbol SYMBOLFROM
		,umfrom.symbol SYMBOLTO
		,1 Numerator
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE (UMC.factor * UMC.numerator / UMC.denominator)
			END Denominator
		,CASE 
			WHEN UMC.denominator = 0
				OR UMC.factor = 0
				OR UMC.numerator = 0
				THEN NULL
			ELSE (1 / (UMC.factor * UMC.numerator / UMC.denominator))
			END UOMConversionFactor -- A zero factor, numerator or denominator returns NULL instead of a divide error.
		,CASE 
			WHEN UMC.product = '0'
				THEN 4
			ELSE 2
			END PrecedenceRank -- A reverse rule ranks below the direct rule of the same specificity.
		,UMC.recid ConversionRecId
	FROM UNITOFMEASURECONVERSION UMC
	INNER JOIN UNITOFMEASURE umfrom ON UMC.fromunitofmeasure = umfrom.recid
	INNER JOIN UNITOFMEASURE umto ON UMC.tounitofmeasure = umto.recid
	
	UNION ALL -- Generic (product 0) conversions copied to every released product, so a join on a real product finds them.
	
	SELECT P.product
		,umfrom.symbol SYMBOLFROM
		,umto.symbol SYMBOLTO
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE (UMC.factor * UMC.numerator / UMC.denominator)
			END Numerator
		,1 Denominator
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE ((UMC.factor * UMC.numerator / UMC.denominator) / 1)
			END UOMConversionFactor
		,3 PrecedenceRank
		,UMC.recid ConversionRecId
	FROM UNITOFMEASURECONVERSION UMC
	INNER JOIN UNITOFMEASURE umfrom ON UMC.fromunitofmeasure = umfrom.recid
	INNER JOIN UNITOFMEASURE umto ON UMC.tounitofmeasure = umto.recid
	CROSS JOIN (
		SELECT DISTINCT product
		FROM INVENTTABLE
		WHERE product != '0'
		) P -- Released products: one row per product across all companies, because conversions are shared.
	WHERE UMC.product = '0'
	
	UNION ALL -- Generic (product 0) conversions in the opposite direction, copied to every released product.
	
	SELECT P.product
		,umto.symbol SYMBOLFROM
		,umfrom.symbol SYMBOLTO
		,1 Numerator
		,CASE 
			WHEN UMC.denominator = 0
				THEN NULL
			ELSE (UMC.factor * UMC.numerator / UMC.denominator)
			END Denominator
		,CASE 
			WHEN UMC.denominator = 0
				OR UMC.factor = 0
				OR UMC.numerator = 0
				THEN NULL
			ELSE (1 / (UMC.factor * UMC.numerator / UMC.denominator))
			END UOMConversionFactor
		,4 PrecedenceRank
		,UMC.recid ConversionRecId
	FROM UNITOFMEASURECONVERSION UMC
	INNER JOIN UNITOFMEASURE umfrom ON UMC.fromunitofmeasure = umfrom.recid
	INNER JOIN UNITOFMEASURE umto ON UMC.tounitofmeasure = umto.recid
	CROSS JOIN (
		SELECT DISTINCT product
		FROM INVENTTABLE
		WHERE product != '0'
		) P
	WHERE UMC.product = '0'
	)
SELECT R.product
	,R.SYMBOLFROM
	,R.SYMBOLTO
	,R.Numerator
	,R.Denominator
	,R.UOMConversionFactor
FROM (
	SELECT C.product
		,C.SYMBOLFROM
		,C.SYMBOLTO
		,C.Numerator
		,C.Denominator
		,C.UOMConversionFactor
		,ROW_NUMBER() OVER (
			PARTITION BY C.product
			,C.SYMBOLFROM
			,C.SYMBOLTO ORDER BY C.PrecedenceRank
				,C.ConversionRecId
			) RowNo -- Keeps exactly one row per (product, SYMBOLFROM, SYMBOLTO): the highest-precedence rule.
	FROM Candidate C
	) R
WHERE R.RowNo = 1
GO
