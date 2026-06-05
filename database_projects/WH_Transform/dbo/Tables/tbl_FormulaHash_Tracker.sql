CREATE TABLE [dbo].[tbl_FormulaHash_Tracker] (
    [DataAreaId]     VARCHAR (8000) NULL,
    [BomId]          VARCHAR (8000) NULL,
    [ItemId]         VARCHAR (8000) NULL,
    [IngredientHash] VARCHAR (64)   NULL,
    [LastCheckedUtc] DATETIME2 (3)  NULL,
    [LastChangedUtc] DATETIME2 (3)  NULL
);


GO

