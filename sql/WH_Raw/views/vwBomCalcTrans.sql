-- Auto Generated (Do not modify) 4F0ED33E6183E4A9C4476D9623B91B3351494F6A84D13225FB257DC11DD86C50
/****** Object:  View [dbo].[vwBomCalcTrans]    Script Date: 3/23/2026 12:49:56 PM ******/


CREATE     view [dbo].[vwBomCalcTrans]
as
select 
 b.*
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
, ISNULL(IIP.CurrentActiveCost,0) CurrentActiveCost
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
	when 'Utility0' then 'Direct_Utility_Cost_Standard'
	when 'WhseOVH' then 'Overhead_Warehouse_Cost_Standard'
	when 'Subcontrct' then 'Outside_Processing_Cost_Standard'
	else 'Unknown - ' + b.costgroupid
  end  CostGroup
, case when bcg.costgroupbehavior_$label in ('variable','undefined') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end VariableCost
, case when bcg.costgroupbehavior_$label in ('fixed') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end FixedCost
, isnull(case when bcg.costgroupbehavior_$label in ('variable','undefined') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end, 0) +
  isnull(case when bcg.costgroupbehavior_$label in ('fixed') then cast(round(b.costpriceqty, 4) as decimal(38,4)) end, 0) TotalCost
, bcg.costgroupbehavior_$label
, IIP.createddatetime PriceCreatedDatetime
, id.configid
from WH_Raw.dbo.bomcalctrans b
 join WH_Raw.dbo.bomcalctable bt
  on b.dataareaid = bt.dataareaid
    and b.pricecalcid = bt.pricecalcid
 join 
        --(select dataareaid, itemid, inventdimid, MAX(pricecalcid) m_pricecalcid
        --from bomcalctable 
        --group by dataareaid, itemid, inventdimid) bt2

        (SELECT zbt.dataareaid, zbt.itemid, zbt.inventdimid, MAX(zbt.pricecalcid) m_pricecalcid
        FROM WH_Raw.dbo.bomcalctable zbt
        JOIN WH_Raw.dbo.inventitemprice ziip
            ON  ziip.dataareaid  = zbt.dataareaid
            AND ziip.pricecalcid = zbt.pricecalcid
        GROUP BY zbt.dataareaid, zbt.itemid, zbt.inventdimid) bt2
    on bt.dataareaid = bt2.dataareaid
      and bt.itemid = bt2.itemid
      and bt.inventdimid = bt2.inventdimid
      and bt.pricecalcid = bt2.m_pricecalcid
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
	and IIPa.todate >= b.transdate
	and IIPa.pricetypedesc = 'Cost'
LEFT JOIN WH_Raw.dbo.ledger l
  on b.dataareaid = l.name

--where bt.itemid = '10356'



/*


	SELECT DISTINCT b.[DATAAREAID]
		, b.[ITEMID]
		, b.InventSiteID
		, b.ACTIVATIONDATE
	FROM WH_Raw.dbo.[vwBOMCALCTRANS] b
	WHERE b.itemid='10356'
	--and
	--b.[ACTIVATIONDATE] < CURRENT_TIMESTAMP;


GO
*/