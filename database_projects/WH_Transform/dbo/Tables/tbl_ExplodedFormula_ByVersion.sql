CREATE TABLE [dbo].[tbl_ExplodedFormula_ByVersion] (
    [ExplodedFormulaKey]   BIGINT          NULL,
    [DataAreaId]           VARCHAR (8000)  NULL,
    [FgItemId]             VARCHAR (8000)  NULL,
    [FgSiteId]             VARCHAR (8000)  NULL,
    [FgBomId]              VARCHAR (8000)  NULL,
    [PeriodFromDate]       DATETIME2 (3)   NULL,
    [PeriodToDate]         DATETIME2 (3)   NULL,
    [RmItemId]             VARCHAR (8000)  NULL,
    [RmSiteId]             VARCHAR (8000)  NULL,
    [LbsPerLbFG]           DECIMAL (28, 8) NULL,
    [NativeLbsPerLbFG]     DECIMAL (28, 8) NULL,
    [RmNativeUomId]        VARCHAR (8000)  NULL,
    [UomConverted]         INT             NULL,
    [UomConversionMissing] INT             NULL,
    [PercentControlled]    INT             NULL,
    [Percent]              DECIMAL (28, 8) NULL,
    [BomPath]              VARCHAR (8000)  NULL,
    [BomLevel]             INT             NULL,
    [FgFormulaUomId]       VARCHAR (8000)  NULL,
    [FgFormulaQtyLbs]      DECIMAL (28, 8) NULL,
    [FgItemName]           VARCHAR (8000)  NULL,
    [FgItemGroupId]        VARCHAR (8000)  NULL,
    [RmItemName]           VARCHAR (8000)  NULL,
    [RmItemGroupId]        VARCHAR (8000)  NULL,
    [IsCurrentPeriod]      INT             NULL,
    [LoadedAtUtc]          DATETIME2 (3)   NULL
);


GO

