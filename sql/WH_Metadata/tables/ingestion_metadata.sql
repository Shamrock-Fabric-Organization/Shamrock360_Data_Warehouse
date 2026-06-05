SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ingestion_metadata](
	[DataSource] [varchar](1000) NULL,
	[DatabaseName] [varchar](1000) NULL,
	[SourceTableSchema] [varchar](255) NULL,
	[SourceTableName] [varchar](255) NULL,
	[TargetTableSchema] [varchar](255) NULL,
	[TargetTableName] [varchar](255) NULL,
	[ProcessingStoredProcedure] [varchar](255) NULL,
	[ColumnKey] [varchar](1000) NULL,
	[ColumnIncrementalLoad] [varchar](1000) NULL,
	[TableColumns] [varchar](8000) NULL,
	[Incremental] [int] NULL,
	[RefreshFrequencyHours] [int] NULL,
	[LastLoadDateTime] [datetime2](3) NULL,
	[FullLoadComplete] [int] NULL,
	[Active] [int] NULL,
	[LoadStatus] [int] NULL,
	[IncrementalLoadSubstractionDays] [int] NULL
) ON [PRIMARY]
GO
