CREATE TABLE [dbo].[tbl_DIM_Department] (
    [DepartmentKey]            BIGINT         NULL,
    [Department]               VARCHAR (8000) NULL,
    [Department_Name]          VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

