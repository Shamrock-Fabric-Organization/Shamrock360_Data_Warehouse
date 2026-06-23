-- Auto Generated (Do not modify) D0E4F6C363A49BEE832EB1726E979E02210BAECC5A43ABADE5B75DDACF4F55BD

/****** Object:  View [dbo].[vw_stage_NewEmployee]    Script Date: 5/21/2026 1:03:17 PM ******/


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE   VIEW [dbo].[vw_stage_NewEmployee]
AS
SELECT
    EmployeeKey
    , Personnel_Number
    , Employee_Name
    , Employment_Type
    , Employment_Type_Desc
    , IsPerson
    , [Source]
    , CAST(ValidFrom AS DATETIME2(3))                                       AS RecordEffectiveStartDate
    , CAST(ValidTo AS DATETIME2(3))                                         AS RecordEffectiveEndDate
    , CASE WHEN GETDATE() >= ValidFrom AND GETDATE() <= ValidTo
           THEN 1
           ELSE 0
      END                                                                   AS RecordStatus
FROM vw_stage_DIM_Employee_incoming AS Source
WHERE NOT EXISTS (
    SELECT 1
    FROM tbl_DIM_Employee AS Target
    WHERE Target.Personnel_Number = Source.Personnel_Number
        AND Target.RecordEffectiveStartDate = CAST(Source.ValidFrom AS DATETIME2(3))
);