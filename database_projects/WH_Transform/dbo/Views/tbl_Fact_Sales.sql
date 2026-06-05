/****** Object:  View [dbo].[tbl_Fact_Sales]    Script Date: 5/19/2026 4:12:14 PM ******/
/****** Object:  View [dbo].[tbl_Fact_Sales]    Script Date: 4/23/2026 2:40:48 PM ******/


CREATE                           VIEW [dbo].[tbl_Fact_Sales] AS 		
SELECT 
	CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())))	RecordID
	,ST.dataareaid	CMPNY
	,SL.salesstatus_$label	SalesLine_Status


	,COALESCE(case when CIT.invoicedate='01/01/1900' then null else CIT.invoicedate end
			,case when sl.shippingdateconfirmed= '01/01/1900' then  sl.shippingdaterequested  else sl.shippingdateconfirmed end  ----SL.shippingdaterequested change to case stmt on 04/06/2026
			, ST.createddatetime) 	DATE
	,convert(int, convert(char(8),COALESCE(case when CIT.invoicedate='01/01/1900' then null else CIT.invoicedate end
			,case when sl.shippingdateconfirmed= '01/01/1900' then  sl.shippingdaterequested  else sl.shippingdateconfirmed end  ----SL.shippingdaterequested change to case stmt on 04/06/2026
			, ST.createddatetime),112))	DATEKey

	,ST.createddatetime	OrderDate
	,convert(int, convert(char(8),ST.createddatetime,112))	OrderDateKey


	,SL.shippingdaterequested	SalesLine_RequestedShipDate
	,convert(int, convert(char(8),SL.shippingdaterequested,112))	SalesLine_RequestedShipDateKey
	,SL.shippingdateconfirmed	SalesLine_ShipDate
	,convert(int, convert(char(8),SL.shippingdateconfirmed,112))	SalesLine_ShipDateKey

	,SL.confirmeddlv SalesLine_DeliveryDate
	,convert(int, convert(char(8),SL.confirmeddlv,112))	SalesLine_DeliveryDateKey

	,CIT.invoicedate	InvoiceDate
	,convert(int, convert(char(8),CIT.invoicedate,112))	InvoiceDateKey
	,ST.dataareaid	Legal_Entity_ID
	,ST.custaccount	CustomerID	--is the invoice account needed??
	, ST.invoiceaccount	InvoiceAccount
	,SL.itemid	ProductID
	,ST.dataareaid +'-'+ ST.custaccount +'-'+ SL.itemid	CPCID
	,CIT.invoiceid	InvoiceNo
	,ST.salesid	Customer_Order_Number
	,SL.salesqty	Quantity
	,SL.salesunit	Quantity_UoM
	,case when SL.salesunit = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * SL.salesqty	Quantity_LBs
	,IT.unitvolume * SL.salesqty	Volume
	,SL.salesunit	Volume_UoM
	,SL.salesprice	Price
	,SL.currencycode	Currency
	,SL.lineamount	Amount
	,SL.currencycode	Amount_Currency
	,CASE WHEN SL.salestype_$label = 'ReturnItem' then SL.salesqty else 0 end Returned_Quantity
	,CASE WHEN SL.salestype_$label = 'ReturnItem' then SL.lineamount else 0 end Returned_Amount
	,HCM.personnelnumber	SalesLine_Salesman_ID		--this is the personnelnumber, would they rather have the RECID?
	, coalesce(HCMct.personnelnumber, HCM.personnelnumber)	Customer_Salesman_ID		--this is the personnelnumber, would they rather have the RECID?
	, coalesce(dsc.Total_Direct_Cost_Standard, dsc2.Total_Direct_Cost_Standard) Total_Direct_Cost_Standard
	, coalesce(dsc.Total_Overhead_Cost_Standard, dsc2.Total_Overhead_Cost_Standard) Total_Overhead_Cost_Standard
	, coalesce(dsc.Packaging_Cost_Standard, dsc2.Packaging_Cost_Standard) Packaging_Cost_Standard
	, coalesce(dsc.TotalCost, dsc2.TotalCost) TotalCost
	,'D365FO'		Source
	, ISNULL(dc.CustomerKey, -1) HistoricCustomerKey
	, ISNULL(dcc.CustomerKey, -1) CustomerKey
	, ISNULL(dp.ProductKey, -1) HistoricProductKey
	, ISNULL(dpc.ProductKey, -1) ProductKey
	, COALESCE(dsc.StandardCostKey, dsc2.StandardCostKey, -1) StandardCostKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(de.EmployeeKey, -1) SalesLine_EmployeeKey
	, ISNULL(dect.EmployeeKey, -1) CustAcct_EmployeeKey
	, ISNULL(dest.EmployeeKey, -1) SalesTaker_EmployeeKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(dso.SalesOrderKey, -1) SalesOrderKey
	, CASE WHEN MCT.mcrcleared = 1 THEN -1 ELSE ST.mcrorderstopped END  AS OnHold
	, CASE WHEN MCT.mcrcleared = 1 THEN 'Cleared' ELSE CONVERT(varchar(10), ST.mcrorderstopped_$label) END AS OrderOnHold
	, MCT.mcrholdcode  AS HoldCode
	, MCT.mcrreasoncode AS HoldReasonCode
	, SL.linenum SalesOrderLineNumber
	,SL.createddatetime	SalesLineCreatedDate
	,convert(int, convert(char(8),SL.createddatetime,112))	SalesLineCreatedDateKey
	----, ISNULL(dms.MarketSegmentationKey, -1) HistoricMarketSegmentationKey  --Per Kevin Y 2026-02-02 historic value not needed
	, ISNULL(dmsc.MarketSegmentationKey, -1) MarketSegmentationKey
	, st.purchorderformnum PurchaseOrderFormNumber
	, ISNULL(da.AddressKey, -1) DeliveryAddressKey
FROM WH_Raw.dbo.salestable ST
JOIN WH_Raw.dbo.SalesLine SL
	ON ST.salesid = SL.salesid
		AND ST.dataareaid = SL.dataareaid
JOIN WH_Raw.dbo.InventTable IT
	ON SL.itemid = IT.itemid
		AND SL.dataareaid = IT.dataareaid
LEFT JOIN WH_Raw.dbo.custinvoicetrans CIT
	ON SL.dataareaid = CIT.dataareaid
		AND SL.salesid = CIT.salesid
		AND SL.inventtransid = CIT.inventtransid
LEFT JOIN WH_Raw.dbo.InventDIM ID
	ON SL.inventdimid = ID.inventdimid
		AND SL.dataareaid = IT.dataareaid

JOIN WH_Raw.dbo.CustTable CT
	ON ST.custaccount = CT.accountnum
		AND ST.dataareaid = CT.dataareaid

LEFT JOIN WH_Raw.dbo.hcmworker HCM
	ON ST.workersalesresponsible = HCM.recid

LEFT JOIN WH_Raw.dbo.hcmworker HCMct
	ON CT.maincontactworker = HCMct.recid

LEFT JOIN WH_Raw.dbo.hcmworker HCMst
	ON ST.workersalestaker = HCMst.recid

LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND SL.salesunit = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'


LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dc
	ON ST.custaccount = dc.Customer_ID
		AND ST.dataareaid = dc.CMPNY
		AND ST.createddatetime between dc.RecordEffectiveStartDate and dc.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Customer dcc
	ON ST.custaccount = dcc.Customer_ID
		AND ST.dataareaid = dcc.CMPNY
		AND dcc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dp
	ON SL.itemid = dp.Product_ID
		AND SL.dataareaid = dp.CMPNY
		AND SL.createddatetime between dp.RecordEffectiveStartDate and dp.RecordEffectiveEndDate

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON SL.itemid = dpc.Product_ID
		AND SL.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc
	ON SL.itemid = dsc.Product_ID
		AND SL.dataareaid = dsc.CMPNY
		AND ID.inventsiteid = dsc.siteid
		AND SL.createddatetime between dsc.activationdate and dsc.enddate --dsc.RecordEffectiveStartDate and dsc.RecordEffectiveEndDate

LEFT JOIN WH_Raw.dbo.vwinventitempriceagg iip
		----JOIN (
		----SELECT dataareaid, itemid, inventsiteid, activationdate, todate, max(modifieddatetime) max_modifieddatetime
		----FROM WH_Raw.dbo.vwinventitemprice iip
		----GROUP BY dataareaid, itemid, inventsiteid, activationdate, todate
		----) m_iip
		----ON iip.dataareaid = m_iip.dataareaid
		----	AND iip.itemid = m_iip.itemid
		----	AND iip.inventsiteid = m_iip.inventsiteid
		----	AND iip.activationdate = m_iip.activationdate
		----	AND iip.todate = m_iip.todate
		----	AND iip.modifieddatetime = m_iip.max_modifieddatetime
	--)
    ON SL.dataareaid = IIP.dataareaid
    and SL.itemid = IIP.itemid
    and ID.inventsiteid = IIP.inventsiteid
    and SL.createddatetime between IIP.activationdate and IIP.todate

----LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc2
----	ON SL.itemid = dsc2.Product_ID
----		AND SL.dataareaid = dsc2.CMPNY
----		AND ID.inventsiteid != dsc2.siteid
----		----AND ROUND(IIP.PricePerUnit,2) = ROUND(dsc2.TotalCost,2)
----		--AND ROUND(IIP.PricePerUnit,2,1) = ROUND(dsc2.TotalCost,2,1)
----		AND ROUND(IIP.PricePerUnit,2,1) between (ROUND(dsc2.TotalCost,2,1) - 0.01) and (ROUND(dsc2.TotalCost,2,1) + 0.01)
----		AND ST.createddatetime between dsc2.RecordEffectiveStartDate and dsc2.RecordEffectiveEndDate

-- OUTER APPLY: limits to 1 dsc2 row per sales line where site differs.
-- OUTER APPLY justified: ranking requires ID.inventsiteid from outer scope —
-- no set-based alternative exists.
OUTER APPLY (
    SELECT TOP 1 *
    FROM WH_Transform.dbo.tbl_DIM_StandardCost dsc2_inner
    WHERE dsc2_inner.Product_ID = SL.itemid
        AND dsc2_inner.CMPNY    = SL.dataareaid
        AND dsc2_inner.siteid  != ID.inventsiteid
        AND ROUND(IIP.PricePerUnit,2,1) BETWEEN (ROUND(dsc2_inner.TotalCost,2,1) - 0.01)
                                             AND (ROUND(dsc2_inner.TotalCost,2,1) + 0.01)
        AND ST.createddatetime BETWEEN dsc2_inner.activationdate --RecordEffectiveStartDate
                                   AND dsc2_inner.EndDate --RecordEffectiveEndDate
    ORDER BY dsc2_inner.SiteID  -- deterministic; swap for a business-preferred site if needed
) dsc2



LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON SL.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND SL.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee de
	ON HCM.personnelnumber = de.Personnel_Number
		AND de.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee dect
	ON coalesce(HCMct.personnelnumber, HCM.personnelnumber) = dect.Personnel_Number
		AND dect.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Employee dest
	ON HCMst.personnelnumber = dest.Personnel_Number
		AND dest.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON SL.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND SL.createddatetime between dw.RecordEffectiveStartDate and dw.RecordEffectiveEndDate

LEFT JOIN (WH_Raw.dbo.MCRHoldCodeTrans MCT 
		JOIN (select dataareaid, InventRefID, max(modifieddatetime) max_modifieddatetime
			from WH_Raw.dbo.MCRHoldCodeTrans
			group by dataareaid, InventRefID) m_MCT
		  ON MCT.dataareaid  = m_MCT.dataareaid
		    AND MCT.InventRefID  = m_MCT.InventRefID
		    AND MCT.modifieddatetime  = m_MCT.max_modifieddatetime  )
    ON MCT.InventRefId = ST.SalesId  
    AND MCT.DataAreaId = ST.DataAreaId 
	AND MCT.mcrholdcleardatetime = '01/01/1900'

--LEFT JOIN WH_Transform.dbo.tbl_DIM_MarketSegmentation dms  --Per Kevin Y 2026-02-02 historic value not needed
--	ON ST.custaccount = dms.CustomerID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND SL.itemid = dms.ProductID  --Per Kevin Y 2026-02-02 historic value not needed
--		AND ST.dataareaid = dms.CMPNY  --Per Kevin Y 2026-02-02 historic value not needed
--		AND ST.createddatetime between dms.RecordEffectiveStartDate and dms.RecordEffectiveEndDate  --Per Kevin Y 2026-02-02 historic value not needed

LEFT JOIN WH_Transform.dbo.tbl_DIM_MarketSegmentation dmsc
	ON ST.custaccount = dmsc.CustomerID
		AND SL.itemid = dmsc.ProductID
		AND ST.dataareaid = dmsc.CMPNY
		AND dmsc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SalesOrder dso
	ON ST.salesid = dso.SalesOrderId
		AND ST.dataareaid = dso.CMPNY
		AND dso.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Address da
	ON SL.deliverypostaladdress = da.AddressRecID
		AND dso.RecordStatus=1

GO

