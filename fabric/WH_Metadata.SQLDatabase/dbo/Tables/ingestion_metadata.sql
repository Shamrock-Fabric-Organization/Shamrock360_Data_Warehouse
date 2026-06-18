CREATE TABLE [dbo].[ingestion_metadata] (
    [DataSource]                      VARCHAR (1000) NULL,
    [DatabaseName]                    VARCHAR (1000) NULL,
    [SourceTableSchema]               VARCHAR (255)  NULL,
    [SourceTableName]                 VARCHAR (255)  NULL,
    [TargetTableSchema]               VARCHAR (255)  NULL,
    [TargetTableName]                 VARCHAR (255)  NULL,
    [ProcessingStoredProcedure]       VARCHAR (255)  NULL,
    [ColumnKey]                       VARCHAR (1000) NULL,
    [ColumnIncrementalLoad]           VARCHAR (1000) NULL,
    [TableColumns]                    VARCHAR (8000) NULL,
    [Incremental]                     INT            NULL,
    [RefreshFrequencyHours]           INT            NULL,
    [LastLoadDateTime]                DATETIME2 (3)  NULL,
    [FullLoadComplete]                INT            NULL,
    [Active]                          INT            NULL,
    [LoadStatus]                      INT            NULL,
    [IncrementalLoadSubstractionDays] INT            NULL
);


GO

