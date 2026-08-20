-- Auto Generated (Do not modify) 643D9A4001C0212D71C200D300EDF28D554FB6962B6BA24F0BEB31A1DF61E44D

--USE WH_Transform

CREATE OR ALTER  VIEW tbl_Fact_CustomerPackingSlipTransactions
AS
WITH PackingSlipLines AS (
    SELECT
        cpst.DATAAREAID,
        cpst.SALESID,
        cpst.ITEMID,
        cpst.LINENUM,
        cpst.salesunit                                       AS ShippedUnit,
        cpst.QTY                                             AS ShippedQty,
        cpst.PACKINGSLIPID,
        cpsj.DELIVERYDATE                                    AS ActualShipDate,
        st.CUSTACCOUNT                                      AS CustomerId,
        ec.NAME                                             AS SalesCategory,
        id.INVENTSITEID,
        id.INVENTLOCATIONID,
        id.inventbatchid,
        id.inventserialid,
        CASE
            WHEN cpst.SALESLINESHIPPINGDATECONFIRMED = '1900-01-01' THEN cpst.SALESLINESHIPPINGDATEREQUESTED
            ELSE cpst.SALESLINESHIPPINGDATECONFIRMED
        END                                                 AS EffectiveShipDate
        ,cpst.SALESLINESHIPPINGDATECONFIRMED  
        ,cpst.SALESLINESHIPPINGDATEREQUESTED  
        ,st.createddatetime  SalesOrderCreatedDateTime
    FROM WH_Raw.dbo.CustPackingSlipTrans cpst
    JOIN WH_Raw.dbo.CustPackingSlipJour cpsj
        ON  cpsj.SALESID       = cpst.SALESID
        AND cpsj.PACKINGSLIPID = cpst.PACKINGSLIPID
        AND cpsj.DATAAREAID    = cpst.DATAAREAID
    JOIN WH_Raw.dbo.SalesTable st
        ON  st.SALESID        = cpst.ORIGSALESID
        AND st.DATAAREAID     = cpst.DATAAREAID
    JOIN WH_Raw.dbo.InventDim id
        ON  id.INVENTDIMID    = cpst.INVENTDIMID
        AND id.DATAAREAID     = cpst.DATAAREAID
    LEFT JOIN WH_Raw.dbo.EcoResCategory ec
        ON  ec.RECID          = cpst.SALESCATEGORY
)
SELECT
    ps.DATAAREAID CMPNY,
    ps.SALESID,
    ps.ITEMID,
    ps.LINENUM,
    ps.PACKINGSLIPID,
    ps.CustomerId,
    ps.SalesCategory,
    ps.INVENTSITEID SiteID,
    ps.INVENTLOCATIONID Warehouse,
    ps.inventbatchid,
    ps.ActualShipDate,
    ps.EffectiveShipDate EstimatedDate,
    ps.ShippedUnit,
    ps.ShippedQty Delivered,

    CASE
        WHEN ps.ShippedUnit = 'lb' THEN 1                                               -- already in LB
        WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor  -- direct sales-unit -> LB conversion
        ELSE (case when ps.ShippedUnit = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) * 2.20462262185 -- fallback: convert KG -> LB (1 / 0.45359237)
    END * ps.ShippedQty      Delivered_LBs,

    CASE
        WHEN ps.ShippedUnit = 'kg' THEN 1                                               -- already in KG
        WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor  -- direct sales-unit -> KG conversion
        ELSE (case when ps.ShippedUnit = 'lb' then 1 else UOMC_lb.UOMConversionFactor end ) * 0.45359237  -- fallback: convert LBs -> KG
    END * ps.ShippedQty      Delivered_KGs,

    DATEDIFF(day, ps.EffectiveShipDate, ps.ActualShipDate)        AS DayVariance
    ,ps.SALESLINESHIPPINGDATECONFIRMED
    ,ps.SALESLINESHIPPINGDATEREQUESTED
    ,ps.SalesOrderCreatedDateTime

    , ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, ISNULL(dp.ProductKey, -1) HistoricProductKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(dso.SalesOrderKey, -1) SalesOrderKey
	, ISNULL(dcps.CustomerPackingSlipKey, -1) CustomerPackingSlipKey

FROM PackingSlipLines ps


LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
	ON ps.CustomerId = dc.Customer_ID
		AND ps.dataareaid = dc.CMPNY
		AND ps.SalesOrderCreatedDateTime between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dcc
	ON ps.CustomerId = dcc.Customer_ID
		AND ps.dataareaid = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON ps.itemid = dp.Product_ID
		AND ps.dataareaid = dp.CMPNY
		AND ps.SalesOrderCreatedDateTime between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON ps.itemid = dpc.Product_ID
		AND ps.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON ps.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ps.inventsiteid = ds.Site_ID
		AND ps.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON ps.dataareaid = dw.CMPNY
		AND ps.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SalesOrder dso
	ON ps.salesid = dso.SalesOrderId
		AND ps.dataareaid = dso.CMPNY
		AND dso.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_CustomerPackingSlip dcps
	ON ps.PACKINGSLIPID = dcps.CustomerPackingSlipId
		AND ps.dataareaid = dcps.CMPNY
		AND dcps.RecordStatus=1


JOIN WH_Raw.dbo.InventTable IT
	ON ps.itemid = IT.itemid
		AND ps.dataareaid = IT.dataareaid

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND ps.ShippedUnit = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'
 
 LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
     ON IT.product = UOMC_kg.product
         AND ps.ShippedUnit = UOMC_kg.SYMBOLFROM
         AND UOMC_kg.SYMBOLTO = 'kg'











--WHERE 
----ActualShipDate > EffectiveShipDate
----    and 
----    salesid between 'SON0000900' and 'SON0000950'
--ORDER BY 
--    inventserialid,
--    SALESID, ITEMID, Delivered



/*

select count(1)
FROM CustPackingSlipTrans cpt

select count(1)
FROM CustPackingSlipJour cpj


*/











--WHERE 
----ActualShipDate > EffectiveShipDate
----    and 
----    salesid between 'SON0000900' and 'SON0000950'
--ORDER BY 
--    inventserialid,
--    SALESID, ITEMID, Delivered



/*

select count(1)
FROM CustPackingSlipTrans cpt

select count(1)
FROM CustPackingSlipJour cpj


*/