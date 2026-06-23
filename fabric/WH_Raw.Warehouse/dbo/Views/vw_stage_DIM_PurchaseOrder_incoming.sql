-- Auto Generated (Do not modify) 394FEC492A053B0436905570A5BF86AA3D1494E16CF48803E26AB42BD262C475

/****** Object:  View [dbo].[vw_stage_DIM_PurchaseOrder_incoming]    Script Date: 2/3/2026 10:36:37 AM ******/



--drop  VIEW dbo.[vw_stage_DIM_PurchaseOrder_incoming]	

CREATE   VIEW [dbo].[vw_stage_DIM_PurchaseOrder_incoming]
as
WITH Numbers AS (
    -- Generate numbers 1-500 (adjust max length as needed)
    SELECT n FROM (VALUES 
        (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
        (21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
        (41),(42),(43),(44),(45),(46),(47),(48),(49),(50),(51),(52),(53),(54),(55),(56),(57),(58),(59),(60),
        (61),(62),(63),(64),(65),(66),(67),(68),(69),(70),(71),(72),(73),(74),(75),(76),(77),(78),(79),(80),
        (81),(82),(83),(84),(85),(86),(87),(88),(89),(90),(91),(92),(93),(94),(95),(96),(97),(98),(99),(100),
        (101),(102),(103),(104),(105),(106),(107),(108),(109),(110),(111),(112),(113),(114),(115),(116),(117),(118),(119),(120),
        (121),(122),(123),(124),(125),(126),(127),(128),(129),(130),(131),(132),(133),(134),(135),(136),(137),(138),(139),(140),
        (141),(142),(143),(144),(145),(146),(147),(148),(149),(150),(151),(152),(153),(154),(155),(156),(157),(158),(159),(160),
        (161),(162),(163),(164),(165),(166),(167),(168),(169),(170),(171),(172),(173),(174),(175),(176),(177),(178),(179),(180),
        (181),(182),(183),(184),(185),(186),(187),(188),(189),(190),(191),(192),(193),(194),(195),(196),(197),(198),(199),(200)
    ) AS Numbers(n)
),
CharacterProcessing AS (
    SELECT 
        dpt.RECID,
        dpt.NAME as OriginalName,
        n as Position,
        SUBSTRING(dpt.NAME, n, 1) as CurrentChar,
        CASE 
            WHEN n = 1 THEN ' '
            ELSE SUBSTRING(dpt.NAME, n - 1, 1)
        END as PrevChar
    FROM WH_Raw.dbo.DirPartyTable dpt
    CROSS JOIN Numbers
    WHERE n <= LEN(dpt.NAME)
        AND dpt.NAME IS NOT NULL
),
FormattedNames AS (
SELECT 
    RECID,
    OriginalName,
    STRING_AGG(
        CASE 
            WHEN PrevChar IN (' ', '-', '''','.','/','&') THEN UPPER(CurrentChar)
            ELSE LOWER(CurrentChar)
        END,
        ''
    ) WITHIN GROUP (ORDER BY Position) as Formatted_Name
FROM CharacterProcessing
GROUP BY RECID, OriginalName
)
SELECT
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(pt.dataareaid AS VARCHAR(100))
            ,CAST(pt.purchid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS PurchaseOrderKey
    , pt.dataareaid CMPNY
    , pt.purchid PurchaseOrderNumber
    , pt.purchname PurchaseOrderName
    , pt.orderaccount VendorAccount
    , pt.invoiceaccount InvoiceVendorAccount
    , pt.payment PaymentTerms
    , pmt.description PaymentTermsDesc
    , pmt.numofdays PaymentTermsNumOfDays
    , pt.vendorref VendorReference
    , pt.currencycode
    , pt.isencumbrancerequired
    , pt.isencumbrancerequired_$label EncumberanceRequiredYN
    , pt.purchstatus
    , pt.purchstatus_$label PurchStatusDesc
    , pt.returnreasoncodeid
    , rrc.description ReturnReasonDesc
    , rrg.description ReturnReasonGroupDesc
    , pt.createddatetime
	--, convert(int, convert(char(8),pt.createddatetime,112))	CreatedDateKey
    , pt.inventlocationid Warehouse
    , pt.inventsiteid SiteID
    , pt.deliveryname
    , pt.itembuyergroupid
    , pt.purchpoolid
    , pp.name PurchPoolName
    , hcm.personnelnumber RequestorPersonnelNumber
    , coalesce(fn.Formatted_Name ,dpt.name) RequestorName
    , hcmp.personnelnumber POPlacerPersonnelNumber
    , coalesce(fnp.Formatted_Name ,dptp.name) POPlacerName
    , pt.dlvterm
    , pt.dlvmode
    , vpsj.minDeliveryDate
    , vpsj.maxDeliveryDate
	,'D365FO'	 Source
	,NULL	 RecordEffectiveStartDate
	,NULL	 RecordEffectiveEndDate
	,NULL	 RecordStatus

FROM WH_Raw.dbo.purchtable pt
LEFT JOIN WH_Raw.dbo.returnreasoncode rrc
    ON pt.returnreasoncodeid = rrc.reasoncodeid
      AND pt.dataareaid = rrc.dataareaid
LEFT JOIN WH_Raw.dbo.returnreasoncodegroup rrg
    ON rrc.reasoncodegroupid = rrg.reasoncodegroupid
      AND rrc.dataareaid = rrg.dataareaid

LEFT JOIN WH_Raw.dbo.purchpool pp
    ON pt.purchpoolid = pp.purchpoolid
      AND pt.dataareaid = pp.dataareaid

LEFT JOIN WH_Raw.dbo.paymterm pmt
    ON pt.payment = pmt.paymtermid
      AND pt.dataareaid = pmt.dataareaid

LEFT JOIN WH_Raw.dbo.hcmworker hcm
    ON pt.requester = hcm.recid

LEFT JOIN WH_Raw.dbo.dirpartytable dpt
	ON dpt.recid = hcm.person

LEFT JOIN FormattedNames fn
    ON dpt.recid = fn.recid

LEFT JOIN WH_Raw.dbo.hcmworker hcmp
    ON pt.workerpurchplacer = hcmp.recid

LEFT JOIN WH_Raw.dbo.dirpartytable dptp
	ON dptp.recid = hcmp.person

LEFT JOIN FormattedNames fnp
    ON dptp.recid = fnp.recid

LEFT JOIN (select dataareaid, purchid, dlvmode, dlvterm, min(deliverydate) minDeliveryDate, max(deliverydate) maxDeliveryDate
            from WH_Raw.dbo.vendpackingslipjour
            group by  dataareaid, purchid, dlvmode, dlvterm ) vpsj
    ON pt.dataareaid = vpsj.dataareaid
      AND pt.purchid = vpsj.purchid


UNION ALL

SELECT -1 PurchaseOrderKey
, 'Unknown' CMPNY
, 'Unknown' PurchaseOrderNumber
, 'Unknown' PurchaseOrderName
, NULL VendorAccount
, NULL InvoiceVendorAccount
, NULL PaymentTerms
, NULL PaymentTermsDesc
, NULL PaymentTermsNumOfDays
, NULL VendorReference
, NULL currencycode
, NULL isencumbrancerequired
, NULL EncumberanceRequiredYN
, NULL purchstatus
, NULL PurchStatusDesc
, NULL returnreasoncodeid
, NULL ReturnReasonDesc
, NULL ReturnReasonGroupDesc
, NULL createddatetime
--, NULL CreatedDateKey
, NULL Warehouse
, NULL SiteID
, NULL deliveryname
, NULL itembuyergroupid
, NULL purchpoolid
, NULL PurchPoolName
, NULL RequestorPersonnelNumber
, NULL RequestorName
, NULL POPlacerPersonnelNumber
, NULL POPlacerName
, NULL dlvterm
, NULL dlvmode
, NULL minDeliveryDate
, NULL maxDeliveryDate

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]