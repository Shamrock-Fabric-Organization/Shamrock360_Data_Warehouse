CREATE TABLE [dbo].[mtbl_EDW_DIM_PhantomProduct] (
    [PhantomProductKey]        BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [Product_ID]               VARCHAR (8000) NULL,
    [Phantom_Product]          VARCHAR (8000) NULL,
    [Commercial_Name]          VARCHAR (8000) NULL,
    [ActiveFormula_ID]         VARCHAR (8000) NULL,
    [Business_Line]            VARCHAR (8000) NULL,
    [Product_Line]             VARCHAR (8000) NULL,
    [Technology]               VARCHAR (8000) NULL,
    [Material]                 VARCHAR (8000) NULL,
    [Description_Internal]     VARCHAR (500)  NULL,
    [Description_External]     VARCHAR (500)  NULL,
    [Application_Benefit]      VARCHAR (500)  NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL,
    [Source]                   VARCHAR (6)    NOT NULL
);


GO

