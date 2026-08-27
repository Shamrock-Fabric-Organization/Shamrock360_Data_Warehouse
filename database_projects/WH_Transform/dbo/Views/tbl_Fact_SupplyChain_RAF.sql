-- Auto Generated (Do not modify) 82A8CF7057E2B93EC396E139771C03279D746CCD2435BD2D3A3D40E60113AF37
CREATE  OR ALTER     VIEW [dbo].[tbl_Fact_SupplyChain_RAF] 
AS 
with workcenterdata as
(
SELECT DISTINCT pjr.dataareaid
    ,pjr.prodid
    ,pjr.oprnum
    ,pjr.oprpriority
    ,pjr.oprpriority_$label
    , pjr.wrkctrid
FROM WH_Raw.dbo.prodroutejob pjr
JOIN (
    SELECT dataareaid
        ,prodid
        ,oprpriority
        ,max(oprnum) moprnum
    FROM WH_Raw.dbo.prodroutejob
    WHERE oprpriority = 0
    GROUP BY dataareaid
        ,prodid
        ,oprpriority
    ) mpjr
    ON pjr.dataareaid = mpjr.dataareaid
        AND pjr.prodid = mpjr.prodid
        AND pjr.oprpriority = mpjr.oprpriority
        AND pjr.oprnum = mpjr.moprnum
)
, details_no_adjustments_no_sold as
(
SELECT it2.statusreceipt, it2.statusissue,it2.referencecategory,
id2.inventserialid,id2.inventsiteid, id2.inventlocationid, id2.inventbatchid,

    pjp.dataareaid CMPNY,
    pjp.ProdId,
    -- CO-PRODUCT FIX (v6): emit the journal LINE's item, not the order header's item.
    -- ProdTable holds one item per production order, so co-/by-product lines were being
    -- relabelled as the parent product. Falls back to pt.ItemId when the line carries no
    -- item, so primary-item rows are unchanged.
    case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end ItemId,
    pjp.JournalId,
    pjp.recid,
    --pjp.linenum,

    pjt.journalnameid,
    pjt.description,
    pjt.posteddatetime,
    convert(int, convert(char(8), pjt.posteddatetime, 112) ) PostedDateKey,
 --   pjp.qtygood,
    --it2.qty,
    coalesce(case when it2.qty = pjp.qtygood OR it2.qty is null then pjp.qtygood else it2.qty end, pjp.qtygood) QTYGood,
    pjp.qtyerror,
    pjp.transdate,
    convert(int, convert(char(8), pjp.transdate, 112) ) TransDateKey,
    pjp.voucher,

    pjp.prodfinished,
    pjp.prodfinished_$label,
    pjt.journaltype_$Label
    , w.wrkctrid

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
    , ISNULL(ds.SiteKey, -1) SiteKey
    , ISNULL(dw.WarehouseKey, -1) WarehouseKey
    , ISNULL(db.BatchKey, -1) BatchKey
    , ISNULL(dr.RouteKey, -1) RouteKey
    , ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey
    , ISNULL(dsn.SerialNumberKey, -1) SerialNumberKey

    --,'@@@@'
    --,pjp.*
FROM WH_Raw.dbo.ProdJournalProd pjp
JOIN WH_Raw.dbo.ProdJournalTable pjt
    ON pjp.dataareaid = pjt.dataareaid
      AND pjp.JournalId = pjt.JournalId
JOIN WH_Raw.dbo.ProdTable pt
    ON pjp.dataareaid = pt.dataareaid
      AND pjp.prodid = pt.prodid

LEFT JOIN WH_Raw.dbo.InventDim id
    ON pt.inventdimid = id.inventdimid
        AND pt.dataareaid = id.DataAreaId


--LEFT JOIN (WH_Raw.dbo.inventtransorigin ito

--        JOIN WH_Raw.dbo.inventtrans it
--          on ito.recid = it.inventtransorigin
--            and ito.dataareaid = it.dataareaid

--        JOIN WH_Raw.dbo.inventdim id2
--          on it.inventdimid = id2.inventdimid
--            and it.dataareaid = id2.dataareaid)
--    ON pjp.prodid = ito.referenceid
--      AND pjp.dataareaid = ito.dataareaid
--      AND pjp.voucher = it.voucherphysical
--      and it.statusreceipt = 1

LEFT JOIN ((select ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid, it.statusreceipt, it.statusissue,ito.referencecategory,sum(it.qty) qty
        from   WH_Raw.dbo.inventtransorigin ito

                JOIN WH_Raw.dbo.inventtrans it
                  on ito.recid = it.inventtransorigin
                    and ito.dataareaid = it.dataareaid
        ------where ((it.statusreceipt in (1,2) or it.statusissue = 1) and ito.referencecategory=2)
        ------    OR ((it.statusreceipt in (1,2) or it.statusissue = 1) and ito.referencecategory=100)
        where ((it.statusreceipt in (1,2) ) and ito.referencecategory=2)
            OR ((it.statusreceipt in (1,2) ) and ito.referencecategory=100)
        group by ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid,it.statusreceipt, it.statusissue,ito.referencecategory) it2
                JOIN WH_Raw.dbo.inventdim id2
                  on it2.inventdimid = id2.inventdimid
                    and it2.dataareaid = id2.dataareaid)
    ON pjp.prodid = it2.referenceid
      AND pjp.dataareaid = it2.dataareaid
      AND pjp.voucher = it2.voucherphysical
      -- CO-PRODUCT FIX (v6): match the line's own item. pt.itemid could never equal the
      -- itemid on a referencecategory = 100 (PmfProdCoBy) InventTrans row, which is why the
      -- referencecategory = 100 branch in the filter above has never matched anything.
      AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = it2.itemid


left JOIN workcenterdata w
    ON pjp.dataareaid = w.dataareaid
        AND pjp.prodid = w.prodid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
    ON pt.dataareaid = dw.CMPNY
        -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
        -- co-product lines take the warehouse from their own inventory transaction.
        AND case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
            then ID.inventlocationid else id2.inventlocationid end = dw.Warehouse_ID
        AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
    -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
    -- co-product lines take the site from their own inventory transaction.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventsiteid else id2.inventsiteid end = ds.Site_ID
        AND pt.dataareaid = ds.CMPNY
        AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
    -- CO-PRODUCT FIX (v6): a co-product is received into its OWN batch, which is carried on
    -- the matched inventory transaction (id2), not on the order header's dimensions (ID).
    -- The guard collapses to ID.inventbatchid for every primary-item line, so those are
    -- unchanged; only a line whose own item differs from the order's item reads id2.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventbatchid else id2.inventbatchid end = db.BatchID
        AND pt.dataareaid = db.CMPNY
        -- CO-PRODUCT FIX (v6): batch is item-scoped, so this must be the line's own item too.
        AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = db.ProductID
        AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
    ON pt.routeid = dr.RouteID
        AND pt.dataareaid = dr.CMPNY
        AND dr.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
    ON pjp.dataareaid = dle.CMPNY
        AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
    -- CO-PRODUCT FIX (v6): resolve ProductKey against the line's own item so ProductKey
    -- agrees with the ItemId now being emitted.
    ON case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = dp.Product_ID
        AND pjp.dataareaid = dp.CMPNY
        AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
    ON pjp.ProdId = dpbo.ProductionBatchOrder
        AND pjp.dataareaid = dpbo.CMPNY
        AND dpbo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
    ON w.wrkctrid = dwc.WorkCenterID
        AND w.dataareaid = dwc.CMPNY
        AND dwc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SerialNumber dsn
    ON id2.inventserialid = dsn.SerialNumber
        AND id2.dataareaid = dsn.CMPNY
        AND dsn.RecordStatus=1


WHERE
pjt.journaltype_$Label = 'ReportFinished'
-- POSTED FILTER (v6): restrict to POSTED journals only.
-- CONFIRMED 2026-08-25 against Shamrock production data. The mapping is 0 = No, 1 = Yes, so
-- "pjt.posted = 1" below is CORRECT AS WRITTEN. This is a settled fact, not an open question.
-- Evidence, WH_Raw.dbo.ProdJournalTable:
--     posted = 0  ->       166 journals, ALL 166 carrying the 1900-01-01 sentinel = NOT POSTED
--     posted = 1  ->   406,404 journals, ZERO sentinels                           = POSTED
-- Confirmed from the LIVE DATA rather than the AOT: the base NoYes enum is genuinely absent
-- from both AOT MCP knowledge bases, so the data was the only route -- and an empirical count
-- is the stronger evidence in any case.
-- WH_Raw does NOT pre-filter: both values are present, so this predicate does real work.
-- Expected impact is small -- 166 of 406,570 journals, ~0.04% at journal-header level (the
-- line-level figure will be at or above that). A small delta is the CORRECT outcome here, not
-- a sign the filter failed to apply.
-- Re-run this if the environment changes; the UNPOSTED value is the one carrying the sentinel:
--     SELECT posted, COUNT(*) AS journals,
--            SUM(CASE WHEN posteddatetime = '1900-01-01' THEN 1 ELSE 0 END) AS sentinel_dt
--     FROM WH_Raw.dbo.ProdJournalTable GROUP BY posted;
AND pjt.posted = 1
AND NOT(pjt.journalnameid like '%adj%')
and pjp.qtygood>=0
)

, details_no_adjustments_sold as
(
SELECT it2.statusreceipt, it2.statusissue,it2.referencecategory,
id2.inventserialid,id2.inventsiteid, id2.inventlocationid, id2.inventbatchid,

    pjp.dataareaid CMPNY,
    pjp.ProdId,
    -- CO-PRODUCT FIX (v6): emit the journal LINE's item, not the order header's item.
    -- ProdTable holds one item per production order, so co-/by-product lines were being
    -- relabelled as the parent product. Falls back to pt.ItemId when the line carries no
    -- item, so primary-item rows are unchanged.
    case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end ItemId,
    pjp.JournalId,
    pjp.recid,
    --pjp.linenum,

    pjt.journalnameid,
    pjt.description,
    pjt.posteddatetime,
     convert(int, convert(char(8), pjt.posteddatetime, 112) ) PostedDateKey,
--   pjp.qtygood,
    --it2.qty,
    coalesce(case when it2.qty = pjp.qtygood OR it2.qty is null then pjp.qtygood else it2.qty end, pjp.qtygood) QTYGood,
    pjp.qtyerror,
    pjp.transdate,
    convert(int, convert(char(8), pjp.transdate, 112) ) TransDateKey,
    pjp.voucher,

    pjp.prodfinished,
    pjp.prodfinished_$label,
    pjt.journaltype_$Label
    , w.wrkctrid

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
    , ISNULL(ds.SiteKey, -1) SiteKey
    , ISNULL(dw.WarehouseKey, -1) WarehouseKey
    , ISNULL(db.BatchKey, -1) BatchKey
    , ISNULL(dr.RouteKey, -1) RouteKey

    , ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey
    , ISNULL(dsn.SerialNumberKey, -1) SerialNumberKey


    --,'@@@@'
    --,pjp.*
FROM WH_Raw.dbo.ProdJournalProd pjp
JOIN WH_Raw.dbo.ProdJournalTable pjt
    ON pjp.dataareaid = pjt.dataareaid
      AND pjp.JournalId = pjt.JournalId
JOIN WH_Raw.dbo.ProdTable pt
    ON pjp.dataareaid = pt.dataareaid
      AND pjp.prodid = pt.prodid

LEFT JOIN WH_Raw.dbo.InventDim id
    ON pt.inventdimid = id.inventdimid
        AND pt.dataareaid = id.DataAreaId


LEFT JOIN ((select ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid, it.statusreceipt, it.statusissue,ito.referencecategory,sum(it.qty) qty
        from   WH_Raw.dbo.inventtransorigin ito

                JOIN WH_Raw.dbo.inventtrans it
                  on ito.recid = it.inventtransorigin
                    and ito.dataareaid = it.dataareaid
        where (( it.statusissue = 1) and ito.referencecategory=2)
            OR (( it.statusissue = 1) and ito.referencecategory=100)
        group by ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid,it.statusreceipt, it.statusissue,ito.referencecategory) it2
                JOIN WH_Raw.dbo.inventdim id2
                  on it2.inventdimid = id2.inventdimid
                    and it2.dataareaid = id2.dataareaid)
    ON pjp.prodid = it2.referenceid
      AND pjp.dataareaid = it2.dataareaid
      AND pjp.voucher = it2.voucherphysical
      -- CO-PRODUCT FIX (v6): match the line's own item. pt.itemid could never equal the
      -- itemid on a referencecategory = 100 (PmfProdCoBy) InventTrans row, which is why the
      -- referencecategory = 100 branch in the filter above has never matched anything.
      AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = it2.itemid


left JOIN workcenterdata w
    ON pjp.dataareaid = w.dataareaid
        AND pjp.prodid = w.prodid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
    ON pt.dataareaid = dw.CMPNY
        -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
        -- co-product lines take the warehouse from their own inventory transaction.
        AND case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
            then ID.inventlocationid else id2.inventlocationid end = dw.Warehouse_ID
        AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
    -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
    -- co-product lines take the site from their own inventory transaction.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventsiteid else id2.inventsiteid end = ds.Site_ID
        AND pt.dataareaid = ds.CMPNY
        AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
    -- CO-PRODUCT FIX (v6): a co-product is received into its OWN batch, which is carried on
    -- the matched inventory transaction (id2), not on the order header's dimensions (ID).
    -- The guard collapses to ID.inventbatchid for every primary-item line, so those are
    -- unchanged; only a line whose own item differs from the order's item reads id2.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventbatchid else id2.inventbatchid end = db.BatchID
        AND pt.dataareaid = db.CMPNY
        -- CO-PRODUCT FIX (v6): batch is item-scoped, so this must be the line's own item too.
        AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = db.ProductID
        AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
    ON pt.routeid = dr.RouteID
        AND pt.dataareaid = dr.CMPNY
        AND dr.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
    ON pjp.dataareaid = dle.CMPNY
        AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
    -- CO-PRODUCT FIX (v6): resolve ProductKey against the line's own item so ProductKey
    -- agrees with the ItemId now being emitted.
    ON case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = dp.Product_ID
        AND pjp.dataareaid = dp.CMPNY
        AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
    ON pjp.ProdId = dpbo.ProductionBatchOrder
        AND pjp.dataareaid = dpbo.CMPNY
        AND dpbo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
    ON w.wrkctrid = dwc.WorkCenterID
        AND w.dataareaid = dwc.CMPNY
        AND dwc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SerialNumber dsn
    ON id2.inventserialid = dsn.SerialNumber
        AND id2.dataareaid = dsn.CMPNY
        AND dsn.RecordStatus=1


WHERE
--pjt.prodid = 'PBO0000399'
--and
pjt.journaltype_$Label = 'ReportFinished'
-- POSTED FILTER (v6): restrict to POSTED journals only.
-- CONFIRMED 2026-08-25 against Shamrock production data. The mapping is 0 = No, 1 = Yes, so
-- "pjt.posted = 1" below is CORRECT AS WRITTEN. This is a settled fact, not an open question.
-- Evidence, WH_Raw.dbo.ProdJournalTable:
--     posted = 0  ->       166 journals, ALL 166 carrying the 1900-01-01 sentinel = NOT POSTED
--     posted = 1  ->   406,404 journals, ZERO sentinels                           = POSTED
-- Confirmed from the LIVE DATA rather than the AOT: the base NoYes enum is genuinely absent
-- from both AOT MCP knowledge bases, so the data was the only route -- and an empirical count
-- is the stronger evidence in any case.
-- WH_Raw does NOT pre-filter: both values are present, so this predicate does real work.
-- Expected impact is small -- 166 of 406,570 journals, ~0.04% at journal-header level (the
-- line-level figure will be at or above that). A small delta is the CORRECT outcome here, not
-- a sign the filter failed to apply.
-- Re-run this if the environment changes; the UNPOSTED value is the one carrying the sentinel:
--     SELECT posted, COUNT(*) AS journals,
--            SUM(CASE WHEN posteddatetime = '1900-01-01' THEN 1 ELSE 0 END) AS sentinel_dt
--     FROM WH_Raw.dbo.ProdJournalTable GROUP BY posted;
AND pjt.posted = 1
AND NOT(pjt.journalnameid like '%adj%')
and pjp.qtygood < 0
)

, details_only_adjustments as
(
SELECT it2.statusreceipt, it2.statusissue,it2.referencecategory,
id2.inventserialid,id2.inventsiteid, id2.inventlocationid, id2.inventbatchid,

    pjp.dataareaid CMPNY,
    pjp.ProdId,
    -- CO-PRODUCT FIX (v6): emit the journal LINE's item, not the order header's item.
    -- ProdTable holds one item per production order, so co-/by-product lines were being
    -- relabelled as the parent product. Falls back to pt.ItemId when the line carries no
    -- item, so primary-item rows are unchanged.
    case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end ItemId,
    pjp.JournalId,
    pjp.recid,
    --NULL linenum,  --pjp.linenum,

    pjt.journalnameid,
    pjt.description,
    pjt.posteddatetime,
     convert(int, convert(char(8), pjt.posteddatetime, 112) ) PostedDateKey,
 --   pjp.qtygood,
    --it2.qty,
    coalesce(case when it2.qty = pjp.qtygood OR it2.qty is null then pjp.qtygood else it2.qty end, pjp.qtygood) QTYGood,
    pjp.qtyerror,
    pjp.transdate,
     convert(int, convert(char(8), pjp.transdate, 112) ) TransDateKey,
    pjp.voucher,

    pjp.prodfinished,
    pjp.prodfinished_$label,
    pjt.journaltype_$Label
    , w.wrkctrid

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dp.ProductKey, -1) ProductKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
    , ISNULL(ds.SiteKey, -1) SiteKey
    , ISNULL(dw.WarehouseKey, -1) WarehouseKey
    , ISNULL(db.BatchKey, -1) BatchKey
    , ISNULL(dr.RouteKey, -1) RouteKey

    , ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey
    , ISNULL(dsn.SerialNumberKey, -1) SerialNumberKey


    --,'@@@@'
    --,pjp.*
FROM WH_Raw.dbo.ProdJournalProd pjp
JOIN WH_Raw.dbo.ProdJournalTable pjt
    ON pjp.dataareaid = pjt.dataareaid
      AND pjp.JournalId = pjt.JournalId
JOIN WH_Raw.dbo.ProdTable pt
    ON pjp.dataareaid = pt.dataareaid
      AND pjp.prodid = pt.prodid

LEFT JOIN WH_Raw.dbo.InventDim id
    ON pt.inventdimid = id.inventdimid
        AND pt.dataareaid = id.DataAreaId


LEFT JOIN ((select ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid, it.statusreceipt, it.statusissue,ito.referencecategory,sum(it.qty) qty
        from   WH_Raw.dbo.inventtransorigin ito

                JOIN WH_Raw.dbo.inventtrans it
                  on ito.recid = it.inventtransorigin
                    and ito.dataareaid = it.dataareaid
        where ((it.statusreceipt in (1,2) or it.statusissue = 1) and ito.referencecategory=2)
            OR ((it.statusreceipt in (1,2) or it.statusissue = 1) and ito.referencecategory=100)
        group by ito.dataareaid, ito.referenceid, it.voucherphysical, it.inventdimid, it.itemid,it.statusreceipt, it.statusissue,ito.referencecategory) it2
                JOIN WH_Raw.dbo.inventdim id2
                  on it2.inventdimid = id2.inventdimid
                    and it2.dataareaid = id2.dataareaid)
    ON pjp.prodid = it2.referenceid
      AND pjp.dataareaid = it2.dataareaid
      AND pjp.voucher = it2.voucherphysical
      -- CO-PRODUCT FIX (v6): match the line's own item. pt.itemid could never equal the
      -- itemid on a referencecategory = 100 (PmfProdCoBy) InventTrans row, which is why the
      -- referencecategory = 100 branch in the filter above has never matched anything.
      AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = it2.itemid


left JOIN workcenterdata w
    ON pjp.dataareaid = w.dataareaid
        AND pjp.prodid = w.prodid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
    ON pt.dataareaid = dw.CMPNY
        -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
        -- co-product lines take the warehouse from their own inventory transaction.
        AND case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
            then ID.inventlocationid else id2.inventlocationid end = dw.Warehouse_ID
        AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
    -- CO-PRODUCT FIX (v6): same guard as tbl_DIM_Batch -- primary lines keep ID,
    -- co-product lines take the site from their own inventory transaction.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventsiteid else id2.inventsiteid end = ds.Site_ID
        AND pt.dataareaid = ds.CMPNY
        AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
    -- CO-PRODUCT FIX (v6): a co-product is received into its OWN batch, which is carried on
    -- the matched inventory transaction (id2), not on the order header's dimensions (ID).
    -- The guard collapses to ID.inventbatchid for every primary-item line, so those are
    -- unchanged; only a line whose own item differs from the order's item reads id2.
    ON case when pjp.itemid is null or pjp.itemid = '' or pjp.itemid = pt.itemid
       then ID.inventbatchid else id2.inventbatchid end = db.BatchID
        AND pt.dataareaid = db.CMPNY
        -- CO-PRODUCT FIX (v6): batch is item-scoped, so this must be the line's own item too.
        AND case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = db.ProductID
        AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
    ON pt.routeid = dr.RouteID
        AND pt.dataareaid = dr.CMPNY
        AND dr.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
    ON pjp.dataareaid = dle.CMPNY
        AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
    -- CO-PRODUCT FIX (v6): resolve ProductKey against the line's own item so ProductKey
    -- agrees with the ItemId now being emitted.
    ON case when pjp.itemid is null or pjp.itemid = '' then pt.itemid else pjp.itemid end = dp.Product_ID
        AND pjp.dataareaid = dp.CMPNY
        AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
    ON pjp.ProdId = dpbo.ProductionBatchOrder
        AND pjp.dataareaid = dpbo.CMPNY
        AND dpbo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
    ON w.wrkctrid = dwc.WorkCenterID
        AND w.dataareaid = dwc.CMPNY
        AND dwc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SerialNumber dsn
    ON id2.inventserialid = dsn.SerialNumber
        AND id2.dataareaid = dsn.CMPNY
        AND dsn.RecordStatus=1


WHERE
pjt.journaltype_$Label = 'ReportFinished'
-- POSTED FILTER (v6): restrict to POSTED journals only.
-- CONFIRMED 2026-08-25 against Shamrock production data. The mapping is 0 = No, 1 = Yes, so
-- "pjt.posted = 1" below is CORRECT AS WRITTEN. This is a settled fact, not an open question.
-- Evidence, WH_Raw.dbo.ProdJournalTable:
--     posted = 0  ->       166 journals, ALL 166 carrying the 1900-01-01 sentinel = NOT POSTED
--     posted = 1  ->   406,404 journals, ZERO sentinels                           = POSTED
-- Confirmed from the LIVE DATA rather than the AOT: the base NoYes enum is genuinely absent
-- from both AOT MCP knowledge bases, so the data was the only route -- and an empirical count
-- is the stronger evidence in any case.
-- WH_Raw does NOT pre-filter: both values are present, so this predicate does real work.
-- Expected impact is small -- 166 of 406,570 journals, ~0.04% at journal-header level (the
-- line-level figure will be at or above that). A small delta is the CORRECT outcome here, not
-- a sign the filter failed to apply.
-- Re-run this if the environment changes; the UNPOSTED value is the one carrying the sentinel:
--     SELECT posted, COUNT(*) AS journals,
--            SUM(CASE WHEN posteddatetime = '1900-01-01' THEN 1 ELSE 0 END) AS sentinel_dt
--     FROM WH_Raw.dbo.ProdJournalTable GROUP BY posted;
AND pjt.posted = 1
AND (pjt.journalnameid like '%adj%')
)
, details as
(
select distinct 9 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from details_no_adjustments_no_sold
union all
select distinct 2 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from details_no_adjustments_sold
where NOT(prodid+'='+isnull(inventserialid,'zzxxzz') in ('PBO0000682=SN000008916') )
union all
select qry,statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from
    (select distinct 8 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,recid,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
    from details_no_adjustments_sold
    where prodid+'='+isnull(inventserialid,'zzxxzz') in ('PBO0000682=SN000008916')
       and recid in (5637163024, 5637163025)
    ) z
union all
select  3 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from details_only_adjustments
where prodid in ('PBO0000228')
union all
select  distinct 4 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from details_only_adjustments
where NOT(prodid in ('PBO0000228','PBO0002699','PBO0006190'))
union all
select qry,statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
from
    (select  distinct 7 qry, statusreceipt,statusissue,referencecategory,inventserialid,inventsiteid,inventlocationid,inventbatchid,CMPNY,ProdId,ItemId,JournalId,recid,journalnameid,description,posteddatetime,PostedDateKey,QTYgood,qtyerror,transdate,TransDateKey,voucher,prodfinished,prodfinished_$label,journaltype_$Label,wrkctrid,Legal_EntityKey,ProductKey,ProductionBatchOrderKey,SiteKey,WarehouseKey,BatchKey,RouteKey,WorkCenterKey,SerialNumberKey
    from details_only_adjustments
    where prodid in ('PBO0002699','PBO0006190')
    ) y
)

SELECT
    d.CMPNY
    , d.ProdId
    , d.ItemId
    , d.JournalId
    , d.journalnameid
    , d.description
    , d.posteddatetime
    , d.PostedDateKey
    , d.QTYGood
    , d.qtyerror
    , d.transdate
    , d.TransDateKey
    , d.voucher
    , d.prodfinished
    , d.prodfinished_$label
    , d.journaltype_$Label
    , d.wrkctrid

    , d.inventsiteid
    , d.inventlocationid
    , d.inventbatchid
    , d.inventserialid

    , d.Legal_EntityKey
    , d.ProductKey
    , d.ProductionBatchOrderKey
    , d.SiteKey
    , d.WarehouseKey
    , d.BatchKey
    , d.RouteKey
    , d.WorkCenterKey
    , d.SerialNumberKey
    , COALESCE(qrank1.testresultvalueoutcome,qrank2.testresultvalueoutcome) QRankTestResult
    , COALESCE(qrank1.QuaityOrderStatus,qrank2.QuaityOrderStatus) QuaityOrderStatus
FROM details d
LEFT JOIN (
        SELECT
              CMPNY
              , inventrefid
              , ISNULL(inventserialid, '') inventserialid
              , testid
              , QuaityOrderStatus
              , MIN(testresultvalueoutcome) testresultvalueoutcome
          FROM (
              SELECT *
                  , ROW_NUMBER() OVER (
                      PARTITION BY CMPNY, inventrefid, ISNULL(inventserialid, ''), testid
                      ORDER BY LineCreatedDateTime DESC
                    ) AS rn
              FROM [dbo].[tbl_Fact_QualityOrderLineResults]
              WHERE testid = 'Q Rank'
          ) ranked
          WHERE rn = 1
          GROUP BY CMPNY
              , inventrefid
              , ISNULL(inventserialid, '')
              , testid
              , QuaityOrderStatus
        ) qrank1
  ON d.CMPNY = qrank1.CMPNY
    AND d.ProdId = qrank1.inventrefid
    AND isnull(d.inventserialid, '') = isnull(qrank1.inventserialid, '')
LEFT JOIN (
        SELECT
              CMPNY
              , inventrefid
              , ISNULL(inventserialid, '') inventserialid
              , testid
              , QuaityOrderStatus
              , MIN(testresultvalueoutcome) testresultvalueoutcome
          FROM (
              SELECT *
                  , ROW_NUMBER() OVER (
                      PARTITION BY CMPNY, inventrefid, ISNULL(inventserialid, ''), testid
                      ORDER BY LineCreatedDateTime DESC
                    ) AS rn
              FROM [dbo].[tbl_Fact_QualityOrderLineResults]
              WHERE testid = 'Q Rank'
              and inventserialid is null
          ) ranked
          WHERE rn = 1
          GROUP BY CMPNY
              , inventrefid
              , ISNULL(inventserialid, '')
              , testid
              , QuaityOrderStatus
        ) qrank2
  ON d.CMPNY = qrank2.CMPNY
    AND d.ProdId = qrank2.inventrefid