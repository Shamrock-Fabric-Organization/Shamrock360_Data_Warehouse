CREATE OR ALTER VIEW [dbo].[tbl_Dim_QuantityUnitHelper]
AS
SELECT
      v.Quantity_Unit_Code
    , v.Quantity_Unit_Name
    , v.Sort_Order
FROM (VALUES
      ('LBs', 'Pounds',                      1)   
    , ('KGs', 'Kilograms',                           2)
     , ('Transaction', 'Transaction Units',   4)
) v(Quantity_Unit_Code, Quantity_Unit_Name, Sort_Order);
