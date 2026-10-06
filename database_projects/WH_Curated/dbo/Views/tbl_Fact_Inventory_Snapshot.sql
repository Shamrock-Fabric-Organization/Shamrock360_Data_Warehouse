
CREATE OR ALTER   VIEW [dbo].[tbl_Fact_Inventory_Snapshot] AS
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_101]
UNION ALL
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_301]
UNION ALL
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_501];
GO


