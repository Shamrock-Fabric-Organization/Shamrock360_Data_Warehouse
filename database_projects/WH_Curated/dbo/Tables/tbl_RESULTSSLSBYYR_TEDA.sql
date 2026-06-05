CREATE TABLE [dbo].[tbl_RESULTSSLSBYYR_TEDA] (
    [DEST]                VARCHAR (50)    NULL,
    [Order Date]          DATE            NULL,
    [Order No]            VARCHAR (50)    NULL,
    [Invoice Date]        DATE            NULL,
    [Invoice No]          VARCHAR (MAX)   NULL,
    [Expected Ship Date]  DATE            NULL,
    [Product Name]        VARCHAR (50)    NULL,
    [Product Description] VARCHAR (50)    NULL,
    [Quantity]            DECIMAL (18)    NULL,
    [Net Weight LBS]      DECIMAL (18, 2) NULL,
    [Unit Price]          DECIMAL (18, 2) NULL,
    [Total Amount]        DECIMAL (18, 2) NULL,
    [Net Amount]          DECIMAL (18, 2) NULL,
    [Customer Name]       VARCHAR (50)    NULL,
    [Customer No]         VARCHAR (50)    NULL,
    [Country]             VARCHAR (50)    NULL,
    [Salesman Name]       VARCHAR (50)    NULL,
    [Salesman No]         VARCHAR (50)    NULL,
    [SnapShotDate]        DATETIME2 (6)   NULL,
    [DataUpdateDate]      DATETIME2 (6)   NULL,
    [Source]              VARCHAR (10)    NULL,
    [TED_SID]             INT             NULL
);


GO

