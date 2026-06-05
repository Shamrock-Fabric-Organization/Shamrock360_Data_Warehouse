-- Auto Generated (Do not modify) 03507983082C89750846408A8504EC1F887EFE673070F20B98F2B8BD1F5DABF8
--use WH_Transform

CREATE     VIEW [dbo].[vw_stage_NewStandardCost]
AS
SELECT
    [StandardCostKey]
,   [CMPNY]
,   [Product_ID]
,   [SiteID]
,   [ActivationDate]                                             -- v5 change: added
,   [EndDate]
,   [Costing_Version]
,   [CurrentActiveCost]
,   [Direct_Material_Cost_Standard]
,   [Packaging_Cost_Standard]
,   [Direct_Labor_Cost_Standard]
,   [Direct_Utility_Cost_Standard]
,   [Overhead_Warehouse_Cost_Standard]
,   [Overhead_Indirect_Supervisor_Cost_Standard]
,   [Overhead_Quality_Cost_Standard]
,   [Overhead_Maintenance_Cost_Standard]
,   [Overhead_Manufacturing_Admin_Cost_Standard]
,   [Overhead_Depreciation_Cost_Standard]
,   [Overhead_Miscellaneous_Manufacturing_Cost_Standard]
,   [Outside_Processing_Cost_Standard]
,   [Total_Direct_Cost_Standard]
,   [Total_Overhead_Cost_Standard]
,   [TotalCost]
,   [accountingcurrency]
-- v5 change: RecordEffectiveStartDate = ActivationDate (not '1900-01-01').
-- The D365 activation date is the real effective start; using a static sentinel
-- date breaks LEAD-based end date calculations.
,   CAST(Source.ActivationDate AS DATETIME2(3)) AS RecordEffectiveStartDate
,   CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
,   1 AS RecordStatus
,   [Source]
FROM vw_stage_DIM_StandardCost_incoming AS Source
WHERE NOT EXISTS (
    SELECT 1
    FROM tbl_DIM_StandardCost AS Target
    WHERE Target.CMPNY        = Source.CMPNY
      AND Target.Product_ID   = Source.Product_ID
      AND Target.SiteID       = Source.SiteID
      AND Target.ActivationDate = Source.ActivationDate   -- v5 change: added
    -- RecordStatus intentionally omitted: if ANY row for this natural key exists
    -- (current, historical, or future) we do not insert again.
);