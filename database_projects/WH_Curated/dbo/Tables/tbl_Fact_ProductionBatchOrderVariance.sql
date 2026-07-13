

CREATE TABLE dbo.tbl_Fact_ProductionBatchOrderVariance(
	[Cost_Level] [varchar](10) NULL,
	[CMPNY] [varchar](8000) NULL,
	[ProductionBatchOrder] [varchar](8000) NULL,
	[ProductionOrderProductID] [varchar](8000) NULL,
	[OutputProductID] [varchar](8000) NULL,
	[Is_CoProduct] [int] NULL,
	[Output_Role] [varchar](10) NOT NULL,
	[Cost_Group] [varchar](8000) NULL,
	[Cost_Type] [varchar](50) NULL,
	[Resource] [varchar](8000) NULL,
	[Oper_No] [bigint] NULL,
	[Net_Realized_Qty] [decimal](28, 8) NULL,
	[Net_Realized_Cost] [decimal](19, 4) NULL,
	[Allowed_Qty] [decimal](28, 8) NULL,
	[Allowed_Cost] [decimal](19, 4) NULL,
	[Lot_Size_Variance] [decimal](19, 4) NULL,
	[Price_Variance] [decimal](19, 4) NULL,
	[Quantity_Variance] [decimal](19, 4) NULL,
	[Substitution_Variance] [decimal](19, 4) NULL,
	[Total_Variance] [decimal](19, 4) NULL,
	[FinishedDate] [date] NULL,
	[FinishedDateKey] [int] NULL,
	[Source] [varchar](6) NOT NULL,
	[Legal_EntityKey] [bigint] NOT NULL,
	[ProductionBatchOrderKey] [bigint] NOT NULL,
	[HistoricalProductKey] [bigint] NOT NULL,
	[ProductKey] [bigint] NOT NULL,
	[HistoricalOutputProductKey] [bigint] NOT NULL,
	[OutputProductKey] [bigint] NOT NULL,
	[SiteKey] [bigint] NOT NULL,
	[WarehouseKey] [bigint] NOT NULL,
	[RouteKey] [bigint] NOT NULL
)
GO

