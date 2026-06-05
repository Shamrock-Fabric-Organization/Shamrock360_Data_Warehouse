CREATE TABLE [dbo].[legacy_tbl_Fact_Sales] (
    [Cmpny]                    VARCHAR (8000) NULL,
    [Order No]                 VARCHAR (8000) NULL,
    [Customer PO]              VARCHAR (50)   NULL,
    [Invoice No]               VARCHAR (8000) NULL,
    [IncoTerms]                VARCHAR (50)   NULL,
    [Warehouse]                VARCHAR (50)   NULL,
    [RecordType]               VARCHAR (12)   NULL,
    [OrderDate]                DATE           NULL,
    [InvoiceDate]              DATE           NULL,
    [ShipDate]                 DATE           NULL,
    [Customer No]              VARCHAR (8000) NULL,
    [Ship To No]               VARCHAR (8000) NULL,
    [CustomerID]               VARCHAR (8000) NULL,
    [CPCID]                    VARCHAR (8000) NULL,
    [CPAID]                    VARCHAR (8000) NULL,
    [CostingLinkID]            VARCHAR (310)  NULL,
    [Product]                  VARCHAR (8000) NULL,
    [Revenue]                  FLOAT (53)     NULL,
    [Volume]                   FLOAT (53)     NULL,
    [MaterialCostPerPound]     FLOAT (53)     NULL,
    [DirectCostPerPound]       FLOAT (53)     NULL,
    [OSProcessingCostPerPound] FLOAT (53)     NULL,
    [OverheadCostPerPound]     FLOAT (53)     NULL,
    [Source]                   VARCHAR (22)   NULL
);


GO

