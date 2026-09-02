
CREATE OR ALTER VIEW [dbo].[tbl_Dim_ProductionVarianceCostLevelHelper]
AS
SELECT
      v.Cost_Level                 -- natural key; joins Fact[Cost_Level] verbatim
    , v.Cost_Level_Key             -- D365 InventCostLevel enum value (Total=0, Single=1, Multi=2)
    , v.Is_Default                 -- 1 = the default single-select value (Multi = D365 screen default)
    , v.Sort_Order                 -- slicer display order (Total, Single, Multi)
    , v.Cost_Level_Description      -- plain-English meaning of the level
FROM (VALUES
      ('Total',   0, 0, 1,
         'One aggregate row per output item = the authoritative posted variance total.')
    , ('Single', 1, 0, 2,
         'D365 Production variance screen default. A consumed sub-assembly appears as a single lump line (not exploded).')
    , ('Multi', 2, 1, 3,
         'Explodes the sub-assembly into per-cost-group rows; reconciles to the same order total as Single.')
) v(Cost_Level, Cost_Level_Key, Is_Default, Sort_Order, Cost_Level_Description);


