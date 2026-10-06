

CREATE OR ALTER                PROCEDURE [dbo].[sp_Execute_Snapshot_Fact_Inventory_101]
AS
BEGIN
	--Declare variables
	DECLARE @DateKey_to_load int

	SET @DateKey_to_load = convert(int, convert(char(8), DATEADD(Day, -1, CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS datetime2(6))), 112))
	select @DateKey_to_load

	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Append_101;
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Extended_Append_101;
	DROP TABLE IF EXISTS stage_tbl_InventSum_Snapshot_append_101;

	--Check to see if data already loaded for given datekey, if so skip loading, if not add new snapshot records
	IF (SELECT COUNT(1) FROM [dbo].[tbl_Fact_Inventory_Snapshot_101] WHERE Snapshot_Date_Key = @DateKey_to_load) = 0
	BEGIN
		-- Create a new append table by merging existing and new snapshot records
		CREATE TABLE stage_tbl_Fact_Inventory_Snapshot_Append_101 AS
		SELECT *
		FROM tbl_Fact_Inventory_Snapshot_101 f
	
		UNION ALL
	
		SELECT *
		FROM vw_stage_Fact_Inventory_Snapshot_incoming_101 AS f

		BEGIN TRY
		BEGIN TRAN;

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_Fact_Inventory_Snapshot_101;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_Fact_Inventory_Snapshot_101 AS
		SELECT *
		FROM stage_tbl_Fact_Inventory_Snapshot_Append_101;
		
		COMMIT TRAN;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			THROW;
		END CATCH

		--****************************************************************
		-- Create a new extended append table by merging existing and new snapshot records
		CREATE TABLE stage_tbl_Fact_Inventory_Snapshot_Extended_Append_101 AS
		SELECT *
		FROM tbl_Fact_Inventory_Snapshot_Extended_101 f
	
		UNION ALL
	
		SELECT *
		FROM vw_stage_Fact_Inventory_Snapshot_Extended_incoming_101 AS f

		BEGIN TRY
		BEGIN TRAN;

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_Fact_Inventory_Snapshot_Extended_101;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_Fact_Inventory_Snapshot_Extended_101 AS
		SELECT *
		FROM stage_tbl_Fact_Inventory_Snapshot_Extended_Append_101;
		
		COMMIT TRAN;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			THROW;
		END CATCH

		--****************************************************************
		--Snapshot the entire InventSum table not just the aggregated data
		CREATE TABLE stage_tbl_InventSum_Snapshot_append_101 AS
		SELECT *
		FROM tbl_InventSum_Snapshot_101

		UNION ALL
		
		SELECT convert(date, DATEADD(Day, -1, CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS datetime2(6))))	Snapshot_Date
		, convert(int, convert(char(8), DATEADD(Day, -1, CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS datetime2(6))), 112))		Snapshot_Date_Key
		,*
		FROM WH_Raw.dbo.inventsum
		WHERE dataareaid = '101'

		BEGIN TRY
		BEGIN TRAN;

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_InventSum_Snapshot_101;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_InventSum_Snapshot_101 AS
		SELECT *
		FROM stage_tbl_InventSum_Snapshot_append_101;
		
		COMMIT TRAN;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			THROW;
		END CATCH

	END

	--ELSE
	-- No change to fact table as data already loaded for given date.

	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Append_101;
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Extended_Append_101;
	DROP TABLE IF EXISTS stage_tbl_InventSum_Snapshot_append_101;
	
END;



