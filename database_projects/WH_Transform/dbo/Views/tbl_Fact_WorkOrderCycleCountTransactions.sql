

/*=============================================================================
  D365 F&O — WHS Cycle Count Activity

  Purpose : Returns cycle count work orders (WORKTRANSTYPE=10) with counted vs
            expected quantities, variance, accept/reject status, location, item,
            and counter. 

  Notes   :
    - Main filter: WORKTRANSTYPE = 10 (CycleCount). 
    - Variance = QTYCOUNTED - QTYEXPECTED

=============================================================================*/

CREATE   VIEW tbl_Fact_WorkOrderCycleCountTransactions 
AS
SELECT
     wt.[DATAAREAID]                               AS CMPNY
    ,wt.[WORKID]                                   AS WorkId
    ,id.[LICENSEPLATEID]                           AS LicensePlateId
    ,id.[inventstatusid]                           AS InventStatusId
    ,wlcc.[QTYEXPECTED]                            AS QtyExpected
    ,wlcc.[QTYCOUNTED]                             AS QtyCounted
    ,wlcc.[QTYCOUNTED] - wlcc.[QTYEXPECTED]        AS QtyVariance
    ,wlcc.[COUNTINGREASONCODE]                     AS ReasonCode
    ,rc.[DESCRIPTION]                              AS ReasonDescription
    ,wlcc.[LINENUM]                                AS LineNum
    ,wt.[WORKTRANSTYPE_$label]                     AS WorkTransType

    ,wlcc.[CYCLECOUNTCOUNTED_$label]               AS IsCounted
    ,wlcc.[ACCEPTREJECT_$label]                    AS AcceptReject
    ,wlcc.[CYCLECOUNTRECONCILE_$label]             AS ReconcileStatus

    ,wl.[WMSLOCATIONID]                            AS WMSLocationId
    ,wl.isanchored_$label                          AS IsAnchored
    ,wl.mandatory_$label						   AS IsCountMandatory
    ,wl.skipped_$label							   AS IsCountSkipped
    ,wl.workstatus_$label					  	   AS WorkLineStatus
    ,wl.workstop_$label							   AS IsWorkStopped
    ,wl.worktype_$label							   AS WorkLineType

    ,wlcc.[ADJUSTMENTWORKID]                       AS AdjustmentWorkId
    ,adj.[WORKTRANSTYPE_$label]                    AS AdjWorkTransType    -- 15 when present
    ,adj.[WORKSTATUS_$label]                       AS AdjWorkStatus
    ,adj.[WORKCREATEDBY]                           AS AdjWorkCreatedBy
    ,adj.[WORKINPROCESSUTCDATETIME]                AS AdjWorkStartedUTC
    ,adj.[WORKCLOSEDUTCDATETIME]                   AS AdjWorkClosedUTC

     -- Adjustment Work Line (from WHSWorkLine for the type=15 work order)
      ,adj_wl.[WORKTYPE_$label]                             AS AdjWorkType
          -- 1=Pick, 2=Put — adjustment is typically a Put to reconcile inventory
      ,adj_wl.[QTYWORK]                              AS AdjQtyWork
          -- the adjustment quantity being applied
      ,adj_wl.[WMSLOCATIONID]                        AS AdjWMSLocationId
          -- location being adjusted (should match the count location)
      ,adj_wl.[UNITID]                               AS AdjUnitId

    , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
    , ISNULL(dwo.WorkOrderKey, -1) WorkOrderKey
    , ISNULL(dawo.WorkOrderKey, -1) AdjustmentWorkOrderKey
    , ISNULL(dpc.ProductKey, -1) ProductKey
	, ISNULL(ds.SiteKey, -1) SiteKey
	, ISNULL(dw.WarehouseKey, -1) WarehouseKey
	, ISNULL(db.BatchKey, -1) BatchKey
	, ISNULL(dsn.SerialNumberKey, -1) SerialNumberKey
	, COALESCE(dsc.StandardCostKey, dsc2.StandardCostKey, -1) StandardCostKey

    ,CONVERT(INT, CONVERT(CHAR(8), wt.[WORKCANCELLEDUTCDATETIME],112))           AS WorkCancelledUTCDateKey
    ,CONVERT(INT, CONVERT(CHAR(8), wt.[WORKINPROCESSUTCDATETIME],112))           AS WorkStartedUTCDateKey
    ,CONVERT(INT, CONVERT(CHAR(8), wt.[WORKCLOSEDUTCDATETIME],112))              AS WorkClosedUTCDateKey
    ,CONVERT(INT, CONVERT(CHAR(8), wt.[CREATEDDATETIME],112))                    AS CreatedDateTimeDateKey
    ,CONVERT(INT, CONVERT(CHAR(8), wt.[MODIFIEDDATETIME],112))                   AS ModifiedDateTimeDateKey
    ,ISNULL(CONVERT(INT, CONVERT(CHAR(8), adj.[WORKINPROCESSUTCDATETIME],112)),19000101)          AS AdjWorkStartedUTCDateKey
    ,ISNULL(CONVERT(INT, CONVERT(CHAR(8), adj.[WORKCLOSEDUTCDATETIME],112)),19000101)             AS AdjWorkClosedUTCDateKey


FROM [WH_Raw].[dbo].[WHSWORKTABLE] wt

JOIN [WH_Raw].[dbo].[WHSWORKLINECYCLECOUNT] wlcc
    ON  wlcc.[DATAAREAID] = wt.[DATAAREAID]
    AND wlcc.[WORKID]     = wt.[WORKID]

JOIN [WH_Raw].[dbo].[WHSWORKLINE] wl
    ON  wl.[DATAAREAID] = wt.[DATAAREAID]
    AND wl.[WORKID]     = wlcc.[WORKID]
    AND wl.[LINENUM]    = wlcc.[LINENUM]

JOIN [WH_Raw].[dbo].[INVENTDIM] id
    ON  id.[INVENTDIMID] = wlcc.[INVENTDIMID]

LEFT JOIN [WH_Raw].[dbo].[INVENTCOUNTINGREASONCODE] rc
    ON  rc.[DATAAREAID] = wt.[DATAAREAID]
    AND rc.[REASONCODE] = wlcc.[COUNTINGREASONCODE]


-- Adjustment work order (WORKTRANSTYPE = 15) — created when variance accepted
LEFT JOIN [WH_Raw].[dbo].[WHSWORKTABLE] adj
    ON  adj.[DATAAREAID]   = wt.[DATAAREAID]
    AND adj.[WORKID]       = wlcc.[ADJUSTMENTWORKID]
    AND adj.[WORKTRANSTYPE] = 15

 LEFT JOIN [WH_Raw].[dbo].[WHSWORKLINE] adj_wl
      ON  adj_wl.[DATAAREAID] = wt.[DATAAREAID]
      AND adj_wl.[WORKID]     = wlcc.[ADJUSTMENTWORKID]
      AND adj_wl.[WORKTYPE]   = 3    -- Count only

LEFT JOIN WH_Transform.dbo.tbl_DIM_Product dpc
	ON wlcc.itemid = dpc.Product_ID
		AND wlcc.dataareaid = dpc.CMPNY
		AND dpc.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkOrder dwo
	ON wt.workid = dwo.workid
		AND wt.dataareaid = dwo.CMPNY
		AND dwo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_WorkOrder dawo
	ON wlcc.[ADJUSTMENTWORKID] = dawo.workid
		AND wt.dataareaid = dawo.CMPNY
		AND dawo.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON wt.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON ID.inventsiteid = ds.Site_ID
		AND wt.dataareaid = ds.CMPNY
		AND ds.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Warehouse dw
	ON wt.dataareaid = dw.CMPNY
		AND ID.inventlocationid = dw.Warehouse_ID
		AND dw.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_Batch db
	ON id.inventbatchid = db.BatchID
		AND wt.dataareaid = db.CMPNY
		AND db.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_SerialNumber dsn
	ON id.inventserialid = dsn.SerialNumber
		AND wt.dataareaid = dsn.CMPNY
		AND dsn.RecordStatus=1


LEFT JOIN WH_Transform.dbo.tbl_DIM_StandardCost dsc
	ON wlcc.itemid = dsc.Product_ID
		AND wt.dataareaid = dsc.CMPNY
		AND ID.inventsiteid = dsc.siteid
		AND wt.[WORKINPROCESSUTCDATETIME] between dsc.activationdate and dsc.enddate --dsc.RecordEffectiveStartDate and dsc.RecordEffectiveEndDate

LEFT JOIN WH_Raw.dbo.vwinventitempriceagg iip
    ON wt.dataareaid = IIP.dataareaid
    and wlcc.itemid = IIP.itemid
    and ID.inventsiteid = IIP.inventsiteid
    and wt.[WORKINPROCESSUTCDATETIME] between IIP.activationdate and IIP.todate

-- OUTER APPLY: limits to 1 dsc2 row per sales line where site differs.
-- OUTER APPLY justified: ranking requires ID.inventsiteid from outer scope —
-- no set-based alternative exists.
OUTER APPLY (
    SELECT TOP 1 *
    FROM WH_Transform.dbo.tbl_DIM_StandardCost dsc2_inner
    WHERE dsc2_inner.Product_ID = wlcc.itemid
        AND dsc2_inner.CMPNY    = wt.dataareaid
        AND dsc2_inner.siteid  != ID.inventsiteid
        AND ROUND(IIP.PricePerUnit,2,1) BETWEEN (ROUND(dsc2_inner.TotalCost,2,1) - 0.01)
                                             AND (ROUND(dsc2_inner.TotalCost,2,1) + 0.01)
        AND wt.[WORKINPROCESSUTCDATETIME] BETWEEN dsc2_inner.activationdate --RecordEffectiveStartDate
                                   AND dsc2_inner.EndDate --RecordEffectiveEndDate
    ORDER BY dsc2_inner.SiteID  -- deterministic; swap for a business-preferred site if needed
) dsc2


WHERE wt.[WORKTRANSTYPE] = 10   -- CycleCount work orders only
GO

