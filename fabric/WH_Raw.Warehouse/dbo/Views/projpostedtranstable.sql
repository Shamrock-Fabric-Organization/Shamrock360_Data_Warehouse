-- Auto Generated (Do not modify) 700C26E436AA4241352B95579B0B09C538FF9B08852A68B13971A79B56FADA8F

	CREATE   VIEW  projpostedtranstable 
	AS
SELECT [projpostedtranstable].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id]
	,[projpostedtranstable].[SinkCreatedOn] AS [SinkCreatedOn]
	,[projpostedtranstable].[SinkModifiedOn] AS [SinkModifiedOn]
	,[projpostedtranstable].[transactionorigin] AS [transactionorigin]
	,[projpostedtranstable].[projtranstype] AS [projtranstype]
	,[projpostedtranstable].[iscorrection] AS [iscorrection]
	,[projpostedtranstable].[issplittransaction] AS [issplittransaction]
	,[projpostedtranstable].[sysdatastatecode] AS [sysdatastatecode]
	,[projpostedtranstable].[transdate] AS [transdate]
	,[projpostedtranstable].[activitynumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [activitynumber]
	,[projpostedtranstable].[categoryid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [categoryid]
	,[projpostedtranstable].[projid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projid]
	,[projpostedtranstable].[itemid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itemid]
	,[projpostedtranstable].[qty] AS [qty]
	,[projpostedtranstable].[transid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transid]
	,[projpostedtranstable].[currencyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencyid]
	,[projpostedtranstable].[linediscount] AS [linediscount]
	,[projpostedtranstable].[linepropertyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [linepropertyid]
	,[projpostedtranstable].[inventtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventtransid]
	,[projpostedtranstable].[totalcostamountcur] AS [totalcostamountcur]
	,[projpostedtranstable].[totalsalesamountcur] AS [totalsalesamountcur]
	,[projpostedtranstable].[psaindirectcomponentgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [psaindirectcomponentgroup]
	,[projpostedtranstable].[currencyidcost] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencyidcost]
	,[projpostedtranstable].[txt] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [txt]
	,[projpostedtranstable].[adjreftransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [adjreftransid]
	,[projpostedtranstable].[defaultdimension] AS [defaultdimension]
	,[projpostedtranstable].[psacontractlinenum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [psacontractlinenum]
	,[projpostedtranstable].[resourcecategory] AS [resourcecategory]
	,[projpostedtranstable].[taxgroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxgroupid]
	,[projpostedtranstable].[taxitemgroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxitemgroupid]
	,[projpostedtranstable].[transidref] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transidref]
	,[projpostedtranstable].[inventdimid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventdimid]
	,[projpostedtranstable].[price] AS [price]
	,[projpostedtranstable].[resource] AS [resource]
	,[projpostedtranstable].[resourcename] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [resourcename]
	,[projpostedtranstable].[vendoraccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendoraccount]
	,[projpostedtranstable].[vendorname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendorname]
	,[projpostedtranstable].[subcontractline] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [subcontractline]
	,[projpostedtranstable].[transactiongroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transactiongroupid]
	,[projpostedtranstable].[transidpackslip] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transidpackslip]
	,[projpostedtranstable].[modifieddatetime] AS [modifieddatetime]
	,[projpostedtranstable].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby]
	,[projpostedtranstable].[modifiedtransactionid] AS [modifiedtransactionid]
	
	,[projpostedtranstable].[createddatetime] AS [createddatetime]
	,[projpostedtranstable].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby]
	,[projpostedtranstable].[createdtransactionid] AS [createdtransactionid]
	,[projpostedtranstable].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid]
	,[projpostedtranstable].[recversion] AS [recversion]
	,[projpostedtranstable].[partition] AS [partition]
	,[projpostedtranstable].[sysrowversion] AS [sysrowversion]
	,[projpostedtranstable].[recid] AS [recid]
	,[projpostedtranstable].[tableid] AS [tableid]
	,[projpostedtranstable].[versionnumber] AS [versionnumber]
	,[projpostedtranstable].[createdon] AS [createdon]
	,[projpostedtranstable].[modifiedon] AS [modifiedon]
	,[projpostedtranstable].[IsDelete] AS [IsDelete]
	,[projpostedtranstable].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
	,CASE [projpostedtranstable].[iscorrection]
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS iscorrection_$label
	,CASE [projpostedtranstable].[issplittransaction]
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS issplittransaction_$label


	,CASE [projpostedtranstable].[projtranstype]
		WHEN 0
			THEN 'None'
		WHEN 1
			THEN 'Revenue'
		WHEN 2
			THEN 'Hour'
		WHEN 3
			THEN 'Expense'
		WHEN 4
			THEN 'Item'
		WHEN 5
			THEN 'OnAccount'
		WHEN 6
			THEN 'WIP'
		WHEN 7
			THEN 'IndirectComponent'
		WHEN 8
			THEN 'Retainage'
		END AS projtranstype_$label


	,CASE [projpostedtranstable].[transactionorigin]
		WHEN 14
			THEN 'ItemRequirement'
		WHEN 15
			THEN 'SalesOrder'
		WHEN 16
			THEN 'ProductionFinished'
		WHEN 17
			THEN 'ProductionConsumed'
		WHEN 18
			THEN 'FeeJournal'
		WHEN 19
			THEN 'EstimateFee'
		WHEN 20
			THEN 'Subscription'
		WHEN 21
			THEN 'Prepayment'
		WHEN 22
			THEN 'Deduction'
		WHEN 23
			THEN 'Milestone'
		WHEN 50
			THEN 'Invoice'
		WHEN 51
			THEN 'InventoryClosing'
		WHEN 52
			THEN 'Adjustment'
		WHEN 53
			THEN 'PostCost'
		WHEN 54
			THEN 'AccrueRevenue'
		WHEN 55
			THEN 'PostEstimate'
		WHEN 56
			THEN 'ReverseEstimate'
		WHEN 57
			THEN 'EliminateEstimate'
		WHEN 58
			THEN 'ReverseElimination'
		WHEN 59
			THEN 'AccrueSubscriptionRev'
		WHEN 63
			THEN 'BeginningBalance'
		WHEN 61
			THEN 'PurchaseRequisition'
		WHEN 60
			THEN 'Timesheet'
		WHEN 64
			THEN 'FreeTextInvoice'
		WHEN 65
			THEN 'VendorInvoice'
		WHEN 66
			THEN 'AdvancedLedgerEntry'
		WHEN 70
			THEN 'PayrollEarningStatement'
		WHEN 71
			THEN 'PayrollPayStatement'
		WHEN 72
			THEN 'ProgressBillingRule'
		WHEN 73
			THEN 'UnitOfDeliveryBillingRule'
		WHEN 74
			THEN 'BudgetReservation'
		WHEN 75
			THEN 'ProjAdvancedJournal'
		WHEN 13
			THEN 'PurchaseOrder'
		WHEN 12
			THEN 'ItemJournal'
		WHEN 10
			THEN 'EstimateAccruedLoss'
		WHEN 9
			THEN 'EliminationInvestment'
		WHEN 8
			THEN 'ExpenseManagement'
		WHEN 7
			THEN 'InvoiceApprovalJournal'
		WHEN 6
			THEN 'InvoiceJournal'
		WHEN 5
			THEN 'GeneralJournal'
		WHEN 4
			THEN 'CostJournal'
		WHEN 1
			THEN 'HourJournal'
		WHEN 0
			THEN 'None'
		END AS transactionorigin_$label
	FROM [dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8].dbo.projpostedtranstable
	WHERE projpostedtranstable.IsDelete IS NULL