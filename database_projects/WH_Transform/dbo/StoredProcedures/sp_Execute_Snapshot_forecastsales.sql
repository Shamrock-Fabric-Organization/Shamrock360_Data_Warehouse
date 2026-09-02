CREATE OR ALTER  PROCEDURE [dbo].[sp_Execute_Snapshot_forecastsales]
AS
BEGIN
	--Declare variables
	DECLARE @DateKey_to_load int

	SET @DateKey_to_load = convert(int, convert(char(8), DATEADD(Day, -1, getdate()), 112))
	--select @DateKey_to_load

	-- Drop intermediate objects if they exist
	DROP TABLE IF EXISTS stage_tbl_forecastsales_Snapshot_append;

	--Check to see if data already loaded for given datekey, if so skip loading, if not add new snapshot records
	IF (SELECT COUNT(1) FROM [dbo].[tbl_forecastsales_Snapshot] WHERE Snapshot_Date_Key = @DateKey_to_load) = 0
	BEGIN
		--****************************************************************
		--Snapshot the entire forecastsales table 
		CREATE TABLE stage_tbl_forecastsales_Snapshot_append AS
		SELECT *
		FROM [tbl_forecastsales_Snapshot]

		UNION ALL
		
		SELECT convert(date, DATEADD(Day, -1, getdate()))	Snapshot_Date
		, convert(int, convert(char(8), DATEADD(Day, -1, getdate()), 112))		Snapshot_Date_Key
		,*
		FROM WH_Raw.dbo.forecastsales

		BEGIN TRY
		BEGIN TRAN;

		-- Drop the original snapshot table to replace with the updated one
		DROP TABLE IF EXISTS [tbl_forecastsales_Snapshot];

		-- Recreate the snapshot table with the updated records from the append table
		CREATE TABLE tbl_forecastsales_Snapshot AS
		SELECT *
		FROM stage_tbl_forecastsales_Snapshot_append;
		
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
	DROP TABLE IF EXISTS stage_tbl_forecastsales_Snapshot_append;
	
END;













