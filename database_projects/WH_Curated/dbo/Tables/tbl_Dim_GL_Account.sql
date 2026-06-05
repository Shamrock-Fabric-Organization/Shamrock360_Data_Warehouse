CREATE TABLE [dbo].[tbl_Dim_GL_Account] (
    [GL_AccountKey]                     BIGINT         NULL,
    [GL_Account_Number]                 VARCHAR (8000) NULL,
    [GL_Account_Name]                   VARCHAR (8000) NULL,
    [accountcategoryref]                BIGINT         NULL,
    [Account_Category]                  VARCHAR (8000) NULL,
    [Account_Category_Name]             VARCHAR (8000) NULL,
    [Account_Type]                      BIGINT         NULL,
    [Account_Type_Description]          VARCHAR (13)   NULL,
    [Category_Account_Type]             BIGINT         NULL,
    [Category_Account_Type_Description] VARCHAR (8000) NULL,
    [Source]                            VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate]          DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]            DATETIME2 (3)  NULL,
    [RecordStatus]                      INT            NULL
);


GO

