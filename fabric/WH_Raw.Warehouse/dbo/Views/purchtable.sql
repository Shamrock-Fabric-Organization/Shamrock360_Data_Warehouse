-- Auto Generated (Do not modify) A6BB70D5D65F402870AC895A284A3FCB4DE1AE8603C40BE1528060B39BEA1611

	CREATE   VIEW [dbo].[purchtable]
	AS
	SELECT [purchtable].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id]
		,[purchtable].[SinkCreatedOn] AS [SinkCreatedOn]
		,[purchtable].[SinkModifiedOn] AS [SinkModifiedOn]
		,[purchtable].[autosummarymoduletype] AS [autosummarymoduletype]
		,[purchtable].[bankdocumenttype] AS [bankdocumenttype]
		,[purchtable].[changerequestrequired] AS [changerequestrequired]
		,[purchtable].[constarget_jp] AS [constarget_jp]
		,[purchtable].[deliverytype] AS [deliverytype]
		,[purchtable].[documentstate] AS [documentstate]
		,[purchtable].[documentstatus] AS [documentstatus]
		,[purchtable].[freightsliptype] AS [freightsliptype]
		,[purchtable].[fshautocreated] AS [fshautocreated]
		,[purchtable].[incltax] AS [incltax]
		,[purchtable].[intercompanyallowindirectcreation] AS [intercompanyallowindirectcreation]
		,[purchtable].[intercompanydirectdelivery] AS [intercompanydirectdelivery]
		,[purchtable].[intercompanyorder] AS [intercompanyorder]
		,[purchtable].[intercompanyorigin] AS [intercompanyorigin]
		,[purchtable].[invoiceautonumbering_lt] AS [invoiceautonumbering_lt]
		,[purchtable].[isencumbrancerequired] AS [isencumbrancerequired]
		,[purchtable].[ismodified] AS [ismodified]
		,[purchtable].[listcode] AS [listcode]
		,[purchtable].[mcrdropshipment] AS [mcrdropshipment]
		,[purchtable].[onetimesupplier] AS [onetimesupplier]
		,[purchtable].[onetimevendor] AS [onetimevendor]
		,[purchtable].[packingslipautonumbering_lt] AS [packingslipautonumbering_lt]
		,[purchtable].[purchasetype] AS [purchasetype]
		,[purchtable].[purchstatus] AS [purchstatus]
		,[purchtable].[retailretailstatustype] AS [retailretailstatustype]
		,[purchtable].[returnreplacementcreated] AS [returnreplacementcreated]
		,[purchtable].[settlevoucher] AS [settlevoucher]
		,[purchtable].[skipupdate] AS [skipupdate]
		,[purchtable].[systementrysource] AS [systementrysource]
		,[purchtable].[unitedvatinvoice_lt] AS [unitedvatinvoice_lt]
		,[purchtable].[skipcreatemarkup] AS [skipcreatemarkup]
		,[purchtable].[skipversioning] AS [skipversioning]
		,[purchtable].[purchaseorderheadercreationmethod] AS [purchaseorderheadercreationmethod]
		,[purchtable].[invoiceregister_lt] AS [invoiceregister_lt]
		,[purchtable].[packingslipregister_lt] AS [packingslipregister_lt]
		,[purchtable].[cxmlorderenable] AS [cxmlorderenable]
		,[purchtable].[vatnumtabletype] AS [vatnumtabletype]
		,[purchtable].[overridesalestax] AS [overridesalestax]
		,[purchtable].[awaitingworkflowtotalscalculation] AS [awaitingworkflowtotalscalculation]
		,[purchtable].[skipshipreceiptdatecalculation] AS [skipshipreceiptdatecalculation]
		,[purchtable].[isintegration] AS [isintegration]
		,[purchtable].[itmfreightresponsibility] AS [itmfreightresponsibility]
		,[purchtable].[itmmeasurementunit] AS [itmmeasurementunit]
		,[purchtable].[itmoverunder] AS [itmoverunder]
		,[purchtable].[itmimportcostingvendor] AS [itmimportcostingvendor]
		,[purchtable].[itmdataeventtype] AS [itmdataeventtype]
		,[purchtable].[sysdatastatecode] AS [sysdatastatecode]
		,[purchtable].[orderaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [orderaccount]
		,[purchtable].[linedisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [linedisc]
		,[purchtable].[accountingdate] AS [accountingdate]
		,[purchtable].[accountingdistributiontemplate] AS [accountingdistributiontemplate]
		,[purchtable].[addressrefrecid] AS [addressrefrecid]
		,[purchtable].[addressreftableid] AS [addressreftableid]
		,[purchtable].[availsalesdate] AS [availsalesdate]
		,[purchtable].[bankcentralbankpurposecode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [bankcentralbankpurposecode]
		,[purchtable].[bankcentralbankpurposetext] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [bankcentralbankpurposetext]
		,[purchtable].[cashdisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [cashdisc]
		,[purchtable].[cashdiscpercent] AS [cashdiscpercent]
		,[purchtable].[confirmeddlv] AS [confirmeddlv]
		,[purchtable].[confirmeddlvearliest] AS [confirmeddlvearliest]
		,[purchtable].[confirmingpo] AS [confirmingpo]
		,[purchtable].[contactpersonid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [contactpersonid]
		,[purchtable].[contractnum_sa] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [contractnum_sa]
		,[purchtable].[countyorigdest] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [countyorigdest]
		,[purchtable].[covstatus] AS [covstatus]
		,[purchtable].[crossdockingdate] AS [crossdockingdate]
		,[purchtable].[currencycode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencycode]
		,[purchtable].[defaultdimension] AS [defaultdimension]
		,[purchtable].[deliverydate] AS [deliverydate]
		,[purchtable].[deliveryname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliveryname]
		,[purchtable].[deliverypostaladdress] AS [deliverypostaladdress]
		,[purchtable].[discpercent] AS [discpercent]
		,[purchtable].[dlvmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvmode]
		,[purchtable].[dlvterm] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvterm]
		,[purchtable].[email] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [email]
		,[purchtable].[enddisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [enddisc]
		,[purchtable].[enterprisenumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [enterprisenumber]
		,[purchtable].[exchangeratedate] AS [exchangeratedate]
		,[purchtable].[finalizeclosingdate] AS [finalizeclosingdate]
		,[purchtable].[fixedduedate] AS [fixedduedate]
		,[purchtable].[fixedexchrate] AS [fixedexchrate]
		,[purchtable].[freightzone] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [freightzone]
		,[purchtable].[intercompanycompanyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanycompanyid]
		,[purchtable].[intercompanycustpurchorderformnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanycustpurchorderformnum]
		,[purchtable].[intercompanyoriginalcustaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyoriginalcustaccount]
		,[purchtable].[intercompanyoriginalsalesid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyoriginalsalesid]
		,[purchtable].[intercompanysalesid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanysalesid]
		,[purchtable].[intrastataddvalue_lv] AS [intrastataddvalue_lv]
		,[purchtable].[intrastatfulfillmentdate_hu] AS [intrastatfulfillmentdate_hu]
		,[purchtable].[inventlocationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventlocationid]
		,[purchtable].[inventsiteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventsiteid]
		,[purchtable].[invoiceaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [invoiceaccount]
		,[purchtable].[itembuyergroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itembuyergroupid]
		,[purchtable].[languageid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [languageid]
		,[purchtable].[localdeliverydate] AS [localdeliverydate]
		,[purchtable].[manualentrychangepolicy] AS [manualentrychangepolicy]
		,[purchtable].[markupgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [markupgroup]
		,[purchtable].[matchingagreement] AS [matchingagreement]
		,[purchtable].[multilinedisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [multilinedisc]
		,[purchtable].[numbersequencegroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [numbersequencegroup]
		,[purchtable].[payment] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [payment]
		,[purchtable].[paymentsched] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymentsched]
		,[purchtable].[paymmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymmode]
		,[purchtable].[paymspec] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymspec]
		,[purchtable].[port] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [port]
		,[purchtable].[postingprofile] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [postingprofile]
		,[purchtable].[pricegroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pricegroupid]
		,[purchtable].[projid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projid]
		,[purchtable].[purchid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchid]
		,[purchtable].[purchname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchname]
		,[purchtable].[purchpoolid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchpoolid]
		,[purchtable].[reasontableref] AS [reasontableref]
		,[purchtable].[receiptdateconfirmed] AS [receiptdateconfirmed]
		,[purchtable].[replenishmentlocation] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [replenishmentlocation]
		,[purchtable].[reqattention] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [reqattention]
		,[purchtable].[requester] AS [requester]
		,[purchtable].[retaildriverdetails] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [retaildriverdetails]
		,[purchtable].[returnitemnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnitemnum]
		,[purchtable].[returnreasoncodeid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnreasoncodeid]
		,[purchtable].[serviceaddress] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [serviceaddress]
		,[purchtable].[servicecategory] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [servicecategory]
		,[purchtable].[servicedate] AS [servicedate]
		,[purchtable].[servicename] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [servicename]
		,[purchtable].[shippingdateconfirmed] AS [shippingdateconfirmed]
		,[purchtable].[shippingdaterequested] AS [shippingdaterequested]
		,[purchtable].[sourcedocumentheader] AS [sourcedocumentheader]
		,[purchtable].[sourcedocumentline] AS [sourcedocumentline]
		,[purchtable].[statprocid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [statprocid]
		,[purchtable].[systementrychangepolicy] AS [systementrychangepolicy]
		,[purchtable].[tamvendrebategroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamvendrebategroupid]
		,[purchtable].[taxgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxgroup]
		,[purchtable].[taxperiodpaymentcode_pl] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxperiodpaymentcode_pl]
		,[purchtable].[transactioncode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transactioncode]
		,[purchtable].[transport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transport]
		,[purchtable].[transportationdocument] AS [transportationdocument]
		,[purchtable].[url] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [url]
		,[purchtable].[vatnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vatnum]
		,[purchtable].[vendgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendgroup]
		,[purchtable].[vendinvoicedeclaration_is] AS [vendinvoicedeclaration_is]
		,[purchtable].[vendorref] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendorref]
		,[purchtable].[workerpurchplacer] AS [workerpurchplacer]
		,[purchtable].[purchorderformnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchorderformnum]
		,[purchtable].[billtoaddress] AS [billtoaddress]
		,[purchtable].[reportingcurrencyfixedexchrate] AS [reportingcurrencyfixedexchrate]
		,[purchtable].[vatnumrecid] AS [vatnumrecid]
		,[purchtable].[requestedshipdate] AS [requestedshipdate]
		,[purchtable].[confirmedshipdate] AS [confirmedshipdate]
		,[purchtable].[shipcalendarid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcalendarid]
		,[purchtable].[projsubcontractnumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projsubcontractnumber]
		,[purchtable].[fintag] AS [fintag]
		,[purchtable].[intentletterid_it] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intentletterid_it]
		,[purchtable].[eximports_in] AS [eximports_in]
		,[purchtable].[tradeendcustomeraccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tradeendcustomeraccount]
		,[purchtable].[itmmentconfirmation] AS [itmmentconfirmation]
		,[purchtable].[itmmeasurement] AS [itmmeasurement]
		,[purchtable].[itmagent] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmagent]
		,[purchtable].[itmdate] AS [itmdate]
		,[purchtable].[itmfromport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmfromport]
		,[purchtable].[itmstatusid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmstatusid]
		,[purchtable].[itmvendaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmvendaccount]
		,[purchtable].[itmintostoredate] AS [itmintostoredate]
		,[purchtable].[itmcontractnumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmcontractnumber]
		,[purchtable].[itmexfactorydate] AS [itmexfactorydate]
		,[purchtable].[tamrebatereference] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamrebatereference]
		,[purchtable].[modifieddatetime] AS [modifieddatetime]
		,[purchtable].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby]
		,[purchtable].[modifiedtransactionid] AS [modifiedtransactionid]
		,[purchtable].[createddatetime] AS [createddatetime]
		,[purchtable].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby]
		,[purchtable].[createdtransactionid] AS [createdtransactionid]
		,[purchtable].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid]
		,[purchtable].[recversion] AS [recversion]
		,[purchtable].[partition] AS [partition]
		,[purchtable].[sysrowversion] AS [sysrowversion]
		,[purchtable].[recid] AS [recid]
		,[purchtable].[tableid] AS [tableid]
		,[purchtable].[versionnumber] AS [versionnumber]
		,[purchtable].[createdon] AS [createdon]
		,[purchtable].[modifiedon] AS [modifiedon]
		,[purchtable].[IsDelete] AS [IsDelete]
		,[purchtable].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
		,CASE [purchtable].[autosummarymoduletype]
			WHEN 0
				THEN 'Vend'
			WHEN 1
				THEN 'Purch'
			END AS autosummarymoduletype_$label
		,CASE [purchtable].[awaitingworkflowtotalscalculation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS awaitingworkflowtotalscalculation_$label
		,CASE [purchtable].[bankdocumenttype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'LetterOfCredit'
			WHEN 2
				THEN 'ImportCollection'
			WHEN 3
				THEN 'LetterOfGuarantee'
			END AS bankdocumenttype_$label
		,CASE [purchtable].[changerequestrequired]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS changerequestrequired_$label
		,CASE [purchtable].[constarget_jp]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS constarget_jp_$label
		,CASE [purchtable].[cxmlorderenable]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS cxmlorderenable_$label
		,CASE [purchtable].[deliverytype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Company'
			END AS deliverytype_$label
		,CASE [purchtable].[documentstate]
			WHEN 20
				THEN 'Rejected'
			WHEN 30
				THEN 'Approved'
			WHEN 35
				THEN 'InExternalReview'
			WHEN 50
				THEN 'Finalized'
			WHEN 40
				THEN 'Confirmed'
			WHEN 0
				THEN 'Draft'
			WHEN 10
				THEN 'InReview'
			END AS documentstate_$label
		,CASE [purchtable].[documentstatus]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Quotation'
			WHEN 2
				THEN 'PurchaseOrder'
			WHEN 3
				THEN 'Confirmation'
			WHEN 4
				THEN 'PickingList'
			WHEN 5
				THEN 'PackingSlip'
			WHEN 6
				THEN 'ReceiptsList'
			WHEN 7
				THEN 'Invoice'
			WHEN 8
				THEN 'ApproveJournal'
			WHEN 9
				THEN 'ProjectInvoice'
			WHEN 10
				THEN 'ProjectPackingSlip'
			WHEN 11
				THEN 'CRMQuotation'
			WHEN 12
				THEN 'Lost'
			WHEN 13
				THEN 'Cancelled'
			WHEN 14
				THEN 'FreeTextInvoice'
			WHEN 15
				THEN 'RFQ'
			WHEN 16
				THEN 'RFQAccept'
			WHEN 17
				THEN 'RFQReject'
			WHEN 18
				THEN 'PurchReq'
			WHEN 19
				THEN 'RFQReSend'
			WHEN 30
				THEN 'ConfirmationRequest'
			WHEN 219
				THEN 'InvoiceRegistration_IN'
			WHEN 220
				THEN 'BillOfEntry_IN'
			WHEN 221
				THEN 'ShippingBill_IN'
			WHEN 101
				THEN 'Invoice4Paym_RU'
			WHEN 102
				THEN 'Facture_RU'
			WHEN 105
				THEN 'FreeTextInvoice4Paym_RU'
			WHEN 150
				THEN 'DeliverySlip_BR'
			WHEN 103
				THEN 'PlSAD'
			WHEN 222
				THEN 'DeliverySlipProject_BR'
			WHEN 20
				THEN 'Note'
			WHEN 21
				THEN 'ProjectPickingList'
			WHEN 22
				THEN 'ITMGoodsInTransitReceive'
			WHEN 23
				THEN 'RevRecRevenueCancelation'
			WHEN 24
				THEN 'RevRecDeferredRevenueInvoice'
			END AS documentstatus_$label
		,CASE [purchtable].[freightsliptype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'UPS'
			END AS freightsliptype_$label
		,CASE [purchtable].[fshautocreated]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS fshautocreated_$label
		,CASE [purchtable].[incltax]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS incltax_$label
		,CASE [purchtable].[intercompanyallowindirectcreation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS intercompanyallowindirectcreation_$label
		,CASE [purchtable].[intercompanydirectdelivery]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS intercompanydirectdelivery_$label
		,CASE [purchtable].[intercompanyorder]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS intercompanyorder_$label
		,CASE [purchtable].[intercompanyorigin]
			WHEN 0
				THEN 'Source'
			WHEN 1
				THEN 'Derived'
			END AS intercompanyorigin_$label
		,CASE [purchtable].[invoiceautonumbering_lt]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS invoiceautonumbering_lt_$label
		,CASE [purchtable].[invoiceregister_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS invoiceregister_lt_$label
		,CASE [purchtable].[isencumbrancerequired]
			WHEN 0
				THEN 'Unknown'
			WHEN 1
				THEN 'No'
			WHEN 2
				THEN 'Yes'
			END AS isencumbrancerequired_$label
		,CASE [purchtable].[isintegration]
			WHEN 3
				THEN 'DataEntity'
			WHEN 2
				THEN 'Dynamics365Sales'
			WHEN 1
				THEN 'CDS'
			WHEN 0
				THEN 'No'
			END AS isintegration_$label
		,CASE [purchtable].[ismodified]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS ismodified_$label
		,CASE [purchtable].[itmdataeventtype]
			WHEN 50
				THEN 'DeletedLite'
			WHEN 49
				THEN 'UpdatedLite'
			WHEN 48
				THEN 'InsertedLite'
			WHEN 47
				THEN 'FinalInsertValidation'
			WHEN 46
				THEN 'FinalUpdateValidation'
			WHEN 45
				THEN 'FinalDeleteValidation'
			WHEN 44
				THEN 'FinalReadValidation'
			WHEN 43
				THEN 'GotDefaultingDependencies'
			WHEN 42
				THEN 'GettingDefaultingDependencies'
			WHEN 41
				THEN 'DefaultedRow'
			WHEN 40
				THEN 'DefaultingRow'
			WHEN 39
				THEN 'DefaultedField'
			WHEN 38
				THEN 'DefaultingField'
			WHEN 37
				THEN 'PostedLoad'
			WHEN 36
				THEN 'PostingLoad'
			WHEN 35
				THEN 'DeletedEntityDataSource'
			WHEN 34
				THEN 'DeletingEntityDataSource'
			WHEN 33
				THEN 'UpdatedEntityDataSource'
			WHEN 32
				THEN 'UpdatingEntityDataSource'
			WHEN 31
				THEN 'InsertedEntityDataSource'
			WHEN 30
				THEN 'InsertingEntityDataSource'
			WHEN 29
				THEN 'FoundEntityDataSource'
			WHEN 28
				THEN 'FindingEntityDataSource'
			WHEN 27
				THEN 'MappedDataSourceToEntity'
			WHEN 26
				THEN 'MappingDataSourceToEntity'
			WHEN 25
				THEN 'MappedEntityToDataSource'
			WHEN 24
				THEN 'MappingEntityToDataSource'
			WHEN 23
				THEN 'InitializedEntityDataSource'
			WHEN 22
				THEN 'InitializingEntityDataSource'
			WHEN 21
				THEN 'PersistedEntity'
			WHEN 20
				THEN 'PersistingEntity'
			WHEN 19
				THEN 'ModifiedFieldValue'
			WHEN 18
				THEN 'ModifyingFieldValue'
			WHEN 17
				THEN 'ValidatedFieldValue'
			WHEN 16
				THEN 'ValidatingFieldValue'
			WHEN 15
				THEN 'ModifiedField'
			WHEN 14
				THEN 'ModifyingField'
			WHEN 13
				THEN 'ValidatedField'
			WHEN 12
				THEN 'ValidatingField'
			WHEN 11
				THEN 'InitializedRecord'
			WHEN 10
				THEN 'InitializingRecord'
			WHEN 9
				THEN 'ValidatedDelete'
			WHEN 8
				THEN 'ValidatingDelete'
			WHEN 7
				THEN 'ValidatedWrite'
			WHEN 6
				THEN 'ValidatingWrite'
			WHEN 5
				THEN 'Deleted'
			WHEN 4
				THEN 'Deleting'
			WHEN 3
				THEN 'Updated'
			WHEN 2
				THEN 'Updating'
			WHEN 1
				THEN 'Inserted'
			WHEN 0
				THEN 'Inserting'
			END AS itmdataeventtype_$label
		,CASE [purchtable].[itmfreightresponsibility]
			WHEN 0
				THEN 'None'
			WHEN 2
				THEN 'BuyerToPayDiff'
			WHEN 1
				THEN 'FactoryToPaySea'
			END AS itmfreightresponsibility_$label
		,CASE [purchtable].[itmimportcostingvendor]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS itmimportcostingvendor_$label
		,CASE [purchtable].[itmmeasurementunit]
			WHEN 5
				THEN 'CubicFeet'
			WHEN 4
				THEN 'Kilogramme'
			WHEN 3
				THEN 'Skids'
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Pounds'
			WHEN 2
				THEN 'CubicMetre'
			END AS itmmeasurementunit_$label
		,CASE [purchtable].[itmoverunder]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS itmoverunder_$label
		,CASE [purchtable].[listcode]
			WHEN 0
				THEN 'IncludeNot'
			WHEN 1
				THEN 'EUTrade'
			WHEN 2
				THEN 'ProductionOnToll'
			WHEN 3
				THEN 'TriangularEUTrade'
			WHEN 4
				THEN 'TriangularProductionOnToll'
			WHEN 50
				THEN 'PropertyMoving_CZ'
			WHEN 51
				THEN 'TriangularIntermediateRole_HU'
			WHEN 52
				THEN 'DEL_EUService'
			WHEN 53
				THEN 'PurchasedOnBehalf_LV'
			END AS listcode_$label
		,CASE [purchtable].[mcrdropshipment]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS mcrdropshipment_$label
		,CASE [purchtable].[onetimesupplier]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS onetimesupplier_$label
		,CASE [purchtable].[onetimevendor]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS onetimevendor_$label
		,CASE [purchtable].[overridesalestax]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS overridesalestax_$label
		,CASE [purchtable].[packingslipautonumbering_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS packingslipautonumbering_lt_$label
		,CASE [purchtable].[packingslipregister_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS packingslipregister_lt_$label
		,CASE [purchtable].[purchaseorderheadercreationmethod]
			WHEN 1
				THEN 'Consignment'
			WHEN 0
				THEN 'Purchase'
			END AS purchaseorderheadercreationmethod_$label
		,CASE [purchtable].[purchasetype]
			WHEN 0
				THEN 'Journal'
			WHEN 1
				THEN 'DEL_Quotation'
			WHEN 2
				THEN 'DEL_Subscription'
			WHEN 3
				THEN 'Purch'
			WHEN 4
				THEN 'ReturnItem'
			WHEN 5
				THEN 'DEL_Blanket'
			END AS purchasetype_$label
		,CASE [purchtable].[purchstatus]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Open'
			WHEN 2
				THEN 'Received'
			WHEN 3
				THEN 'Invoiced'
			WHEN 4
				THEN 'Canceled'
			END AS purchstatus_$label
		,CASE [purchtable].[retailretailstatustype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Document'
			WHEN 2
				THEN 'Sent'
			WHEN 3
				THEN 'PartReceipt'
			WHEN 4
				THEN 'ClosedOk'
			WHEN 5
				THEN 'ClosedDifference'
			WHEN 6
				THEN 'Canceled'
			END AS retailretailstatustype_$label
		,CASE [purchtable].[returnreplacementcreated]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS returnreplacementcreated_$label
		,CASE [purchtable].[settlevoucher]
			WHEN 2
				THEN 'SelectedTransact'
			WHEN 1
				THEN 'OpenTransact'
			WHEN 0
				THEN 'None'
			END AS settlevoucher_$label
		,CASE [purchtable].[skipcreatemarkup]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS skipcreatemarkup_$label
		,CASE [purchtable].[skipshipreceiptdatecalculation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS skipshipreceiptdatecalculation_$label
		,CASE [purchtable].[skipupdate]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Internal'
			WHEN 2
				THEN 'InterCompany'
			WHEN 3
				THEN 'Both'
			END AS skipupdate_$label
		,CASE [purchtable].[skipversioning]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS skipversioning_$label
		,CASE [purchtable].[systementrysource]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'CopyFromSalesOrder'
			WHEN 2
				THEN 'CopyFromSalesQuotation'
			WHEN 3
				THEN 'Project'
			WHEN 4
				THEN 'SalesQuotation'
			WHEN 5
				THEN 'CopyFromPurchaseOrder'
			WHEN 6
				THEN 'RequestForQuote'
			WHEN 7
				THEN 'PurchaseReq'
			WHEN 8
				THEN 'ManualEntry'
			WHEN 9
				THEN 'Agreement'
			WHEN 11
				THEN 'ProductConfig'
			WHEN 12
				THEN 'RetailPOS'
			END AS systementrysource_$label
		,CASE [purchtable].[unitedvatinvoice_lt]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS unitedvatinvoice_lt_$label
		,CASE [purchtable].[vatnumtabletype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'TaxRegistration'
			WHEN 2
				THEN 'TaxVATNumTable'
			END AS vatnumtabletype_$label
	FROM [dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8].dbo.purchtable
	WHERE purchtable.IsDelete IS NULL