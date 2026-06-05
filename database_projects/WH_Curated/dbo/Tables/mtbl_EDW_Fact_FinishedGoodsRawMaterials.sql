CREATE TABLE [dbo].[mtbl_EDW_Fact_FinishedGoodsRawMaterials] (
    [ExplodedFormulaKey]     BIGINT          NULL,
    [DataAreaId]             VARCHAR (8000)  NULL,
    [FgItemId]               VARCHAR (8000)  NULL,
    [FgSiteId]               VARCHAR (8000)  NULL,
    [FgBomId]                VARCHAR (8000)  NULL,
    [RawMaterialProductID]   VARCHAR (8000)  NULL,
    [RmSiteId]               VARCHAR (8000)  NULL,
    [RawMaterialAmtPerLbFG]  DECIMAL (28, 8) NULL,
    [BomPath]                VARCHAR (8000)  NULL,
    [BomLevel]               INT             NULL,
    [PeriodFromDate]         DATETIME2 (3)   NULL,
    [PeriodToDate]           DATETIME2 (3)   NULL,
    [PercentControlled]      INT             NULL,
    [Percent]                DECIMAL (28, 8) NULL,
    [IsCurrent]              INT             NULL,
    [Legal_EntityKey]        BIGINT          NOT NULL,
    [FinishedGoodProductKey] BIGINT          NOT NULL,
    [SiteKey]                BIGINT          NOT NULL,
    [FromDateKey]            INT             NULL,
    [ToDateKey]              INT             NULL,
    [RawMaterialProductKey]  BIGINT          NOT NULL,
    [RawMaterialSiteKey]     BIGINT          NOT NULL
);


GO

