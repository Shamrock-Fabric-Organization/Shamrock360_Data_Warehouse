CREATE TABLE [dbo].[tbl_DIM_WorkOrder] (
    [WorkOrderKey]             BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [WorkId]                   VARCHAR (8000) NULL,
    [WorkCancelledUTC]         DATETIME2 (6)  NULL,
    [WorkStartedUTC]           DATETIME2 (6)  NULL,
    [WorkClosedUTC]            DATETIME2 (6)  NULL,
    [CreatedDateTime]          DATETIME2 (6)  NULL,
    [ModifiedDateTime]         DATETIME2 (6)  NULL,
    [CountWorkStatus]          VARCHAR (8000) NULL,
    [WorkCreatedBy]            VARCHAR (8000) NULL,
    [IsPartialCount]           VARCHAR (8000) NULL,
    [WorkTransType]            VARCHAR (8000) NULL,
    [WorkPriority]             BIGINT         NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);
GO

