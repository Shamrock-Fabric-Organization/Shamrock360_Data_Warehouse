-- Auto Generated (Do not modify) 93F6A95030FF2C53737DF1F8226B7352E4F6659C84621158212C03DE21EF3147

	CREATE   VIEW  salestable 
	AS
	SELECT [salestable].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id]
		,[salestable].[SinkCreatedOn] AS [SinkCreatedOn]
		,[salestable].[SinkModifiedOn] AS [SinkModifiedOn]
		,[salestable].[autosummarymoduletype] AS [autosummarymoduletype]
		,[salestable].[bankdocumenttype] AS [bankdocumenttype]
		,[salestable].[casetagging] AS [casetagging]
		,[salestable].[constarget_jp] AS [constarget_jp]
		,[salestable].[creditcardauthorizationerror] AS [creditcardauthorizationerror]
		,[salestable].[customsexportorder_in] AS [customsexportorder_in]
		,[salestable].[customsshippingbill_in] AS [customsshippingbill_in]
		,[salestable].[deliverydatecontroltype] AS [deliverydatecontroltype]
		,[salestable].[documentstatus] AS [documentstatus]
		,[salestable].[einvoicelinespec] AS [einvoicelinespec]
		,[salestable].[fiscaldoctype_pl] AS [fiscaldoctype_pl]
		,[salestable].[freightsliptype] AS [freightsliptype]
		,[salestable].[girotype] AS [girotype]
		,[salestable].[incltax] AS [incltax]
		,[salestable].[intercompanyallowindirectcreation] AS [intercompanyallowindirectcreation]
		,[salestable].[intercompanyallowindirectcreationorig] AS [intercompanyallowindirectcreationorig]
		,[salestable].[intercompanyautocreateorders] AS [intercompanyautocreateorders]
		,[salestable].[intercompanydirectdelivery] AS [intercompanydirectdelivery]
		,[salestable].[intercompanydirectdeliveryorig] AS [intercompanydirectdeliveryorig]
		,[salestable].[intercompanyorder] AS [intercompanyorder]
		,[salestable].[intercompanyorigin] AS [intercompanyorigin]
		,[salestable].[invoiceautonumbering_lt] AS [invoiceautonumbering_lt]
		,[salestable].[itemtagging] AS [itemtagging]
		,[salestable].[listcode] AS [listcode]
		,[salestable].[mcrorderstopped] AS [mcrorderstopped]
		,[salestable].[natureofassessee_in] AS [natureofassessee_in]
		,[salestable].[onetimecustomer] AS [onetimecustomer]
		,[salestable].[packingslipautonumbering_lt] AS [packingslipautonumbering_lt]
		,[salestable].[pallettagging] AS [pallettagging]
		,[salestable].[pdsbatchattribautores] AS [pdsbatchattribautores]
		,[salestable].[releasestatus] AS [releasestatus]
		,[salestable].[reservation] AS [reservation]
		,[salestable].[returnreplacementcreated] AS [returnreplacementcreated]
		,[salestable].[returnstatus] AS [returnstatus]
		,[salestable].[salesstatus] AS [salesstatus]
		,[salestable].[salestype] AS [salestype]
		,[salestable].[settlevoucher] AS [settlevoucher]
		,[salestable].[shipcarrierblindshipment] AS [shipcarrierblindshipment]
		,[salestable].[shipcarrierdlvtype] AS [shipcarrierdlvtype]
		,[salestable].[shipcarrierexpeditedshipment] AS [shipcarrierexpeditedshipment]
		,[salestable].[shipcarrierfuelsurcharge] AS [shipcarrierfuelsurcharge]
		,[salestable].[shipcarrierresidential] AS [shipcarrierresidential]
		,[salestable].[skipupdate] AS [skipupdate]
		,[salestable].[systementrysource] AS [systementrysource]
		,[salestable].[touched] AS [touched]
		,[salestable].[unitedvatinvoice_lt] AS [unitedvatinvoice_lt]
		,[salestable].[skipcreatemarkup] AS [skipcreatemarkup]
		,[salestable].[skiplineupdate] AS [skiplineupdate]
		,[salestable].[invoiceregister_lt] AS [invoiceregister_lt]
		,[salestable].[packingslipregister_lt] AS [packingslipregister_lt]
		,[salestable].[foreigntrade_mx] AS [foreigntrade_mx]
		,[salestable].[sourcecertificate_mx] AS [sourcecertificate_mx]
		,[salestable].[vatnumtabletype] AS [vatnumtabletype]
		,[salestable].[overridesalestax] AS [overridesalestax]
		,[salestable].[mpsfullrunctpstatus] AS [mpsfullrunctpstatus]
		,[salestable].[isintegration] AS [isintegration]
		,[salestable].[mpsexcludesalesorder] AS [mpsexcludesalesorder]
		,[salestable].[mpsupdateexcludesalesorder] AS [mpsupdateexcludesalesorder]
		,[salestable].[salesorderintegrationcreationtype] AS [salesorderintegrationcreationtype]
		,[salestable].[commissiontype_it] AS [commissiontype_it]
		,[salestable].[printdynamicqrcode_in] AS [printdynamicqrcode_in]
		,[salestable].[invoicetype_w] AS [invoicetype_w]
		,[salestable].[cfditemporaryexport_mx] AS [cfditemporaryexport_mx]
		,[salestable].[credmanexcludesalesorder] AS [credmanexcludesalesorder]
		,[salestable].[credmanreleasedfromcreditcontrol] AS [credmanreleasedfromcreditcontrol]
		,[salestable].[credmanrejected] AS [credmanrejected]
		,[salestable].[credmanincreditcontrol] AS [credmanincreditcontrol]
		,[salestable].[domprocessed] AS [domprocessed]
		,[salestable].[domignore] AS [domignore]
		,[salestable].[domexceptiontype] AS [domexceptiontype]
		,[salestable].[subbillcreatedfromsb] AS [subbillcreatedfromsb]
		,[salestable].[subbillsuppresschilditems] AS [subbillsuppresschilditems]
		,[salestable].[revrecfolloworiginalpricingmethod] AS [revrecfolloworiginalpricingmethod]
		,[salestable].[revrecmultiplesoreallocation] AS [revrecmultiplesoreallocation]
		,[salestable].[gupskippricingcalculation] AS [gupskippricingcalculation]
		,[salestable].[gupdelaypricingcalculation] AS [gupdelaypricingcalculation]
		,[salestable].[sks_cc_invoiceerroraftercapture] AS [sks_cc_invoiceerroraftercapture]
		,[salestable].[sks_cc_skipautoauthduetopartialship] AS [sks_cc_skipautoauthduetopartialship]
		,[salestable].[sks_cc_paylinkstatus] AS [sks_cc_paylinkstatus]
		,[salestable].[sysdatastatecode] AS [sysdatastatecode]
		,[salestable].[linedisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [linedisc]
		,[salestable].[salesid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesid]
		,[salestable].[tdsgroup_in] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tdsgroup_in]
		,[salestable].[addressrefrecid] AS [addressrefrecid]
		,[salestable].[addressreftableid] AS [addressreftableid]
		,[salestable].[bankaccount_lv] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [bankaccount_lv]
		,[salestable].[bankcentralbankpurposecode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [bankcentralbankpurposecode]
		,[salestable].[bankcentralbankpurposetext] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [bankcentralbankpurposetext]
		,[salestable].[cashdisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [cashdisc]
		,[salestable].[cashdiscbasedate] AS [cashdiscbasedate]
		,[salestable].[cashdiscbasedays] AS [cashdiscbasedays]
		,[salestable].[cashdiscpercent] AS [cashdiscpercent]
		,[salestable].[commissiongroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [commissiongroup]
		,[salestable].[contactpersonid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [contactpersonid]
		,[salestable].[countyorigdest] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [countyorigdest]
		,[salestable].[covstatus] AS [covstatus]
		,[salestable].[creditcardapprovalamount] AS [creditcardapprovalamount]
		,[salestable].[creditcardauthorization] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [creditcardauthorization]
		,[salestable].[creditcardcustrefid] AS [creditcardcustrefid]
		,[salestable].[creditnotereasoncode] AS [creditnotereasoncode]
		,[salestable].[curbankaccount_lv] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [curbankaccount_lv]
		,[salestable].[currencycode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencycode]
		,[salestable].[custaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custaccount]
		,[salestable].[custbankaccount_lv] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custbankaccount_lv]
		,[salestable].[custgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custgroup]
		,[salestable].[custinvoiceid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custinvoiceid]
		,[salestable].[customerref] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customerref]
		,[salestable].[deadline] AS [deadline]
		,[salestable].[defaultdimension] AS [defaultdimension]
		,[salestable].[deliverydate] AS [deliverydate]
		,[salestable].[deliveryname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliveryname]
		,[salestable].[deliverypostaladdress] AS [deliverypostaladdress]
		,[salestable].[directdebitmandate] AS [directdebitmandate]
		,[salestable].[discpercent] AS [discpercent]
		,[salestable].[dlvmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvmode]
		,[salestable].[dlvreason] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvreason]
		,[salestable].[dlvterm] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvterm]
		,[salestable].[einvoiceaccountcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [einvoiceaccountcode]
		,[salestable].[email] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [email]
		,[salestable].[enddisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [enddisc]
		,[salestable].[enterprisenumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [enterprisenumber]
		,[salestable].[estimate] AS [estimate]
		,[salestable].[exportreason] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [exportreason]
		,[salestable].[fixedduedate] AS [fixedduedate]
		,[salestable].[fixedexchrate] AS [fixedexchrate]
		,[salestable].[freightzone] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [freightzone]
		,[salestable].[intercompanycompanyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanycompanyid]
		,[salestable].[intercompanyoriginalcustaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyoriginalcustaccount]
		,[salestable].[intercompanyoriginalsalesid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyoriginalsalesid]
		,[salestable].[intercompanypurchid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanypurchid]
		,[salestable].[intrastataddvalue_lv] AS [intrastataddvalue_lv]
		,[salestable].[intrastatfulfillmentdate_hu] AS [intrastatfulfillmentdate_hu]
		,[salestable].[inventlocationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventlocationid]
		,[salestable].[inventsiteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventsiteid]
		,[salestable].[invoiceaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [invoiceaccount]
		,[salestable].[languageid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [languageid]
		,[salestable].[manualentrychangepolicy] AS [manualentrychangepolicy]
		,[salestable].[markupgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [markupgroup]
		,[salestable].[matchingagreement] AS [matchingagreement]
		,[salestable].[multilinedisc] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [multilinedisc]
		,[salestable].[numbersequencegroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [numbersequencegroup]
		,[salestable].[payment] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [payment]
		,[salestable].[paymentsched] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymentsched]
		,[salestable].[paymmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymmode]
		,[salestable].[paymspec] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [paymspec]
		,[salestable].[pdscustrebategroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pdscustrebategroupid]
		,[salestable].[pdsrebateprogramtmagroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pdsrebateprogramtmagroup]
		,[salestable].[port] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [port]
		,[salestable].[postingprofile] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [postingprofile]
		,[salestable].[pricegroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pricegroupid]
		,[salestable].[projid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projid]
		,[salestable].[purchid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchid]
		,[salestable].[purchorderformnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchorderformnum]
		,[salestable].[quotationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [quotationid]
		,[salestable].[receiptdateconfirmed] AS [receiptdateconfirmed]
		,[salestable].[receiptdaterequested] AS [receiptdaterequested]
		,[salestable].[retailchanneltable] AS [retailchanneltable]
		,[salestable].[returndeadline] AS [returndeadline]
		,[salestable].[returnitemnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnitemnum]
		,[salestable].[returnreasoncodeid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnreasoncodeid]
		,[salestable].[returnreplacementid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnreplacementid]
		,[salestable].[salesgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesgroup]
		,[salestable].[salesname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesname]
		,[salestable].[salesoriginid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesoriginid]
		,[salestable].[salespoolid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salespoolid]
		,[salestable].[salesunitid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesunitid]
		,[salestable].[shipcarrieraccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrieraccount]
		,[salestable].[shipcarrieraccountcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrieraccountcode]
		,[salestable].[shipcarrierdeliverycontact] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrierdeliverycontact]
		,[salestable].[shipcarrierid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrierid]
		,[salestable].[shipcarriername] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarriername]
		,[salestable].[shipcarrierpostaladdress] AS [shipcarrierpostaladdress]
		,[salestable].[shippingdateconfirmed] AS [shippingdateconfirmed]
		,[salestable].[shippingdaterequested] AS [shippingdaterequested]
		,[salestable].[smmcampaignid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [smmcampaignid]
		,[salestable].[smmsalesamounttotal] AS [smmsalesamounttotal]
		,[salestable].[sourcedocumentheader] AS [sourcedocumentheader]
		,[salestable].[statprocid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [statprocid]
		,[salestable].[systementrychangepolicy] AS [systementrychangepolicy]
		,[salestable].[taxgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxgroup]
		,[salestable].[taxperiodpaymentcode_pl] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxperiodpaymentcode_pl]
		,[salestable].[tcsgroup_in] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tcsgroup_in]
		,[salestable].[transactioncode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transactioncode]
		,[salestable].[transport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transport]
		,[salestable].[transportationdocument] AS [transportationdocument]
		,[salestable].[url] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [url]
		,[salestable].[vatnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vatnum]
		,[salestable].[workersalesresponsible] AS [workersalesresponsible]
		,[salestable].[workersalestaker] AS [workersalestaker]
		,[salestable].[einvoicecfdiconfirmnumber_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [einvoicecfdiconfirmnumber_mx]
		,[salestable].[satpaymmethod_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satpaymmethod_mx]
		,[salestable].[satpurpose_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satpurpose_mx]
		,[salestable].[certificatenumber_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [certificatenumber_mx]
		,[salestable].[fiscaladdress_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [fiscaladdress_mx]
		,[salestable].[numregidtrib_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [numregidtrib_mx]
		,[salestable].[satincotermcode_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satincotermcode_mx]
		,[salestable].[satshippingreason_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satshippingreason_mx]
		,[salestable].[accountingdistributiontemplate] AS [accountingdistributiontemplate]
		,[salestable].[fundingsource] AS [fundingsource]
		,[salestable].[reportingcurrencyfixedexchrate] AS [reportingcurrencyfixedexchrate]
		,[salestable].[asohorderclass] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [asohorderclass]
		,[salestable].[phone] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [phone]
		,[salestable].[vatnumrecid] AS [vatnumrecid]
		,[salestable].[fintag] AS [fintag]
		,[salestable].[intentletterid_it] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intentletterid_it]
		,[salestable].[taxid] AS [taxid]
		,[salestable].[eximports_in] AS [eximports_in]
		,[salestable].[electronicinvoiceframeworktype_fr] AS [electronicinvoiceframeworktype_fr]
		,[salestable].[servicecode_fr] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [servicecode_fr]
		,[salestable].[projectmanager_fr] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projectmanager_fr]
		,[salestable].[servicecoderefrecid] AS [servicecoderefrecid]
		,[salestable].[customsregime_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customsregime_mx]
		,[salestable].[credmanid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [credmanid]
		,[salestable].[domiterations] AS [domiterations]
		,[salestable].[domprocesseddatetime] AS [domprocesseddatetime]
		,[salestable].[tamdeductionid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamdeductionid]
		,[salestable].[tamrebatereference] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamrebatereference]
		,[salestable].[subbillbilltoname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [subbillbilltoname]
		,[salestable].[subbillbilltopostaladdress] AS [subbillbilltopostaladdress]
		,[salestable].[revreccontractenddate] AS [revreccontractenddate]
		,[salestable].[revreccontractstartdate] AS [revreccontractstartdate]
		,[salestable].[revreclatestreversejournal] AS [revreclatestreversejournal]
		,[salestable].[revrecreallocationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [revrecreallocationid]
		,[salestable].[sks_cc_tmpcreditcardcustrefidforskipauth] AS [sks_cc_tmpcreditcardcustrefidforskipauth]
		,[salestable].[sks_cc_paylinkcount] AS [sks_cc_paylinkcount]
		,[salestable].[sks_cc_paylinkerrormsg] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sks_cc_paylinkerrormsg]
		,[salestable].[modifieddatetime] AS [modifieddatetime]
		,[salestable].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby]
		,[salestable].[modifiedtransactionid] AS [modifiedtransactionid]
		,[salestable].[createddatetime] AS [createddatetime]
		,[salestable].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby]
		,[salestable].[createdtransactionid] AS [createdtransactionid]
		,[salestable].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid]
		,[salestable].[recversion] AS [recversion]
		,[salestable].[partition] AS [partition]
		,[salestable].[sysrowversion] AS [sysrowversion]
		,[salestable].[recid] AS [recid]
		,[salestable].[tableid] AS [tableid]
		,[salestable].[versionnumber] AS [versionnumber]
		,[salestable].[createdon] AS [createdon]
		,[salestable].[modifiedon] AS [modifiedon]
		,[salestable].[IsDelete] AS [IsDelete]
		,[salestable].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
		,CASE [salestable].[autosummarymoduletype]
			WHEN 0
				THEN 'Cust'
			WHEN 1
				THEN 'Sales'
			END AS autosummarymoduletype_$label
		,CASE [salestable].[bankdocumenttype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'LetterOfCredit'
			WHEN 2
				THEN 'ImportCollection'
			WHEN 3
				THEN 'LetterOfGuarantee'
			END AS bankdocumenttype_$label
		,CASE [salestable].[casetagging]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS casetagging_$label
		,CASE [salestable].[cfditemporaryexport_mx]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS cfditemporaryexport_mx_$label
		,CASE [salestable].[commissiontype_it]
			WHEN 0
				THEN 'Invoice'
			WHEN 1
				THEN 'Payment'
			END AS commissiontype_it_$label
		,CASE [salestable].[constarget_jp]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS constarget_jp_$label
		,CASE [salestable].[creditcardauthorizationerror]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS creditcardauthorizationerror_$label
		,CASE [salestable].[credmanexcludesalesorder]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS credmanexcludesalesorder_$label
		,CASE [salestable].[credmanincreditcontrol]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS credmanincreditcontrol_$label
		,CASE [salestable].[credmanrejected]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS credmanrejected_$label
		,CASE [salestable].[credmanreleasedfromcreditcontrol]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS credmanreleasedfromcreditcontrol_$label
		,CASE [salestable].[customsexportorder_in]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS customsexportorder_in_$label
		,CASE [salestable].[customsshippingbill_in]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS customsshippingbill_in_$label
		,CASE [salestable].[deliverydatecontroltype]
			WHEN 5
				THEN 'FullRunCTP'
			WHEN 4
				THEN 'CTP'
			WHEN 3
				THEN 'ATPPlusIssueMargin'
			WHEN 2
				THEN 'ATP'
			WHEN 1
				THEN 'SalesLeadTime'
			WHEN 0
				THEN 'None'
			END AS deliverydatecontroltype_$label
		,CASE [salestable].[documentstatus]
			WHEN 24
				THEN 'RevRecDeferredRevenueInvoice'
			WHEN 23
				THEN 'RevRecRevenueCancelation'
			WHEN 22
				THEN 'ITMGoodsInTransitReceive'
			WHEN 21
				THEN 'ProjectPickingList'
			WHEN 20
				THEN 'Note'
			WHEN 222
				THEN 'DeliverySlipProject_BR'
			WHEN 103
				THEN 'PlSAD'
			WHEN 150
				THEN 'DeliverySlip_BR'
			WHEN 105
				THEN 'FreeTextInvoice4Paym_RU'
			WHEN 102
				THEN 'Facture_RU'
			WHEN 101
				THEN 'Invoice4Paym_RU'
			WHEN 221
				THEN 'ShippingBill_IN'
			WHEN 220
				THEN 'BillOfEntry_IN'
			WHEN 219
				THEN 'InvoiceRegistration_IN'
			WHEN 30
				THEN 'ConfirmationRequest'
			WHEN 19
				THEN 'RFQReSend'
			WHEN 18
				THEN 'PurchReq'
			WHEN 17
				THEN 'RFQReject'
			WHEN 16
				THEN 'RFQAccept'
			WHEN 15
				THEN 'RFQ'
			WHEN 14
				THEN 'FreeTextInvoice'
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
			WHEN 13
				THEN 'Cancelled'
			WHEN 12
				THEN 'Lost'
			END AS documentstatus_$label
		,CASE [salestable].[domexceptiontype]
			WHEN 14
				THEN 'InvalidCoordinatesWhenAzureMapsOnException'
			WHEN 13
				THEN 'InvalidCoordinatesWhenBingMapsOffException'
			WHEN 12
				THEN 'InvalidCoordinatesWhenBingMapsOnException'
			WHEN 11
				THEN 'OtherLineReservationFailure'
			WHEN 10
				THEN 'Generic'
			WHEN 9
				THEN 'QuantityCouldNotBeReserved'
			WHEN 8
				THEN 'MaximumOrdersDataModificationConflict'
			WHEN 7
				THEN 'BingMapsFailure'
			WHEN 6
				THEN 'NoRoadRoute'
			WHEN 5
				THEN 'InvalidCostValue'
			WHEN 4
				THEN 'OrderLineSpecificException'
			WHEN 3
				THEN 'DataModificationConflict'
			WHEN 2
				THEN 'MaximumRejections'
			WHEN 1
				THEN 'NoQuantityAvailable'
			WHEN 0
				THEN 'None'
			END AS domexceptiontype_$label
		,CASE [salestable].[domignore]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS domignore_$label
		,CASE [salestable].[domprocessed]
			WHEN 2
				THEN 'Exception'
			WHEN 1
				THEN 'Complete'
			WHEN 0
				THEN 'None'
			END AS domprocessed_$label
		,CASE [salestable].[einvoicelinespec]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS einvoicelinespec_$label
		,CASE [salestable].[fiscaldoctype_pl]
			WHEN 1
				THEN 'FiscalDocument'
			WHEN 0
				THEN 'Invoice'
			END AS fiscaldoctype_pl_$label
		,CASE [salestable].[foreigntrade_mx]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS foreigntrade_mx_$label
		,CASE [salestable].[freightsliptype]
			WHEN 1
				THEN 'UPS'
			WHEN 0
				THEN 'None'
			END AS freightsliptype_$label
		,CASE [salestable].[girotype]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'FIK'
			WHEN 2
				THEN 'BBS'
			WHEN 3
				THEN 'ESR_blue_PTT'
			WHEN 4
				THEN 'ESR_red_bank'
			WHEN 5
				THEN 'FIK762'
			WHEN 6
				THEN 'ESR_orange'
			WHEN 7
				THEN 'BelSMS101'
			WHEN 8
				THEN 'BelSMS102'
			WHEN 9
				THEN 'Finnish'
			WHEN 10
				THEN 'FIK751'
			WHEN 11
				THEN 'FIK752'
			WHEN 12
				THEN 'QRBill'
			END AS girotype_$label
		,CASE [salestable].[gupdelaypricingcalculation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS gupdelaypricingcalculation_$label
		,CASE [salestable].[gupskippricingcalculation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS gupskippricingcalculation_$label
		,CASE [salestable].[incltax]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS incltax_$label
		,CASE [salestable].[intercompanyallowindirectcreation]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS intercompanyallowindirectcreation_$label
		,CASE [salestable].[intercompanyallowindirectcreationorig]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS intercompanyallowindirectcreationorig_$label
		,CASE [salestable].[intercompanyautocreateorders]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS intercompanyautocreateorders_$label
		,CASE [salestable].[intercompanydirectdelivery]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS intercompanydirectdelivery_$label
		,CASE [salestable].[intercompanydirectdeliveryorig]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS intercompanydirectdeliveryorig_$label
		,CASE [salestable].[intercompanyorder]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS intercompanyorder_$label
		,CASE [salestable].[intercompanyorigin]
			WHEN 1
				THEN 'Derived'
			WHEN 0
				THEN 'Source'
			END AS intercompanyorigin_$label
		,CASE [salestable].[invoiceautonumbering_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS invoiceautonumbering_lt_$label
		,CASE [salestable].[invoiceregister_lt]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS invoiceregister_lt_$label
		,CASE [salestable].[invoicetype_w]
			WHEN 0
				THEN 'TaxInvoice'
			WHEN 1
				THEN 'SimplifiedInvoice'
			END AS invoicetype_w_$label
		,CASE [salestable].[isintegration]
			WHEN 3
				THEN 'DataEntity'
			WHEN 2
				THEN 'Dynamics365Sales'
			WHEN 1
				THEN 'CDS'
			WHEN 0
				THEN 'No'
			END AS isintegration_$label
		,CASE [salestable].[itemtagging]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS itemtagging_$label
		,CASE [salestable].[listcode]
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
		,CASE [salestable].[mcrorderstopped]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS mcrorderstopped_$label
		,CASE [salestable].[mpsexcludesalesorder]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS mpsexcludesalesorder_$label
		,CASE [salestable].[mpsfullrunctpstatus]
			WHEN 1
				THEN 'NotReady'
			WHEN 0
				THEN 'Ready'
			END AS mpsfullrunctpstatus_$label
		,CASE [salestable].[mpsupdateexcludesalesorder]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS mpsupdateexcludesalesorder_$label
		,CASE [salestable].[natureofassessee_in]
			WHEN 7
				THEN 'Others'
			WHEN 6
				THEN 'LocalAuthority'
			WHEN 5
				THEN 'BOI'
			WHEN 4
				THEN 'AOP'
			WHEN 3
				THEN 'Individual'
			WHEN 2
				THEN 'Firm'
			WHEN 1
				THEN 'HUF'
			WHEN 0
				THEN 'Company'
			END AS natureofassessee_in_$label
		,CASE [salestable].[onetimecustomer]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS onetimecustomer_$label
		,CASE [salestable].[overridesalestax]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS overridesalestax_$label
		,CASE [salestable].[packingslipautonumbering_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS packingslipautonumbering_lt_$label
		,CASE [salestable].[packingslipregister_lt]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS packingslipregister_lt_$label
		,CASE [salestable].[pallettagging]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS pallettagging_$label
		,CASE [salestable].[pdsbatchattribautores]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS pdsbatchattribautores_$label
		,CASE [salestable].[printdynamicqrcode_in]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS printdynamicqrcode_in_$label
		,CASE [salestable].[releasestatus]
			WHEN 2
				THEN 'Released'
			WHEN 1
				THEN 'PartialReleased'
			WHEN 0
				THEN 'Open'
			END AS releasestatus_$label
		,CASE [salestable].[reservation]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Automatic'
			WHEN 2
				THEN 'Explosion'
			END AS reservation_$label
		,CASE [salestable].[returnreplacementcreated]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS returnreplacementcreated_$label
		,CASE [salestable].[returnstatus]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Created'
			WHEN 2
				THEN 'Open'
			WHEN 4
				THEN 'Canceled'
			WHEN 3
				THEN 'Closed'
			END AS returnstatus_$label
		,CASE [salestable].[revrecfolloworiginalpricingmethod]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS revrecfolloworiginalpricingmethod_$label
		,CASE [salestable].[revrecmultiplesoreallocation]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS revrecmultiplesoreallocation_$label
		,CASE [salestable].[salesorderintegrationcreationtype]
			WHEN 0
				THEN 'Unknown'
			WHEN 1
				THEN 'WinQuote'
			END AS salesorderintegrationcreationtype_$label
		,CASE [salestable].[salesstatus]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'Open'
			WHEN 2
				THEN 'Delivered'
			WHEN 3
				THEN 'Invoiced'
			WHEN 4
				THEN 'Canceled'
			END AS salesstatus_$label
		,CASE [salestable].[salestype]
			WHEN 7
				THEN 'Prepayment'
			WHEN 6
				THEN 'ItemReq'
			WHEN 5
				THEN 'DEL_Blanket'
			WHEN 4
				THEN 'ReturnItem'
			WHEN 3
				THEN 'Sales'
			WHEN 2
				THEN 'Subscription'
			WHEN 1
				THEN 'DEL_Quotation'
			WHEN 0
				THEN 'Journal'
			END AS salestype_$label
		,CASE [salestable].[settlevoucher]
			WHEN 2
				THEN 'SelectedTransact'
			WHEN 1
				THEN 'OpenTransact'
			WHEN 0
				THEN 'None'
			END AS settlevoucher_$label
		,CASE [salestable].[shipcarrierblindshipment]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS shipcarrierblindshipment_$label
		,CASE [salestable].[shipcarrierdlvtype]
			WHEN 3
				THEN 'PickUp'
			WHEN 2
				THEN 'Air'
			WHEN 1
				THEN 'Ground'
			WHEN 0
				THEN 'Misc'
			END AS shipcarrierdlvtype_$label
		,CASE [salestable].[shipcarrierexpeditedshipment]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS shipcarrierexpeditedshipment_$label
		,CASE [salestable].[shipcarrierfuelsurcharge]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS shipcarrierfuelsurcharge_$label
		,CASE [salestable].[shipcarrierresidential]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS shipcarrierresidential_$label
		,CASE [salestable].[skipcreatemarkup]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS skipcreatemarkup_$label
		,CASE [salestable].[skiplineupdate]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS skiplineupdate_$label
		,CASE [salestable].[skipupdate]
			WHEN 3
				THEN 'Both'
			WHEN 2
				THEN 'InterCompany'
			WHEN 1
				THEN 'Internal'
			WHEN 0
				THEN 'No'
			END AS skipupdate_$label
		,CASE [salestable].[sks_cc_invoiceerroraftercapture]
			WHEN 0
				THEN 'None'
			WHEN 1
				THEN 'CaptureVoided'
			WHEN 2
				THEN 'CaptureVoidFailed'
			END AS sks_cc_invoiceerroraftercapture_$label
		,CASE [salestable].[sks_cc_paylinkstatus]
			WHEN 0
				THEN 'NA'
			WHEN 1
				THEN 'Pending'
			WHEN 2
				THEN 'Error'
			WHEN 3
				THEN 'Completed'
			WHEN 4
				THEN 'Expired'
			WHEN 5
				THEN 'Canceled'
			WHEN 6
				THEN 'All'
			END AS sks_cc_paylinkstatus_$label
		,CASE [salestable].[sks_cc_skipautoauthduetopartialship]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS sks_cc_skipautoauthduetopartialship_$label
		,CASE [salestable].[sourcecertificate_mx]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS sourcecertificate_mx_$label
		,CASE [salestable].[subbillcreatedfromsb]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS subbillcreatedfromsb_$label
		,CASE [salestable].[subbillsuppresschilditems]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS subbillsuppresschilditems_$label
		,CASE [salestable].[systementrysource]
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
		,CASE [salestable].[touched]
			WHEN 0
				THEN 'No'
			WHEN 1
				THEN 'Yes'
			END AS touched_$label
		,CASE [salestable].[unitedvatinvoice_lt]
			WHEN 1
				THEN 'Yes'
			WHEN 0
				THEN 'No'
			END AS unitedvatinvoice_lt_$label
		,CASE [salestable].[vatnumtabletype]
			WHEN 2
				THEN 'TaxVATNumTable'
			WHEN 1
				THEN 'TaxRegistration'
			WHEN 0
				THEN 'None'
			END AS vatnumtabletype_$label
	FROM [dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8].dbo.salestable
	WHERE salestable.IsDelete IS NULL