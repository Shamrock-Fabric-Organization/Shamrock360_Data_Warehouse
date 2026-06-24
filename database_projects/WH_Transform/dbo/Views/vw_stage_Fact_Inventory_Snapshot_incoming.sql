-- Auto Generated (Do not modify) 04E1A94B5DD0FA9FB2B3F0D3CF3F87414049878D6637CA3F1F8E87A4D2422A2C
/****** Object:  View [dbo].[vw_stage_Fact_Inventory_Snapshot_incoming]    Script Date: 5/19/2026 4:18:30 PM ******/
/****** Object:  View [dbo].[vw_stage_Fact_Inventory_Snapshot_incoming]    Script Date: 4/14/2026 9:39:36 AM ******/
/****** Object:  View [dbo].[vw_stage_Fact_Inventory_Snapshot_incoming]    Script Date: 3/6/2026 1:56:23 PM ******/






CREATE  OR ALTER         VIEW [dbo].[vw_stage_Fact_Inventory_Snapshot_incoming] AS 		
SELECT 
	CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())))	InventorySnapshotKey
	,S.dataareaid	CMPNY
	,S.inventsiteid		Site_ID
	,S.inventlocationid	Warehouse_ID
	, convert(date, DATEADD(Day, -1, getdate()))	Snapshot_Date
	, convert(int, convert(char(8), DATEADD(Day, -1, getdate()), 112))		Snapshot_Date_Key
	, S.itemid	Product_ID
	,ERPT.name	 ProductName	
	,ERP.searchname	 ProductSearchName	
	,IT.phantom_$label	Phantom_Product
	, ITMi.unitid  Inventory_UoM

	,s.inventstatusid
	,s.wmslocationid

	, sum(s.arrived) 	arrived
	, sum(s.availordered) 	availordered
	, sum(s.availphysical) 	availphysical
	, sum(s.deducted) 	deducted
	, sum(s.onorder) 	onorder
	, sum(s.ordered) 	ordered
	, sum(s.physicalinvent) 	physicalinvent
	, sum(s.picked) 	picked
	, sum(s.postedqty) 	postedqty
	, sum(s.received) 	received
	, sum(s.registered) 	registered
	, sum(s.reservordered) 	reservordered
	, sum(s.reservphysical) 	reservphysical
	, sum(s.postedvalue)  postedcostamount

	--, SUM( /*case when s.inventstatusid = 'Available' then*/ s.physicalinvent/* else 0 end */) PhysicalAvailable
	--, SUM( case when s.inventstatusid = 'Available' /*and isnull(s.wmslocationid,'') = ''*/ then s.reservphysical  else 0 end ) ReserveAvailable
	--, SUM( /*case when s.inventstatusid = 'Available' then*/ s.physicalinvent/* else 0 end */) -
	--  SUM( case when s.inventstatusid = 'Available' /*and isnull(s.wmslocationid,'') = ''*/ then s.reservphysical  else 0 end ) AvailablePhysical

	--,'###'
	--, SUM( /*case when s.inventstatusid = 'Available' then*/ s.physicalinvent/* else 0 end */) PhysicalAvailable
	--, SUM( case when s.inventstatusid = 'Available' and s.wmslocationid is null then s.reservphysical  else 0 end ) ReserveAvailable
	--, SUM( /*case when s.inventstatusid = 'Available' then*/ s.physicalinvent/* else 0 end */) -
	--  SUM( case when s.inventstatusid = 'Available' and s.wmslocationid is null then s.reservphysical  else 0 end ) AvailablePhysical

	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.arrived) 	arrived_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.availordered) 	availordered_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.availphysical) 	availphysical_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.deducted) 	deducted_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.onorder) 	onorder_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.ordered) 	ordered_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.physicalinvent) 	physicalinvent_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.picked) 	picked_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.postedqty) 	postedqty_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.received) 	received_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.registered) 	registered_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.reservordered) 	reservordered_LBs
	-- , sum(case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end * s.reservphysical) 	reservphysical_LBs

	     -- ===== LB measures (updated: fall back to KG -> LB when no LB conversion) =====
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.arrived)         arrived_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.availordered)    availordered_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.availphysical)   availphysical_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.deducted)        deducted_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.onorder)         onorder_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.ordered)         ordered_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.physicalinvent)  physicalinvent_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.picked)          picked_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.postedqty)       postedqty_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.received)        received_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.registered)      registered_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.reservordered)   reservordered_LBs
     , sum(CASE WHEN ITMi.unitid = 'lb' THEN 1
                WHEN UOMC_lb.UOMConversionFactor IS NOT NULL THEN UOMC_lb.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'kg' then 1 else UOMC_kg.UOMConversionFactor end) / 0.45359237
           END * s.reservphysical)  reservphysical_LBs
 
     -- ===== KG measures (new: fall back to LB -> KG when no KG conversion) =====
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.arrived)         arrived_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.availordered)    availordered_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.availphysical)   availphysical_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.deducted)        deducted_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.onorder)         onorder_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.ordered)         ordered_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.physicalinvent)  physicalinvent_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.picked)          picked_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.postedqty)       postedqty_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.received)        received_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.registered)      registered_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.reservordered)   reservordered_KGs
     , sum(CASE WHEN ITMi.unitid = 'kg' THEN 1
                WHEN UOMC_kg.UOMConversionFactor IS NOT NULL THEN UOMC_kg.UOMConversionFactor
                ELSE (case when ITMi.unitid = 'lb' then 1 else UOMC_lb.UOMConversionFactor end) * 0.45359237
           END * s.reservphysical)  reservphysical_KGs


	, it.primaryvendorid

	,'D365FO'		Source

	, ISNULL(dpc.ProductKey, -1) ProductKey
	--, ISNULL(dpca.ProductKey, -1) AllProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(dv.VendorKey, -1) VendorKey

	, COALESCE(dsc.StandardCostKey, dsc2.StandardCostKey, -1) StandardCostKey


FROM WH_Raw.dbo.inventsum s
JOIN WH_Raw.dbo.InventTable IT
	ON s.itemid = IT.itemid
		AND s.dataareaid = IT.dataareaid
LEFT JOIN WH_Raw.dbo.EcoResProductTranslation ERPT			
	ON IT.product = ERPT.product		
		AND ERPT.languageid = 'en-US'	
LEFT JOIN WH_Raw.dbo.EcoResProduct ERP			
	ON IT.product = ERP.recid		
LEFT JOIN WH_Raw.dbo.inventtablemodule ITMi
	ON s.dataareaid = ITMi.dataareaid
		AND s.itemid = ITMi.itemid
		AND ITMi.moduletype = 0
LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_lb
    ON IT.product = UOMC_lb.product
	    AND ITMi.unitid = UOMC_lb.SYMBOLFROM
		AND UOMC_lb.SYMBOLTO = 'lb'
 
 LEFT JOIN WH_Raw.dbo.vwUnitOfMeasureConversion UOMC_kg
     ON IT.product = UOMC_kg.product
         AND ITMi.unitid = UOMC_kg.SYMBOLFROM
         AND UOMC_kg.SYMBOLTO = 'kg'
		 
LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON s.itemid = dpc.Product_ID
		AND s.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

--LEFT JOIN WH_Transform.dbo.tbl_DIM_Product_All dpca
--	ON s.itemid = dpca.Product_ID
--		AND s.dataareaid = dpca.CMPNY
--		AND dpca.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON s.inventsiteid = ds.Site_ID
		AND s.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON s.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON s.dataareaid = dw.CMPNY
		AND s.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Vendor dv
	ON it.primaryvendorid = dv.Vendor_ID
		AND it.dataareaid = dv.CMPNY
		AND dv.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc
	ON s.itemid = dsc.Product_ID
		AND s.dataareaid = dsc.CMPNY
		AND s.inventsiteid = dsc.siteid
		AND getdate() between dsc.ActivationDate and dsc.EndDate --dsc.RecordEffectiveStartDate and dsc.RecordEffectiveEndDate

LEFT JOIN WH_Raw.dbo.vwinventitempriceagg iip
    ON s.dataareaid = IIP.dataareaid
    and s.itemid = IIP.itemid
    and s.inventsiteid = IIP.inventsiteid
    and getdate() between IIP.activationdate and IIP.todate

-- OUTER APPLY: limits to 1 dsc2 row per sales line where site differs.
-- OUTER APPLY justified: ranking requires ID.inventsiteid from outer scope —
-- no set-based alternative exists.
OUTER APPLY (
    SELECT TOP 1 *
    FROM WH_Transform.dbo.tbl_DIM_StandardCost dsc2_inner
    WHERE dsc2_inner.Product_ID = s.itemid
        AND dsc2_inner.CMPNY    = s.dataareaid
        AND dsc2_inner.siteid  != s.inventsiteid
        AND ROUND(IIP.PricePerUnit,2,1) BETWEEN (ROUND(dsc2_inner.TotalCost,2,1) - 0.01)
                                             AND (ROUND(dsc2_inner.TotalCost,2,1) + 0.01)
        AND getdate() BETWEEN dsc2_inner.ActivationDate --RecordEffectiveStartDate
                                   AND dsc2_inner.EndDate --RecordEffectiveEndDate
    ORDER BY dsc2_inner.SiteID  -- deterministic; swap for a business-preferred site if needed
) dsc2


--where s.itemid= '10001' --'10051'  --'10018'
GROUP BY 
S.dataareaid	
	,S.inventsiteid		
	,S.inventlocationid	
	, S.itemid	
	,ERPT.name	 	
	,ERP.searchname	 	
	,IT.phantom_$label	
	, ITMi.unitid  

	,s.inventstatusid
	,s.wmslocationid

	, dpc.ProductKey
	--, dpca.ProductKey
	, ds.SiteKey
	, dle.Legal_EntityKey
	, dw.WarehouseKey
	, it.primaryvendorid
	, dv.VendorKey
	, COALESCE(dsc.StandardCostKey, dsc2.StandardCostKey, -1)
--ORDER BY s.dataareaid
--	,s.itemid
--	, s.inventsiteid
--	, s.inventlocationid
	
--	,s.inventstatusid
--	,s.wmslocationid
--ORDER BY s.dataareaid
--	,s.itemid
--	, s.inventsiteid
--	, s.inventlocationid
	
--	,s.inventstatusid
--	,s.wmslocationid