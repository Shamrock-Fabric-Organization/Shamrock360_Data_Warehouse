
create   view vwBomCalcTrans
as
select b.*
, l.accountingcurrency 
, l.reportingcurrency
, bt.bomid
, bt.itemid
, bt.inventdimid inventdimid_bomcalctable
, bv.active
, bv.approved
, id.inventsiteid
, IIP.activationdate
, IIP.todate
, IIP.versionid
, IIP.price
, IIP.priceunit
, IIP.PricePerUnit
, IIP.unitid unitid_inventitemprice
, IIP.CurrentActiveCost
, CASE when IIPa.dataareaid is null then 0 else 1 end LatestStandardCostFlag
, case when calctype in (5,8,9, 10) then 1 else 0 end MultiLevelcalc
, case when calctype in (2,5,8) then 1 else 0 end SingleLevelcalc
, case when calctype = 0 then 1 else 0 end TotalLevelCalc
, case b.costgroupid
	when 'DirectMatl' then 'Direct_Material_Cost_Standard'
	when 'Packaging' then 'Packaging_Cost_Standard'
	when 'AdminOVH' then 'Overhead_Manufacturing_Admin_Cost_Standard'
	when 'DeprcOVH' then 'Overhead_Depreciation_Cost_Standard'
	when 'Labor' then 'Direct_Labor_Cost_Standard'
	when 'MiscOVH' then 'Overhead_Miscellaneous_Manufacturing_Cost_Standard'
	when 'MtnceOVH' then 'Overhead_Maintenance_Cost_Standard'
	when 'QCOVH' then 'Overhead_Quality_Cost_Standard'
	when 'SupvOVH' then 'Overhead_Indirect_Supervisor_Cost_Standard'
	when 'Utility' then 'Direct_Utility_Cost_Standard'
	when 'WhseOVH' then 'Overhead_Warehouse_Cost_Standard'
	else 'Unknown - ' + b.costgroupid
  end  CostGroup
, case when bcg.costgroupbehavior_$label in ('variable','undefined') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end VariableCost
, case when bcg.costgroupbehavior_$label in ('fixed') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end FixedCost
, isnull(case when bcg.costgroupbehavior_$label in ('variable','undefined') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end, 0) +
  isnull(case when bcg.costgroupbehavior_$label in ('fixed') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end, 0) TotalCost
, bcg.costgroupbehavior_$label
from WH_Raw.dbo.bomcalctrans b
 join WH_Raw.dbo.bomcalctable bt
  on b.dataareaid = bt.dataareaid
    and b.pricecalcid = bt.pricecalcid
left join WH_Raw.dbo.bomversion bv
  on b.dataareaid = bv.dataareaid
    and bt.bomid = bv.bomid
 join WH_Raw.dbo.bomcostgroup bcg
  on b.dataareaid = bcg.dataareaid
    and b.costgroupid = bcg.costgroupid
 join WH_Raw.dbo.inventdim id
  on bt.inventdimid = id.inventdimid
    and b.dataareaid = id.dataareaid
left join WH_Raw.dbo.vwInventItemPrice IIP
  on b.dataareaid = IIP.dataareaid
    and bt.itemid = IIP.itemid
    and bt.inventdimid = IIP.inventdimid
    and b.pricecalcid = IIP.pricecalcid
left join WH_Raw.dbo.vwInventItemPriceAgg IIPa
  on b.dataareaid = IIPa.dataareaid
    and bt.itemid = IIPa.itemid
    and b.pricecalcid = IIPa.pricecalcid
	and IIPa.activationdate <= b.transdate
	and IIPa.pricetypedesc = 'Cost'
LEFT JOIN WH_Raw.dbo.ledger l
  on b.dataareaid = l.name

GO

