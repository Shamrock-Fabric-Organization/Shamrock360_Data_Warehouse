CREATE TABLE [dbo].[mtbl_EDW_Dim_TestGroup] (
    [TestGroupKey]             BIGINT          NULL,
    [CMPNY]                    VARCHAR (8000)  NULL,
    [TestGroupId]              VARCHAR (8000)  NULL,
    [TestGroupDescription]     VARCHAR (8000)  NULL,
    [AcceptableQualityLevel]   DECIMAL (38, 6) NULL,
    [IsDestructive]            VARCHAR (8000)  NULL,
    [Source]                   VARCHAR (6)     NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)   NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)   NULL,
    [RecordStatus]             INT             NULL
);
GO

