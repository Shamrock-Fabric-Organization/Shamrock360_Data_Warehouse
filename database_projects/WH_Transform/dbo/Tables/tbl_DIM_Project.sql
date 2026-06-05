CREATE TABLE [dbo].[tbl_DIM_Project] (
    [ProjectKey]               BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [ProjId]                   VARCHAR (8000) NULL,
    [ProjectName]              VARCHAR (8000) NULL,
    [ProjectContractID]        VARCHAR (8000) NULL,
    [ProjectType]              VARCHAR (8000) NULL,
    [ProjectStage]             VARCHAR (8000) NULL,
    [BudgetControlInterval]    VARCHAR (8000) NULL,
    [ProjectedStartDate]       DATETIME2 (6)  NULL,
    [ProjectedEndDate]         DATETIME2 (6)  NULL,
    [StartDate]                DATETIME2 (6)  NULL,
    [EndDate]                  DATETIME2 (6)  NULL,
    [Status]                   VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

