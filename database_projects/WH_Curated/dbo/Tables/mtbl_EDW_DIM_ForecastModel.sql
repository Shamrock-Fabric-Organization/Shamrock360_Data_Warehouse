CREATE TABLE [dbo].[mtbl_EDW_DIM_ForecastModel](
	[ForecastModelKey] [bigint] NULL,
	[CMPNY] [varchar](8000) NULL,
	[ModelId] [varchar](8000) NULL,
	[Model_Description] [varchar](8000) NULL,
	[Blocked] [varchar](10) NULL,
	[ModelType] [varchar](10) NULL,
	[Source] [varchar](6) NOT NULL,
	[RecordEffectiveStartDate] [datetime2](3) NULL,
	[RecordEffectiveEndDate] [datetime2](3) NULL,
	[RecordStatus] [int] NULL
) 
GO
