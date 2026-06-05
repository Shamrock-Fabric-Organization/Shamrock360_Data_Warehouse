CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimEmployee]
AS
BEGIN
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Append;

    -- --------------------------------------------------------
    -- Step 1: Identify new employment periods not yet in the DIM
    -- Natural key: Personnel_Number + RecordEffectiveStartDate
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Employee_New AS
    SELECT *
    FROM vw_stage_NewEmployee;

    -- --------------------------------------------------------
    -- Step 2: (SCD Type 2 — commented out, not required)
    -- --------------------------------------------------------
    --CREATE TABLE stage_tbl_DIM_Employee_Expired AS
    --SELECT Target.*
    --FROM tbl_DIM_Employee AS Target
    --JOIN vw_stage_DIM_Employee_incoming AS Source
    --    ON Target.Personnel_Number = Source.Personnel_Number
    --        AND Target.RecordEffectiveStartDate = CAST(Source.validfrom AS DATETIME2(3))
    --WHERE Target.RecordStatus = 1
    --    AND (
    --        ISNULL(Target.Harmonized_Name, '') <> ISNULL(Source.Harmonized_Name, '')
    --        ...
    --        );

    -- --------------------------------------------------------
    -- Step 3: Identify employment periods with Type 1 attribute changes
    -- Join on Personnel_Number + RecordEffectiveStartDate to pin
    -- each DIM row to its matching source period — avoids fan-out
    -- when an employee has multiple employment periods.
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Employee_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_Employee AS Target
    JOIN vw_stage_DIM_Employee_incoming AS Source
        ON Target.Personnel_Number = Source.Personnel_Number
       AND Target.RecordEffectiveStartDate = CAST(Source.validfrom AS DATETIME2(3))
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.Employee_Name, '')           COLLATE Latin1_General_BIN2 <> ISNULL(Source.Employee_Name, '')           COLLATE Latin1_General_BIN2
            OR ISNULL(Target.Employment_Type, 0)       <> ISNULL(Source.Employment_Type, 0)
            OR ISNULL(Target.Employment_Type_Desc, '') <> ISNULL(Source.Employment_Type_Desc, '')
            OR ISNULL(Target.IsPerson, '')             <> ISNULL(Source.IsPerson, '')
            OR Target.RecordEffectiveEndDate           <> CAST(Source.validto AS DATETIME2(3))
            );

    -- Build the updated records to insert back into the final table.
    -- RecordEffectiveStartDate/EndDate/RecordStatus come from Source
    -- (validfrom/validto) so the DIM always reflects the D365 period.
    CREATE TABLE stage_tbl_DIM_Employee_Type1_OnlyUpdatedRecords AS
    SELECT
        Target.EmployeeKey
        , Target.Personnel_Number
        , Source.Employee_Name
        , Source.Employment_Type
        , Source.Employment_Type_Desc
        , Source.IsPerson
        , Target.Source
        , CAST(Source.validfrom AS DATETIME2(3))                            AS RecordEffectiveStartDate
        , CAST(Source.validto AS DATETIME2(3))                              AS RecordEffectiveEndDate
        , CASE WHEN GETDATE() >= Source.validfrom AND GETDATE() <= Source.validto
               THEN 1
               ELSE 0
          END                                                               AS RecordStatus
    FROM stage_tbl_DIM_Employee_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_Employee_incoming AS Source
        ON Target.Personnel_Number = Source.Personnel_Number
       AND Target.RecordEffectiveStartDate = CAST(Source.validfrom AS DATETIME2(3));

    -- --------------------------------------------------------
    -- Step 4: Identify employment periods deleted from source
    -- A period is "deleted" only when that specific
    -- Personnel_Number + RecordEffectiveStartDate combination
    -- no longer appears in the source — not the whole employee.
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Employee_Deleted AS
    SELECT *
    FROM tbl_DIM_Employee AS Target
    WHERE Target.RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_Employee_incoming AS Source
            WHERE Source.Personnel_Number = Target.Personnel_Number
                AND CAST(Source.validfrom AS DATETIME2(3)) = Target.RecordEffectiveStartDate
            );

    -- --------------------------------------------------------
    -- Step 5: Assemble the final dimension snapshot
    -- Exclude only the specific period rows being replaced or
    -- deleted — other periods for the same employee are kept.
    -- --------------------------------------------------------
    CREATE TABLE stage_tbl_DIM_Employee_Final AS

    -- Unchanged periods — exclude only periods being replaced or soft-deleted
    SELECT *
    FROM tbl_DIM_Employee
    WHERE RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1 FROM stage_tbl_DIM_Employee_Deleted d
            WHERE d.Personnel_Number = tbl_DIM_Employee.Personnel_Number
                AND d.RecordEffectiveStartDate = tbl_DIM_Employee.RecordEffectiveStartDate
        )
        AND NOT EXISTS (
            SELECT 1 FROM stage_tbl_DIM_Employee_Type1_UpdatesNeeded u
            WHERE u.Personnel_Number = tbl_DIM_Employee.Personnel_Number
                AND u.RecordEffectiveStartDate = tbl_DIM_Employee.RecordEffectiveStartDate
        )

    --UNION ALL
    ---- Expire old records (SCD Type 2 — commented out)
    --SELECT ...
    --FROM stage_tbl_DIM_Employee_Expired

    --UNION ALL
    ---- Insert new versions of changed records (SCD Type 2 — commented out)
    --SELECT ...

    UNION ALL

    -- New employment periods
    SELECT *
    FROM stage_tbl_DIM_Employee_New

    UNION ALL

    -- Type 1 updated periods (attributes refreshed, same period key)
    SELECT *
    FROM stage_tbl_DIM_Employee_Type1_OnlyUpdatedRecords

    UNION ALL

    -- Soft-delete periods that no longer exist in source
    SELECT
        EmployeeKey
        , Personnel_Number
        , Employee_Name
        , Employment_Type
        , Employment_Type_Desc
        , IsPerson
        , Source
        , RecordEffectiveStartDate
        , CAST(GETDATE() AS DATETIME2(3))   AS RecordEffectiveEndDate
        , 0                                 AS RecordStatus
    FROM stage_tbl_DIM_Employee_Deleted;

    -- --------------------------------------------------------
    -- Step 6: Merge with existing historical records and dedup
    -- Dedup key: Personnel_Number + RecordEffectiveStartDate
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Append;

    CREATE TABLE stage_tbl_DIM_Employee_Append AS
    SELECT *
    FROM tbl_DIM_Employee f
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_Employee_Final AS d
        WHERE d.Personnel_Number = f.Personnel_Number
            AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
        )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_Employee_Final AS f
    ORDER BY Personnel_Number
        , RecordEffectiveStartDate;

    -- --------------------------------------------------------
    -- Step 7: Replace DIM table with updated records
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS tbl_DIM_Employee;

    CREATE TABLE tbl_DIM_Employee AS
    SELECT *
    FROM stage_tbl_DIM_Employee_Append

    -- --------------------------------------------------------
    -- Step 8: Clean up intermediate tables
    -- --------------------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_Employee_Type1_OnlyUpdatedRecords;

END;