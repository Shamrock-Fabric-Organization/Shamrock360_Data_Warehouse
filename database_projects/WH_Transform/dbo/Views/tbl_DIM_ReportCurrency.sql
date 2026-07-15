CREATE OR ALTER VIEW [dbo].[tbl_Dim_ReportCurrency]
AS
SELECT
      v.Report_Currency_Code
    , v.Report_Currency_Name
    , v.Sort_Order
FROM (VALUES
      ('USD', 'US Dollar',                      1)   
    , ('EUR', 'Euro',                           2)
    , ('CNY', 'Chinese Yuan Renminbi',          3)
    , ('Transaction', 'Transaction Currency',   4)
) v(Report_Currency_Code, Report_Currency_Name, Sort_Order);
