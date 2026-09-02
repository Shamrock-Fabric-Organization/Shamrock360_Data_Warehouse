-- USE WH_Transform

CREATE OR ALTER PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimTradeAgreement]
AS
BEGIN
    -- Drop intermediate objects if they exist
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Type1_OnlyUpdatedRecords;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Append;

    -- Step 1: Identify new records not in the current dimension table
    CREATE TABLE stage_tbl_DIM_TradeAgreement_New AS
    SELECT *
    FROM vw_stage_NewTradeAgreement;

    -- Step 2: Identify records with Type 1 changes
    CREATE TABLE stage_tbl_DIM_TradeAgreement_Type1_UpdatesNeeded AS
    SELECT Target.*
    FROM tbl_DIM_TradeAgreement AS Target
    JOIN vw_stage_DIM_TradeAgreement_incoming AS Source
        ON  ISNULL(Target.AgreementID, '') = ISNULL(Source.AgreementID, '')
        AND ISNULL(Target.CMPNY, '')       = ISNULL(Source.CMPNY, '')
    WHERE Target.RecordStatus = 1
        AND (
            ISNULL(Target.JournalName,      '') <> ISNULL(Source.JournalName,      '')
            OR ISNULL(Target.AgreementName, '') <> ISNULL(Source.AgreementName,    '')
            OR ISNULL(CAST(Target.PostedDate AS VARCHAR(30)), '') <> ISNULL(CAST(Source.PostedDate AS VARCHAR(30)), '')
            OR ISNULL(Target.Posted,        '') <> ISNULL(Source.Posted,            '')
            OR ISNULL(Target.DefaultRelation,'') <> ISNULL(Source.DefaultRelation, '')
            );

    -- Create table with refreshed attribute values, preserving original key and audit fields
    CREATE TABLE stage_tbl_DIM_TradeAgreement_Type1_OnlyUpdatedRecords AS
    SELECT
          Target.TradeAgreementKey
        , Target.CMPNY
        , Target.AgreementID
        , Source.JournalName
        , Source.AgreementName
        , Source.PostedDate
        , Source.Posted
        , Source.DefaultRelation
        , Target.Source
        , Target.RecordEffectiveStartDate
        , Target.RecordEffectiveEndDate
        , Target.RecordStatus
    FROM stage_tbl_DIM_TradeAgreement_Type1_UpdatesNeeded AS Target
    JOIN vw_stage_DIM_TradeAgreement_incoming AS Source
        ON  ISNULL(Target.AgreementID, '') = ISNULL(Source.AgreementID, '')
        AND ISNULL(Target.CMPNY, '')       = ISNULL(Source.CMPNY, '');

    -- Step 3: Identify records deleted from source
    CREATE TABLE stage_tbl_DIM_TradeAgreement_Deleted AS
    SELECT *
    FROM tbl_DIM_TradeAgreement AS Target
    WHERE Target.RecordStatus = 1
        AND NOT EXISTS (
            SELECT 1
            FROM vw_stage_DIM_TradeAgreement_incoming AS Source
            WHERE ISNULL(Target.AgreementID, '') = ISNULL(Source.AgreementID, '')
              AND ISNULL(Target.CMPNY, '')       = ISNULL(Source.CMPNY, '')
            );

    -- Step 4: Build final dimension state
    CREATE TABLE stage_tbl_DIM_TradeAgreement_Final AS

        -- Unchanged active records
        SELECT *
        FROM tbl_DIM_TradeAgreement
        WHERE RecordStatus = 1
            AND (ISNULL(CMPNY, '') + '~=~' + ISNULL(AgreementID, '')) NOT IN (
                SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(AgreementID, '') FROM stage_tbl_DIM_TradeAgreement_Deleted
                UNION
                SELECT ISNULL(CMPNY, '') + '~=~' + ISNULL(AgreementID, '') FROM stage_tbl_DIM_TradeAgreement_Type1_UpdatesNeeded
                )

    UNION ALL

        -- New records
        SELECT * FROM stage_tbl_DIM_TradeAgreement_New

    UNION ALL

        -- Type 1 updated records (attributes refreshed, key preserved)
        SELECT * FROM stage_tbl_DIM_TradeAgreement_Type1_OnlyUpdatedRecords

    UNION ALL

        -- Deleted records — expire them
        SELECT
              TradeAgreementKey
            , CMPNY
            , AgreementID
            , JournalName
            , AgreementName
            , PostedDate
            , Posted
            , DefaultRelation
            , Source
            , RecordEffectiveStartDate
            , GETDATE()  AS RecordEffectiveEndDate
            , 0          AS RecordStatus
        FROM stage_tbl_DIM_TradeAgreement_Deleted;

    -- Step 5: Merge with existing table, de-duplicate by natural key + start date
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Append;

    CREATE TABLE stage_tbl_DIM_TradeAgreement_Append AS
    SELECT *
    FROM tbl_DIM_TradeAgreement AS f
    WHERE NOT EXISTS (
        SELECT 1
        FROM stage_tbl_DIM_TradeAgreement_Final AS d
        WHERE ISNULL(d.AgreementID, '')       = ISNULL(f.AgreementID, '')
          AND ISNULL(d.CMPNY, '')             = ISNULL(f.CMPNY, '')
          AND d.RecordEffectiveStartDate      = f.RecordEffectiveStartDate
        )

    UNION ALL

    SELECT *
    FROM stage_tbl_DIM_TradeAgreement_Final AS f
    ORDER BY CMPNY, AgreementID, RecordEffectiveStartDate;

    -- Step 6: Replace dimension table
	BEGIN TRY
	BEGIN TRAN;

    DROP TABLE IF EXISTS tbl_DIM_TradeAgreement;

    CREATE TABLE tbl_DIM_TradeAgreement AS
    SELECT *
    FROM stage_tbl_DIM_TradeAgreement_Append;
		
	COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		THROW;
	END CATCH

    -- Step 7: Clean up intermediates
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Expired;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Final;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Append;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Type1_UpdatesNeeded;
    DROP TABLE IF EXISTS stage_tbl_DIM_TradeAgreement_Type1_OnlyUpdatedRecords;

END;