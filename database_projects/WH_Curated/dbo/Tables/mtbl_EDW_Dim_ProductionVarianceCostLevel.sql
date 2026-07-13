
CREATE TABLE dbo.mtbl_EDW_Dim_ProductionVarianceCostLevel(
	[Cost_Level] [varchar](6) NOT NULL,
	[Cost_Level_Key] [int] NOT NULL,
	[Is_Default] [int] NOT NULL,
	[Sort_Order] [int] NOT NULL,
	[Cost_Level_Description] [varchar](110) NOT NULL
)
GO
