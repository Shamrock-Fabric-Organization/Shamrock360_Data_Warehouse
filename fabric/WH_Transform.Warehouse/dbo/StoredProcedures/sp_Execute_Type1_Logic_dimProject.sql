--USE WH_transform




CREATE   PROCEDURE [dbo].[sp_Execute_Type1_Logic_dimProject]
AS
BEGIN
	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Type1_OnlyUpdatedRecords;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Append;

	-- Step 1: Identify new records not in the current dimension table
	-- Uses view created for this purpose vw_stage_NewProject
	-- Create a table to store new records identified from the view
	CREATE TABLE stage_tbl_DIM_Project_New AS
	SELECT *
	FROM vw_stage_NewProject

	---- Step 2: Identify records that need to be expired
	---- Create a table to store records that have changed and need to be expired
	--CREATE TABLE stage_tbl_DIM_Project_Expired AS
	--SELECT Target.*
	--FROM tbl_DIM_Project AS Target
	--JOIN vw_stage_DIM_Project_incoming AS Source
	--	ON Target.ProjId = Source.ProjId
	--		AND Target.CMPNY = Source.CMPNY
	--WHERE Target.RecordStatus = 1
	--	AND (
	--		ISNULL(Target.ProjectName, '') <> ISNULL(Source.ProjectName, '')
	--		OR ISNULL(Target.ProjectContractID, '') <> ISNULL(Source.ProjectContractID, '')
	--		OR ISNULL(Target.ProjectType, '') <> ISNULL(Source.ProjectType, '')
	--		OR ISNULL(Target.ProjectStage, '') <> ISNULL(Source.ProjectStage, '')
	--		OR ISNULL(Target.BudgetControlInterval, '') <> ISNULL(Source.BudgetControlInterval, '')
	--		OR ISNULL(Target.ProjectedStartDate, '1900-01-01') <> ISNULL(Source.ProjectedStartDate, '1900-01-01')
	--		OR ISNULL(Target.ProjectedEndDate, '1900-01-01') <> ISNULL(Source.ProjectedEndDate, '1900-01-01')
	--		OR ISNULL(Target.StartDate, '1900-01-01') <> ISNULL(Source.StartDate, '1900-01-01')
	--		OR ISNULL(Target.EndDate, '1900-01-01') <> ISNULL(Source.EndDate, '1900-01-01')
	--		OR ISNULL(Target.Status, '') <> ISNULL(Source.Status, '')
	--		);

	-- Step 3: Identify records with Type 1-only changes
	CREATE TABLE stage_tbl_DIM_Project_Type1_UpdatesNeeded AS
	SELECT Target.*
	FROM tbl_DIM_Project AS Target
	JOIN vw_stage_DIM_Project_incoming AS Source
		ON  Target.ProjId = Source.ProjId
		AND Target.CMPNY  = Source.CMPNY
	WHERE Target.RecordStatus = 1
		AND (
			ISNULL(Target.ProjectName, '')           <> ISNULL(Source.ProjectName, '')
			OR ISNULL(Target.ProjectContractID, '')  <> ISNULL(Source.ProjectContractID, '')
			OR ISNULL(Target.ProjectType, '')        <> ISNULL(Source.ProjectType, '')
			OR ISNULL(Target.ProjectStage, '')       <> ISNULL(Source.ProjectStage, '')
			OR ISNULL(Target.BudgetControlInterval, '') <> ISNULL(Source.BudgetControlInterval, '')
			OR ISNULL(Target.ProjectedStartDate, '1900-01-01') <> ISNULL(Source.ProjectedStartDate, '1900-01-01')
			OR ISNULL(Target.ProjectedEndDate, '1900-01-01')   <> ISNULL(Source.ProjectedEndDate, '1900-01-01')
			OR ISNULL(Target.StartDate, '1900-01-01')          <> ISNULL(Source.StartDate, '1900-01-01')
			OR ISNULL(Target.EndDate, '1900-01-01')            <> ISNULL(Source.EndDate, '1900-01-01')
			OR ISNULL(Target.Status, '')             <> ISNULL(Source.Status, '')
			)

	--Create table with Type 1 changes for insert into final table
	CREATE TABLE stage_tbl_DIM_Project_Type1_OnlyUpdatedRecords AS
	SELECT
		  Target.ProjectKey
		, Target.CMPNY
		, Target.ProjId
		, Source.ProjectName
		, Source.ProjectContractID
		, Source.ProjectType
		, Source.ProjectStage
		, Source.BudgetControlInterval
		, Source.ProjectedStartDate
		, Source.ProjectedEndDate
		, Source.StartDate
		, Source.EndDate
		, Source.Status

		, Target.Source
		, Target.RecordEffectiveStartDate
		, Target.RecordEffectiveEndDate
		, Target.RecordStatus
	FROM stage_tbl_DIM_Project_Type1_UpdatesNeeded AS Target
	JOIN vw_stage_DIM_Project_incoming AS Source
		ON  Target.ProjId = Source.ProjId
		AND Target.CMPNY  = Source.CMPNY

	-- Step 4: Identify records that exist in DIM but are missing from the source (i.e., deleted)
	-- Create a table to store records that are deleted from the source
	CREATE TABLE stage_tbl_DIM_Project_Deleted AS
	SELECT *
	FROM tbl_DIM_Project AS Target
	WHERE Target.RecordStatus = 1
		AND NOT EXISTS (
			SELECT 1
			FROM vw_stage_DIM_Project_incoming AS Source
			WHERE Target.ProjId = Source.ProjId
			  AND Target.CMPNY  = Source.CMPNY
			);

	-- Step 5: Create the final dimension table
	-- Create the final dimension table combining unchanged, expired, new, and deleted records
	CREATE TABLE stage_tbl_DIM_Project_Final AS
		-- Add records from DIM that had no changes
	SELECT *
	FROM tbl_DIM_Project
	WHERE RecordStatus = 1
		AND (CMPNY + '~=~' + ProjId) NOT IN
			(
			-- SELECT CMPNY + '~=~' + ProjId
			-- FROM stage_tbl_DIM_Project_Expired
			-- UNION
			SELECT CMPNY + '~=~' + ProjId
			FROM stage_tbl_DIM_Project_Deleted
			UNION
			SELECT CMPNY + '~=~' + ProjId
			FROM stage_tbl_DIM_Project_Type1_UpdatesNeeded
			)

	--UNION ALL

	---- Expire old records
	--SELECT [ProjectKey]
	--	, [CMPNY]
	--	, [ProjId]
	--	, [ProjectName]
	--	, [ProjectContractID]
	--	, [ProjectType]
	--	, [ProjectStage]
	--	, [BudgetControlInterval]
	--	, [ProjectedStartDate]
	--	, [ProjectedEndDate]
	--	, [StartDate]
	--	, [EndDate]
	--	, [Status]
	--	, [Source]
	--	, [RecordEffectiveStartDate]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 0 AS RecordStatus
	--FROM stage_tbl_DIM_Project_Expired

	--UNION ALL

	---- Insert new versions of changed records
	--SELECT s.[ProjectKey]
	--	, s.[CMPNY]
	--	, s.[ProjId]
	--	, s.[ProjectName]
	--	, s.[ProjectContractID]
	--	, s.[ProjectType]
	--	, s.[ProjectStage]
	--	, s.[BudgetControlInterval]
	--	, s.[ProjectedStartDate]
	--	, s.[ProjectedEndDate]
	--	, s.[StartDate]
	--	, s.[EndDate]
	--	, s.[Status]
	--	, s.[Source]
	--	, CAST(GETDATE() AS DATETIME2(3)) AS RecordEffectiveStartDate
	--	, CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	--	, 1 AS RecordStatus
	--FROM vw_stage_DIM_Project_incoming s
	--JOIN stage_tbl_DIM_Project_Expired e
	--	ON s.ProjId = e.ProjId
	--		AND s.CMPNY = e.CMPNY

	UNION ALL

	-- Insert new records
	SELECT *
	FROM stage_tbl_DIM_Project_New

	UNION ALL

	-- Insert Type 1 updated records
	SELECT *
	FROM stage_tbl_DIM_Project_Type1_OnlyUpdatedRecords

	UNION ALL

	-- Expire deleted records
	SELECT
		  ProjectKey
		, CMPNY
		, ProjId
		, ProjectName
		, ProjectContractID
		, ProjectType
		, ProjectStage
		, BudgetControlInterval
		, ProjectedStartDate
		, ProjectedEndDate
		, StartDate
		, EndDate
		, Status
		, Source
		, RecordEffectiveStartDate
		, GETDATE()  AS RecordEffectiveEndDate
		, 0          AS RecordStatus
	FROM stage_tbl_DIM_Project_Deleted;

	-- Step 6: Replace the original table with deduplicated append
	-- Drop the append table if it exists before rebuilding the dimension
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Append;

	-- Create a new append table by merging existing and final dimension records
	CREATE TABLE stage_tbl_DIM_Project_Append AS
	SELECT *
	FROM tbl_DIM_Project f
	WHERE NOT EXISTS (
			SELECT 1
			FROM stage_tbl_DIM_Project_Final AS d
			WHERE d.ProjId                   = f.ProjId
				AND d.CMPNY                  = f.CMPNY
				AND d.RecordEffectiveStartDate = f.RecordEffectiveStartDate
			)

	UNION ALL

	SELECT *
	FROM stage_tbl_DIM_Project_Final AS f
	ORDER BY CMPNY
		, ProjId
		, RecordEffectiveStartDate

	-- Step 7: Replace the DIM table with the updated records
	-- Drop the original dimension table to replace with the updated one
	DROP TABLE IF EXISTS tbl_DIM_Project;

	-- Recreate the dimension table with the updated records from the append table
	CREATE TABLE tbl_DIM_Project AS
	SELECT *
	FROM stage_tbl_DIM_Project_Append;

	-- Step 8: Clean up intermediate objects used
	-- Drop intermediate tables if they exist
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_New;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Expired;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Deleted;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Final;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Append;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Type1_UpdatesNeeded;
	DROP TABLE IF EXISTS stage_tbl_DIM_Project_Type1_OnlyUpdatedRecords;

	---- Step 9: Clear staging table
	---- Drop the staging/source table after processing is complete -- not needed using a view for incoming data
	--DROP TABLE IF EXISTS vw_stage_DIM_Project_incoming;
END;