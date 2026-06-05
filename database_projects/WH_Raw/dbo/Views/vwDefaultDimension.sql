




CREATE VIEW vwDefaultDimension
AS
select R.DEFAULTDIMENSION
--, 				CASE
--					WHEN (S1.[~Key] IS NOT NULL)
--						THEN S1.[~Value]
--					ELSE NULL --R.[CostCenterCd]
--				END  as [CostCenterCd] 
, CASE
					WHEN (S2.[~Key] IS NOT NULL)
						THEN S2.[~Value]
					ELSE NULL --R.[DepartmentCd]
				END AS [Department] 
, CASE
					WHEN (S3.[~Key] IS NOT NULL)
						THEN S3.[~Value]
					ELSE NULL --R.[BusinessUnitCd]
				END as [BusinessUnit] 

, CASE
					WHEN (S4.[~Key] IS NOT NULL)
						THEN S4.[~Value]
					ELSE NULL 
				END as [MainAccount] 
, CASE
					WHEN (S5.[~Key] IS NOT NULL)
						THEN S5.[~Value]
					ELSE NULL 
				END as [ProductLine] 
, CASE
					WHEN (S6.[~Key] IS NOT NULL)
						THEN S6.[~Value]
					ELSE NULL 
				END as [Site] 
--, CASE
--					WHEN (S7.[~Key] IS NOT NULL)
--						THEN S7.[~Value]
--					ELSE NULL 
--				END as [OrderReasonCd] 

FROM (select distinct DEFAULTDIMENSION from DefaultDimensionView) R
		--LEFT OUTER JOIN
		--(
		--	SELECT
		--		MAX(S.[DISPLAYVALUE]) AS [~Value]
		--		, S.[DEFAULTDIMENSION] AS [~Key]
		--	FROM DefaultDimensionView S
		--	WHERE
		--		S.[NAME] = 'CostCenter'
		--	GROUP BY
		--		S.[DEFAULTDIMENSION]
		--) S1 ON
		--	S1.[~Key] = R.[DefaultDimension]
		LEFT OUTER JOIN
		(
			SELECT
				MAX(S.[DISPLAYVALUE]) AS [~Value]
				, S.[DEFAULTDIMENSION] AS [~Key]
			FROM DefaultDimensionView S
			WHERE
				S.[NAME] = 'Department'
			GROUP BY
				S.[DEFAULTDIMENSION]
		) S2 ON
			S2.[~Key] = R.[DefaultDimension]

		LEFT OUTER JOIN
		(
			SELECT
				MAX(S.[DISPLAYVALUE]) AS [~Value]
				, S.[DEFAULTDIMENSION] AS [~Key]
			FROM DefaultDimensionView S
			WHERE
				S.[NAME] = 'BusinessUnit'
			GROUP BY
				S.[DEFAULTDIMENSION]
		) S3 ON
			S3.[~Key] = R.[DefaultDimension]

		LEFT OUTER JOIN
		(
			SELECT
				MAX(S.[DISPLAYVALUE]) AS [~Value]
				, S.[DEFAULTDIMENSION] AS [~Key]
			FROM DefaultDimensionView S
			WHERE
				S.[NAME] = 'MainAccount'
			GROUP BY
				S.[DEFAULTDIMENSION]
		) S4 ON
			S4.[~Key] = R.[DefaultDimension]
		LEFT OUTER JOIN
		(
			SELECT
				MAX(S.[DISPLAYVALUE]) AS [~Value]
				, S.[DEFAULTDIMENSION] AS [~Key]
			FROM DefaultDimensionView S
			WHERE
				S.[NAME] = 'ProductLine'
			GROUP BY
				S.[DEFAULTDIMENSION]
		) S5 ON
			S5.[~Key] = R.[DefaultDimension]
		LEFT OUTER JOIN
		(
			SELECT
				MAX(S.[DISPLAYVALUE]) AS [~Value]
				, S.[DEFAULTDIMENSION] AS [~Key]
			FROM DefaultDimensionView S
			WHERE
				S.[NAME] = 'Site'
			GROUP BY
				S.[DEFAULTDIMENSION]
		) S6 ON
			S6.[~Key] = R.[DefaultDimension]
		--LEFT OUTER JOIN
		--(
		--	SELECT
		--		MAX(S.[DISPLAYVALUE]) AS [~Value]
		--		, S.[DEFAULTDIMENSION] AS [~Key]
		--	FROM DefaultDimensionView S
		--	WHERE
		--		S.[NAME] = 'OrderReason'
		--	GROUP BY
		--		S.[DEFAULTDIMENSION]
		--) S7 ON
		--	S7.[~Key] = R.[DefaultDimension]

GO

