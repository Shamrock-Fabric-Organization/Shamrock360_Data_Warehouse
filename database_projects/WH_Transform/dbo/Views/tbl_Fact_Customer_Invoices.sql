-- Auto Generated (Do not modify) 00D8A384DC19110001EA31135E9B1CBD2AB164D5BEC3AA6E1D8FC7314979319B
/****** Object:  View [dbo].[tbl_Fact_Customer_Invoices]    Script Date: 5/19/2026 4:15:43 PM ******/
/****** Object:  View [dbo].[tbl_Fact_Customer_Invoices]    Script Date: 4/23/2026 2:42:06 PM ******/


CREATE OR ALTER                            VIEW [dbo].[tbl_Fact_Customer_Invoices]
as
select  cit.dataareaid CMPNY  
, cit.invoiceid  Invoice_ID
, cit.invoicedate InvoiceDate
, convert(int, convert(char(8), cit.invoicedate,112)) InvoiceDateKey
, cit.salesid Sales_ID
, cij.orderaccount  Order_Account
, cij.invoiceaccount Invoice_Account
, cij.taxgroup Tax_Group
, PAV.COUNTRYREGIONID Country
, cit.name Invoice_Line_Name
, cij.invoiceamount InvoiceAmount
, cij.invoiceamountmst InvoiceAmountMST
, mt_freight.calculatedamount Freight 
, mt_fuelchg.calculatedamount Fuel_Charge

, mt_Comms.calculatedamount  Comms
, mt_PLT_Brk_Ch.calculatedamount PLT_Brk_Ch
, mt_Tariff_SC.calculatedamount  Tariff_SC


, cit.linenum LineNumber
, cit.itemid Product_ID
, id.inventsiteid  Site_ID
, id.inventlocationid Warehouse_ID
, cit.lineamount LineAmount
, cit.lineamountmst LineAmountMST
, cit.currencycode Current_Code
, cit.salesunit 
--, CASE WHEN left( cit.invoiceid ,2) = 'FT' and cit.qty=1 then cij.qty else cit.qty end Qty
, cit.qty Qty
     , CASE
         WHEN cit.salesunit = 'lb' THEN 1                                               -- already in LB
         WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor  -- direct sales-unit -> LB conversion
         ELSE (case when cit.salesunit = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) * 2.20462262185 -- fallback: convert KG -> LB (1 / 0.45359237)
       END * cit.qty      Quantity_LBs

     , CASE
         WHEN cit.salesunit = 'kg' THEN 1                                               -- already in KG
         WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor  -- direct sales-unit -> KG conversion
         ELSE (case when cit.salesunit = 'lb' then 1 else UOMC_lb.UOMConversionFactor end ) * 0.45359237  -- fallback: convert LBs -> KG
       END * cit.qty      Quantity_KGs
--,cit.inventqty

, cit.salesprice SalesPrice
, itcost.costamountposted CostAmount
, itcost.costamountphysical CostAmountPhysical
, cit.lineamount + isnull(itcost.costamountposted,0) Margin  

, cit.inventtransid InventTransID
, cit.inventdimid InventDimID
, cij.postedstate  postedstateID
, cij.postedstate_$label PostedState
,'D365FO'		Source

, ISNULL(dc.CustomerKey, -1) CustomerKey
, ISNULL(dic.CustomerKey, -1) InvoiceCustomerKey
, ISNULL(dp.ProductKey, -1) ProductKey
, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
, ISNULL(ds.SiteKey, -1) SiteKey
, COALESCE(dsc.StandardCostKey, dsc2.StandardCostKey, -1) StandardCostKey
, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
, ISNULL(dso.SalesOrderKey, -1) SalesOrderKey
	, ISNULL(da.AddressKey, -1) DeliveryAddressKey

from WH_Raw.dbo.custinvoicetrans cit
join (select dataareaid , invoiceid  , invoicedate , isnull(salesid, 'none') salesid, min(linenum) min_linenumber
        from WH_Raw.dbo.custinvoicetrans 
        group by dataareaid , invoiceid  , invoicedate , isnull(salesid, 'none')
        ) min_ln
  on cit.dataareaid = min_ln.dataareaid
    and cit.invoiceid = min_ln.invoiceid
    and cit.invoicedate = min_ln.invoicedate
    and isnull(cit.salesid,'none') = isnull(min_ln.salesid,'none')
join WH_Raw.dbo.custinvoicejour cij
  on cit.dataareaid = cij.dataareaid
    and cit.invoiceid = cij.invoiceid
    and isnull(cit.salesid,'none') = isnull(cij.salesid,'none')
    and cit.invoicedate = cij.invoicedate

left JOIN WH_Raw.dbo.InventTable IT
	ON cit.itemid = IT.itemid
		AND cit.dataareaid = IT.dataareaid

left join (WH_Raw.dbo.custinvoicejour cij2
        left JOIN WH_Raw.dbo.markuptrans mt_freight
          on cij2.recid = mt_freight.transrecid
            and mt_freight.markupcode = 'Freight'
            and mt_freight.transtableid = 11259
        left JOIN WH_Raw.dbo.markuptrans mt_fuelchg
          on cij2.recid = mt_fuelchg.transrecid
            and mt_fuelchg.markupcode = 'Fuel Chrg'
            and mt_fuelchg.transtableid = 11259

        left JOIN WH_Raw.dbo.markuptrans mt_Comms
          on cij2.recid = mt_Comms.transrecid
            and mt_Comms.markupcode = 'Comms'
            and mt_Comms.transtableid = 11259
        left JOIN WH_Raw.dbo.markuptrans mt_PLT_Brk_Ch
          on cij2.recid = mt_PLT_Brk_Ch.transrecid
            and mt_PLT_Brk_Ch.markupcode = 'PLT Brk Ch'
            and mt_PLT_Brk_Ch.transtableid = 11259
        left JOIN WH_Raw.dbo.markuptrans mt_Tariff_SC
          on cij2.recid = mt_Tariff_SC.transrecid
            and mt_Tariff_SC.markupcode = 'Tariff SC'
            and mt_Tariff_SC.transtableid = 11259
            )
  on cit.dataareaid = cij2.dataareaid
    and cit.invoiceid = cij2.invoiceid
    and isnull(cit.salesid,'none') = isnull(cij2.salesid,'none')
    and cit.invoicedate = cij2.invoicedate
    and cit.linenum = min_ln.min_linenumber

------join (WH_Raw.dbo.custinvoicejour cij
------        left JOIN WH_Raw.dbo.markuptrans mt_freight
------          on cij.recid = mt_freight.transrecid
------            and mt_freight.markupcode = 'Freight'
------            and mt_freight.transtableid = 11259
------        left JOIN WH_Raw.dbo.markuptrans mt_fuelchg
------          on cij.recid = mt_fuelchg.transrecid
------            and mt_fuelchg.markupcode = 'Fuel Chrg'
------            and mt_fuelchg.transtableid = 11259)
------  on cit.dataareaid = cij.dataareaid
------    and cit.invoiceid = cij.invoiceid
------    and cit.salesid = cij.salesid
------    and cit.invoicedate = cij.invoicedate

left join 
    (select ito.dataareaid, ito.inventtransid, sum(it.costamountposted) costamountposted  --InventTrans Records aggregated to get the cost
    , sum(it.costamountphysical) costamountphysical
    from WH_Raw.dbo.inventtransorigin ito
     join WH_Raw.dbo.inventtrans it
      on ito.recid = it.inventtransorigin
        and ito.dataareaid = it.dataareaid
        and it.statusissue=1
    group by ito.dataareaid, ito.inventtransid
    ) itcost
      on cit.inventtransid = itcost.inventtransid
        and cit.dataareaid = itcost.dataareaid
left join WH_Raw.dbo.LogisticsPostalAddressView PAV
  on pav.recid = cij.deliverypostaladdress
left join WH_Raw.dbo.inventdim id
  on cit.dataareaid = id.dataareaid
    and cit.inventdimid = id.inventdimid
 
LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND cit.salesunit = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'
 
 LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
     ON IT.product = UOMC_kg.product
         AND cit.salesunit = UOMC_kg.SYMBOLFROM
         AND UOMC_kg.SYMBOLTO = 'kg'

 
LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
	ON cij.orderaccount = dc.Customer_ID
		AND cit.dataareaid = dc.CMPNY
		AND cit.createddatetime between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dic
	ON cij.invoiceaccount = dic.Customer_ID
		AND cit.dataareaid = dic.CMPNY
		AND cit.createddatetime between dic.RecordEffectiveStartDate and dic.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON cit.itemid = dp.Product_ID
		AND cit.dataareaid = dp.CMPNY
		AND cit.createddatetime between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON cit.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND cit.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1


        
LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc
	ON cit.itemid = dsc.Product_ID
		AND cit.dataareaid = dsc.CMPNY
		AND ID.inventsiteid = dsc.siteid
		AND cit.createddatetime between dsc.activationdate and dsc.EndDate --dsc.RecordEffectiveStartDate and dsc.RecordEffectiveEndDate

LEFT JOIN WH_Raw.dbo.vwinventitempriceagg iip
    ON cit.dataareaid = IIP.dataareaid
    and cit.itemid = IIP.itemid
    and ID.inventsiteid = IIP.inventsiteid
    and cit.createddatetime between IIP.activationdate and IIP.todate
    and iip.pricetype=0
    
------LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc2
------	ON cit.itemid = dsc2.Product_ID
------		AND cit.dataareaid = dsc2.CMPNY
------		AND ID.inventsiteid != dsc2.siteid
------		----AND ROUND(IIP.PricePerUnit,2) = ROUND(dsc2.TotalCost,2)
------		--AND ROUND(IIP.PricePerUnit,2,1) = ROUND(dsc2.TotalCost,2,1)
------		AND ROUND(IIP.PricePerUnit,2,1) between (ROUND(dsc2.TotalCost,2,1) - 0.01) and (ROUND(dsc2.TotalCost,2,1) + 0.01)
------		AND cit.createddatetime between dsc2.RecordEffectiveStartDate and dsc2.RecordEffectiveEndDate

-- OUTER APPLY: limits to 1 dsc2 row per sales line where site differs.
-- OUTER APPLY justified: ranking requires ID.inventsiteid from outer scope —
-- no set-based alternative exists.
OUTER APPLY (
    SELECT TOP 1 *
    FROM WH_Transform.dbo.tbl_DIM_StandardCost dsc2_inner
    WHERE dsc2_inner.Product_ID = cit.itemid
        AND dsc2_inner.CMPNY    = cit.dataareaid
        AND dsc2_inner.siteid  != ID.inventsiteid
        AND ROUND(IIP.PricePerUnit,2,1) BETWEEN (ROUND(dsc2_inner.TotalCost,2,1) - 0.01)
                                             AND (ROUND(dsc2_inner.TotalCost,2,1) + 0.01)
        AND cit.createddatetime BETWEEN dsc2_inner.ActivationDate --RecordEffectiveStartDate
                                   AND dsc2_inner.EndDate --RecordEffectiveEndDate
    ORDER BY dsc2_inner.SiteID  -- deterministic; swap for a business-preferred site if needed
) dsc2



LEFT JOIN WH_Transform.dbo.tbl_DIM_MarketSegmentation dmsc
	ON cij.orderaccount = dmsc.CustomerID
		AND cit.itemid = dmsc.ProductID
		AND cit.dataareaid = dmsc.CMPNY
		AND dmsc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SalesOrder dso
	ON cit.salesid = dso.SalesOrderId
		AND cit.dataareaid = dso.CMPNY
		AND dso.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Address da
	ON cit.deliverypostaladdress = da.AddressRecID
		AND dso.RecordStatus=1