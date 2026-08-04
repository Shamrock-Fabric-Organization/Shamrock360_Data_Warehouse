


CREATE TABLE [dbo].[mtbl_EDW_Fact_StandardCost](
	[CMPNY] [varchar](8000) NULL,
	[Product_ID] [varchar](8000) NULL,
	[LegacyProductCode] [varchar](8000) NULL,
	[SiteID] [varchar](8000) NULL,
	[ActivationDate] [datetime2](3) NULL,
	[EndDate] [datetime2](6) NULL,
	[Costing_Version] [varchar](8000) NULL,
	[CurrentActiveCost] [int] NULL,
	[Direct_Material_Cost_Standard] [decimal](38, 6) NULL,
	[Packaging_Cost_Standard] [decimal](38, 6) NULL,
	[Direct_Labor_Cost_Standard] [decimal](38, 6) NULL,
	[Direct_Utility_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Warehouse_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Indirect_Supervisor_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Quality_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Maintenance_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Manufacturing_Admin_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Depreciation_Cost_Standard] [decimal](38, 6) NULL,
	[Overhead_Miscellaneous_Manufacturing_Cost_Standard] [decimal](38, 6) NULL,
	[Outside_Processing_Cost_Standard] [decimal](38, 6) NULL,
	[Total_Direct_Cost_Standard] [decimal](38, 6) NULL,
	[Total_Overhead_Cost_Standard] [decimal](38, 6) NULL,
	[TotalCost] [decimal](38, 6) NULL,
	[accountingcurrency] [varchar](8000) NULL,
	[Source] [varchar](6) NOT NULL,
	[StandardCostKey] [bigint] NULL,
	[Legal_EntityKey] [bigint] NOT NULL,
	[HistoricalProductKey] [bigint] NOT NULL,
	[ProductKey] [bigint] NOT NULL,
	[SiteKey] [bigint] NOT NULL,
	[ActivationDateKey] [int] NULL
) 
GO





