
CREATE OR ALTER   VIEW [dbo].[tbl_forecastsales_Snapshot] AS
SELECT * FROM [dbo].[tbl_forecastsales_Snapshot_101]
UNION ALL
SELECT * FROM [dbo].[tbl_forecastsales_Snapshot_301]
UNION ALL
SELECT * FROM [dbo].[tbl_forecastsales_Snapshot_501];
GO



