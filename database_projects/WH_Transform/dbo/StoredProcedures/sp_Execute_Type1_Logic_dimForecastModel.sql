


CREATE PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimForecastModel]
AS
BEGIN
	-- -- Drop intermediate objects --------------------------------------------
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Type1_Updates;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Final;

	-- =========================================================================
	-- Step 1: brand-new natural keys (CMPNY + ModelId not yet in the dim)
	-- =========================================================================
	CREATE TABLE stage_tbl_DIM_ForecastModel_New AS
	SELECT *
	FROM vw_stage_NewForecastModel;

	-- =========================================================================
	-- Step 2: Type-1 updates — natural key matches an existing row but at least
	-- one attribute differs (or the row was previously expired). Updated in place.
	-- =========================================================================
	CREATE TABLE stage_tbl_DIM_ForecastModel_Type1_Updates AS
	SELECT Target.CMPNY
		,Target.ModelId
	FROM tbl_DIM_ForecastModel AS Target
	JOIN vw_stage_DIM_ForecastModel_incoming AS Source ON Target.CMPNY = Source.CMPNY
		AND Target.ModelId = Source.ModelId
	WHERE (
			ISNULL(Target.Model_Description, '') <> ISNULL(Source.Model_Description, '')
			OR ISNULL(Target.Blocked, '') <> ISNULL(Source.Blocked, '')
			OR ISNULL(Target.ModelType, '') <> ISNULL(Source.ModelType, '')
			OR ISNULL(Target.RecordStatus, - 1) <> 1 -- reactivate a previously-expired key
			);

	-- =========================================================================
	-- Step 3: deletes — active rows whose natural key is no longer in the source
	-- =========================================================================
	CREATE TABLE stage_tbl_DIM_ForecastModel_Deleted AS
	SELECT Target.CMPNY
		,Target.ModelId
	FROM tbl_DIM_ForecastModel AS Target
	WHERE ISNULL(Target.RecordStatus, 0) = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_ForecastModel_incoming AS Source
			WHERE Source.CMPNY = Target.CMPNY
				AND Source.ModelId = Target.ModelId
			);

	-- =========================================================================
	-- Step 4: build the merged Final set
	-- =========================================================================
	CREATE TABLE stage_tbl_DIM_ForecastModel_Final AS
	-- A. Unchanged rows (neither Type-1 updated nor deleted)
	SELECT t.[ForecastModelKey]
		,t.[CMPNY]
		,t.[ModelId]
		,t.[Model_Description]
		,t.[Blocked]
		,t.[ModelType]
		,t.[Source]
		,t.[RecordEffectiveStartDate]
		,t.[RecordEffectiveEndDate]
		,t.[RecordStatus]
	FROM tbl_DIM_ForecastModel AS t
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_ForecastModel_Type1_Updates u
			WHERE u.CMPNY = t.CMPNY
				AND u.ModelId = t.ModelId
			)
		AND NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_ForecastModel_Deleted d
			WHERE d.CMPNY = t.CMPNY
				AND d.ModelId = t.ModelId
			)
	
	UNION ALL
	
	-- B. Type-1 updated rows: keep key + ORIGINAL StartDate; overwrite attributes;
	--    reopen EndDate and set active.
	SELECT t.[ForecastModelKey]
		,t.[CMPNY]
		,t.[ModelId]
		,s.[Model_Description]
		,s.[Blocked]
		,s.[ModelType]
		,s.[Source]
		,t.[RecordEffectiveStartDate] -- PRESERVE original first-seen date
		,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
		,1 AS RecordStatus
	FROM tbl_DIM_ForecastModel AS t
	JOIN stage_tbl_DIM_ForecastModel_Type1_Updates u ON u.CMPNY = t.CMPNY
		AND u.ModelId = t.ModelId
	JOIN vw_stage_DIM_ForecastModel_incoming AS s ON s.CMPNY = t.CMPNY
		AND s.ModelId = t.ModelId
	
	UNION ALL
	
	-- C. Brand-new rows
	SELECT [ForecastModelKey]
		,[CMPNY]
		,[ModelId]
		,[Model_Description]
		,[Blocked]
		,[ModelType]
		,[Source]
		,[RecordEffectiveStartDate]
		,[RecordEffectiveEndDate]
		,[RecordStatus]
	FROM stage_tbl_DIM_ForecastModel_New
	
	UNION ALL
	
	-- D. Deleted -> soft-expire: keep last-known attributes + StartDate; stamp EndDate; RecordStatus = 0
	SELECT t.[ForecastModelKey]
		,t.[CMPNY]
		,t.[ModelId]
		,t.[Model_Description]
		,t.[Blocked]
		,t.[ModelType]
		,t.[Source]
		,t.[RecordEffectiveStartDate]
		,CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
		,0 AS RecordStatus
	FROM tbl_DIM_ForecastModel AS t
	JOIN stage_tbl_DIM_ForecastModel_Deleted d ON d.CMPNY = t.CMPNY
		AND d.ModelId = t.ModelId;

	-- =========================================================================
	-- Step 5: replace the DIM with the merged set
	-- =========================================================================
	DROP TABLE IF EXISTS tbl_DIM_ForecastModel;
	
	CREATE TABLE tbl_DIM_ForecastModel AS
	SELECT [ForecastModelKey]
		,[CMPNY]
		,[ModelId]
		,[Model_Description]
		,[Blocked]
		,[ModelType]
		,[Source]
		,[RecordEffectiveStartDate]
		,[RecordEffectiveEndDate]
		,[RecordStatus]
	FROM stage_tbl_DIM_ForecastModel_Final;

	-- =========================================================================
	-- Step 6: cleanup
	-- =========================================================================
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_New;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Type1_Updates;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Deleted;
    DROP TABLE IF EXISTS stage_tbl_DIM_ForecastModel_Final;

	END;
