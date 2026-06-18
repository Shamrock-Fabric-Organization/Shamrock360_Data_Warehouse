CREATE               PROCEDURE [dbo].[sp_Execute_Snapshot_Fact_Inventory]
AS
BEGIN
	--Declare variables
	DECLARE @DateKey_to_load int

	SET @DateKey_to_load = convert(int, convert(char(8), DATEADD(Day, -1, getdate()), 112))
	select @DateKey_to_load

	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Append;
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Extended_Append;
	DROP TABLE IF EXISTS stage_tbl_InventSum_Snapshot_append;

	--Check to see if data already loaded for given datekey, if so skip loading, if not add new snapshot records
	IF (SELECT COUNT(1) FROM [dbo].[tbl_Fact_Inventory_Snapshot] WHERE Snapshot_Date_Key = @DateKey_to_load) = 0
	BEGIN
		-- Create a new append table by merging existing and new snapshot records
		CREATE TABLE stage_tbl_Fact_Inventory_Snapshot_Append AS
		SELECT *
		FROM tbl_Fact_Inventory_Snapshot f
	
		UNION ALL
	
		SELECT *
		FROM vw_stage_Fact_Inventory_Snapshot_incoming AS f

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_Fact_Inventory_Snapshot;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_Fact_Inventory_Snapshot AS
		SELECT *
		FROM stage_tbl_Fact_Inventory_Snapshot_Append;


		--****************************************************************
		-- Create a new extended append table by merging existing and new snapshot records
		CREATE TABLE stage_tbl_Fact_Inventory_Snapshot_Extended_Append AS
		SELECT *
		FROM tbl_Fact_Inventory_Snapshot_Extended f
	
		UNION ALL
	
		SELECT *
		FROM vw_stage_Fact_Inventory_Snapshot_Extended_incoming AS f

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_Fact_Inventory_Snapshot_Extended;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_Fact_Inventory_Snapshot_Extended AS
		SELECT *
		FROM stage_tbl_Fact_Inventory_Snapshot_Extended_Append;

		--****************************************************************
		--Snapshot the entire InventSum table not just the aggregated data
		CREATE TABLE stage_tbl_InventSum_Snapshot_append AS
		SELECT *
		FROM tbl_InventSum_Snapshot

		UNION ALL
		
		SELECT convert(date, DATEADD(Day, -1, getdate()))	Snapshot_Date
		, convert(int, convert(char(8), DATEADD(Day, -1, getdate()), 112))		Snapshot_Date_Key
		,*
		FROM WH_Raw.dbo.inventsum

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS tbl_InventSum_Snapshot;

		-- Recreate the dimension table with the updated records from the append table
		CREATE TABLE tbl_InventSum_Snapshot AS
		SELECT *
		FROM stage_tbl_InventSum_Snapshot_append;

	END

	--ELSE
	-- No change to fact table as data already loaded for given date.

	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Append;
	DROP TABLE IF EXISTS stage_tbl_Fact_Inventory_Snapshot_Extended_Append;
	DROP TABLE IF EXISTS stage_tbl_InventSum_Snapshot_append;
	
END;