CREATE OR ALTER VIEW  tbl_Fact_VendorInvoiceTransactions
AS
WITH
-- charges_raw: normalize EVERY misc charge to the invoice natural key.
-- Branch A = HEADER-grain charges (TRANSTABLEID = 19561 -> VENDINVOICEJOUR).
-- Branch B = LINE-grain   charges (TRANSTABLEID = 8417  -> VENDINVOICETRANS).
charges_raw AS
(
    -- Branch A — HEADER charges
    SELECT
        j.INVOICEID,
        j.INVOICEDATE,
        j.INTERNALINVOICEID,
        j.DATAAREAID,
        m.MARKUPCODE,
        m.CALCULATEDAMOUNT,
        m.CURRENCYCODE
    FROM WH_Raw.[dbo].[MARKUPTRANS] m
        INNER JOIN WH_Raw.[dbo].[VENDINVOICEJOUR] j
            ON  m.TRANSRECID = j.RECID
            AND m.DATAAREAID = j.DATAAREAID
    WHERE m.TRANSTABLEID = 19561                -- VENDINVOICEJOUR 
      AND m.DATAAREAID   = '101'

    UNION ALL

    -- Branch B — LINE charges
    SELECT
        t.INVOICEID,
        t.INVOICEDATE,
        t.INTERNALINVOICEID,
        t.DATAAREAID,
        m.MARKUPCODE,
        m.CALCULATEDAMOUNT,
        m.CURRENCYCODE
    FROM WH_Raw.[dbo].[MARKUPTRANS] m
        INNER JOIN WH_Raw.[dbo].[VENDINVOICETRANS] t
            ON  m.TRANSRECID = t.RECID
            AND m.DATAAREAID = t.DATAAREAID
    WHERE m.TRANSTABLEID = 8417                 -- VENDINVOICETRANS 
      AND m.DATAAREAID   = '101'
),

-- charges_by_invoice: GROUP charges_raw to EXACTLY one row per invoice and
-- pivot the FIXED charge-code set via conditional aggregation 
-- [Charge: Total] sums all codes; [Charge: Other] captures any
-- code OUTSIDE the fixed set so nothing is silently dropped.
charges_by_invoice AS
(
    SELECT
        cr.INVOICEID,
        cr.INVOICEDATE,
        --------cr.NUMBERSEQUENCEGROUP,
        cr.INTERNALINVOICEID,
        cr.DATAAREAID,
        cr.CURRENCYCODE,

        SUM(CASE WHEN cr.MARKUPCODE = 'Freight'    THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: Freight],
        SUM(CASE WHEN cr.MARKUPCODE = 'Pallet'     THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: Pallet],
        SUM(CASE WHEN cr.MARKUPCODE = 'PetrolChrg' THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: PetrolChrg],
        SUM(CASE WHEN cr.MARKUPCODE = 'Sales Tax'  THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: Sales Tax],
        SUM(CASE WHEN cr.MARKUPCODE = 'Setup Fee'  THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: Setup Fee],
        SUM(CASE WHEN cr.MARKUPCODE = 'Tote Dep'   THEN cr.CALCULATEDAMOUNT ELSE 0 END) AS [Charge: Tote Dep],

        SUM(cr.CALCULATEDAMOUNT)                                                        AS [Charge: Total],

        -- Anything NOT in the fixed set — so no charge is ever lost
        SUM(CASE
                WHEN cr.MARKUPCODE NOT IN
                    ('Freight','Pallet','PetrolChrg','Sales Tax','Setup Fee','Tote Dep')
                THEN cr.CALCULATEDAMOUNT ELSE 0
            END)                                                                        AS [Charge: Other]
    FROM charges_raw cr
    GROUP BY
        cr.INVOICEID,
        cr.INVOICEDATE,
        cr.INTERNALINVOICEID,
        cr.DATAAREAID,
        cr.CURRENCYCODE
), 
prelim as
(
SELECT
    vit.DATAAREAID                                  AS [CMPNY],
    vit.ORIGPURCHID                                 AS [PurchaseOrder],
    vij.InvoiceAccount                              AS VendorAccount,
    vij.INVOICEID                                   AS InvoiceID,
    vij.INVOICEAMOUNT                               AS InvoiceAmount,
    vij.INVOICEDATE                                 AS InvoiceDate,
    vit.LINENUM                                     AS [LineNumber],
    vit.ITEMID                                      AS [Item],
    ISNULL(cat.NAME,'')                             AS [ProcurementCategory],
    vit.NAME                                        AS [Description],
    vit.QTY                                         AS [Quantity],
    vit.PurchUnit                                   AS [Quantity_UoM],

    CASE
        WHEN vit.PurchUnit = 'lb' THEN 1                                               -- already in LB
        WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor  -- direct sales-unit -> LB conversion
        ELSE (case when vit.PurchUnit = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) * 2.20462262185 -- fallback: convert KG -> LB (1 / 0.45359237)
    END * vit.QTY      Quantity_LBs,

    CASE
        WHEN vit.PurchUnit = 'kg' THEN 1                                               -- already in KG
        WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor  -- direct sales-unit -> KG conversion
        ELSE (case when vit.PurchUnit = 'lb' then 1 else UOMC_lb.UOMConversionFactor end ) * 0.45359237  -- fallback: convert LBs -> KG
    END * vit.QTY      Quantity_KGs,

    vit.CURRENCYCODE  VIT_CURRENCYCODE,
     CASE
        WHEN vit.PRICEUNIT = 0 THEN vit.PURCHPRICE
        ELSE vit.PURCHPRICE / vit.PRICEUNIT
    END                                             AS [UnitPrice],
    vit.DISCAMOUNT                                  AS [Discount],
    vit.DISCPERCENT                                 AS [DiscountPercent],
    vit.LINEAMOUNT                                  AS [LineAmount],
    vit.LINEAMOUNTTAX                               AS [SalesTaxIncluded],
    ISNULL(t99.TAX1099FIELDNUM,'')                  AS [1099Box],
    vit.TAX1099AMOUNT                               AS [1099Amount],
    ISNULL(vit.TAX1099STATE,'')                     AS [StateProvince],
    vit.TAX1099STATEAMOUNT                          AS [1099StateAmount],
    ISNULL(rr.REASON,'')                            AS [ReasonCode],
    ISNULL(rr.REASONCOMMENT,'')                     AS [ReasonComment],

    -- ---- Misc-charge totals (INVOICE grain, repeated per line) ----------
    -- COALESCE turns the NULL from the LEFT JOIN (invoice with no charges)
    -- into 0. COALESCE is permitted under the Hard SQL Rules.
    isnull(cbi.CURRENCYCODE,'')       CHG_CURRENCYCODE,
    COALESCE(cbi.[Charge: Freight],    0)           AS [FreightCharge],
    COALESCE(cbi.[Charge: Pallet],     0)           AS [PalletCharge],
    COALESCE(cbi.[Charge: PetrolChrg], 0)           AS [PetrolCharge],
    COALESCE(cbi.[Charge: Sales Tax],  0)           AS [SalesTaxCharge],
    COALESCE(cbi.[Charge: Setup Fee],  0)           AS [SetupFeeCharge],
    COALESCE(cbi.[Charge: Tote Dep],   0)           AS [ToteDepCharge],
    COALESCE(cbi.[Charge: Other],      0)           AS [OtherCharge],
    COALESCE(cbi.[Charge: Total],      0)           AS [TotalCharge]

    FROM 
    WH_Raw.[dbo].[VendInvoiceTrans] vit

    JOIN WH_raw.dbo.VendInvoiceJour vij
        ON vit.INVOICEID          = vij.INVOICEID
            AND vit.INVOICEDATE         = vij.INVOICEDATE
            ----AND vit.NUMBERSEQUENCEGROUP = vij.NUMBERSEQUENCEGROUP
            AND vit.INTERNALINVOICEID   = vij.INTERNALINVOICEID
            AND vit.DATAAREAID          = vij.DATAAREAID
            ----AND vit.purchid           = vij.purchid

    LEFT JOIN WH_Raw.[dbo].[TAX1099FIELDS] t99
        ON vit.TAX1099FIELDS = t99.RECID

    LEFT JOIN WH_Raw.[dbo].[REASONTABLEREF] rr
        ON vit.REASONTABLEREF = rr.RECID

     LEFT JOIN WH_Raw.[dbo].[ECORESCATEGORY] cat
         ON vit.PROCUREMENTCATEGORY = cat.RECID

    -- Invoice-grain charge totals. One row per invoice, so this repeats
    -- the totals on each line WITHOUT fan-out. Join on the invoice natural key
    LEFT JOIN charges_by_invoice cbi
        ON  vit.INVOICEID          = cbi.INVOICEID
        AND vit.INVOICEDATE        = cbi.INVOICEDATE
        AND vit.INTERNALINVOICEID  = cbi.INTERNALINVOICEID
        AND vit.DATAAREAID         = cbi.DATAAREAID

    LEFT JOIN WH_Raw.dbo.InventTable IT
	    ON vit.itemid = IT.itemid
		    AND vit.dataareaid = IT.dataareaid

    LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
        ON IT.product = UOMC_lb.product
	        AND vit.PurchUnit = UOMC_lb.SYMBOLFROM
		    AND UOMC_lb.SYMBOLTO = 'lb'
 
     LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
         ON IT.product = UOMC_kg.product
             AND vit.PurchUnit = UOMC_kg.SYMBOLFROM
             AND UOMC_kg.SYMBOLTO = 'kg'

), 
qty_totals as
(
SELECT CMPNY
    ,  PurchaseOrder
    ,  InvoiceID
    ,  SUM(ISNULL(Quantity_LBs,0)) TotalQuantityLBs
    ,  SUM(Quantity) TotQty
    ,  COUNT(1) NumRows
FROM prelim
GROUP BY CMPNY
    ,  PurchaseOrder
    ,  InvoiceID
)
SELECT p.CMPNY
    ,  p.PurchaseOrder
    ,  p.VendorAccount
    ,  p.InvoiceID
    ,  p.InvoiceAmount
    -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.InvoiceAmount InvoiceAmount_USD
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.InvoiceAmount InvoiceAmount_EUR
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.InvoiceAmount InvoiceAmount_CNY
    ,  p.InvoiceDate
    ,  LineNumber
    ,  Item                      AS  ProductID
    ,  ProcurementCategory
    ,  Description
    ,  Quantity
    ,  Quantity_UoM
    ,  Quantity_LBs
    ,  Quantity_KGs
    ,  VIT_CURRENCYCODE
    ,  CHG_CURRENCYCODE
    ,  UnitPrice
    -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.UnitPrice UnitPrice_USD
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.UnitPrice UnitPrice_EUR
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.UnitPrice UnitPrice_CNY
    ,  Discount
    -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.Discount Discount_USD
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.Discount Discount_EUR
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.Discount Discount_CNY
    ,  DiscountPercent
    ,  LineAmount
     -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.LineAmount LineAmount_USD
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.LineAmount LineAmount_EUR
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.LineAmount LineAmount_CNY
   ,  SalesTaxIncluded
     -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.SalesTaxIncluded SalesTaxIncluded_USD
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.SalesTaxIncluded SalesTaxIncluded_EUR
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.SalesTaxIncluded SalesTaxIncluded_CNY
   ,  [1099Box]
    ,  [1099Amount]
    -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.[1099Amount] [1099Amount_USD]
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.[1099Amount] [1099Amount_EUR]
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.[1099Amount] [1099Amount_CNY]
    ,  StateProvince
    ,  [1099StateAmount]
    -- Txn basis (FROM p.vit_currencycode) 
    , CASE WHEN p.vit_currencycode = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * p.[1099StateAmount] [1099StateAmount_USD]
    , CASE WHEN p.vit_currencycode = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * p.[1099StateAmount] [1099StateAmount_EUR]
    , CASE WHEN p.vit_currencycode = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * p.[1099StateAmount] [1099StateAmount_CNY]
    ,  ReasonCode
    ,  ReasonComment
    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * FreightCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * FreightCharge ) END FreightCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * FreightCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * FreightCharge ) END FreightCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * FreightCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * FreightCharge ) END FreightCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * FreightCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * FreightCharge ) END FreightCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PalletCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PalletCharge ) END PalletCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PalletCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PalletCharge ) END PalletCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PalletCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PalletCharge ) END PalletCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PalletCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PalletCharge ) END PalletCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PetrolCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PetrolCharge ) END PetrolCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PetrolCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PetrolCharge ) END PetrolCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PetrolCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PetrolCharge ) END PetrolCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * PetrolCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * PetrolCharge ) END PetrolCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SalesTaxCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SalesTaxCharge ) END SalesTaxCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SalesTaxCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SalesTaxCharge ) END SalesTaxCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SalesTaxCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SalesTaxCharge ) END SalesTaxCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SalesTaxCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SalesTaxCharge ) END SalesTaxCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SetupFeeCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SetupFeeCharge ) END SetupFeeCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SetupFeeCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SetupFeeCharge ) END SetupFeeCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SetupFeeCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SetupFeeCharge ) END SetupFeeCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * SetupFeeCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * SetupFeeCharge ) END SetupFeeCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * ToteDepCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * ToteDepCharge ) END ToteDepCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * ToteDepCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * ToteDepCharge ) END ToteDepCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * ToteDepCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * ToteDepCharge ) END ToteDepCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * ToteDepCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * ToteDepCharge ) END ToteDepCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * OtherCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * OtherCharge ) END OtherCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * OtherCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * OtherCharge ) END OtherCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * OtherCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * OtherCharge ) END OtherCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * OtherCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * OtherCharge ) END OtherCharge_CNY

    ,  CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * TotalCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * TotalCharge ) END TotalCharge
    -- Charge basis (FROM p.chg_currencycode) 
    , CASE WHEN p.chg_currencycode = 'USD' THEN 1.0 ELSE erCHGUSD.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * TotalCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * TotalCharge ) END TotalCharge_USD
    , CASE WHEN p.chg_currencycode = 'EUR' THEN 1.0 ELSE erCHGEUR.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * TotalCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * TotalCharge ) END TotalCharge_EUR
    , CASE WHEN p.chg_currencycode = 'CNY' THEN 1.0 ELSE erCHGCNY.ExchangeRate END * CASE WHEN t.TotalQuantityLBs=0 THEN (((Quantity*1.0) / t.TotQty) * TotalCharge ) else (((Quantity_LBs*1.0) / t.TotalQuantityLBs) * TotalCharge ) END TotalCharge_CNY

	, ISNULL(dv.VendorKey, -1) VendorKey
	, ISNULL(dp.ProductKey, -1) ProductKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dpo.PurchaseOrderKey, -1)  PurchaseOrerKey
    , CONVERT(int, CONVERT(char(8), InvoiceDate, 112)) InvoiceDateKey

-- =========================== ADDED: currency-conversion audit columns ===========================
-- Rate_Missing flags: 1 when a NON-identity conversion found no matching rate row (else 0).
-- (Identity convert, e.g. source = target, never needs a rate, so it is never flagged missing.)
, CASE WHEN p.vit_currencycode <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_USD_Rate_Missing
, CASE WHEN p.vit_currencycode <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_EUR_Rate_Missing
, CASE WHEN p.vit_currencycode <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Txn_CNY_Rate_Missing
, CASE WHEN p.chg_currencycode <> 'USD' AND erCHGUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_USD_Rate_Missing
, CASE WHEN p.chg_currencycode <> 'EUR' AND erCHGEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_EUR_Rate_Missing
, CASE WHEN p.chg_currencycode <> 'CNY' AND erCHGCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END AS Cost_CNY_Rate_Missing
-- ================================================================================================

FROM prelim p
JOIN qty_totals t
  ON p.CMPNY = t.CMPNY
    AND p.PurchaseOrder = t.PurchaseOrder
    AND p.InvoiceID = t.InvoiceID


LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dv
	ON p.VendorAccount = dv.Vendor_ID
		AND p.CMPNY = dv.CMPNY
		AND dv.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON p.item = dp.Product_ID
		AND p.CMPNY = dp.CMPNY
		AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON p.CMPNY = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_PurchaseOrder dpo
	  ON p.PurchaseOrder = dpo.PurchaseOrderNumber
	    AND p.CMPNY = dpo.CMPNY
		AND dpo.RecordStatus=1

-- =========================== ADDED: exchange-rate joins (currency conversion) ===========================
-- TXN-BASIS joins: fromcurrencycode = vit_currencycode (transaction/document currency).
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON erTxnUSD.fromcurrencycode = p.vit_currencycode
   AND erTxnUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
   AND erTxnUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON erTxnEUR.fromcurrencycode = p.vit_currencycode
   AND erTxnEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
   AND erTxnEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON erTxnCNY.fromcurrencycode = p.vit_currencycode
   AND erTxnCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
   AND erTxnCNY.exchangeratetype = 'Default global rate'

-- CHARGE-BASIS joins: fromcurrencycode = chg_currencycode (markuptrans charges currency).
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCHGUSD
    ON erCHGUSD.fromcurrencycode = p.chg_currencycode
   AND erCHGUSD.tocurrencycode   = 'USD'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erCHGUSD.validfrom and erCHGUSD.validto
   AND erCHGUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCHGEUR
    ON erCHGEUR.fromcurrencycode = p.chg_currencycode
   AND erCHGEUR.tocurrencycode   = 'EUR'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erCHGEUR.validfrom and erCHGEUR.validto
   AND erCHGEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCHGCNY
    ON erCHGCNY.fromcurrencycode = p.chg_currencycode
   AND erCHGCNY.tocurrencycode   = 'CNY'
   AND convert(date, convert(char(8), p.InvoiceDate, 112)) between erCHGCNY.validfrom and erCHGCNY.validto
   AND erCHGCNY.exchangeratetype = 'Default global rate' 
-- ========================================================================================================


