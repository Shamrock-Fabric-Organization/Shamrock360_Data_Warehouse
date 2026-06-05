CREATE TABLE [dbo].[mtbl_EDW_DIM_Route] (
    [RouteKey]                 BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [RouteID]                  VARCHAR (8000) NULL,
    [RouteName]                VARCHAR (8000) NULL,
    [ApproverPersonnelNumber]  VARCHAR (8000) NULL,
    [ApproverName]             VARCHAR (8000) NULL,
    [Approved]                 VARCHAR (3)    NULL,
    [CheckRoute]               VARCHAR (3)    NULL,
    [RouteType]                VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

