
CREATE OR ALTER   VIEW [dbo].[tbl_Fact_Inventory_Snapshot_Extended] AS
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_Extended_101]
UNION ALL
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_Extended_301]
UNION ALL
SELECT * FROM [dbo].[tbl_Fact_Inventory_Snapshot_Extended_501];
GO



