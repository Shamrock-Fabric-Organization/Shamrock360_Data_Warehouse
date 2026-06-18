CREATE TABLE [dbo].[tbl_FormulaHash_Tracker] (

	[DataAreaId] varchar(8000) NULL, 
	[BomId] varchar(8000) NULL, 
	[ItemId] varchar(8000) NULL, 
	[IngredientHash] varchar(64) NULL, 
	[LastCheckedUtc] datetime2(3) NULL, 
	[LastChangedUtc] datetime2(3) NULL
);