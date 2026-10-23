-- One row per legacy company and legacy salesman name, with two personnel numbers:
--   Seller_Personnel_Number: who the legacy salesman is. A name match to the current employee dimension (D365 rows and
--       the Legacy- rows that vw_EDW_Dim_Employee adds), used only when the name belongs to exactly one current
--       personnel number. Feeds SalesLine_EmployeeKey, as the name join (de) does today.
--   Owner_Personnel_Number: who owns that salesman's accounts now. XREF_Salesman_ID first (it maps a legacy salesman to
--       the D365 employee who took over the book, e.g. Joe Sankovic to 1168, and agents to employees), else the seller.
--       Feeds CustAcct_EmployeeKey, as the cross-reference join (de3) does today.
-- A name shared by several current personnel numbers gives no seller (key -1) and shows in Seller_Resolution, so two
-- different people with the same name are never merged. Names are compared trimmed; the warehouse is case-insensitive.
-- The view groups by company and name, so it returns at most one row per legacy salesman: joining to it cannot add rows.
CREATE OR ALTER VIEW [dbo].[vw_Legacy_Salesman_Resolution]
AS
WITH legacy_salesman AS (
    SELECT lda.CMPNY AS Legacy_Company
        , lda.Salesman
        , LTRIM(RTRIM(lda.Salesman)) AS Salesman_Match
    FROM dbo.tbl_DIM_Accounts AS lda
    WHERE lda.RecordStatus = 1
      AND ISNULL(LTRIM(RTRIM(lda.Salesman)), '') <> ''
    GROUP BY lda.CMPNY, lda.Salesman
),
xref AS (
    SELECT LTRIM(RTRIM(x.Apollo_SalesmanName)) AS Salesman_Match
        , MIN(x.D365_SalesmanID) AS Personnel_Number
        , COUNT(DISTINCT x.D365_SalesmanID) AS Personnel_Numbers
    FROM dbo.XREF_Salesman_ID AS x
    GROUP BY LTRIM(RTRIM(x.Apollo_SalesmanName))
),
name_match AS (
    SELECT LTRIM(RTRIM(e.Employee_Name)) AS Salesman_Match
        , MIN(e.Personnel_Number) AS Personnel_Number
        , COUNT(DISTINCT e.Personnel_Number) AS Personnel_Numbers
    FROM dbo.mtbl_EDW_DIM_Employee AS e
    WHERE e.RecordStatus = 1
    GROUP BY LTRIM(RTRIM(e.Employee_Name))
),
resolved AS (
    SELECT ls.Legacy_Company
        , ls.Salesman
        , CASE WHEN nm.Personnel_Numbers = 1 THEN nm.Personnel_Number END AS Seller_Personnel_Number
        , CASE WHEN x.Personnel_Numbers = 1 THEN x.Personnel_Number END AS Xref_Personnel_Number
        , CASE WHEN nm.Personnel_Numbers = 1 THEN 'Unique name match'
               WHEN nm.Personnel_Numbers > 1 THEN 'Ambiguous name: several current personnel numbers'
               ELSE 'No name match' END AS Seller_Resolution
        , CASE WHEN x.Personnel_Numbers = 1 THEN 'Cross-reference'
               WHEN x.Personnel_Numbers > 1 THEN 'Cross-reference names several personnel numbers'
               ELSE 'Not in cross-reference' END AS Xref_Resolution
    FROM legacy_salesman AS ls
    LEFT JOIN xref AS x ON x.Salesman_Match = ls.Salesman_Match
    LEFT JOIN name_match AS nm ON nm.Salesman_Match = ls.Salesman_Match
)
SELECT Legacy_Company
    , Salesman
    , Seller_Personnel_Number
    , COALESCE(Xref_Personnel_Number, Seller_Personnel_Number) AS Owner_Personnel_Number
    , Seller_Resolution
    , Xref_Resolution
FROM resolved;
