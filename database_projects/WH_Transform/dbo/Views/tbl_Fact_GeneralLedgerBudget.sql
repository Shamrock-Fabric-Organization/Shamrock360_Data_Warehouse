-- Auto Generated (Do not modify) B8E2C2AE9893CB4518CE0BA78A78313DF325777EC0A8C9AF4F08B0D127C0BD14

CREATE   VIEW tbl_Fact_GeneralLedgerBudget 
as
SELECT 
budgetmodeldataareaid CMPNY
, GL_Account
, date
, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) BudgetDateKey
,budgetmodelid  BudgetModel
,budgettype_$label BudgetTypeDesc
,transactioncurrency  CurrencyCode
,budgettransactiontype_$label BudgetTransactionType
,accountingcurrencyamount accountingcurrencyamount
,transactioncurrencyamount transactioncurrencyamount
,quantity 
,isnull(dle.Legal_EntityKey, -1) Legal_EntityKey
,isnull(dbm.BudgetModelKey, -1) BudgetModelKey
,isnull(dd.DepartmentKey, -1) DepartmentKey
,isnull(ds.SiteKey, -1) SiteKey

FROM 
(
SELECT 
bth.budgettransactiontype
,bth.[budgettransactiontype_$label]
,bth.transactionstatus
,bth.[transactionstatus_$label]
,bth.budgetmodelid
,bth.budgetsubmodelid
,bth.budgetmodeltype
,bth.[budgetmodeltype_$label]
,bth.budgetmodeldataareaid
,btl.budgettype
, btl.budgettype_$label
, ld.Business_Unit
, ld.Department
, ld.GL_Account
, ld.Product_Line
, ld.Site
, btl.accountingcurrencyamount
, btl.date
, btl.linenumber
, btl.quantity
, btl.transactioncurrency
, btl.transactioncurrencyamount


FROM WH_Raw.dbo.BudgetTransactionLine btl
LEFT JOIN WH_Raw.dbo.BudgetTransactionHeader bth 
  ON bth.RECID = btl.[budgettransactionheader]

LEFT JOIN WH_Raw.dbo.vwLedgerDimension ld
  ON btl.ledgerdimension = ld.LedgerDimension
) b

LEFT JOIN [dbo].[tbl_DIM_Legal_Entity] dle
  ON b.budgetmodeldataareaid = dle.CMPNY
    AND dle.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_Department] dd
  ON b.Department = dd.Department
    AND dd.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_Site] ds
  ON b.Site = ds.Site_ID
    AND b.budgetmodeldataareaid = ds.CMPNY
    AND ds.recordstatus = 1

LEFT JOIN [dbo].[tbl_DIM_BudgetModel] dbm
  ON b.budgetmodelid = dbm.BudgetModel
    AND b.budgetmodeldataareaid = dbm.CMPNY
    AND dbm.recordstatus = 1


--GROUP BY budgetmodeldataareaid --CMPNY
--, GL_Account
--, date
--, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) --BudgetDateKey
--,budgetmodelid -- BudgetModel
--,budgettype_$label --BudgetTypeDesc
--,transactioncurrency  --CurrencyCode
--,budgettransactiontype_$label --BudgetTransactionType

--,isnull(dle.Legal_EntityKey, -1) --Legal_EntityKey
--,isnull(dbm.BudgetModelKey, -1) --BudgetModelKey
--,isnull(dd.DepartmentKey, -1) --DepartmentKey
--,isnull(ds.SiteKey, -1) --SiteKey


--GROUP BY budgetmodeldataareaid --CMPNY
--, GL_Account
--, date
--, CONVERT(INT, CONVERT(CHAR(8), date, 112) ) --BudgetDateKey
--,budgetmodelid -- BudgetModel
--,budgettype_$label --BudgetTypeDesc
--,transactioncurrency  --CurrencyCode
--,budgettransactiontype_$label --BudgetTransactionType

--,isnull(dle.Legal_EntityKey, -1) --Legal_EntityKey
--,isnull(dbm.BudgetModelKey, -1) --BudgetModelKey
--,isnull(dd.DepartmentKey, -1) --DepartmentKey
--,isnull(ds.SiteKey, -1) --SiteKey