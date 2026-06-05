CREATE TABLE [dbo].[mtbl_EDW_Dim_Employee] (
    [EmployeeKey]              BIGINT         NULL,
    [Personnel_Number]         VARCHAR (8000) NULL,
    [Employee_Name]            VARCHAR (8000) NULL,
    [Employment_Type]          BIGINT         NULL,
    [Employment_Type_Desc]     VARCHAR (10)   NULL,
    [IsPerson]                 VARCHAR (3)    NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (6)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (6)  NULL,
    [RecordStatus]             INT            NULL
);


GO

