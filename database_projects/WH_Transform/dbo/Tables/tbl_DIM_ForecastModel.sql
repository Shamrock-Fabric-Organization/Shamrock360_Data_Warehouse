CREATE TABLE [dbo].[tbl_DIM_ForecastModel] (
      [ForecastModelKey]          bigint        NOT NULL
    , [CMPNY]                     varchar(8000) NULL
    , [ModelId]                   varchar(8000) NULL
    , [Model_Description]         varchar(8000) NULL     -- ForecastModel.Txt (EDT ForecastName)
    , [Blocked]                   varchar(10)   NULL     -- ForecastModel.Blocked
    , [ModelType]                 varchar(10)   NULL     -- ForecastModel.Type
    , [Source]                    varchar(6)    NOT NULL
    , [RecordEffectiveStartDate]  datetime2(3)  NULL
    , [RecordEffectiveEndDate]    datetime2(3)  NULL
    , [RecordStatus]              int           NULL     -- 1 = active, 0 = soft-expired
);
