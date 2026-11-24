

CREATE OR ALTER VIEW [dbo].[vw_stage_DIM_InvoiceCharge_incoming]
as
SELECT

    -- -------------------------------------------------------
    -- Keys
    -- -------------------------------------------------------
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(codes.dataareaid AS VARCHAR(100))
            ,CAST(codes.markupcode AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS InvoiceChargeKey,
    codes.dataareaid                                    AS CMPNY,
    codes.markupcode                                    AS MarkupCode,

    ISNULL(CASE WHEN mtb.txt = N'' THEN NULL ELSE mtb.txt END, ISNULL(codes.txt, N'')) AS ChargeDescription, 
    mtb.taxitemgroup                                    AS TaxItemGroup,
    CAST(mtb.maxamount AS decimal(38,6))                AS MaxAmount,
    CAST(mtb.isshipping AS bigint)                      AS IsShipping,
    CAST(mtb.refundable AS bigint)                      AS IsRefundable,
    CASE WHEN mtb.recid IS NULL THEN 0 ELSE 1 END       AS InMarkupTable

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

from (
    -- Distinct charge codes that appear on customer invoice journals (transtableid 11259 = CustInvoiceJour).
    -- MAX(txt) keeps the text typed on the transaction, used only when markuptable has no row for the code.
    select mt.dataareaid
         , mt.markupcode
         , max(mt.txt) as txt
    from WH_Raw.dbo.markuptrans as mt
    where mt.transtableid = 11259
      and mt.markupcode is not null
    group by mt.dataareaid, mt.markupcode
    ) as codes

left join WH_Raw.dbo.markuptable as mtb
    on  mtb.dataareaid = codes.dataareaid
    and mtb.markupcode = codes.markupcode
    and mtb.moduletype = 1      -- 1 = Cust (customer module)

UNION ALL

SELECT 
-1 InvoiceChargeKey
, 'Unknown' CMPNY
, 'Unknown' MarkupCode
, NULL ChargeDescription
, NULL TaxItemGroup
, NULL MaxAmount
, NULL IsShipping
, NULL IsRefundable
, NULL InMarkupTable
, NULL Source
, NULL RecordEffectiveStartDate
, NULL RecordEffectiveEndDate
, NULL RecordStatus
