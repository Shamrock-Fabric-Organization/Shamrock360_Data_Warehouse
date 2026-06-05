--use WH_Transform
--go



CREATE          VIEW [dbo].[vw_stage_DIM_SalesOrder_incoming]
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
            ,CAST(st.dataareaid AS VARCHAR(100))
            ,CAST(st.SALESID AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS SalesOrderKey,
    st.DATAAREAID                                       AS CMPNY,
    st.SALESID                                          AS SalesOrderId,

    -- -------------------------------------------------------
    -- Order Classification
    -- -------------------------------------------------------
    st.SALESTYPE SalesType,
    st.SALESTYPE_$label SalesTypeDesc, 
    st.SALESSTATUS SalesStatus,
    st.SALESSTATUS_$label SalesStatusDesc,
    st.DOCUMENTSTATUS DocumentStatus,
    st.DOCUMENTSTATUS_$label DocumentStatusDesc,

    -- -------------------------------------------------------
    -- Order Origin & Channel
    -- -------------------------------------------------------
    st.SALESORIGINID                                    AS SalesOriginId,
    st.SALESPOOLID                                      AS SalesPoolId,

    -- -------------------------------------------------------
    -- Delivery
    -- -------------------------------------------------------
    st.DLVMODE                                          AS DeliveryModeCode,
    ISNULL(dm.TXT, N'')                                 AS DeliveryModeDescription,

    st.DLVTERM                                          AS DeliveryTermCode,
    ISNULL(dt.TXT, N'')                                 AS DeliveryTermDescription,

    st.DELIVERYNAME                                     AS DeliveryName,
    st.DLVREASON                                        AS DeliveryReason,
    st.INVENTSITEID                                     AS SiteId,
    st.INVENTLOCATIONID                                 AS WarehouseId,

    -- -------------------------------------------------------
    -- Payment
    -- -------------------------------------------------------
    st.PAYMENT                                          AS PaymentTermId,
    ISNULL(pt.DESCRIPTION, N'')                         AS PaymentTermDescription,
    st.CURRENCYCODE                                     AS CurrencyCode,

    -- -------------------------------------------------------
    -- Sales Assignment
    -- -------------------------------------------------------
    --st.WORKERSALESRESPONSIBLE                           AS SalesResponsibleKey,     -- FK → DimSalesPerson.SalesPersonKey
    ISNULL(wr.PERSONNELNUMBER, N'')                     AS SalesResponsiblePersonnelNo,
    ISNULL(wrdp.NAME, N'')                              AS SalesResponsibleName,

    --st.WORKERSALESTAKER                                 AS SalesTakerKey,           -- FK → DimSalesPerson.SalesPersonKey
    ISNULL(wt.PERSONNELNUMBER, N'')                     AS SalesTakerPersonnelNo,
    ISNULL(wtdp.NAME, N'')                              AS SalesTakerName,

    -- -------------------------------------------------------
    -- Reference Numbers
    -- -------------------------------------------------------
    st.PURCHORDERFORMNUM                                AS CustomerPONumber,
    st.QUOTATIONID                                      AS QuotationId,
    st.PROJID                                           AS ProjectId,
    st.RETURNITEMNUM                                    AS ReturnItemNum,

    -- -------------------------------------------------------
    -- Key Dates
    -- -------------------------------------------------------
    CAST(st.CREATEDDATETIME  AS date)                   AS OrderCreatedDate,
    CAST(st.SHIPPINGDATEREQUESTED AS date)              AS ShippingDateRequested,
    CAST(st.SHIPPINGDATECONFIRMED AS date)              AS ShippingDateConfirmed,
    CAST(st.RECEIPTDATEREQUESTED  AS date)              AS ReceiptDateRequested,
    CAST(st.RECEIPTDATECONFIRMED  AS date)              AS ReceiptDateConfirmed,

    -- -------------------------------------------------------
    -- Audit
    -- -------------------------------------------------------
    st.CREATEDDATETIME                                  AS CreatedDateTime,
    st.MODIFIEDDATETIME                                 AS ModifiedDateTime

	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

from WH_Raw.dbo.salestable as st

left join WH_Raw.dbo.custtable as ct
    on  ct.accountnum  = st.custaccount
    and ct.dataareaid  = st.dataareaid

left join WH_Raw.dbo.dlvmode as dm
    on  dm.code        = st.dlvmode
    and dm.dataareaid  = st.dataareaid

left join WH_Raw.dbo.dlvterm as dt
    on  dt.code        = st.dlvterm
    and dt.dataareaid  = st.dataareaid

left join WH_Raw.dbo.paymterm as pt
    on  pt.paymtermid  = st.payment
    and pt.dataareaid  = st.dataareaid

left join WH_Raw.dbo.hcmworker as wr
    on  wr.recid       = st.workersalesresponsible

left join WH_Raw.dbo.dirpartytable as wrdp
    on  wrdp.recid     = wr.person

left join WH_Raw.dbo.hcmworker as wt
    on  wt.recid       = st.workersalestaker

left join WH_Raw.dbo.dirpartytable as wtdp
    on  wtdp.recid     = wt.person

UNION ALL

SELECT 
-1 SalesOrderKey
, 'Unknown' CMPNY
, 'Unknown' SalesOrderId
, NULL SalesType
, NULL SalesTypeDesc
, NULL SalesStatus
, NULL SalesStatusDesc
, NULL DocumentStatus
, NULL DocumentStatusDesc
, NULL SalesOriginId
, NULL SalesPoolId
, NULL DeliveryModeCode
, NULL DeliveryModeDescription
, NULL DeliveryTermCode
, NULL DeliveryTermDescription
, NULL DeliveryName
, NULL DeliveryReason
, NULL SiteId
, NULL WarehouseId
, NULL PaymentTermId
, NULL PaymentTermDescription
, NULL CurrencyCode
, NULL SalesResponsiblePersonnelNo
, NULL SalesResponsibleName
, NULL SalesTakerPersonnelNo
, NULL SalesTakerName
, NULL CustomerPONumber
, NULL QuotationId
, NULL ProjectId
, NULL ReturnItemNum
, NULL OrderCreatedDate
, NULL ShippingDateRequested
, NULL ShippingDateConfirmed
, NULL ReceiptDateRequested
, NULL ReceiptDateConfirmed
, NULL CreatedDateTime
, NULL ModifiedDateTime
, NULL Source
, NULL RecordEffectiveStartDate
, NULL RecordEffectiveEndDate
, NULL RecordStatus

GO

