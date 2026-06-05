



CREATE view [dbo].[vw_dlyorder_Cumulative] as
select
[Cono] as CMPNY,
[Order#] as OrderNo,
[Cust #] as CustomerNo,
[Customer] as Customer,
[Shipto Name] as ShipToName,
[Shipto Addr1] as ShipToAddress,
[Ship To] as ShipToCity,
[St] as ShipToState,
[Shipto Addr4] as ShipToZip,
[Date Ord] as OrderDate,
[Date Req] as RequestDate,
[Cust Po] as PONo,
[Whse] as Warehouse,
[Via], 
[Product] as ProductCode,
[Prod Line] as ProductLine,
Cast([Lbs] as float) as Volume,
Cast([Price $] as float) as Price,
Cast([Ext] as float) as Revenue, 
[MoYr] as FiscalPeriod,
Cast([Dir  Cost LB] as float) as DirectCost,
Cast([Contr LB] as float) as ContributionPerLBS,
Cast([Contribution] as float) as Contribution,
Cast([Tot  Cost LB] as float) as TotalCostPerLBS,
Cast([Profit LB] as float) as GMPerLBS,
Cast([Gross Margin] as float) as GrossMargin,
[Salesman] as Salesman,
[SnapShotDate],
[DataUpdateDate],
[Source]
from tbl_dlyorder

GO

