-- Auto Generated (Do not modify) 611781E98EA7A5BA3950BDAFFCB19FBADFB166DD3531CF832D6A786220533605
/****** Object:  View [dbo].[tbl_Fact_ProjectPostedTransactions]    Script Date: 3/31/2026 9:00:23 AM ******/
--USE WH_Transform

CREATE OR ALTER VIEW [dbo].[tbl_Fact_ProjectPostedTransactions]
as

/*
=============================================================================
CWIP — InvoiceStatus per Posted Transaction
Replicates D365 F&SCM X++ ProjPostTrans.invoiceStatus() display method logic
including the full isBillingRuleInvoiceable() implementation.

Client:   Shamrock
Platform: Microsoft Fabric Warehouse (Fabric Link export)
Date:     2026-03-27

X++ DECISION LOGIC (applied in order):
  1.  Adjusted sale record exists?                   → 'Adjusted'
  2.  Project type ≠ TimeMaterial?                   → 'Nonchargeable'
  3.  LineProperty.ToBeInvoiced ≠ Yes?               → 'Nonchargeable'
  4.  No sale records at all?                        → 'Nonchargeable'
  5.  Invoiced + remaining chargeable + OnHold?      → 'PartiallyInvoicedWithOnhold'
  6.  Invoiced + remaining chargeable?               → 'PartiallyInvoiced'
  7.  Invoiced + nothing chargeable + OnHold?        → 'FullyInvoicedWithOnhold'
  8.  Invoiced + nothing chargeable?                 → 'FullyInvoiced'
  9.  Not invoiced + chargeable funding exists?      → isBillingRuleInvoiceable()
        → 'Chargeable' or 'Nonchargeable' (see full logic below)
 10.  Otherwise                                      → 'Nonchargeable'

isBillingRuleInvoiceable() — path used: isBillingRuleInvoiceableWithProjType
  (Multiple Contract Lines feature confirmed OFF for Shamrock)

  TimeMaterial projects:
    a. No contract (ProjInvoiceProjId empty)         → Nonchargeable
    b. CategoryType = None (OnAccount, no category)  → Chargeable
    c. No billing rules on contract                  → Chargeable
    d. Billing rules exist:
       - Category in T&M contract line setup         → Chargeable
       - Category in UOD/Progress/Fee billing rule   → Chargeable
       - Retention category                          → Chargeable
       - Otherwise                                   → Nonchargeable

  FixedPrice projects (note: already caught by Step 2 as Nonchargeable
  unless they reach Step 9 via a different path — included for completeness):
    - With billing rules: Revenue + contractBillingRule → Chargeable
    - With billing rules: OnAccount only              → Chargeable
    - Without billing rules: OnAccount only           → Chargeable
    - Retention category                              → Chargeable
    - Otherwise                                       → Nonchargeable

SALE TABLE MAP (MCP-verified):
  Hour (0)      ProjEmplTransSale     join on TransId
  Item (1)      ProjItemTransSale     join on ProjTransId  ← different column!
  Cost (2)      ProjCostTransSale     join on TransId
  Revenue (3)   ProjRevenueTransSale  join on TransId
  OnAccount (4) ProjOnAccTransSale    join on TransId

 VERIFY IN FABRIC AS MORE DATA IS AVAILABLE:
  - TransStatus_$label: currently only 'Posted' observed — verify others as data grows
  - FundingType_$label: ProjFundingSource empty — verify 'Customer','Grant',
    'OnHoldFundingSource' labels when data is available
  - LineType_$label on PSAContractLineItems: table empty — using assumed standard
    labels 'TAndM','UnitOfDelivery','Progress','Fee'. Run validation query #3 when data arrives.
  - CategoryType_$label on ProjCategory: confirm 'None' label via validation query #4
=============================================================================
*/

WITH

-- ============================================================
-- CTE 1: Base posted transactions
-- ============================================================
base AS (
    SELECT
        pptt.DataAreaId,
        pptt.TransId,
        pptt.ProjId,
        pptt.TransDate,
        pptt.ProjTransType_$label       AS TransType,
        pptt.CategoryId,
        pptt.ItemId,
        pptt.resource,
        pptt.LinePropertyId,
        pptt.PSAContractLineNum,        -- needed for billing rule UOD/Progress/Fee check
        pptt.ResourceName,
        pptt.VendorAccount,
        pptt.VendorName,
        pptt.Qty,
        pptt.TotalCostAmountCur,
        pptt.TotalSalesAmountCur,
        pptt.currencyid 
    FROM WH_Raw.dbo.projpostedtranstable pptt
),

-- ============================================================
-- CTE 2: Project attributes
-- ============================================================
proj AS (
    SELECT
        pt.DataAreaId,
        pt.ProjId,
        pt.Name                         AS ProjectName,
        pt.Type_$label                  AS ProjectType,
        pt.ProjInvoiceProjId            AS ContractId
    FROM WH_Raw.dbo.projtable pt
),

-- ============================================================
-- CTE 3: Line property — ToBeInvoiced flag
-- ============================================================
lineprop AS (
    SELECT
        lp.DataAreaId,
        lp.LinePropertyId,
        lp.ToBeInvoiced                 -- 1 = Yes (eligible), 0 = No
    FROM WH_Raw.dbo.projlineproperty lp
),

-- ============================================================
-- CTE 4: Project category — CategoryType drives billing rule eligibility
-- ============================================================
category AS (
    SELECT
        pc.DataAreaId,
        pc.CategoryId,
        pc.CategoryType_$label          AS CategoryType,
        pc.PsaCustPaymentRetention      -- 1 = retention category (always invoiceable)
    FROM WH_Raw.dbo.projcategory pc
),

-- ============================================================
-- CTE 5: All sale records — UNION across all 5 transaction types
--         ⚠ ProjItemTransSale uses ProjTransId, not TransId
-- ============================================================
sale_records AS (
    SELECT DataAreaId, TransId          AS TransId, TransStatus_$label, FundingSource FROM WH_Raw.dbo.projcosttranssale
    UNION ALL
    SELECT DataAreaId, TransId          AS TransId, TransStatus_$label, FundingSource FROM WH_Raw.dbo.projempltranssale
    UNION ALL
    SELECT DataAreaId, ProjTransId      AS TransId, TransStatus_$label, FundingSource FROM WH_Raw.dbo.projitemtranssale
    UNION ALL
    SELECT DataAreaId, TransId          AS TransId, TransStatus_$label, FundingSource FROM WH_Raw.dbo.projrevenuetranssale
    UNION ALL
    SELECT DataAreaId, TransId          AS TransId, TransStatus_$label, FundingSource FROM WH_Raw.dbo.projonacctranssale
),

-- ============================================================
-- CTE 6: Aggregate status flags per transaction
-- ============================================================
sale_flags AS (
    SELECT
        sr.DataAreaId,
        sr.TransId,

        MAX(CASE
            WHEN sr.TransStatus_$label = 'Adjusted'
            THEN 1 ELSE 0
        END)                                                            AS IsAdjusted,

        MAX(CASE
            WHEN sr.TransStatus_$label IN (
                'Invoiced', 'MarkedCreditnote', 'CreditnoteProposal'
            )
            THEN 1 ELSE 0
        END)                                                            AS IsInvoiced,

        MAX(CASE
            WHEN sr.TransStatus_$label IN ('Posted', 'InvoiceProposal')
             AND fs.FundingType_$label IN ('Customer', 'Grant')
            THEN 1 ELSE 0
        END)                                                            AS IsChargeable,

        MAX(CASE
            WHEN sr.TransStatus_$label IN (
                'Invoiced', 'MarkedCreditnote', 'CreditnoteProposal'
            )
             AND fs.FundingType_$label = 'OnHoldFundingSource'
            THEN 1 ELSE 0
        END)                                                            AS IsOnHold

    FROM sale_records sr
    LEFT JOIN WH_Raw.dbo.projfundingsource fs ON fs.RecId = sr.FundingSource
    GROUP BY sr.DataAreaId, sr.TransId
),

-- ============================================================
-- CTE 7: Billing rule existence check per contract
--         (PSAContractLineItems::hasBillingRules)
--         Currently empty for Shamrock — logic degrades gracefully
--         to Chargeable until billing rules are configured.
-- ============================================================
contract_has_billing_rules AS (
    SELECT DISTINCT
        cli.DataAreaId,
        cli.ProjInvoiceProjId
    FROM WH_Raw.dbo.psacontractlineitems cli
),

-- ============================================================
-- CTE 8: T&M billing rule category setup
--         Categories explicitly included as chargeable in a T&M contract line.
--         PSAContractLineItemsSetup (project+category) joined to
--         PSAContractLineItems (T&M line type).
--         ⚠ LineType_$label = 'TAndM' — verify when table has data
-- ============================================================
tm_category_in_billing_rule AS (
    SELECT
        s.DataAreaId,
        s.ProjId,
        s.CategoryId
    FROM WH_Raw.dbo.psacontractlineitemssetup s
    INNER JOIN WH_Raw.dbo.psacontractlineitems cli
        ON  cli.ContractLineNum     = s.ContractLineNum
        AND cli.DataAreaId          = s.DataAreaId
        AND cli.LineType_$label     = 'TAndM'           -- ⚠ verify label
),

-- ============================================================
-- CTE 9: UOD / Progress / Fee billing rule lines
--         Used when a transaction is linked to a specific contract line
--         via PSAContractLineNum and matches the fee project+category.
--         ⚠ LineType_$label values — verify when table has data
-- ============================================================
fee_billing_rule_lines AS (
    SELECT
        cli.DataAreaId,
        cli.ProjInvoiceProjId,
        cli.ContractLineNum,
        cli.FeeProjId,
        cli.FeeCategoryId
    FROM WH_Raw.dbo.psacontractlineitems cli
    WHERE cli.LineType_$label IN ('UnitOfDelivery', 'Progress', 'Fee')  -- ⚠ verify labels
),

-- ============================================================
-- CTE 10: Retention categories (always invoiceable regardless of billing rules)
-- ============================================================
retention_categories AS (
    SELECT
        pc.DataAreaId,
        pc.CategoryId
    FROM WH_Raw.dbo.projcategory pc
    WHERE pc.PsaCustPaymentRetention = 1
)

-- ============================================================
-- FINAL: One row per transaction with InvoiceStatus
-- ============================================================

SELECT
    -- Identity
    b.DataAreaId CMPNY,
    b.ProjId,
    b.TransDate TransactionDate,
    convert(int, convert(char(8), b.TransDate, 112)) TransactionDateKey,
    b.CategoryId,
    wct.name ResourceName,
    b.ItemId,
    b.TotalSalesAmountCur TotalSalesAmount,
    -- >>> ADDED (Txn basis, FROM b.currencyid): TotalSalesAmount in USD / EUR / CNY
    CASE WHEN b.currencyid = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * b.TotalSalesAmountCur  AS TotalSalesAmount_USD,
    CASE WHEN b.currencyid = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * b.TotalSalesAmountCur  AS TotalSalesAmount_EUR,
    CASE WHEN b.currencyid = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * b.TotalSalesAmountCur  AS TotalSalesAmount_CNY,
    b.TotalCostAmountCur AmountInTransaction,
    -- >>> ADDED (Txn basis, FROM b.currencyid): AmountInTransaction in USD / EUR / CNY
    CASE WHEN b.currencyid = 'USD' THEN 1.0 ELSE erTxnUSD.ExchangeRate END * b.TotalCostAmountCur  AS AmountInTransaction_USD,
    CASE WHEN b.currencyid = 'EUR' THEN 1.0 ELSE erTxnEUR.ExchangeRate END * b.TotalCostAmountCur  AS AmountInTransaction_EUR,
    CASE WHEN b.currencyid = 'CNY' THEN 1.0 ELSE erTxnCNY.ExchangeRate END * b.TotalCostAmountCur  AS AmountInTransaction_CNY,
    --b.TotalCostAmountCur TotalCostAmount,
    CASE WHEN b.currencyid = l.accountingcurrency THEN 1.0 ELSE er.ExchangeRate END * b.TotalCostAmountCur  TotalCostAmount,  --Converted to LegalEntity currency
    -- >>> ADDED (Cost/MST basis, FROM l.accountingcurrency): TotalCostAmount in USD / EUR / CNY
    --     TotalCostAmount is already expressed in the legal-entity accounting currency
    --     (the existing `er` conversion above), so we step it FROM l.accountingcurrency
    --     onward to each target via the erCost* joins. Identity guard handles e.g. USD->USD.
    CASE WHEN l.accountingcurrency = 'USD' THEN 1.0 ELSE erCostUSD.ExchangeRate END
        * (CASE WHEN b.currencyid = l.accountingcurrency THEN 1.0 ELSE er.ExchangeRate END * b.TotalCostAmountCur)  AS TotalCostAmount_USD,
    CASE WHEN l.accountingcurrency = 'EUR' THEN 1.0 ELSE erCostEUR.ExchangeRate END
        * (CASE WHEN b.currencyid = l.accountingcurrency THEN 1.0 ELSE er.ExchangeRate END * b.TotalCostAmountCur)  AS TotalCostAmount_EUR,
    CASE WHEN l.accountingcurrency = 'CNY' THEN 1.0 ELSE erCostCNY.ExchangeRate END
        * (CASE WHEN b.currencyid = l.accountingcurrency THEN 1.0 ELSE er.ExchangeRate END * b.TotalCostAmountCur)  AS TotalCostAmount_CNY,
    -- =========================================================
    -- InvoiceStatus — full X++ logic in set-based SQL
    -- =========================================================
    CASE
        -- Step 1: Adjusted always wins
        WHEN sf.TransId IS NOT NULL AND sf.IsAdjusted = 1
            THEN 'Adjusted'

        -- Step 2: Non-TimeMaterial projects are never client-invoiceable
        WHEN p.ProjectType IS NULL OR p.ProjectType <> 'TimeMaterial'
            THEN 'Nonchargeable'

        -- Step 3: Line property must be flagged for invoicing
        WHEN lineprop.ToBeInvoiced IS NULL OR lineprop.ToBeInvoiced = 0
            THEN 'Nonchargeable'

        -- Step 4: No sale records — transaction not yet processed
        WHEN sf.TransId IS NULL
            THEN 'Nonchargeable'

        -- Steps 5–8: Invoice status combinations
        WHEN sf.IsInvoiced = 1 AND sf.IsChargeable = 1 AND sf.IsOnHold = 1
            THEN 'PartiallyInvoicedWithOnhold'

        WHEN sf.IsInvoiced = 1 AND sf.IsChargeable = 1
            THEN 'PartiallyInvoiced'

        WHEN sf.IsInvoiced = 1 AND sf.IsChargeable = 0 AND sf.IsOnHold = 1
            THEN 'FullyInvoicedWithOnhold'

        WHEN sf.IsInvoiced = 1 AND sf.IsChargeable = 0
            THEN 'FullyInvoiced'

        -- Step 9: Not invoiced + chargeable funding
        --         → isBillingRuleInvoiceableWithProjType() logic
        WHEN sf.IsInvoiced = 0 AND sf.IsChargeable = 1
            THEN CASE

                -- 9a. No contract assigned → not invoiceable
                WHEN p.ContractId IS NULL OR p.ContractId = ''
                    THEN 'Nonchargeable'

                -- 9b. CategoryType = None (OnAccount / no category) → always invoiceable
                --     Verified Shamrock labels: Cost=3, Item=4.
                --     'None' (type 0) not present in Shamrock data — IS NULL covers
                --     OnAccount transactions where CategoryId is empty and the
                --     LEFT JOIN to projcategory returns no match.
                WHEN cat.CategoryType IS NULL OR cat.CategoryType = 'None'
                    THEN 'Chargeable'

                -- 9c. No billing rules on this contract → invoiceable
                --     (currently always true while PSAContractLineItems is empty)
                WHEN cbr.ProjInvoiceProjId IS NULL
                    THEN 'Chargeable'

                -- 9d. Billing rules exist — check category-level eligibility:

                -- Retention category → always invoiceable
                WHEN rc.CategoryId IS NOT NULL
                    THEN 'Chargeable'

                -- Category included in a T&M billing rule contract line setup
                WHEN tmc.CategoryId IS NOT NULL
                    THEN 'Chargeable'

                -- Category matches a UOD/Progress/Fee billing rule for this contract line
                WHEN b.PSAContractLineNum <> ''
                     AND fbr.ContractLineNum IS NOT NULL
                    THEN 'Chargeable'

                -- Billing rules exist but category is not included
                ELSE 'Nonchargeable'

            END

        -- Step 10: Default
        ELSE 'Nonchargeable'

    END                                                                  AS InvoiceStatus,

    b.TransType,
    b.currencyid TransCurrencyCode,
    l.accountingcurrency LegalEntityCurrencyCode,
    -- >>> ADDED audit columns: explicit FROM-currency per conversion basis
    b.currencyid          AS Txn_Source_Currency,    -- Txn basis FROM currency
    l.accountingcurrency  AS Cost_Source_Currency,   -- Cost/MST basis FROM currency
    -- >>> ADDED Rate_Missing flags (1 = a non-identity conversion had no matching rate)
    CASE WHEN b.currencyid <> 'USD' AND erTxnUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Txn_USD_Rate_Missing,
    CASE WHEN b.currencyid <> 'EUR' AND erTxnEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Txn_EUR_Rate_Missing,
    CASE WHEN b.currencyid <> 'CNY' AND erTxnCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Txn_CNY_Rate_Missing,
    CASE WHEN l.accountingcurrency <> 'USD' AND erCostUSD.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Cost_USD_Rate_Missing,
    CASE WHEN l.accountingcurrency <> 'EUR' AND erCostEUR.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Cost_EUR_Rate_Missing,
    CASE WHEN l.accountingcurrency <> 'CNY' AND erCostCNY.ExchangeRate IS NULL THEN 1 ELSE 0 END  AS Cost_CNY_Rate_Missing,
    --b.VendorAccount,
    --b.VendorName,

    --Additional attributes that may be remved or excluded
    --p.ProjectName,  --in dimension
    --p.ContractId,  --in dimension
    --p.ProjectType,  --in dimension
    b.TransId,

    --b.LinePropertyId,
    --lineprop.ToBeInvoiced,
    --b.PSAContractLineNum,
    --b.ResourceName,  --in dimension
    b.Qty,

    ------ Raw flags (useful for debugging / validation)
    ----CASE WHEN sf.TransId IS NULL THEN 0 ELSE sf.IsAdjusted   END        AS IsAdjusted,
    ----CASE WHEN sf.TransId IS NULL THEN 0 ELSE sf.IsInvoiced   END        AS IsInvoiced,
    ----CASE WHEN sf.TransId IS NULL THEN 0 ELSE sf.IsChargeable END        AS IsChargeable,
    ----CASE WHEN sf.TransId IS NULL THEN 0 ELSE sf.IsOnHold     END        AS IsOnHold,

    ------ Billing rule diagnostic flags (all 0 while PSAContractLineItems is empty)
    ----CASE WHEN cbr.ProjInvoiceProjId IS NOT NULL THEN 1 ELSE 0 END       AS ContractHasBillingRules,
    ----CASE WHEN tmc.CategoryId        IS NOT NULL THEN 1 ELSE 0 END       AS CategoryInTMBillingRule,
    ----CASE WHEN fbr.ContractLineNum   IS NOT NULL THEN 1 ELSE 0 END       AS CategoryInFeeBillingRule,
    ----CASE WHEN rc.CategoryId         IS NOT NULL THEN 1 ELSE 0 END       AS IsRetentionCategory


    ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey,
    ISNULL(dpj.ProjectKey, -1) ProjectKey,
    ISNULL(dp.ProductKey, -1) ProductKey,
	ISNULL(dwc.WorkCenterKey, -1) WorkCenterKey,
    ISNULL(dv.VendorKey, -1) VendorKey

FROM base b
INNER JOIN proj p
    ON  p.ProjId      = b.ProjId
    AND p.DataAreaId  = b.DataAreaId
JOIN WH_Raw.dbo.ledger l
    on b.dataareaid = l.name
LEFT JOIN lineprop
    ON  lineprop.LinePropertyId = b.LinePropertyId
    AND lineprop.DataAreaId     = b.DataAreaId
LEFT JOIN category cat
    ON  cat.CategoryId   = b.CategoryId
    AND cat.DataAreaId   = b.DataAreaId
LEFT JOIN sale_flags sf
    ON  sf.TransId    = b.TransId
    AND sf.DataAreaId = b.DataAreaId
LEFT JOIN contract_has_billing_rules cbr
    ON  cbr.ProjInvoiceProjId = p.ContractId
    AND cbr.DataAreaId        = b.DataAreaId
LEFT JOIN tm_category_in_billing_rule tmc
    ON  tmc.ProjId     = b.ProjId
    AND tmc.CategoryId = b.CategoryId
    AND tmc.DataAreaId = b.DataAreaId
LEFT JOIN fee_billing_rule_lines fbr
    ON  fbr.ProjInvoiceProjId = p.ContractId
    AND fbr.FeeProjId         = b.ProjId
    AND fbr.FeeCategoryId     = b.CategoryId
    AND fbr.ContractLineNum   = b.PSAContractLineNum
    AND fbr.DataAreaId        = b.DataAreaId
LEFT JOIN retention_categories rc
    ON  rc.CategoryId  = b.CategoryId
    AND rc.DataAreaId  = b.DataAreaId
LEFT JOIN WH_Raw.dbo.wrkctrtable wct
    ON b.resource = wct.recid


LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON b.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON b.itemid = dp.Product_ID
		AND b.dataareaid = dp.CMPNY
		AND dp.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Project dpj
	ON b.ProjId = dpj.ProjID
		AND b.dataareaid = dpj.CMPNY
		AND dpj.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkCenter dwc
	ON wct.wrkctrid = dwc.WorkCenterID
		AND wct.dataareaid = dwc.CMPNY
		AND dwc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dv
	ON b.VendorAccount = dv.Vendor_ID
		AND b.dataareaid = dv.CMPNY
		AND dv.RecordStatus=1

LEFT JOIN WH_Raw.dbo.vwExchangeRate er
    ON er.fromcurrencycode = b.currencyid
        AND er.tocurrencycode = l.accountingcurrency
        AND convert(date, convert(char(8), b.TransDate, 112)) between er.validfrom and er.validto
        AND er.exchangeratetype = 'Default global rate'

-- =============================================================================
-- >>> ADDED RATE JOINS (additive) — mirror the canonical `er` join above.
--     Same date normalization, same exchangeratetype, same vwExchangeRate source.
--
--     TXN-BASIS set (fromcurrencycode = b.currencyid): drives TotalSalesAmount_*
--     and AmountInTransaction_*. Shared by all txn-basis money columns.
-- =============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnUSD
    ON erTxnUSD.fromcurrencycode = b.currencyid
        AND erTxnUSD.tocurrencycode = 'USD'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erTxnUSD.validfrom and erTxnUSD.validto
        AND erTxnUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnEUR
    ON erTxnEUR.fromcurrencycode = b.currencyid
        AND erTxnEUR.tocurrencycode = 'EUR'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erTxnEUR.validfrom and erTxnEUR.validto
        AND erTxnEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erTxnCNY
    ON erTxnCNY.fromcurrencycode = b.currencyid
        AND erTxnCNY.tocurrencycode = 'CNY'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erTxnCNY.validfrom and erTxnCNY.validto
        AND erTxnCNY.exchangeratetype = 'Default global rate'

-- =============================================================================
--     COST/MST-BASIS set (fromcurrencycode = l.accountingcurrency): drives
--     TotalCostAmount_* (cost already converted INTO l.accountingcurrency by `er`).
--     Shared by all cost-basis money columns.
-- =============================================================================
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostUSD
    ON erCostUSD.fromcurrencycode = l.accountingcurrency
        AND erCostUSD.tocurrencycode = 'USD'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erCostUSD.validfrom and erCostUSD.validto
        AND erCostUSD.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostEUR
    ON erCostEUR.fromcurrencycode = l.accountingcurrency
        AND erCostEUR.tocurrencycode = 'EUR'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erCostEUR.validfrom and erCostEUR.validto
        AND erCostEUR.exchangeratetype = 'Default global rate'
LEFT JOIN WH_Raw.dbo.vwExchangeRate erCostCNY
    ON erCostCNY.fromcurrencycode = l.accountingcurrency
        AND erCostCNY.tocurrencycode = 'CNY'
        AND convert(date, convert(char(8), b.TransDate, 112)) between erCostCNY.validfrom and erCostCNY.validto
        AND erCostCNY.exchangeratetype = 'Default global rate'

