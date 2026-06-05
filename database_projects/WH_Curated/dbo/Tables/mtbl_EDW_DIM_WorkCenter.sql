CREATE TABLE [dbo].[mtbl_EDW_DIM_WorkCenter] (
    [WorkCenterKey]            BIGINT          NULL,
    [CMPNY]                    VARCHAR (8000)  NULL,
    [WorkCenterID]             VARCHAR (8000)  NULL,
    [WorkCenterName]           VARCHAR (8000)  NULL,
    [WorkCenterIDandName]      VARCHAR (8000)  NULL,
    [wrkctrtype]               BIGINT          NULL,
    [wrkctrtype_$label]        VARCHAR (9)     NULL,
    [effectivitypct]           DECIMAL (38, 6) NULL,
    [errorpct]                 DECIMAL (38, 6) NULL,
    [operationschedpct]        DECIMAL (38, 6) NULL,
    [processcategoryid]        VARCHAR (8000)  NULL,
    [routegroupid]             VARCHAR (8000)  NULL,
    [ResourceGroup]            VARCHAR (8000)  NULL,
    [ResourceGroupName]        VARCHAR (8000)  NULL,
    [Source]                   VARCHAR (6)     NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)   NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)   NULL,
    [RecordStatus]             INT             NULL
);


GO

