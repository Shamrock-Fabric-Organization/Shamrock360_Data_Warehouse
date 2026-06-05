


CREATE           VIEW [dbo].[tbl_Fact_GeneralLedger] AS 		
SELECT CASE 
		WHEN LD.GL_Account IS NULL
			THEN ma.mainaccountid
		ELSE LD.GL_Account
		END GL_Account
	,ISNULL(gl.GL_AccountKey, -1) GL_AccountKey
	,gje.accountingdate
	,CONVERT(INT, convert(CHAR(8), gje.accountingdate, 112)) accountingdatekey
	,transactioncurrencyamount
	,accountingcurrencyamount
	,reportingcurrencyamount
	,quantity
	,iscorrection
	,iscorrection_$label
	,iscredit
	,iscredit_$label
	,transactioncurrencycode
	,paymentreference
	,gjae.postingtype
	,gjae.postingtype_$label
	,gjae.ledgerdimension
	,generaljournalentry
	,mainaccount
	--, LD.GL_Account
	--, ma.mainaccountid
	,TEXT
	,reasonref
	,gjae.recid
	,ledgeraccount
	,gje.documentdate
	,gje.createdby
	,gje.createddatetime
	,gje.fiscalcalendarperiod
	,fcp.type FiscalCalendarPeriodType
	,fcp.type_$label FiscalCalendarPeriodType_$label
	,gje.journalcategory
	,gje.journalcategory_$label
	,gje.journalnumber
	,gje.ledger
	,le.name Legal_Entity
	,ISNULL(cmp.Legal_EntityKey, - 1) Legal_EntityKey
	,gje.ledgerentryjournal
	,gje.postinglayer
	,gje.postinglayer_$label
	,gje.subledgervoucher
	,gje.subledgervoucherdataareaid
	,lej.journalnumber lej_journalnumber
	,lej.ledgerjournaltabledataareaid
	,ljt.approver
	,ljt.dataareaid
	,ljt.journalnum
	,LD.Business_Unit
	,LD.Department
	,LD.Product_Line
	,LD.Site
	,ISNULL(d.DepartmentKey, -1) DepartmentKey
	,ISNULL(ds.SiteKey, -1) SiteKey
FROM WH_Raw.dbo.generaljournalaccountentry gjae

JOIN WH_Raw.dbo.generaljournalentry gje
	ON gjae.generaljournalentry = gje.recid

LEFT JOIN WH_Raw.dbo.vwLedgerDimension LD
	ON gjae.ledgerdimension = LD.LedgerDimension

LEFT JOIN WH_Raw.dbo.mainaccount ma
	ON gjae.mainaccount = ma.recid

LEFT JOIN WH_Raw.dbo.fiscalcalendarperiod fcp
	ON gje.fiscalcalendarperiod = fcp.recid

LEFT JOIN WH_Raw.dbo.ledger le
	ON gje.ledger = le.recid

LEFT JOIN WH_Raw.dbo.ledgerentryjournal lej
	ON gje.ledgerentryjournal = lej.recid

LEFT JOIN WH_Raw.dbo.ledgerjournaltable ljt
	ON gje.subledgervoucherdataareaid = ljt.dataareaid
		AND lej.journalnumber = ljt.journalnum

LEFT JOIN [dbo].[tbl_DIM_Legal_Entity] cmp
	ON le.name = cmp.CMPNY

LEFT JOIN WH_Transform.[dbo].[tbl_DIM_GL_Account] gl
	ON CASE 
		WHEN LD.GL_Account IS NULL
			THEN ma.mainaccountid
		ELSE LD.GL_Account
		END = gl.GL_Account_Number

LEFT JOIN WH_Transform.[dbo].[tbl_DIM_Department] d
	ON LD.Department = d.Department

LEFT JOIN WH_Transform.dbo.tbl_DIM_Site ds
	ON LD.Site = ds.Site_ID
		AND gje.subledgervoucherdataareaid = ds.CMPNY
		AND ds.RecordStatus=1

GO

