-- Auto Generated (Do not modify) 99BF34920BC503195DC0D7F9DC620A9191A1139A2F0DFFD76358665A9FADD974

----drop VIEW [dbo].[vw_stage_DIM_CustomerPackingSlip_incoming]

CREATE          VIEW [dbo].[vw_stage_DIM_CustomerPackingSlip_incoming]
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
            ,CAST(cpsj.dataareaid AS VARCHAR(100))
            ,CAST(cpsj.PACKINGSLIPID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS CustomerPackingSlipKey
    -- Natural Key
    , cpsj.DATAAREAID                            AS CMPNY
    , cpsj.PACKINGSLIPID                         AS CustomerPackingSlipId
    , cpsj.SALESID                               AS SalesId

    -- Dates
    , CAST(cpsj.DELIVERYDATE  AS DATE)           AS ShipDate
    , CAST(cpsj.DOCUMENTDATE  AS DATE)           AS DocumentDate

    -- Customer
    , cpsj.ORDERACCOUNT                          AS CustomerAccount
    , cpsj.INVOICEACCOUNT                        AS InvoiceAccount
    , cpsj.PURCHASEORDER                         AS CustomerPO

    -- Shipping
    , cpsj.DELIVERYNAME                          AS ShipToName
    , cpsj.DLVMODE                               AS DeliveryMode
    , cpsj.DLVTERM                               AS DeliveryTerms
    , cpsj.DLVREASON                             AS DeliveryReason
    , cpsj.INVENTLOCATIONID                      AS ShipFromWarehouse
    , cpsj.SHIPCARRIERID                         AS CarrierId

    -- Audit
    , cpsj.CREATEDDATETIME                       AS CreatedDateTime

   	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus

FROM WH_Raw.dbo.CustPackingSlipJour cpsj

UNION ALL

SELECT 
-1 CustomerPackingSlipKey
, 'Unknown' CMPNY
, 'Unknown' CustomerPackingSlipId
, NULL SalesId
, NULL ShipDate
, NULL DocumentDate
, NULL CustomerAccount
, NULL InvoiceAccount
, NULL CustomerPO
, NULL ShipToName
, NULL DeliveryMode
, NULL DeliveryTerms
, NULL DeliveryReason
, NULL ShipFromWarehouse
, NULL CarrierID
, NULL CreatedDateTime
, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]