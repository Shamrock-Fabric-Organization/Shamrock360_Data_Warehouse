
CREATE OR ALTER VIEW [dbo].[vw_stage_DIM_Invoice_incoming]
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
            ,CAST(cij.dataareaid AS VARCHAR(100))
            ,CAST(cij.invoiceid AS VARCHAR(100))
            ,CAST(cij.invoicedate AS VARCHAR(100))
            ,CAST(cij.salesid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS InvoiceKey,
    cij.dataareaid                                      AS CMPNY,
    cij.invoiceid                                       AS Invoice_ID,
    cij.invoicedate                                     AS InvoiceDate,
    ISNULL(CASE WHEN cij.salesid = '' THEN NULL ELSE cij.salesid END, 'none') AS Sales_ID,   -- a blank counts as NULL. The D365 link can store a blank as '' instead of NULL.

    cij.orderaccount                                    AS Order_Account,
    cij.invoiceaccount                                  AS Invoice_Account,
    cij.custgroup                                       AS CustomerGroup,

    cij.customerref                                     AS CustomerRef,
    cij.purchaseorder                                   AS CustomerPONumber,
    cij.documentnum                                     AS DocumentNum,
    cij.billofladingid                                  AS BillOfLadingId,
    cij.ledgervoucher                                   AS LedgerVoucher,
    cij.salesoriginid                                   AS SalesOriginId,

    CAST(cij.salestype AS bigint)                       AS SalesType,
    cij.salestype_$label                                AS SalesTypeDesc,
    CAST(cij.refnum AS bigint)                          AS ReferenceType,
    cij.refnum_$label                                   AS ReferenceTypeDesc,
    CAST(cij.postedstate AS bigint)                     AS PostedStateID,
    cij.postedstate_$label                              AS PostedState,
    cij.iscorrection_$label                             AS IsCorrection,
    cij.proforma_$label                                 AS IsProforma,
    cij.prepayment_$label                               AS IsPrepayment,

    cij.currencycode                                    AS CurrencyCode,
    cij.taxgroup                                        AS Tax_Group,
    cij.postingprofile                                  AS PostingProfile,

    cij.payment                                         AS PaymentTermId,
    ISNULL(pt.DESCRIPTION, N'')                         AS PaymentTermDescription,
    CAST(cij.documentdate AS date)                      AS DocumentDate,
    CAST(cij.duedate AS date)                           AS DueDate,

    cij.dlvmode                                         AS DeliveryModeCode,
    ISNULL(dm.TXT, N'')                                 AS DeliveryModeDescription,
    cij.dlvterm                                         AS DeliveryTermCode,
    ISNULL(dt.TXT, N'')                                 AS DeliveryTermDescription,
    cij.deliveryname                                    AS DeliveryName,

    cij.createddatetime                                 AS CreatedDateTime,
    cij.modifieddatetime                                AS ModifiedDateTime

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

from WH_Raw.dbo.custinvoicejour as cij

left join WH_Raw.dbo.paymterm as pt
    on  pt.paymtermid  = cij.payment
    and pt.dataareaid  = cij.dataareaid

left join WH_Raw.dbo.dlvmode as dm
    on  dm.code        = cij.dlvmode
    and dm.dataareaid  = cij.dataareaid

left join WH_Raw.dbo.dlvterm as dt
    on  dt.code        = cij.dlvterm
    and dt.dataareaid  = cij.dataareaid

UNION ALL

SELECT 
-1 InvoiceKey
, 'Unknown' CMPNY
, 'Unknown' Invoice_ID
, CAST('1900-01-01' AS DATETIME2(6)) InvoiceDate
, 'Unknown' Sales_ID
, NULL Order_Account
, NULL Invoice_Account
, NULL CustomerGroup
, NULL CustomerRef
, NULL CustomerPONumber
, NULL DocumentNum
, NULL BillOfLadingId
, NULL LedgerVoucher
, NULL SalesOriginId
, NULL SalesType
, NULL SalesTypeDesc
, NULL ReferenceType
, NULL ReferenceTypeDesc
, NULL PostedStateID
, NULL PostedState
, NULL IsCorrection
, NULL IsProforma
, NULL IsPrepayment
, NULL CurrencyCode
, NULL Tax_Group
, NULL PostingProfile
, NULL PaymentTermId
, NULL PaymentTermDescription
, NULL DocumentDate
, NULL DueDate
, NULL DeliveryModeCode
, NULL DeliveryModeDescription
, NULL DeliveryTermCode
, NULL DeliveryTermDescription
, NULL DeliveryName
, NULL CreatedDateTime
, NULL ModifiedDateTime
, NULL Source
, NULL RecordEffectiveStartDate
, NULL RecordEffectiveEndDate
, NULL RecordStatus
