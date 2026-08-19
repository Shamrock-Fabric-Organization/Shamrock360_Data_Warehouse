
CREATE OR ALTER VIEW [dbo].[tbl_Fact_ProductionBatchOrderVariance]
AS
WITH ord AS (
    -- Order + PRIMARY finished good (the Production line at the order's collect level)
    SELECT
          pt.[dataareaid]         AS DataAreaId
        , pt.[prodid]             AS ProdId
        , pt.[itemid]             AS FinItem
        , fg.[costgroupid]        AS FinCostGroup
        , pt.[realdate]           AS RealDate
        , pt.[collectreflevel]    AS CollectRefLevel
        , pt.[collectrefprodid]   AS CollectRefProdId
        , pt.[prodstatus_$label]  AS ProdStatus
        , fg.[realqty]            AS ActQty
    FROM WH_Raw.dbo.prodtable AS pt
    INNER JOIN WH_Raw.dbo.prodcalctrans AS fg
        ON  fg.[dataareaid]          = pt.[dataareaid]
        AND fg.[transrefid]          = pt.[prodid]
        AND fg.[collectrefprodid]    = pt.[collectrefprodid]
        AND fg.[collectreflevel]     = pt.[collectreflevel]
        AND fg.[transreftype_$label] = 'Production'
        AND fg.[calctype_$label]     = 'Production'
        AND fg.[resource]            = pt.[itemid]
    WHERE pt.[prodstatus_$label] = 'Completed'
),
price_receipt AS (
    -- getFinancialIssueOrReceiptPriceForProductionOrder (AxTable_InventCostTrans L1474-1502).
    -- For a Completed order the engine prices the estimate from the InventItemPrice STAMPED
    -- on the finished good's FINANCIAL Issue/Receipt cost transaction posted on the production
    -- END date. Transcribed VERBATIM from the X++ `select firstonly inventItemPrice ... exists
    -- join inventCostTrans`:
    --   inventCostTrans.CostTransState   == Financial            (ONLY -- Physical excluded)
    --   inventCostTrans.CostTransRefType == Production
    --   inventCostTrans.CostTransType    IN (Issue, Receipt)
    --   inventCostTrans.TransDate        == prodTable.RealDate   (EXACT date; lake datetime2 -> DATE)
    --   join InventItemPrice on RecId == inventCostTrans.ItemPriceRefRecId
    --   pick: order by InventItemPrice ActivationDate desc, CreatedDateTime desc (recid = proxy)
    -- NO pricecalcid filter: a BLANK pricecalcid is a valid MANUAL standard cost and MUST be
    -- carried so it routes to the manual-price branch (initEstimate L588 finds no BOMCalcTable
    -- -> loadEstimate else-branch L806), exactly as the engine does.
    -- ENGINE InventTransId match (prodCalcTrans.inventTransId()) approximated by
    -- transrefid=prodid + itemid: one finished-good lot per production order, so this isolates
    -- the same cost trans. FinancialInventDimId exists-join omitted -- empirically inert for
    -- Shamrock 
    SELECT
          o.DataAreaId, o.ProdId,
          ict.[itempricerefrecid] AS ItemPriceRecId,
          ROW_NUMBER() OVER (
              PARTITION BY o.DataAreaId, o.ProdId
              ORDER BY iip.[activationdate] DESC, iip.[recid] DESC) AS rn
    FROM ord AS o
    INNER JOIN WH_Raw.dbo.inventcosttrans AS ict
        ON  ict.[dataareaid]              = o.DataAreaId
        AND ict.[transrefid]              = o.ProdId
        AND ict.[itemid]                  = o.FinItem
        AND ict.[costtransstate_$label]   = 'Financial'
        AND ict.[costtransreftype_$label] = 'Production'
        AND ict.[costtranstype_$label]    IN ('Issue','Receipt')
        AND CAST(ict.[transdate] AS DATE) = CAST(o.RealDate AS DATE)
        AND ISNULL(ict.[itempricerefrecid], 0) <> 0
    INNER JOIN WH_Raw.dbo.inventitemprice AS iip
        ON  iip.[recid] = ict.[itempricerefrecid]
),
price_date AS (
    -- FALLBACK = InventItemPrice::stdCostFindDate -> findCurrent(ItemId, Cost, dim, RealDate,
    -- Standard) (AxTable_InventItemPrice L561-618): the active standard-cost version as of
    -- RealDate. Fires ONLY when NO financial Issue/Receipt price exists for the order (engine
    -- `if (!currentInventItemPrice)`, calc L246). No pricecalcid filter (blank -> manual branch).
    SELECT
          o.DataAreaId, o.ProdId,
          iip.[recid] AS ItemPriceRecId,
          ROW_NUMBER() OVER (
              PARTITION BY o.DataAreaId, o.ProdId
              ORDER BY iip.[activationdate] DESC, iip.[recid] DESC) AS rn
    FROM ord AS o
    INNER JOIN WH_Raw.dbo.inventitemprice AS iip
        ON  iip.[dataareaid]         = o.DataAreaId
        AND iip.[itemid]             = o.FinItem
        AND iip.[pricetype_$label]   = 'Cost'
        AND iip.[costingtype_$label] = 'Standard'
        AND iip.[activationdate]     <= o.RealDate
),
chosen_price AS (
    -- Engine calc() L235-251: the receipt-stamped price if the Completed order has one, else
    -- the date fallback. Resolve the winning InventItemPrice's PriceCalcId + pcsPrice.
    -- pcsPrice = price / priceUnit (AxTable_InventItemPrice.pcsPrice L194 -> InventPriceMap;)
    -- PriceCalcId drives the roll-up-vs-manual split downstream:
    -- initEstimate L588 BOMCalcTable::find(PriceCalcId); loadEstimate L721 `if (bomCalcTable)`
    -- roll-up ELSE L806 manual synthetic Production estimate. One row per Completed order.
    SELECT
          o.DataAreaId, o.ProdId, o.FinItem, o.FinCostGroup, o.RealDate, o.CollectRefLevel,
          o.CollectRefProdId, o.ProdStatus, o.ActQty,
          COALESCE(pr.ItemPriceRecId, pd.ItemPriceRecId) AS ItemPriceRecId,
          iip.[pricecalcid] AS PriceCalcId,
          CAST(iip.[price] / CASE WHEN ISNULL(iip.[priceunit],0) = 0 THEN 1 ELSE iip.[priceunit] END
               AS DECIMAL(38,16)) AS PcsPrice
    FROM ord AS o
    LEFT JOIN price_receipt AS pr
        ON pr.DataAreaId = o.DataAreaId AND pr.ProdId = o.ProdId AND pr.rn = 1
    LEFT JOIN price_date AS pd
        ON pd.DataAreaId = o.DataAreaId AND pd.ProdId = o.ProdId AND pd.rn = 1
    LEFT JOIN WH_Raw.dbo.inventitemprice AS iip
        ON iip.[recid] = COALESCE(pr.ItemPriceRecId, pd.ItemPriceRecId)
),
ord_price AS (
    -- ROLL-UP path (loadEstimate L721 `if (bomCalcTable)`): the chosen price's PriceCalcId
    -- resolves to a BOMCalcTable. INNER JOIN drops blank/manual-price orders, which then
    -- fall to the mp_roster branch (NOT EXISTS ord_price). Attach estQty + scaling factor.
    SELECT
          p.DataAreaId, p.ProdId, p.FinItem, p.RealDate, p.CollectRefLevel,
          p.CollectRefProdId, p.ProdStatus, p.ActQty, p.PriceCalcId,
          bct.[qty] AS EstQty,
          CASE WHEN bct.[qty] <> 0
               THEN CAST(p.ActQty AS DECIMAL(38,16)) / CAST(bct.[qty] AS DECIMAL(38,16))
               ELSE 0 END AS Factor
    FROM chosen_price AS p
    INNER JOIN WH_Raw.dbo.bomcalctable AS bct
        ON  bct.[dataareaid]  = p.DataAreaId
        AND bct.[pricecalcid] = p.PriceCalcId
    WHERE p.PriceCalcId IS NOT NULL AND p.PriceCalcId <> ''
),
est_key AS (
    -- ESTIMATE lines (standard-cost roll-up) with the AX allowed/lot-size math.
    -- MULTI-LEVEL (#2): pulls level-1 direct components PLUS the level>=2 bom=No
    -- CostGroup explosion of any level-1 bom=Yes sub-assembly, mirroring the ACTUAL
    -- side (act_key) exactly. SrcLevel = bomcalctrans.[level] capped at 2, so the
    -- level>=2 detail enters MULTI only ((SrcLevel=1 AND Split=No) OR SrcLevel=2);
    -- the level-1 bom=Yes lump (Split=Yes) is dropped in Multi and swapped for its
    -- CostGroup detail, which nets 1:1 against the actual L2 by identical BucketKey.
    -- Single/Total (SrcLevel=1) are untouched. The L2 CostGroup StdCost sums exactly
    -- to the L1 BOM lump StdCost, so the swap preserves the total standard (no double-count).
    -- DisplayKey = the grid grain; WrkCtrType is carried for the Process COMPUTE key.
    SELECT
          op.DataAreaId
        , op.ProdId
        , CAST(CASE WHEN b.[level] >= 2 THEN 2 ELSE b.[level] END AS INT) AS SrcLevel
        , b.[bom_$label]         AS Split
        , wc.[wrkctrtype_$label] AS WrkCtrType
        , CASE
            WHEN b.[calctype_$label] IN ('Item','Service','BOM','Burden')
                THEN CONCAT('M|', ISNULL(b.[costgroupid],''), '|', b.[calctype_$label], '|',
                            ISNULL(b.[resource],''), '|', CAST(ISNULL(b.[oprnum],0) AS VARCHAR(20)), '|',
                            ISNULL(b.[bom_$label],''))
            WHEN b.[calctype_$label] IN ('Process','Setup','Qty')
                THEN CONCAT('P|', ISNULL(b.[costgroupid],''), '|', b.[calctype_$label], '|',
                            ISNULL(b.[oprid],''), '|', CAST(ISNULL(b.[oprnum],0) AS VARCHAR(20)))
            WHEN b.[calctype_$label] IN ('IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                         'IndirectOutUnitBased','IndirectPurchUnitBased')
                THEN CONCAT('I|', ISNULL(b.[costgroupid],''), '|', b.[calctype_$label], '|',
                            ISNULL(b.[resource],''))
            WHEN b.[calctype_$label] = 'CostGroup'
                THEN CONCAT('C|', ISNULL(b.[costgroupid],''), '|', b.[calctype_$label], '|',
                            ISNULL(b.[resource],''))
            ELSE CONCAT('X|', ISNULL(b.[costgroupid],''), '|', b.[calctype_$label], '|',
                        ISNULL(b.[resource],''), '|', ISNULL(b.[oprid],''), '|',
                        CAST(ISNULL(b.[oprnum],0) AS VARCHAR(20)))
          END AS DisplayKey
        , b.[calctype_$label] AS CalcType
        , b.[costgroupid]     AS CostGroupId
        , CASE WHEN b.[calctype_$label] IN ('Process','Setup','Qty')
               THEN b.[oprid] ELSE b.[resource] END AS ResourceDisplay
        , b.[oprnum]          AS OprNum
        , CAST(b.[consumptionconstant] + op.Factor * b.[consumptionvariable] AS DECIMAL(38,16)) AS StdQty
        , CAST(b.[costmarkupqty] + CAST(op.ActQty AS DECIMAL(38,16)) * b.[costpriceqty] AS DECIMAL(38,16)) AS StdCost
        , CAST(b.[costmarkupqty] * (1 - op.Factor) AS DECIMAL(38,16)) AS LotSizeVariance
    FROM ord_price AS op
    INNER JOIN WH_Raw.dbo.bomcalctrans AS b
        ON  b.[dataareaid]  = op.DataAreaId
        AND b.[pricecalcid] = op.PriceCalcId
        AND (b.[level] = 1 OR b.[bom_$label] = 'No')   -- #2: L1 direct + deeper bom=No CostGroup detail (mirrors act_key grain)
        AND b.[calctype_$label] IN ('Item','Service','BOM','Burden','Process','Setup','Qty',
                                    'IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                    'IndirectOutUnitBased','IndirectPurchUnitBased','CostGroup')
    LEFT JOIN WH_Raw.dbo.wrkctrtable AS wc
        ON  wc.[dataareaid] = op.DataAreaId
        AND wc.[wrkctrid]   = b.[resource]
),
est_raw AS (
    -- COMPUTE key = DisplayKey plus WrkCtrType for Process/Setup/Qty
    -- (findOrCreateVarianceTrans lines 475/482: bucket keys on the resource's WrkCtrType).
    SELECT
          DataAreaId, ProdId, SrcLevel, Split, DisplayKey
        , CONCAT(CAST(SrcLevel AS VARCHAR(2)), '|', ISNULL(Split,''), '|', DisplayKey,
                 CASE WHEN CalcType IN ('Process','Setup','Qty')
                      THEN CONCAT('|', ISNULL(WrkCtrType,'')) ELSE '' END) AS BucketKey
        , CalcType, CostGroupId, ResourceDisplay, OprNum, StdQty, StdCost, LotSizeVariance
    FROM est_key
),
est AS (
    SELECT
          DataAreaId, ProdId, BucketKey
        , MAX(SrcLevel)        AS SrcLevel
        , MAX(Split)           AS Split
        , MAX(DisplayKey)      AS DisplayKey
        , MAX(CalcType)        AS CalcType
        , MAX(CostGroupId)     AS CostGroupId
        , MAX(ResourceDisplay) AS ResourceDisplay
        , MAX(OprNum)          AS OprNum
        , SUM(StdQty)          AS StdQty
        , SUM(StdCost)         AS StdCost
        , SUM(LotSizeVariance) AS LotSizeVariance
    FROM est_raw
    GROUP BY DataAreaId, ProdId, BucketKey
),
act_key AS (
    -- ACTUAL consumption/cost at CollectRefLevel + 1. WrkCtrType carried for the Process COMPUTE key.
    SELECT
          op.DataAreaId
        , op.ProdId
        , CASE WHEN (p.[collectreflevel] - op.CollectRefLevel) >= 2 THEN 2
               ELSE (p.[collectreflevel] - op.CollectRefLevel) END AS SrcLevel
        , p.[bom_$label]         AS Split
        , wc.[wrkctrtype_$label] AS WrkCtrType
        , CASE
            WHEN p.[calctype_$label] IN ('Item','Service','BOM','Burden')
                THEN CONCAT('M|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)), '|',
                            ISNULL(p.[bom_$label],''))
            WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
                THEN CONCAT('P|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[oprid],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
            WHEN p.[calctype_$label] IN ('IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                         'IndirectOutUnitBased','IndirectPurchUnitBased')
                THEN CONCAT('I|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            WHEN p.[calctype_$label] = 'CostGroup'
                THEN CONCAT('C|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            ELSE CONCAT('X|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                        ISNULL(p.[resource],''), '|', ISNULL(p.[oprid],''), '|',
                        CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
          END AS DisplayKey
        , p.[calctype_$label] AS CalcType
        , p.[costgroupid]     AS CostGroupId
        , CASE WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
               THEN p.[oprid] ELSE p.[resource] END AS ResourceDisplay
        , p.[oprnum]              AS OprNum
        , p.[realconsump]         AS RealConsump
        , p.[realcostamount]      AS RealCostAmount
        , p.[realcostadjustment]  AS RealCostAdjustment
    FROM ord_price AS op
    INNER JOIN WH_Raw.dbo.prodcalctrans AS p
        ON  p.[dataareaid]          = op.DataAreaId
        AND p.[transrefid]          = op.ProdId
        AND p.[collectrefprodid]    = op.CollectRefProdId
        AND p.[transreftype_$label] = 'Production'
        AND (p.[collectreflevel] = op.CollectRefLevel + 1 OR p.[bom_$label] = 'No')
        AND p.[calctype_$label] IN ('Item','Service','BOM','Burden','Process','Setup','Qty',
                                    'IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                    'IndirectOutUnitBased','IndirectPurchUnitBased','CostGroup')
    LEFT JOIN WH_Raw.dbo.wrkctrtable AS wc
        ON  wc.[dataareaid] = op.DataAreaId
        AND wc.[wrkctrid]   = p.[resource]
),
act_raw AS (
    SELECT
          DataAreaId, ProdId, SrcLevel, Split, DisplayKey
        , CONCAT(CAST(SrcLevel AS VARCHAR(2)), '|', ISNULL(Split,''), '|', DisplayKey,
                 CASE WHEN CalcType IN ('Process','Setup','Qty')
                      THEN CONCAT('|', ISNULL(WrkCtrType,'')) ELSE '' END) AS BucketKey
        , CalcType, CostGroupId, ResourceDisplay, OprNum
        , RealConsump, RealCostAmount, RealCostAdjustment
    FROM act_key
),
act AS (
    SELECT
          DataAreaId, ProdId, BucketKey
        , MAX(SrcLevel)            AS SrcLevel
        , MAX(Split)               AS Split
        , MAX(DisplayKey)          AS DisplayKey
        , MAX(CalcType)            AS CalcType
        , MAX(CostGroupId)         AS CostGroupId
        , MAX(ResourceDisplay)     AS ResourceDisplay
        , MAX(OprNum)              AS OprNum
        , SUM(RealConsump)         AS RealConsump
        , SUM(RealCostAmount)      AS RealCostAmount
        , SUM(RealCostAdjustment)  AS RealCostAdjustment
    FROM act_raw
    GROUP BY DataAreaId, ProdId, BucketKey
),
-- =====================================================================
-- CO-PRODUCT BRANCH (Is_CoProduct=1). Reuses the SAME bucket keys/formulas
-- as the primary; only the ACTUAL source (pmfcobyprodcalctrans) and the
-- ESTIMATE (one synthetic manual-price line) differ. See header OUTPUTS.
-- =====================================================================
coby_roster AS (
    -- Co-product outputs of the order (PmfProdCoBy), genuine co-products only.
    SELECT
          o.DataAreaId, o.ProdId, o.CollectRefProdId, o.CollectRefLevel
        , pc.[recid]    AS CobyRecId
        , pc.[itemid]   AS OutputItem
        , pc.[realdate] AS RealDate
    FROM ord AS o
    INNER JOIN WH_Raw.dbo.pmfprodcoby AS pc
        ON  pc.[dataareaid]         = o.DataAreaId
        AND pc.[prodid]             = o.ProdId
        AND pc.[producttype_$label] = 'Co_Product'
),
coby_head AS (
    -- Reported finished good (qty basis) + item cost group, from the co-product's
    -- level-0 Production roll-up row (buildFinishedItemQuery L89-103).
    SELECT
          r.DataAreaId, r.ProdId, r.CollectRefProdId, r.CollectRefLevel,
          r.CobyRecId, r.OutputItem, r.RealDate,
          SUM(fg.[realqty])     AS CobyRealQty,
          MAX(fg.[costgroupid]) AS CobyCostGroup
    FROM coby_roster AS r
    INNER JOIN WH_Raw.dbo.pmfcobyprodcalctrans AS fg
        ON  fg.[dataareaid]          = r.DataAreaId
        AND fg.[transrefid]          = r.ProdId
        AND fg.[collectrefprodid]    = r.CollectRefProdId
        AND fg.[transreftype_$label] = 'Production'
        AND fg.[pmfidrefcobyrecid]   = r.CobyRecId
        AND fg.[collectreflevel]     = r.CollectRefLevel
        AND fg.[calctype_$label]     = 'Production'
    GROUP BY r.DataAreaId, r.ProdId, r.CollectRefProdId, r.CollectRefLevel,
             r.CobyRecId, r.OutputItem, r.RealDate
),
coby_price AS (
    -- Active standard cost pcsPrice = price / priceUnit for the co-product item.
    SELECT
          h.DataAreaId, h.ProdId, h.CobyRecId, h.OutputItem, h.CobyRealQty, h.CobyCostGroup,
          CAST(iip.[price] / CASE WHEN ISNULL(iip.[priceunit],0) = 0 THEN 1 ELSE iip.[priceunit] END
               AS DECIMAL(38,16)) AS PcsPrice,
          ROW_NUMBER() OVER (
              PARTITION BY h.DataAreaId, h.ProdId, h.CobyRecId
              ORDER BY iip.[activationdate] DESC, iip.[recid] DESC) AS rn
    FROM coby_head AS h
    INNER JOIN WH_Raw.dbo.inventitemprice AS iip
        ON  iip.[dataareaid]         = h.DataAreaId
        AND iip.[itemid]             = h.OutputItem
        AND iip.[pricetype_$label]   = 'Cost'
        AND iip.[costingtype_$label] = 'Standard'
        AND iip.[activationdate]     <= h.RealDate
        AND iip.[price]              <> 0
),
est_coby_raw AS (
    -- ONE synthetic estimate line per co-product PER CobyRecId: CalcType=Production,
    -- StdCost = qty*pcsPrice, StdQty=0, LotSize=0 (est-only -> all Substitution).
    -- Same bucket/display key shape as est.
    SELECT
          p.DataAreaId
        , p.ProdId
        , CONCAT('1|No|X|', ISNULL(p.CobyCostGroup,''), '|Production|', ISNULL(p.OutputItem,''), '||0') AS BucketKey
        , CAST(1 AS INT)            AS SrcLevel
        , CAST('No' AS VARCHAR(10)) AS Split
        , CONCAT('X|', ISNULL(p.CobyCostGroup,''), '|Production|', ISNULL(p.OutputItem,''), '||0')      AS DisplayKey
        , CAST('Production' AS VARCHAR(50)) AS CalcType
        , p.CobyCostGroup           AS CostGroupId
        , p.OutputItem              AS ResourceDisplay
        , CAST(0 AS BIGINT)         AS OprNum
        , CAST(0 AS DECIMAL(38,16)) AS StdQty
        , CAST(p.CobyRealQty * p.PcsPrice AS DECIMAL(38,16)) AS StdCost
        , CAST(0 AS DECIMAL(38,16)) AS LotSizeVariance
        , p.OutputItem              AS OutputItem
        , CAST(1 AS INT)            AS IsCoProduct
    FROM coby_price AS p
    WHERE p.rn = 1
),
est_coby AS (
    -- FAN-OUT GUARD: collapse to (DataAreaId, ProdId, OutputItem, BucketKey) grain, 
    -- MIRRORING act_coby, so an order that lists the SAME co-product item under >1 
    -- PmfProdCoBy RecId (same itemid+costgroup -> identical BucketKey) does NOT fan out. 
    -- Without this, the 2 per-RecId estimate rows both match the 1 merged act_coby row 
    -- in the FULL OUTER JOIN and DOUBLE realized cost. StdCost sums across RecIds = 
    -- total co-product standard (StdQty/LotSize are 0 on every co-product estimate row, 
    -- so summing them is a no-op). No-op on single-RecId orders.
    SELECT
          DataAreaId, ProdId, OutputItem, BucketKey
        , MAX(SrcLevel)        AS SrcLevel
        , MAX(Split)           AS Split
        , MAX(DisplayKey)      AS DisplayKey
        , MAX(CalcType)        AS CalcType
        , MAX(CostGroupId)     AS CostGroupId
        , MAX(ResourceDisplay) AS ResourceDisplay
        , MAX(OprNum)          AS OprNum
        , SUM(StdQty)          AS StdQty
        , SUM(StdCost)         AS StdCost
        , SUM(LotSizeVariance) AS LotSizeVariance
        , MAX(IsCoProduct)     AS IsCoProduct
    FROM est_coby_raw
    GROUP BY DataAreaId, ProdId, OutputItem, BucketKey
),
act_key_coby AS (
    -- Co-product ACTUAL details from PmfCoByProdCalcTrans (buildActualQuery L54-87).
    SELECT
          r.DataAreaId
        , r.ProdId
        , r.OutputItem
        , CASE WHEN (p.[collectreflevel] - r.CollectRefLevel) >= 2 THEN 2
               ELSE (p.[collectreflevel] - r.CollectRefLevel) END AS SrcLevel
        , p.[bom_$label]         AS Split
        , wc.[wrkctrtype_$label] AS WrkCtrType
        , CASE
            WHEN p.[calctype_$label] IN ('Item','Service','BOM','Burden')
                THEN CONCAT('M|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)), '|',
                            ISNULL(p.[bom_$label],''))
            WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
                THEN CONCAT('P|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[oprid],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
            WHEN p.[calctype_$label] IN ('IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                         'IndirectOutUnitBased','IndirectPurchUnitBased')
                THEN CONCAT('I|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            WHEN p.[calctype_$label] = 'CostGroup'
                THEN CONCAT('C|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            ELSE CONCAT('X|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                        ISNULL(p.[resource],''), '|', ISNULL(p.[oprid],''), '|',
                        CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
          END AS DisplayKey
        , p.[calctype_$label] AS CalcType
        , p.[costgroupid]     AS CostGroupId
        , CASE WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
               THEN p.[oprid] ELSE p.[resource] END AS ResourceDisplay
        , p.[oprnum]              AS OprNum
        , p.[realconsump]         AS RealConsump
        , p.[realcostamount]      AS RealCostAmount
        , p.[realcostadjustment]  AS RealCostAdjustment
    FROM coby_roster AS r
    INNER JOIN WH_Raw.dbo.pmfcobyprodcalctrans AS p
        ON  p.[dataareaid]          = r.DataAreaId
        AND p.[transrefid]          = r.ProdId
        AND p.[collectrefprodid]    = r.CollectRefProdId
        AND p.[transreftype_$label] = 'Production'
        AND p.[pmfidrefcobyrecid]   = r.CobyRecId
        AND (p.[collectreflevel] = r.CollectRefLevel + 1 OR p.[bom_$label] = 'No')
        AND p.[calctype_$label] IN ('Item','Service','BOM','Burden','Process','Setup','Qty',
                                    'IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                    'IndirectOutUnitBased','IndirectPurchUnitBased','CostGroup')
    LEFT JOIN WH_Raw.dbo.wrkctrtable AS wc
        ON  wc.[dataareaid] = r.DataAreaId
        AND wc.[wrkctrid]   = p.[resource]
),
act_raw_coby AS (
    SELECT
          DataAreaId, ProdId, OutputItem, SrcLevel, Split, DisplayKey
        , CONCAT(CAST(SrcLevel AS VARCHAR(2)), '|', ISNULL(Split,''), '|', DisplayKey,
                 CASE WHEN CalcType IN ('Process','Setup','Qty')
                      THEN CONCAT('|', ISNULL(WrkCtrType,'')) ELSE '' END) AS BucketKey
        , CalcType, CostGroupId, ResourceDisplay, OprNum
        , RealConsump, RealCostAmount, RealCostAdjustment
    FROM act_key_coby
),
act_coby AS (
    SELECT
          DataAreaId, ProdId, OutputItem, BucketKey
        , MAX(SrcLevel)           AS SrcLevel
        , MAX(Split)              AS Split
        , MAX(DisplayKey)         AS DisplayKey
        , MAX(CalcType)           AS CalcType
        , MAX(CostGroupId)        AS CostGroupId
        , MAX(ResourceDisplay)    AS ResourceDisplay
        , MAX(OprNum)             AS OprNum
        , SUM(RealConsump)        AS RealConsump
        , SUM(RealCostAmount)     AS RealCostAmount
        , SUM(RealCostAdjustment) AS RealCostAdjustment
    FROM act_raw_coby
    GROUP BY DataAreaId, ProdId, OutputItem, BucketKey
),
-- =====================================================================
-- MANUAL-PRICE PRIMARY BRANCH (Is_CoProduct=0).
-- A primary finished good with NO standard-cost CALC price (pricecalcid
-- NULL) is dropped from the calc-priced path (ord_price). X++ loadEstimate
-- else-branch (AxClass_ProdStandardVariance L806-831) injects ONE synthetic
-- Production estimate from inventItemPrice.pcsPrice() -- identical mechanism
-- to co-products. Gated on NOT EXISTS(ord_price) => DISJOINT from the
-- calc-priced anchors (zero regression). BUILT PER X++.
-- =====================================================================
mp_roster AS (
    -- MANUAL-PRICE path (loadEstimate L806-831): the chosen price has NO BOMCalcTable
    -- (blank PriceCalcId, or a pricecalcid with no roll-up) -> NOT in ord_price. The engine
    -- injects ONE synthetic Production estimate = ActQty * pcsPrice of the SAME chosen
    -- (receipt-stamped / date-fallback) price -- it does NOT re-derive a date pick. PcsPrice
    -- is carried straight from chosen_price.
    SELECT
          p.DataAreaId, p.ProdId, p.CollectRefProdId, p.CollectRefLevel,
          p.FinItem AS OutputItem, p.FinCostGroup, p.RealDate, p.ActQty, p.PcsPrice, p.ItemPriceRecId
    FROM chosen_price AS p
    WHERE NOT EXISTS (
        SELECT 1 FROM ord_price AS op
        WHERE op.DataAreaId = p.DataAreaId AND op.ProdId = p.ProdId)
),
est_mp AS (
    -- ONE synthetic Production estimate line: StdCost = ActQty * pcsPrice, StdQty=0, LotSize=0.
    -- pcsPrice comes from the chosen price (receipt-stamped first, date fallback second) via
    -- mp_roster; ISNULL guard mirrors pcsPrice() = 0 on an empty InventItemPrice record.
    -- COST GROUP: AxTable_InventItemPrice.costGroupId() -- `select firstonly CostGroupId from
    -- InventItemCostGroupRollup where InventItemPriceRefRecId == <chosen InventItemPrice RecId>
    -- && CostLevel == CostLevelType::Total (0)`. Threaded via chosen_price.ItemPriceRecId. The
    -- firstonly (no order-by) resolves to the clustered-index first row = MIN(recid); replicated
    -- with ROW_NUMBER ORDER BY recid. Falls back to the finished good's cost group (FinCostGroup)
    -- when the chosen price has no Total-level rollup row. Per-cost-group ONLY -- does NOT change
    -- the output/order 4-way total (the whole lump stays; only its cost-group label moves).
    SELECT
          r.DataAreaId
        , r.ProdId
        , CONCAT('1|No|X|', ISNULL(COALESCE(cgr.costgroupid, r.FinCostGroup),''), '|Production|', ISNULL(r.OutputItem,''), '||0') AS BucketKey
        , CAST(1 AS INT)            AS SrcLevel
        , CAST('No' AS VARCHAR(10)) AS Split
        , CONCAT('X|', ISNULL(COALESCE(cgr.costgroupid, r.FinCostGroup),''), '|Production|', ISNULL(r.OutputItem,''), '||0')      AS DisplayKey
        , CAST('Production' AS VARCHAR(50)) AS CalcType
        , COALESCE(cgr.costgroupid, r.FinCostGroup) AS CostGroupId
        , r.OutputItem              AS ResourceDisplay
        , CAST(0 AS BIGINT)         AS OprNum
        , CAST(0 AS DECIMAL(38,16)) AS StdQty
        , CAST(r.ActQty * ISNULL(r.PcsPrice, 0) AS DECIMAL(38,16)) AS StdCost
        , CAST(0 AS DECIMAL(38,16)) AS LotSizeVariance
        , r.OutputItem              AS OutputItem
        , CAST(0 AS INT)            AS IsCoProduct
    FROM mp_roster AS r
    LEFT JOIN (
        SELECT [inventitempricerefrecid] AS ItemPriceRecId, [costgroupid] AS costgroupid,
               ROW_NUMBER() OVER (PARTITION BY [inventitempricerefrecid] ORDER BY [recid]) AS rn
        FROM WH_Raw.dbo.inventitemcostgrouprollup
        WHERE [costlevel] = 0                    -- CostLevelType::Total
    ) AS cgr
        ON  cgr.ItemPriceRecId = r.ItemPriceRecId
        AND cgr.rn = 1
),
act_key_mp AS (
    -- Manual-price primary actuals from prodcalctrans (same key logic as act_key, rooted on mp_roster).
    SELECT
          r.DataAreaId
        , r.ProdId
        , r.OutputItem
        , CASE WHEN (p.[collectreflevel] - r.CollectRefLevel) >= 2 THEN 2
               ELSE (p.[collectreflevel] - r.CollectRefLevel) END AS SrcLevel
        , p.[bom_$label]         AS Split
        , wc.[wrkctrtype_$label] AS WrkCtrType
        , CASE
            WHEN p.[calctype_$label] IN ('Item','Service','BOM','Burden')
                THEN CONCAT('M|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)), '|',
                            ISNULL(p.[bom_$label],''))
            WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
                THEN CONCAT('P|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[oprid],''), '|', CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
            WHEN p.[calctype_$label] IN ('IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                         'IndirectOutUnitBased','IndirectPurchUnitBased')
                THEN CONCAT('I|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            WHEN p.[calctype_$label] = 'CostGroup'
                THEN CONCAT('C|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                            ISNULL(p.[resource],''))
            ELSE CONCAT('X|', ISNULL(p.[costgroupid],''), '|', p.[calctype_$label], '|',
                        ISNULL(p.[resource],''), '|', ISNULL(p.[oprid],''), '|',
                        CAST(ISNULL(p.[oprnum],0) AS VARCHAR(20)))
          END AS DisplayKey
        , p.[calctype_$label] AS CalcType
        , p.[costgroupid]     AS CostGroupId
        , CASE WHEN p.[calctype_$label] IN ('Process','Setup','Qty')
               THEN p.[oprid] ELSE p.[resource] END AS ResourceDisplay
        , p.[oprnum]              AS OprNum
        , p.[realconsump]         AS RealConsump
        , p.[realcostamount]      AS RealCostAmount
        , p.[realcostadjustment]  AS RealCostAdjustment
    FROM mp_roster AS r
    INNER JOIN WH_Raw.dbo.prodcalctrans AS p
        ON  p.[dataareaid]          = r.DataAreaId
        AND p.[transrefid]          = r.ProdId
        AND p.[collectrefprodid]    = r.CollectRefProdId
        AND p.[transreftype_$label] = 'Production'
        AND (p.[collectreflevel] = r.CollectRefLevel + 1 OR p.[bom_$label] = 'No')
        AND p.[calctype_$label] IN ('Item','Service','BOM','Burden','Process','Setup','Qty',
                                    'IndirectSurcharge','IndirectRate','IndirectInUnitBased',
                                    'IndirectOutUnitBased','IndirectPurchUnitBased','CostGroup')
    LEFT JOIN WH_Raw.dbo.wrkctrtable AS wc
        ON  wc.[dataareaid] = r.DataAreaId
        AND wc.[wrkctrid]   = p.[resource]
),
act_raw_mp AS (
    SELECT
          DataAreaId, ProdId, OutputItem, SrcLevel, Split, DisplayKey
        , CONCAT(CAST(SrcLevel AS VARCHAR(2)), '|', ISNULL(Split,''), '|', DisplayKey,
                 CASE WHEN CalcType IN ('Process','Setup','Qty')
                      THEN CONCAT('|', ISNULL(WrkCtrType,'')) ELSE '' END) AS BucketKey
        , CalcType, CostGroupId, ResourceDisplay, OprNum
        , RealConsump, RealCostAmount, RealCostAdjustment
    FROM act_key_mp
),
act_mp AS (
    SELECT
          DataAreaId, ProdId, OutputItem, BucketKey
        , MAX(SrcLevel)           AS SrcLevel
        , MAX(Split)              AS Split
        , MAX(DisplayKey)         AS DisplayKey
        , MAX(CalcType)           AS CalcType
        , MAX(CostGroupId)        AS CostGroupId
        , MAX(ResourceDisplay)    AS ResourceDisplay
        , MAX(OprNum)             AS OprNum
        , SUM(RealConsump)        AS RealConsump
        , SUM(RealCostAmount)     AS RealCostAmount
        , SUM(RealCostAdjustment) AS RealCostAdjustment
    FROM act_raw_mp
    GROUP BY DataAreaId, ProdId, OutputItem, BucketKey
),
output_header AS (
    -- One header row per output (primary + each co-product) for the Total projection.
    SELECT DataAreaId, ProdId, FinItem AS OutputItem, FinCostGroup AS HeaderCostGroup, CAST(0 AS INT) AS IsCoProduct
    FROM ord
    UNION ALL
    SELECT DataAreaId, ProdId, OutputItem, CobyCostGroup AS HeaderCostGroup, CAST(1 AS INT) AS IsCoProduct
    FROM coby_head
),
est_all AS (
    -- Unified estimate set (primary + co-product), keyed by Output_Item.
    SELECT
          e.DataAreaId, e.ProdId, o.FinItem AS OutputItem, CAST(0 AS INT) AS IsCoProduct,
          e.BucketKey, e.SrcLevel, e.Split, e.DisplayKey, e.CalcType, e.CostGroupId,
          e.ResourceDisplay, e.OprNum, e.StdQty, e.StdCost, e.LotSizeVariance
    FROM est AS e
    INNER JOIN ord AS o ON o.DataAreaId = e.DataAreaId AND o.ProdId = e.ProdId
    UNION ALL
    SELECT
          DataAreaId, ProdId, OutputItem, IsCoProduct,
          BucketKey, SrcLevel, Split, DisplayKey, CalcType, CostGroupId,
          ResourceDisplay, OprNum, StdQty, StdCost, LotSizeVariance
    FROM est_coby
    UNION ALL
    SELECT
          DataAreaId, ProdId, OutputItem, IsCoProduct,
          BucketKey, SrcLevel, Split, DisplayKey, CalcType, CostGroupId,
          ResourceDisplay, OprNum, StdQty, StdCost, LotSizeVariance
    FROM est_mp
),
act_all AS (
    -- Unified actual set (primary + co-product), keyed by Output_Item.
    SELECT
          a.DataAreaId, a.ProdId, o.FinItem AS OutputItem, CAST(0 AS INT) AS IsCoProduct,
          a.BucketKey, a.SrcLevel, a.Split, a.DisplayKey, a.CalcType, a.CostGroupId,
          a.ResourceDisplay, a.OprNum, a.RealConsump, a.RealCostAmount, a.RealCostAdjustment
    FROM act AS a
    INNER JOIN ord AS o ON o.DataAreaId = a.DataAreaId AND o.ProdId = a.ProdId
    UNION ALL
    SELECT
          DataAreaId, ProdId, OutputItem, CAST(1 AS INT) AS IsCoProduct,
          BucketKey, SrcLevel, Split, DisplayKey, CalcType, CostGroupId,
          ResourceDisplay, OprNum, RealConsump, RealCostAmount, RealCostAdjustment
    FROM act_coby
    UNION ALL
    SELECT
          DataAreaId, ProdId, OutputItem, CAST(0 AS INT) AS IsCoProduct,
          BucketKey, SrcLevel, Split, DisplayKey, CalcType, CostGroupId,
          ResourceDisplay, OprNum, RealConsump, RealCostAmount, RealCostAdjustment
    FROM act_mp
),
joined AS (
    SELECT
          COALESCE(e.DataAreaId, a.DataAreaId)             AS DataAreaId
        , COALESCE(e.ProdId, a.ProdId)                     AS ProdId
        , COALESCE(e.OutputItem, a.OutputItem)             AS OutputItem
        , COALESCE(e.IsCoProduct, a.IsCoProduct)           AS IsCoProduct
        , COALESCE(e.SrcLevel, a.SrcLevel)                 AS SrcLevel
        , COALESCE(e.Split, a.Split)                       AS Split
        , COALESCE(e.BucketKey, a.BucketKey)               AS BucketKey
        , COALESCE(e.DisplayKey, a.DisplayKey)             AS DisplayKey
        , COALESCE(e.CostGroupId, a.CostGroupId)           AS Cost_Group
        , COALESCE(e.CalcType, a.CalcType)                 AS Cost_Type
        , COALESCE(e.ResourceDisplay, a.ResourceDisplay)   AS Resource
        , COALESCE(e.OprNum, a.OprNum)                     AS Oper_No
        , COALESCE(a.RealConsump, 0)                       AS Net_Realized_Qty
        , COALESCE(a.RealCostAmount, 0)                    AS Net_Realized_Cost
        , COALESCE(a.RealCostAmount, 0) + COALESCE(a.RealCostAdjustment, 0) AS Real_Cost_Total
        , COALESCE(e.StdQty, 0)                            AS Allowed_Qty
        , COALESCE(e.StdCost, 0)                           AS Allowed_Cost
        , COALESCE(e.LotSizeVariance, 0)                   AS Lot_Size_Variance
        , CASE WHEN e.BucketKey IS NOT NULL AND e.StdQty <> 0 AND a.BucketKey IS NOT NULL
               THEN 1 ELSE 0 END                           AS Is_Matched
        , e.StdQty                                         AS E_StdQty
        , e.StdCost                                        AS E_StdCost
        , a.RealConsump                                    AS A_RealConsump
    FROM est_all AS e
    FULL OUTER JOIN act_all AS a
        ON  e.DataAreaId = a.DataAreaId
        AND e.ProdId     = a.ProdId
        AND e.OutputItem = a.OutputItem
        AND e.BucketKey  = a.BucketKey
),
calc AS (
    SELECT
          j.*
        , o2.FinItem                                                            AS OrderPrimaryItem
        , o2.RealDate                                                           AS RealDate
        , CAST(CASE WHEN j.Is_Matched = 1 AND j.A_RealConsump <> 0
                    THEN j.Real_Cost_Total - j.A_RealConsump * (j.E_StdCost / CASE WHEN j.E_StdQty = 0 THEN NULL ELSE j.E_StdQty END)
                    ELSE 0 END AS DECIMAL(38,16))                                   AS Price_Variance
        , CAST(CASE WHEN j.Is_Matched = 1
                    THEN (j.A_RealConsump - j.E_StdQty) * (j.E_StdCost / CASE WHEN j.E_StdQty = 0 THEN NULL ELSE j.E_StdQty END)
                    ELSE 0 END AS DECIMAL(38,16))                                   AS Quantity_Variance
        , CAST(CASE WHEN j.Is_Matched = 1
                    THEN 0
                    ELSE j.Real_Cost_Total - j.Allowed_Cost END AS DECIMAL(38,16)) AS Substitution_Variance
    FROM joined AS j
    -- Order's PRIMARY finished good (ord is 1 row/order; LEFT keeps every calc row).
    LEFT JOIN ord AS o2
        ON  o2.DataAreaId = j.DataAreaId
        AND o2.ProdId     = j.ProdId
),
posted AS (
    -- SNAP-TO-POSTED reference. The AUTHORITATIVE posted GL variance, inventcosttransvariance (split=0) joined
    -- to inventcosttrans (costtransreftype='Production'), aggregated to (order, output item).
    -- v.[costamount] is EDT CostAmountNonMonetary (AOT-confirmed) = the CALCULATED, NON-currency-
    -- rounded variance the engine posted. Carried onto the Total projection ties to the posted ledger to the 
    -- penny regardless of the immaterial per-unit rounding residual in the reconstructed full-precision 4-way columns.
    -- Grain matches R2 (per DataAreaId, ProdId, Output_Item); 1 row per output.
    SELECT
          ict.[dataareaid] AS DataAreaId
        , ict.[transrefid] AS ProdId
        , ict.[itemid]     AS OutputItem
        , CAST(SUM(CASE WHEN v.[variancetype_$label] = 'LotSize'      THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Lot_Posted
        , CAST(SUM(CASE WHEN v.[variancetype_$label] = 'ProdPrice'    THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Price_Posted
        , CAST(SUM(CASE WHEN v.[variancetype_$label] = 'Quantity'     THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Qty_Posted
        , CAST(SUM(CASE WHEN v.[variancetype_$label] = 'Substitution' THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Sub_Posted
        , CAST(SUM(CASE WHEN v.[variancetype_$label] = 'Scrap'        THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Scrap_Posted
        , CAST(SUM(CASE WHEN ISNULL(v.[variancetype_$label],'') NOT IN
                        ('LotSize','ProdPrice','Quantity','Substitution','Scrap')
                        THEN v.[costamount] ELSE 0 END) AS DECIMAL(19,4)) AS Other_Posted
        , CAST(SUM(v.[costamount]) AS DECIMAL(19,4)) AS Total_Posted
    FROM WH_Raw.dbo.inventcosttransvariance AS v
    INNER JOIN WH_Raw.dbo.inventcosttrans   AS ict
        ON ict.[recid] = v.[inventcosttransrefrecid]
    WHERE ict.[costtransreftype_$label] = 'Production'
      AND v.[split] = 0
    GROUP BY ict.[dataareaid], ict.[transrefid], ict.[itemid]
),
-- =====================================================================
-- OUTPUT: three level projections (Cost_Level discriminator), all from
-- the SAME bucket-grain computation, for EVERY output (primary + co-products
-- via Output_Item / Is_CoProduct). Filters mirror AxClass_CostSheetPanel
-- L84-91 (Level_Corresponds_To_RollupLevel) over InventCostLevel + Split.
-- =====================================================================
-- ---- Level = Single : SrcLevel=1 (both Split). ----
output_noSKs as (
    SELECT
      CONVERT(VARCHAR(64),
          HASHBYTES('SHA2_256',
              CAST(CONCAT('Single','|',c.DataAreaId,'|',c.ProdId,'|',c.OutputItem,'|',c.DisplayKey) AS VARCHAR(8000))), 2) AS ProductionVarianceResource_SK
    , CAST('Single' AS VARCHAR(10))                                       AS Cost_Level
    , c.DataAreaId                                                        AS DataAreaId
    , c.ProdId                                                            AS ProdId
    , c.OutputItem                                                        AS Output_Item
    , MAX(c.OrderPrimaryItem)                                             AS Order_Primary_ItemId
    , MAX(c.IsCoProduct)                                                  AS Is_CoProduct
    , CASE WHEN MAX(c.IsCoProduct) = 1 THEN 'Co-product' ELSE 'Primary' END AS Output_Role
    , MAX(c.Cost_Group)                                                   AS Cost_Group
    , MAX(c.Cost_Type)                                                    AS Cost_Type
    , MAX(c.Resource)                                                     AS Resource
    , MAX(c.Oper_No)                                                      AS Oper_No
    , CAST(SUM(c.Net_Realized_Qty)  AS DECIMAL(28,8) )                    AS Net_Realized_Qty
    , CAST(SUM(c.Net_Realized_Cost) AS DECIMAL(19,4) )                    AS Net_Realized_Cost
    , CAST(SUM(c.Allowed_Qty)       AS DECIMAL(28,8) )                    AS Allowed_Qty
    , CAST(SUM(c.Allowed_Cost)      AS DECIMAL(19,4) )                    AS Allowed_Cost
    , CAST(SUM(c.Lot_Size_Variance)     AS DECIMAL(19,4) )                AS Lot_Size_Variance
    , CAST(SUM(c.Price_Variance)        AS DECIMAL(19,4) )                AS Price_Variance
    , CAST(SUM(c.Quantity_Variance)     AS DECIMAL(19,4) )                AS Quantity_Variance
    , CAST(SUM(c.Substitution_Variance) AS DECIMAL(19,4) )               AS Substitution_Variance
    , CAST(SUM(c.Lot_Size_Variance + c.Price_Variance + c.Quantity_Variance + c.Substitution_Variance)
           AS DECIMAL(19,4) )                                            AS Total_Variance
    ------ SNAP-TO-POSTED: populated on the Total projection only (posted ledger is order/output grain).
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Lot_Size_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Price_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Quantity_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Substitution_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Scrap_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Other_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Total_Variance_Posted
    -- Order-level report-as-finished / cost date (ProdTable.RealDate via ord/o2 in calc).
    -- Constant per ProdId (in GROUP BY), so MAX() surfaces it without touching the grain.
    , CAST(MAX(c.RealDate) AS DATE)                                       AS FinishedDate
    , CONVERT(INT, CONVERT(VARCHAR(8), MAX(c.RealDate), 112))             AS FinishedDateKey
    , 'D365FO'                                                            AS Source
FROM calc AS c
WHERE c.SrcLevel = 1
GROUP BY c.DataAreaId, c.ProdId, c.OutputItem, c.DisplayKey

UNION ALL
-- ---- Level = Multi : (SrcLevel=1 AND Split=No) OR SrcLevel=2. ----
-- Drops the level-1 bom=Yes lump, replaces it with the level-2 CostGroup explosion.
SELECT
      CONVERT(VARCHAR(64),
          HASHBYTES('SHA2_256',
              CAST(CONCAT('Multi','|',c.DataAreaId,'|',c.ProdId,'|',c.OutputItem,'|',c.DisplayKey) AS VARCHAR(8000))), 2) AS ProductionVarianceResource_SK
    , CAST('Multi' AS VARCHAR(10))                                        AS Cost_Level
    , c.DataAreaId                                                        AS DataAreaId
    , c.ProdId                                                            AS ProdId
    , c.OutputItem                                                        AS Output_Item
    , MAX(c.OrderPrimaryItem)                                             AS Order_Primary_ItemId
    , MAX(c.IsCoProduct)                                                  AS Is_CoProduct
    , CASE WHEN MAX(c.IsCoProduct) = 1 THEN 'Co-product' ELSE 'Primary' END AS Output_Role
    , MAX(c.Cost_Group)                                                   AS Cost_Group
    , MAX(c.Cost_Type)                                                    AS Cost_Type
    , MAX(c.Resource)                                                     AS Resource
    , MAX(c.Oper_No)                                                      AS Oper_No
    , CAST(SUM(c.Net_Realized_Qty)  AS DECIMAL(28,8) )                    AS Net_Realized_Qty
    , CAST(SUM(c.Net_Realized_Cost) AS DECIMAL(19,4) )                    AS Net_Realized_Cost
    , CAST(SUM(c.Allowed_Qty)       AS DECIMAL(28,8) )                    AS Allowed_Qty
    , CAST(SUM(c.Allowed_Cost)      AS DECIMAL(19,4) )                    AS Allowed_Cost
    , CAST(SUM(c.Lot_Size_Variance)     AS DECIMAL(19,4) )                AS Lot_Size_Variance
    , CAST(SUM(c.Price_Variance)        AS DECIMAL(19,4) )                AS Price_Variance
    , CAST(SUM(c.Quantity_Variance)     AS DECIMAL(19,4) )                AS Quantity_Variance
    , CAST(SUM(c.Substitution_Variance) AS DECIMAL(19,4) )               AS Substitution_Variance
    , CAST(SUM(c.Lot_Size_Variance + c.Price_Variance + c.Quantity_Variance + c.Substitution_Variance)
           AS DECIMAL(19,4) )                                            AS Total_Variance
    ------ SNAP-TO-POSTED: populated on the Total projection only (posted ledger is order/output grain).
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Lot_Size_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Price_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Quantity_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Substitution_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Scrap_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Other_Variance_Posted
    ----, CAST(NULL AS DECIMAL(19,4))                                         AS Total_Variance_Posted
    -- Order-level report-as-finished / cost date (ProdTable.RealDate via ord/o2 in calc).
    -- Constant per ProdId (in GROUP BY), so MAX() surfaces it without touching the grain.
    , CAST(MAX(c.RealDate) AS DATE)                                       AS FinishedDate
    , CONVERT(INT, CONVERT(VARCHAR(8), MAX(c.RealDate), 112))             AS FinishedDateKey
    , 'D365FO'                                                            AS Source
FROM calc AS c
WHERE (c.SrcLevel = 1 AND c.Split = 'No') OR c.SrcLevel = 2
GROUP BY c.DataAreaId, c.ProdId, c.OutputItem, c.DisplayKey

UNION ALL
-- ---- Level = Total : one row per output (primary + each co-product) = AUTHORITATIVE posted total. ----
-- Multi basis ((SrcLevel=1 AND Split=No) OR SrcLevel=2) so it ties to the posted GL variance
-- for a CostBreakdown=SubLedger company. 
SELECT
      CONVERT(VARCHAR(64),
          HASHBYTES('SHA2_256',
              CAST(CONCAT('Total','|',c.DataAreaId,'|',c.ProdId,'|',c.OutputItem) AS VARCHAR(8000))), 2) AS ProductionVarianceResource_SK
    , CAST('Total' AS VARCHAR(10))                                        AS Cost_Level
    , c.DataAreaId                                                        AS DataAreaId
    , c.ProdId                                                            AS ProdId
    , c.OutputItem                                                        AS Output_Item
    , MAX(c.OrderPrimaryItem)                                             AS Order_Primary_ItemId
    , MAX(c.IsCoProduct)                                                  AS Is_CoProduct
    , CASE WHEN MAX(c.IsCoProduct) = 1 THEN 'Co-product' ELSE 'Primary' END AS Output_Role
    , MAX(h.HeaderCostGroup)                                              AS Cost_Group
    , CAST('Production' AS VARCHAR(50))                                   AS Cost_Type
    , c.OutputItem                                                        AS Resource
    , CAST(0 AS BIGINT)                                                   AS Oper_No
    , CAST(NULL AS DECIMAL(28,8) )                                        AS Net_Realized_Qty
    , CAST(SUM(c.Net_Realized_Cost) AS DECIMAL(19,4) )                    AS Net_Realized_Cost
    , CAST(NULL AS DECIMAL(28,8) )                                        AS Allowed_Qty
    , CAST(SUM(c.Allowed_Cost)      AS DECIMAL(19,4) )                    AS Allowed_Cost
    ------, CAST(SUM(c.Lot_Size_Variance)     AS DECIMAL(19,4) )                AS Lot_Size_Variance
    ------, CAST(SUM(c.Price_Variance)        AS DECIMAL(19,4) )                AS Price_Variance
    ------, CAST(SUM(c.Quantity_Variance)     AS DECIMAL(19,4) )                AS Quantity_Variance
    ------, CAST(SUM(c.Substitution_Variance) AS DECIMAL(19,4) )               AS Substitution_Variance
    ------, CAST(SUM(c.Lot_Size_Variance + c.Price_Variance + c.Quantity_Variance + c.Substitution_Variance)
    ------       AS DECIMAL(19,4) )                                            AS Total_Variance
    -- SNAP-TO-POSTED: the authoritative posted GL variance for this output (from the `posted`
    -- CTE ). posted is 1 row/output; GROUP BY is per output, so MAX() just
    -- surfaces that single value without fan-out. Guarantees ties to the posted ledger.
    , MAX(pst.Lot_Posted)                                                 AS Lot_Size_Variance
    , MAX(pst.Price_Posted)                                               AS Price_Variance
    , MAX(pst.Qty_Posted)                                                 AS Quantity_Variance
    , MAX(pst.Sub_Posted)                                                 AS Substitution_Variance
    --, MAX(pst.Scrap_Posted)                                               AS Scrap_Variance  --Not in Single of Multi level data
    --, MAX(pst.Other_Posted)                                               AS Other_Variance  --Not in Single of Multi level data
    , MAX(pst.Total_Posted)                                               AS Total_Variance
    -- Order-level report-as-finished / cost date (ProdTable.RealDate via ord/o2 in calc).
    -- Constant per ProdId (in GROUP BY), so MAX() surfaces it without touching the grain.
    , CAST(MAX(c.RealDate) AS DATE)                                       AS FinishedDate
    , CONVERT(INT, CONVERT(VARCHAR(8), MAX(c.RealDate), 112))             AS FinishedDateKey
    , 'D365FO'                                                            AS Source
FROM calc AS c
INNER JOIN output_header AS h
    ON  h.DataAreaId = c.DataAreaId
    AND h.ProdId     = c.ProdId
    AND h.OutputItem = c.OutputItem
LEFT JOIN posted AS pst
    ON  pst.DataAreaId = c.DataAreaId
    AND pst.ProdId     = c.ProdId
    AND pst.OutputItem = c.OutputItem
-- MULTI basis (not Single): under CostBreakdown=SubLedger the posted order total is the
-- Split=No sum (calcVariances L339), so Total must exclude the level-1 bom=Yes sub-production
-- lump and carry the level-2 explosion instead. Single-level orders are unaffected (Single=Multi).
WHERE (c.SrcLevel = 1 AND c.Split = 'No') OR c.SrcLevel = 2
GROUP BY c.DataAreaId, c.ProdId, c.OutputItem

)
----Output with SKs from dimensions
SELECT 
--o.ProductionVarianceResource_SK
--, 
o.Cost_Level
, o.DataAreaId  CMPNY
, o.ProdId  ProductionBatchOrder
, o.Order_Primary_ItemId ProductionOrderProductID
, o.Output_Item  OutputProductID
, o.Is_CoProduct
, o.Output_Role
, o.Cost_Group
, o.Cost_Type
, o.Resource
, o.Oper_No
, dle.accountingcurrency
, o.Net_Realized_Qty
, o.Net_Realized_Cost
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Net_Realized_Cost   Net_Realized_Cost_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Net_Realized_Cost   Net_Realized_Cost_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Net_Realized_Cost   Net_Realized_Cost_CNY
, o.Allowed_Qty
, o.Allowed_Cost
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Allowed_Cost   Allowed_Cost_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Allowed_Cost   Allowed_Cost_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Allowed_Cost   Allowed_Cost_CNY

, o.Lot_Size_Variance
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Lot_Size_Variance   Lot_Size_Variance_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Lot_Size_Variance   Lot_Size_Variance_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Lot_Size_Variance   Lot_Size_Variance_CNY
, o.Price_Variance
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Price_Variance   Price_Variance_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Price_Variance   Price_Variance_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Price_Variance   Price_Variance_CNY
, o.Quantity_Variance
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Quantity_Variance   Quantity_Variance_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Quantity_Variance   Quantity_Variance_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Quantity_Variance   Quantity_Variance_CNY
, o.Substitution_Variance
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Substitution_Variance   Substitution_Variance_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Substitution_Variance   Substitution_Variance_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Substitution_Variance   Substitution_Variance_CNY
, o.Total_Variance
-- Txn basis (FROM dle.accountingcurrency) 
, CASE WHEN dle.accountingcurrency = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * o.Total_Variance   Total_Variance_USD
, CASE WHEN dle.accountingcurrency = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * o.Total_Variance   Total_Variance_EUR
, CASE WHEN dle.accountingcurrency = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * o.Total_Variance   Total_Variance_CNY

----, o.Lot_Size_Variance_Posted
----, o.Price_Variance_Posted
----, o.Quantity_Variance_Posted
----, o.Substitution_Variance_Posted
----, o.Scrap_Variance_Posted
----, o.Other_Variance_Posted
----, o.Total_Variance_Posted

, o.FinishedDate
, o.FinishedDateKey
, o.Source

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dpbo.ProductionBatchOrderKey, -1) ProductionBatchOrderKey
    , ISNULL(dp.ProductKey, -1) HistoricalProductKey
    , ISNULL(dpc.ProductKey, -1) ProductKey
    , ISNULL(odp.ProductKey, -1) HistoricalOutputProductKey
    , ISNULL(odpc.ProductKey, -1) OutputProductKey
    , ISNULL(cpdp.ProductKey, -1) HistoricalCoProductKey
    , ISNULL(cpdpc.ProductKey, -1) CoProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey

	, ISNULL(dr.RouteKey, -1) RouteKey


-- =========================== ADDED: currency-conversion audit columns ===========================
-- Rate_Missing flags: 1 when a NON-identity conversion found no matching rate row (else 0).
-- (Identity convert, e.g. source = target, never needs a rate, so it is never flagged missing.)
, CASE WHEN dle.accountingcurrency <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
, CASE WHEN dle.accountingcurrency <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
-- ================================================================================================

FROM output_noSKs  o

JOIN WH_Raw.dbo.prodtable  pt 
  ON pt.prodid = o.ProdId 
    AND pt.dataareaid = o.DataAreaId

JOIN WH_Raw.dbo.inventdim  id 
  ON id.inventdimid = pt.inventdimid 
    AND id.dataareaid = pt.dataareaid

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON o.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_ProductionBatchOrder dpbo
	ON o.ProdId = dpbo.ProductionBatchOrder
		AND o.dataareaid = dpbo.CMPNY
		AND dpbo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON o.Order_Primary_ItemId = dp.Product_ID
		AND o.dataareaid = dp.CMPNY
		AND pt.createddatetime between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON o.Order_Primary_ItemId = dpc.Product_ID
		AND o.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product odp
	ON o.Output_Item = odp.Product_ID
		AND o.dataareaid = odp.CMPNY
		AND pt.createddatetime between odp.RecordEffectiveStartDate and odp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product odpc
	ON o.Output_Item = odpc.Product_ID
		AND o.dataareaid = odpc.CMPNY
		AND odpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product cpdp
	ON o.Output_Item = cpdp.Product_ID
		AND o.dataareaid = cpdp.CMPNY
        AND o.Is_CoProduct = 1
		AND pt.createddatetime between cpdp.RecordEffectiveStartDate and cpdp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product cpdpc
	ON o.Output_Item = cpdpc.Product_ID
		AND o.dataareaid = cpdpc.CMPNY
        AND o.Is_CoProduct = 1
		AND cpdpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND o.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON o.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Route dr
	ON pt.dataareaid = dr.CMPNY
		AND pt.routeid = dr.RouteID
		AND dr.RecordStatus=1

-- =========================== ADDED: exchange-rate joins (currency conversion) ===========================
-- TXN-BASIS joins: fromcurrencycode = vit_currencycode (transaction/document currency).
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON erTxnUSD.fromcurrencycode = dle.accountingcurrency
   AND erTxnUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), o.FinishedDate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
   AND erTxnUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON erTxnEUR.fromcurrencycode = dle.accountingcurrency
   AND erTxnEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), o.FinishedDate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
   AND erTxnEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON erTxnCNY.fromcurrencycode = dle.accountingcurrency
   AND erTxnCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), o.FinishedDate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
   AND erTxnCNY.exchangeratetype = 'Default global rate' 

