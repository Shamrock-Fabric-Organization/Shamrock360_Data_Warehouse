

/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/
/**************************************************************************************************************************************************/



/*************************************************************
** Proc: [dbo].[usp_CreateDataVirtualizationViews_Prep]
** Author: David Shaffer
** Date: May 2025
** Description: RENAME [ID] TO [SNL_ID] AND [FNO_ID] TO [ID] for EDL to SL for TimeXtender migration compatibility
**              Create additional views needed for TimeXtender BIA Baseline project
		This is for TimeXtender migration compatibility ONLY, NOT NEW INSTALLS

** Parameters: 
	passed parameters
		@StorageDS - Synapse / dataverse connection
	returned parameters
		none

** Revisions:
Date:   		Author:      		Description:
------------- 	--------------		---------------------------------------------------------------------------------
06/06/2025		David Shaffer		created to get around field renames 

** Example: 
	exec [dbo].[usp_CreateDataVirtualizationViews_Prep] 'dataverse-gferpuat-unqd5e157ade8f5ef11b0157c1e521c7'

**************************************************************/


CREATE             PROCEDURE [dbo].[usp_CreateDataVirtualizationViews_Prep] 
AS

	/***********************************************************************************/

	--dataverse db 
	DECLARE @Dataverse NVARCHAR(200) = '[dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8]'

	DECLARE @sql nvarchar(max)
	DECLARE @sql2 nvarchar(max)
	DECLARE @sql3 nvarchar(max)
	DECLARE @sql4 nvarchar(max)

	
	
	-- create view definition  DefaultDimensionView
	SET @sql = '' + '
	CREATE OR ALTER VIEW  DefaultDimensionView
	AS
		SELECT
			T1.DISPLAYVALUE AS DISPLAYVALUE
			, T1.DIMENSIONATTRIBUTEVALUESET AS DEFAULTDIMENSION
			, T1.RECID AS TABLERECID
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.ENTITYINSTANCE AS ENTITYINSTANCE
			, T2.PARTITION AS PARTITION#2
			, T3.REPORTCOLUMNNAME AS REPORTCOLUMNNAME
			, T3.RECID AS DIMENSIONATTRIBUTEID
			, T3.BACKINGENTITYTYPE AS BACKINGENTITYTYPE
			, T3.KEYATTRIBUTE AS KEYATTRIBUTE
			, T3.NAMEATTRIBUTE AS NAMEATTRIBUTE
			, T3.NAME AS NAME
			, T3.PARTITION AS PARTITION#3
		FROM DIMENSIONATTRIBUTEVALUESETITEM T1
		CROSS JOIN DIMENSIONATTRIBUTEVALUE T2
		CROSS JOIN DIMENSIONATTRIBUTE T3
		WHERE (
				(
					(T1.DIMENSIONATTRIBUTEVALUE = T2.RECID)
					AND (T1.PARTITION = T2.PARTITION)
					)
				AND (
					(T2.DIMENSIONATTRIBUTE = T3.RECID)
					AND (T2.PARTITION = T3.PARTITION)
					)
				)'

	exec (@sql)
		



	-- create view definition  DIMATTRIBUTEOMBUSINESSUNIT
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [DIMATTRIBUTEOMBUSINESSUNIT]
	AS
		SELECT
			T1.RECID AS KEY_
			, T1.OMOPERATINGUNITNUMBER AS VALUE
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.NAME AS NAME
			, T2.PARTITION AS PARTITION#2
		FROM DIRPARTYTABLE T1
		CROSS JOIN DIRPARTYTABLE T2
		WHERE (
				(
					(T1.OMOPERATINGUNITTYPE = 4)
					AND (
						(T1.RECID = T2.RECID)
						AND (T1.PARTITION = T2.PARTITION)
						)
					)
				)'

	exec (@sql)
		

	-- create view definition  DIMATTRIBUTEOMCOSTCENTER
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [DIMATTRIBUTEOMCOSTCENTER]
	AS
		SELECT
			T1.RECID AS KEY_
			, T1.OMOPERATINGUNITNUMBER AS VALUE
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.NAME AS NAME
			, T2.PARTITION AS PARTITION#2
		FROM DIRPARTYTABLE T1
		CROSS JOIN DIRPARTYTABLE T2
		WHERE (
				(
					(T1.OMOPERATINGUNITTYPE = 2)
					AND (
						(T1.RECID = T2.RECID)
						AND (T1.PARTITION = T2.PARTITION)
						)
					)
				)'

	exec (@sql)
		

	-- create view definition  DIMATTRIBUTEOMDEPARTMENT
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [DIMATTRIBUTEOMDEPARTMENT]
	AS
		SELECT
			T1.RECID AS KEY_
			, T1.OMOPERATINGUNITNUMBER AS VALUE
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.NAME AS NAME
			, T2.PARTITION AS PARTITION#2
		FROM DIRPARTYTABLE T1
		CROSS JOIN DIRPARTYTABLE T2
		WHERE (
				(
					(T1.OMOPERATINGUNITTYPE = 1)
					AND (
						(T1.RECID = T2.RECID)
						AND (T1.PARTITION = T2.PARTITION)
						)
					)
				)'

	exec (@sql)
		

	-- create view definition  LOGISTICSPOSTALADDRESSVIEW
	SET @sql = '' + '
	CREATE OR ALTER VIEW  LOGISTICSPOSTALADDRESSVIEW
	AS
		SELECT
			T1.COUNTY AS COUNTY
			, T1.DISTRICT AS DISTRICT
			, T1.POSTBOX AS POSTBOX
			, T1.ADDRESS AS ADDRESS
			, T1.BUILDINGCOMPLIMENT AS BUILDINGCOMPLIMENT
			, T1.CITY AS CITY
			, T1.COUNTRYREGIONID AS COUNTRYREGIONID
			, T1.LATITUDE AS LATITUDE
			, T1.STATE AS STATE
			, T1.STREET AS STREET
			, T1.STREETNUMBER AS STREETNUMBER
			, T1.TIMEZONE AS TIMEZONE
			, T1.LONGITUDE AS LONGITUDE
			, T1.ZIPCODE AS ZIPCODE
			, T1.LOCATION AS LOCATION
			, T1.VALIDFROM AS VALIDFROM
			, T1.VALIDTO AS VALIDTO
			, T1.RECID AS POSTALADDRESSRECID
			, T1.RECID AS POSTALADDRESS
			, T1.DISTRICTNAME AS DISTRICTNAME
			, T1.FLATID_RU AS FLATID_RU
			, T1.HOUSEID_RU AS HOUSEID_RU
			, T1.STREETID_RU AS STREETID_RU
			, T1.BUILDING_RU AS BUILDING_RU
			, T1.APARTMENT_RU AS APARTMENT_RU
			, T1.ISPRIVATE AS ISPRIVATE
			, T1.PRIVATEFORPARTY AS PRIVATEFORPARTY
			, T1.RECID AS XRECID_LOGISTICSPOSTALADDRESS
			, T1.RECVERSION AS XRECVERSION_LOGISTICSPOSTALADDRESS
			, T1.CITYRECID AS CITYRECID
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.CURRENCYCODE AS COUNTRYCURRENCYCODE
			, T2.ISOCODE AS ISOCODE
			, T2.PARTITION AS PARTITION#2
			, T3.DESCRIPTION AS LOCATIONNAME
			, T3.PARTITION AS PARTITION#3
		FROM LOGISTICSPOSTALADDRESS T1
		CROSS JOIN LOGISTICSADDRESSCOUNTRYREGION T2
		CROSS JOIN LOGISTICSLOCATION T3
		WHERE (
				(
					(T1.COUNTRYREGIONID = T2.COUNTRYREGIONID)
					AND (T1.PARTITION = T2.PARTITION)
					)
				AND (
					(T1.LOCATION = T3.RECID)
					AND (T1.PARTITION = T3.PARTITION)
					)
				)'

	exec (@sql)
		

	-- create view definition  DirPartyPostalAddressView
	SET @sql = '' + '
	CREATE OR ALTER VIEW  DirPartyPostalAddressView
	AS
		SELECT
			T1.PARTY AS PARTY
			, T1.RECID AS PARTYLOCATION
			, T1.ISPRIMARY AS ISPRIMARY
			, T1.ISLOCATIONOWNER AS ISLOCATIONOWNER
			, T1.ISPRIMARYTAXREGISTRATION AS ISPRIMARYTAXREGISTRATION
			, T1.RECID AS TABLERECID
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.LOCATIONNAME AS LOCATIONNAME
			, T2.ADDRESS AS ADDRESS
			, T2.STREETNUMBER AS STREETNUMBER
			, T2.STREET AS STREET
			, case when len(isnull(T2.STREETNUMBER,''''))>0 then T2.STREETNUMBER + case when len(isnull(T2.STREET,''''))>0 then '' '' + T2.STREET end
						ELSE case when len(isnull(T2.STREET,''''))>0 then T2.STREET end end STREETADDRESS
			, T2.CITY AS CITY
			, T2.ZIPCODE AS ZIPCODE
			, T2.STATE AS STATE
			, T2.COUNTY AS COUNTY
			, T2.COUNTRYREGIONID AS COUNTRYREGIONID
			, T2.DISTRICT AS DISTRICT
			, T2.POSTBOX AS POSTBOX
			, T2.BUILDINGCOMPLIMENT AS BUILDINGCOMPLIMENT
			, T2.TIMEZONE AS TIMEZONE
			, T2.LONGITUDE AS LONGITUDE
			, T2.LATITUDE AS LATITUDE
			, T2.LOCATION AS LOCATION
			, T2.VALIDFROM AS VALIDFROM
			, T2.VALIDTO AS VALIDTO
			, T2.COUNTRYCURRENCYCODE AS COUNTRYCURRENCYCODE
			, T2.ISPRIVATE AS ISPRIVATE
			, T2.DISTRICTNAME AS DISTRICTNAME
			, T2.POSTALADDRESS AS POSTALADDRESS
			, T2.ISOCODE AS ISOCODE
			, T2.STREETID_RU AS STREETID_RU
			, T2.HOUSEID_RU AS HOUSEID_RU
			, T2.FLATID_RU AS FLATID_RU
			, T2.BUILDING_RU AS BUILDING_RU
			, T2.APARTMENT_RU AS APARTMENT_RU
			, T2.PRIVATEFORPARTY AS PRIVATEFORPARTY
			, T2.XRECID_LOGISTICSPOSTALADDRESS AS XRECID_LOGISTICSPOSTALADDRESS
			, T2.XRECVERSION_LOGISTICSPOSTALADDRESS AS XRECVERSION_LOGISTICSPOSTALADDRESS
			, T2.CITYRECID AS CITYRECID
			, T2.PARTITION AS PARTITION#2
		FROM DIRPARTYLOCATION T1
		LEFT OUTER JOIN LOGISTICSPOSTALADDRESSVIEW T2
			ON (
					(T1.LOCATION = T2.LOCATION)
					AND (T1.PARTITION = T2.PARTITION)
					)
		WHERE (T1.ISPOSTALADDRESS = 1)'

	exec (@sql)
		

	-- create view definition  LOGISTICSADDRESSCOUNTRYREGTRANSLFILTERED
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [LOGISTICSADDRESSCOUNTRYREGTRANSLFILTERED]
	AS
		SELECT
			T1.COUNTRYREGIONID AS COUNTRYREGIONID
			, T1.LANGUAGEID AS LANGUAGEID
			, T1.SHORTNAME AS SHORTNAME
			, T1.RECID AS TABLERECID
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.PARTITION AS PARTITION#2
		FROM LOGISTICSADDRESSCOUNTRYREGIONTRANSLATION T1
		CROSS JOIN SYSTEMPARAMETERS T2
		WHERE (
				(T1.LANGUAGEID = T2.SYSTEMLANGUAGEID)
				AND (T1.PARTITION = T2.PARTITION)
				)'

	exec (@sql)
		

	-- create view definition  LOGISTICSENTITYLOCATIONVIEW
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [LOGISTICSENTITYLOCATIONVIEW]
	AS
		SELECT
			T1.SITE AS ENTITY
			, T1.LOCATION AS LOCATION
			, T1.ISPOSTALADDRESS AS ISPOSTALADDRESS
			, T1.ISPRIMARY AS ISPRIMARY
			, T1.RECID AS ENTITYLOCATION
			, T1.ISPRIVATE AS ISPRIVATE
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, 1 AS UnionAllBranchId
			, (CAST((1) AS INT)) AS ENTITYTYPE
			, (CAST((''1900-01-01T00:00:00'') AS DATETIME)) AS VALIDFROM
			, (CAST((''2154-12-31T23:59:59'') AS DATETIME)) AS VALIDTO
		FROM INVENTSITELOGISTICSLOCATION T1

		UNION ALL

		SELECT
			T1.INVENTLOCATION
			, T1.LOCATION
			, T1.ISPOSTALADDRESS
			, T1.ISPRIMARY
			, T1.RECID
			, T1.ISPRIVATE
			, T1.PARTITION
			, T1.RECID
			, 2
			, (CAST((2) AS INT)) AS ENTITYTYPE
			, (CAST((''1900-01-01T00:00:00'') AS DATETIME)) AS VALIDFROM
			, (CAST((''2154-12-31T23:59:59'') AS DATETIME)) AS VALIDTO
		FROM INVENTLOCATIONLOGISTICSLOCATION T1

		UNION ALL

		SELECT
			T1.APPLICATIONBASKET
			, T1.LOCATION
			, T1.ISPOSTALADDRESS
			, T1.ISPRIMARY
			, T1.RECID
			, T1.ISPRIVATE
			, T1.PARTITION
			, T1.RECID
			, 3
			, (CAST((3) AS INT)) AS ENTITYTYPE
			, (CAST((''1900-01-01T00:00:00'') AS DATETIME)) AS VALIDFROM
			, (CAST((''2154-12-31T23:59:59'') AS DATETIME)) AS VALIDTO
		FROM HCMAPPLICATIONBASKETLOCATION T1

		UNION ALL

		SELECT
			T1.PARTY
			, T1.LOCATION
			, T1.ISPOSTALADDRESS
			, T1.ISPRIMARY
			, T1.RECID
			, T1.ISPRIVATE
			, T1.PARTITION
			, T1.RECID
			, 4
			, (CAST((4) AS INT)) AS ENTITYTYPE
			, (CAST((''1900-01-01T00:00:00'') AS DATETIME)) AS VALIDFROM
			, (CAST((''2154-12-31T23:59:59'') AS DATETIME)) AS VALIDTO
		FROM DIRPARTYLOCATION T1'

	exec (@sql)
		

	-- create view definition  LOGISTICSENTITYPOSTALADDRESSVIEW
	SET @sql = '' + '
	CREATE OR ALTER VIEW  [LOGISTICSENTITYPOSTALADDRESSVIEW]
	AS
		SELECT
			T1.ISPRIMARY AS ISPRIMARY
			, T1.LOCATION AS LOCATION
			, T1.ENTITYLOCATION AS ENTITYLOCATION
			, T1.ENTITY AS ENTITY
			, T1.ENTITYTYPE AS ENTITYTYPE
			, T1.PARTITION AS PARTITION
			, T1.RECID AS RECID
			, T2.PARTITION AS PARTITION#2
			, T2.ADDRESS AS ADDRESS
			, T2.BUILDINGCOMPLIMENT AS BUILDINGCOMPLIMENT
			, T2.CITY AS CITY
			, T2.COUNTRYCURRENCYCODE AS COUNTRYCURRENCYCODE
			, T2.COUNTRYREGIONID AS COUNTRYREGIONID
			, T2.COUNTY AS COUNTY
			, T2.DISTRICT AS DISTRICT
			, T2.LATITUDE AS LATITUDE
			, T2.LOCATIONNAME AS LOCATIONNAME
			, T2.LONGITUDE AS LONGITUDE
			, T2.POSTBOX AS POSTBOX
			, T2.POSTALADDRESS AS POSTALADDRESS
			, T2.STATE AS STATE
			, T2.STREET AS STREET
			, T2.STREETNUMBER AS STREETNUMBER
			, T2.TIMEZONE AS TIMEZONE
			, T2.VALIDFROM AS VALIDFROM
			, T2.VALIDTO AS VALIDTO
			, T2.ZIPCODE AS ZIPCODE
		FROM LOGISTICSENTITYLOCATIONVIEW T1
		CROSS JOIN LOGISTICSPOSTALADDRESSVIEW T2
		WHERE (
				T1.LOCATION = T2.LOCATION
				AND (T1.PARTITION = T2.PARTITION)
				)'

	exec (@sql)
		

	-- create view definition  ECORESPRODUCTATTRIBUTEVALUE
	SET @sql = '' + '
	CREATE OR ALTER VIEW ECORESPRODUCTATTRIBUTEVALUE
	AS
	SELECT T1.VALUE AS VALUE
		,T1.ATTRIBUTE AS ATTRIBUTE
		,T1.PARTITION AS PARTITION
		,T1.RECID AS RECID
		,T2.PRODUCT AS PRODUCT
		,T2.PARTITION AS PARTITION#2
	FROM ECORESATTRIBUTEVALUE T1
	CROSS JOIN ECORESINSTANCEVALUE T2
	WHERE (
			(
				(T1.INSTANCEVALUE = T2.RECID)
				AND (T1.PARTITION = T2.PARTITION)
				)
		--	AND T2.INSTANCERELATIONTYPE IN (3885)
			)'

	exec (@sql)
	



	-- create view definition  salestable
	SET @sql = '' + '
	CREATE OR ALTER VIEW  salestable 
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
				THEN ''Cust''
			WHEN 1
				THEN ''Sales''
			END AS autosummarymoduletype_$label
		,CASE [salestable].[bankdocumenttype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''LetterOfCredit''
			WHEN 2
				THEN ''ImportCollection''
			WHEN 3
				THEN ''LetterOfGuarantee''
			END AS bankdocumenttype_$label
		,CASE [salestable].[casetagging]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS casetagging_$label
		,CASE [salestable].[cfditemporaryexport_mx]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS cfditemporaryexport_mx_$label
		,CASE [salestable].[commissiontype_it]
			WHEN 0
				THEN ''Invoice''
			WHEN 1
				THEN ''Payment''
			END AS commissiontype_it_$label
		,CASE [salestable].[constarget_jp]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS constarget_jp_$label
		,CASE [salestable].[creditcardauthorizationerror]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS creditcardauthorizationerror_$label
		,CASE [salestable].[credmanexcludesalesorder]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS credmanexcludesalesorder_$label
		,CASE [salestable].[credmanincreditcontrol]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS credmanincreditcontrol_$label
		,CASE [salestable].[credmanrejected]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS credmanrejected_$label
		,CASE [salestable].[credmanreleasedfromcreditcontrol]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS credmanreleasedfromcreditcontrol_$label
		,CASE [salestable].[customsexportorder_in]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS customsexportorder_in_$label
		,CASE [salestable].[customsshippingbill_in]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS customsshippingbill_in_$label
		,CASE [salestable].[deliverydatecontroltype]
			WHEN 5
				THEN ''FullRunCTP''
			WHEN 4
				THEN ''CTP''
			WHEN 3
				THEN ''ATPPlusIssueMargin''
			WHEN 2
				THEN ''ATP''
			WHEN 1
				THEN ''SalesLeadTime''
			WHEN 0
				THEN ''None''
			END AS deliverydatecontroltype_$label
		,CASE [salestable].[documentstatus]
			WHEN 24
				THEN ''RevRecDeferredRevenueInvoice''
			WHEN 23
				THEN ''RevRecRevenueCancelation''
			WHEN 22
				THEN ''ITMGoodsInTransitReceive''
			WHEN 21
				THEN ''ProjectPickingList''
			WHEN 20
				THEN ''Note''
			WHEN 222
				THEN ''DeliverySlipProject_BR''
			WHEN 103
				THEN ''PlSAD''
			WHEN 150
				THEN ''DeliverySlip_BR''
			WHEN 105
				THEN ''FreeTextInvoice4Paym_RU''
			WHEN 102
				THEN ''Facture_RU''
			WHEN 101
				THEN ''Invoice4Paym_RU''
			WHEN 221
				THEN ''ShippingBill_IN''
			WHEN 220
				THEN ''BillOfEntry_IN''
			WHEN 219
				THEN ''InvoiceRegistration_IN''
			WHEN 30
				THEN ''ConfirmationRequest''
			WHEN 19
				THEN ''RFQReSend''
			WHEN 18
				THEN ''PurchReq''
			WHEN 17
				THEN ''RFQReject''
			WHEN 16
				THEN ''RFQAccept''
			WHEN 15
				THEN ''RFQ''
			WHEN 14
				THEN ''FreeTextInvoice''
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Quotation''
			WHEN 2
				THEN ''PurchaseOrder''
			WHEN 3
				THEN ''Confirmation''
			WHEN 4
				THEN ''PickingList''
			WHEN 5
				THEN ''PackingSlip''
			WHEN 6
				THEN ''ReceiptsList''
			WHEN 7
				THEN ''Invoice''
			WHEN 8
				THEN ''ApproveJournal''
			WHEN 9
				THEN ''ProjectInvoice''
			WHEN 10
				THEN ''ProjectPackingSlip''
			WHEN 11
				THEN ''CRMQuotation''
			WHEN 13
				THEN ''Cancelled''
			WHEN 12
				THEN ''Lost''
			END AS documentstatus_$label
		,CASE [salestable].[domexceptiontype]
			WHEN 14
				THEN ''InvalidCoordinatesWhenAzureMapsOnException''
			WHEN 13
				THEN ''InvalidCoordinatesWhenBingMapsOffException''
			WHEN 12
				THEN ''InvalidCoordinatesWhenBingMapsOnException''
			WHEN 11
				THEN ''OtherLineReservationFailure''
			WHEN 10
				THEN ''Generic''
			WHEN 9
				THEN ''QuantityCouldNotBeReserved''
			WHEN 8
				THEN ''MaximumOrdersDataModificationConflict''
			WHEN 7
				THEN ''BingMapsFailure''
			WHEN 6
				THEN ''NoRoadRoute''
			WHEN 5
				THEN ''InvalidCostValue''
			WHEN 4
				THEN ''OrderLineSpecificException''
			WHEN 3
				THEN ''DataModificationConflict''
			WHEN 2
				THEN ''MaximumRejections''
			WHEN 1
				THEN ''NoQuantityAvailable''
			WHEN 0
				THEN ''None''
			END AS domexceptiontype_$label
		,CASE [salestable].[domignore]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS domignore_$label
		,CASE [salestable].[domprocessed]
			WHEN 2
				THEN ''Exception''
			WHEN 1
				THEN ''Complete''
			WHEN 0
				THEN ''None''
			END AS domprocessed_$label
		,CASE [salestable].[einvoicelinespec]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS einvoicelinespec_$label
		,CASE [salestable].[fiscaldoctype_pl]
			WHEN 1
				THEN ''FiscalDocument''
			WHEN 0
				THEN ''Invoice''
			END AS fiscaldoctype_pl_$label
		,CASE [salestable].[foreigntrade_mx]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS foreigntrade_mx_$label
		,CASE [salestable].[freightsliptype]
			WHEN 1
				THEN ''UPS''
			WHEN 0
				THEN ''None''
			END AS freightsliptype_$label
		,CASE [salestable].[girotype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''FIK''
			WHEN 2
				THEN ''BBS''
			WHEN 3
				THEN ''ESR_blue_PTT''
			WHEN 4
				THEN ''ESR_red_bank''
			WHEN 5
				THEN ''FIK762''
			WHEN 6
				THEN ''ESR_orange''
			WHEN 7
				THEN ''BelSMS101''
			WHEN 8
				THEN ''BelSMS102''
			WHEN 9
				THEN ''Finnish''
			WHEN 10
				THEN ''FIK751''
			WHEN 11
				THEN ''FIK752''
			WHEN 12
				THEN ''QRBill''
			END AS girotype_$label
		,CASE [salestable].[gupdelaypricingcalculation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS gupdelaypricingcalculation_$label
		,CASE [salestable].[gupskippricingcalculation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS gupskippricingcalculation_$label
		,CASE [salestable].[incltax]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS incltax_$label
		,CASE [salestable].[intercompanyallowindirectcreation]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS intercompanyallowindirectcreation_$label
		,CASE [salestable].[intercompanyallowindirectcreationorig]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS intercompanyallowindirectcreationorig_$label
		,CASE [salestable].[intercompanyautocreateorders]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS intercompanyautocreateorders_$label
		,CASE [salestable].[intercompanydirectdelivery]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS intercompanydirectdelivery_$label
		,CASE [salestable].[intercompanydirectdeliveryorig]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS intercompanydirectdeliveryorig_$label
		,CASE [salestable].[intercompanyorder]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS intercompanyorder_$label
		,CASE [salestable].[intercompanyorigin]
			WHEN 1
				THEN ''Derived''
			WHEN 0
				THEN ''Source''
			END AS intercompanyorigin_$label
		,CASE [salestable].[invoiceautonumbering_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS invoiceautonumbering_lt_$label
		,CASE [salestable].[invoiceregister_lt]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS invoiceregister_lt_$label
		,CASE [salestable].[invoicetype_w]
			WHEN 0
				THEN ''TaxInvoice''
			WHEN 1
				THEN ''SimplifiedInvoice''
			END AS invoicetype_w_$label
		,CASE [salestable].[isintegration]
			WHEN 3
				THEN ''DataEntity''
			WHEN 2
				THEN ''Dynamics365Sales''
			WHEN 1
				THEN ''CDS''
			WHEN 0
				THEN ''No''
			END AS isintegration_$label
		,CASE [salestable].[itemtagging]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS itemtagging_$label
		,CASE [salestable].[listcode]
			WHEN 0
				THEN ''IncludeNot''
			WHEN 1
				THEN ''EUTrade''
			WHEN 2
				THEN ''ProductionOnToll''
			WHEN 3
				THEN ''TriangularEUTrade''
			WHEN 4
				THEN ''TriangularProductionOnToll''
			WHEN 50
				THEN ''PropertyMoving_CZ''
			WHEN 51
				THEN ''TriangularIntermediateRole_HU''
			WHEN 52
				THEN ''DEL_EUService''
			WHEN 53
				THEN ''PurchasedOnBehalf_LV''
			END AS listcode_$label
		,CASE [salestable].[mcrorderstopped]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS mcrorderstopped_$label
		,CASE [salestable].[mpsexcludesalesorder]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS mpsexcludesalesorder_$label
		,CASE [salestable].[mpsfullrunctpstatus]
			WHEN 1
				THEN ''NotReady''
			WHEN 0
				THEN ''Ready''
			END AS mpsfullrunctpstatus_$label
		,CASE [salestable].[mpsupdateexcludesalesorder]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS mpsupdateexcludesalesorder_$label
		,CASE [salestable].[natureofassessee_in]
			WHEN 7
				THEN ''Others''
			WHEN 6
				THEN ''LocalAuthority''
			WHEN 5
				THEN ''BOI''
			WHEN 4
				THEN ''AOP''
			WHEN 3
				THEN ''Individual''
			WHEN 2
				THEN ''Firm''
			WHEN 1
				THEN ''HUF''
			WHEN 0
				THEN ''Company''
			END AS natureofassessee_in_$label
		,CASE [salestable].[onetimecustomer]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS onetimecustomer_$label
		,CASE [salestable].[overridesalestax]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS overridesalestax_$label
		,CASE [salestable].[packingslipautonumbering_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS packingslipautonumbering_lt_$label
		,CASE [salestable].[packingslipregister_lt]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS packingslipregister_lt_$label
		,CASE [salestable].[pallettagging]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS pallettagging_$label
		,CASE [salestable].[pdsbatchattribautores]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS pdsbatchattribautores_$label
		,CASE [salestable].[printdynamicqrcode_in]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS printdynamicqrcode_in_$label
		,CASE [salestable].[releasestatus]
			WHEN 2
				THEN ''Released''
			WHEN 1
				THEN ''PartialReleased''
			WHEN 0
				THEN ''Open''
			END AS releasestatus_$label
		,CASE [salestable].[reservation]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Automatic''
			WHEN 2
				THEN ''Explosion''
			END AS reservation_$label
		,CASE [salestable].[returnreplacementcreated]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS returnreplacementcreated_$label
		,CASE [salestable].[returnstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Created''
			WHEN 2
				THEN ''Open''
			WHEN 4
				THEN ''Canceled''
			WHEN 3
				THEN ''Closed''
			END AS returnstatus_$label
		,CASE [salestable].[revrecfolloworiginalpricingmethod]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS revrecfolloworiginalpricingmethod_$label
		,CASE [salestable].[revrecmultiplesoreallocation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS revrecmultiplesoreallocation_$label
		,CASE [salestable].[salesorderintegrationcreationtype]
			WHEN 0
				THEN ''Unknown''
			WHEN 1
				THEN ''WinQuote''
			END AS salesorderintegrationcreationtype_$label
		,CASE [salestable].[salesstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Open''
			WHEN 2
				THEN ''Delivered''
			WHEN 3
				THEN ''Invoiced''
			WHEN 4
				THEN ''Canceled''
			END AS salesstatus_$label
		,CASE [salestable].[salestype]
			WHEN 7
				THEN ''Prepayment''
			WHEN 6
				THEN ''ItemReq''
			WHEN 5
				THEN ''DEL_Blanket''
			WHEN 4
				THEN ''ReturnItem''
			WHEN 3
				THEN ''Sales''
			WHEN 2
				THEN ''Subscription''
			WHEN 1
				THEN ''DEL_Quotation''
			WHEN 0
				THEN ''Journal''
			END AS salestype_$label
		,CASE [salestable].[settlevoucher]
			WHEN 2
				THEN ''SelectedTransact''
			WHEN 1
				THEN ''OpenTransact''
			WHEN 0
				THEN ''None''
			END AS settlevoucher_$label
		,CASE [salestable].[shipcarrierblindshipment]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS shipcarrierblindshipment_$label
		,CASE [salestable].[shipcarrierdlvtype]
			WHEN 3
				THEN ''PickUp''
			WHEN 2
				THEN ''Air''
			WHEN 1
				THEN ''Ground''
			WHEN 0
				THEN ''Misc''
			END AS shipcarrierdlvtype_$label
		,CASE [salestable].[shipcarrierexpeditedshipment]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS shipcarrierexpeditedshipment_$label
		,CASE [salestable].[shipcarrierfuelsurcharge]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS shipcarrierfuelsurcharge_$label
		,CASE [salestable].[shipcarrierresidential]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS shipcarrierresidential_$label
		,CASE [salestable].[skipcreatemarkup]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipcreatemarkup_$label
		,CASE [salestable].[skiplineupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skiplineupdate_$label
		,CASE [salestable].[skipupdate]
			WHEN 3
				THEN ''Both''
			WHEN 2
				THEN ''InterCompany''
			WHEN 1
				THEN ''Internal''
			WHEN 0
				THEN ''No''
			END AS skipupdate_$label
		,CASE [salestable].[sks_cc_invoiceerroraftercapture]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''CaptureVoided''
			WHEN 2
				THEN ''CaptureVoidFailed''
			END AS sks_cc_invoiceerroraftercapture_$label
		,CASE [salestable].[sks_cc_paylinkstatus]
			WHEN 0
				THEN ''NA''
			WHEN 1
				THEN ''Pending''
			WHEN 2
				THEN ''Error''
			WHEN 3
				THEN ''Completed''
			WHEN 4
				THEN ''Expired''
			WHEN 5
				THEN ''Canceled''
			WHEN 6
				THEN ''All''
			END AS sks_cc_paylinkstatus_$label
		,CASE [salestable].[sks_cc_skipautoauthduetopartialship]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS sks_cc_skipautoauthduetopartialship_$label
		,CASE [salestable].[sourcecertificate_mx]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS sourcecertificate_mx_$label
		,CASE [salestable].[subbillcreatedfromsb]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillcreatedfromsb_$label
		,CASE [salestable].[subbillsuppresschilditems]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillsuppresschilditems_$label
		,CASE [salestable].[systementrysource]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''CopyFromSalesOrder''
			WHEN 2
				THEN ''CopyFromSalesQuotation''
			WHEN 3
				THEN ''Project''
			WHEN 4
				THEN ''SalesQuotation''
			WHEN 5
				THEN ''CopyFromPurchaseOrder''
			WHEN 6
				THEN ''RequestForQuote''
			WHEN 7
				THEN ''PurchaseReq''
			WHEN 8
				THEN ''ManualEntry''
			WHEN 9
				THEN ''Agreement''
			WHEN 11
				THEN ''ProductConfig''
			WHEN 12
				THEN ''RetailPOS''
			END AS systementrysource_$label
		,CASE [salestable].[touched]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS touched_$label
		,CASE [salestable].[unitedvatinvoice_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS unitedvatinvoice_lt_$label
		,CASE [salestable].[vatnumtabletype]
			WHEN 2
				THEN ''TaxVATNumTable''
			WHEN 1
				THEN ''TaxRegistration''
			WHEN 0
				THEN ''None''
			END AS vatnumtabletype_$label
	FROM '+@Dataverse+'.dbo.salestable
	WHERE salestable.IsDelete IS NULL '

	exec (@sql)


	-- create view definition  salesline
	SET @sql = '' + '
	CREATE OR ALTER VIEW  salesline 
	AS
	SELECT [salesline].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id]
		,[salesline].[SinkCreatedOn] AS [SinkCreatedOn]
		,[salesline].[SinkModifiedOn] AS [SinkModifiedOn]
		,[salesline].[agreementskipautolink] AS [agreementskipautolink]
		,[salesline].[blocked] AS [blocked]
		,[salesline].[casetagging] AS [casetagging]
		,[salesline].[complete] AS [complete]
		,[salesline].[deliverydatecontroltype] AS [deliverydatecontroltype]
		,[salesline].[deliverytype] AS [deliverytype]
		,[salesline].[intercompanyorigin] AS [intercompanyorigin]
		,[salesline].[inventreftype] AS [inventreftype]
		,[salesline].[itemreplaced] AS [itemreplaced]
		,[salesline].[itemtagging] AS [itemtagging]
		,[salesline].[linedeliverytype] AS [linedeliverytype]
		,[salesline].[pallettagging] AS [pallettagging]
		,[salesline].[pdsbatchattribautores] AS [pdsbatchattribautores]
		,[salesline].[pdsexcludefromrebate] AS [pdsexcludefromrebate]
		,[salesline].[pdssamelot] AS [pdssamelot]
		,[salesline].[pdssamelotoverride] AS [pdssamelotoverride]
		,[salesline].[reservation] AS [reservation]
		,[salesline].[returnallowreservation] AS [returnallowreservation]
		,[salesline].[returnstatus] AS [returnstatus]
		,[salesline].[salesstatus] AS [salesstatus]
		,[salesline].[salestype] AS [salestype]
		,[salesline].[scrap] AS [scrap]
		,[salesline].[shipcarrierdlvtype] AS [shipcarrierdlvtype]
		,[salesline].[skipupdate] AS [skipupdate]
		,[salesline].[stattriangulardeal] AS [stattriangulardeal]
		,[salesline].[stockedproduct] AS [stockedproduct]
		,[salesline].[systementrysource] AS [systementrysource]
		,[salesline].[taxautogenerated] AS [taxautogenerated]
		,[salesline].[skipcreatemarkup] AS [skipcreatemarkup]
		,[salesline].[sourcingorigin] AS [sourcingorigin]
		,[salesline].[skipdefaultingsourcingvendor] AS [skipdefaultingsourcingvendor]
		,[salesline].[skipintercompanypurchorderaccountingdistribution] AS [skipintercompanypurchorderaccountingdistribution]
		,[salesline].[syncpurchline] AS [syncpurchline]
		,[salesline].[syncintercompanypurchline] AS [syncintercompanypurchline]
		,[salesline].[skipdeliveryscheduleupdate] AS [skipdeliveryscheduleupdate]
		,[salesline].[skipassigninventtransid] AS [skipassigninventtransid]
		,[salesline].[autocreateintercompanyorders] AS [autocreateintercompanyorders]
		,[salesline].[skippricedisccalc] AS [skippricedisccalc]
		,[salesline].[consignment_mx] AS [consignment_mx]
		,[salesline].[samples_mx] AS [samples_mx]
		,[salesline].[mcrmarginupdated] AS [mcrmarginupdated]
		,[salesline].[salessalesordercreationmethod] AS [salessalesordercreationmethod]
		,[salesline].[overridesalestax] AS [overridesalestax]
		,[salesline].[inventoryserviceautooffset] AS [inventoryserviceautooffset]
		,[salesline].[mpsfullrunctpstatus] AS [mpsfullrunctpstatus]
		,[salesline].[softreserveblocklevel] AS [softreserveblocklevel]
		,[salesline].[issoftreservedexternally] AS [issoftreservedexternally]
		,[salesline].[skippricedisccalcinbulkcreation] AS [skippricedisccalcinbulkcreation]
		,[salesline].[isintegration] AS [isintegration]
		,[salesline].[mpsexcludesalesline] AS [mpsexcludesalesline]
		,[salesline].[mpsupdateexcludesalesline] AS [mpsupdateexcludesalesline]
		,[salesline].[skippricedisccalconimport] AS [skippricedisccalconimport]
		,[salesline].[salesorderintegrationcreationtype] AS [salesorderintegrationcreationtype]
		,[salesline].[defaultlinenumberfromlinecreationsequencenumber] AS [defaultlinenumberfromlinecreationsequencenumber]
		,[salesline].[keepsalespriceandsetdiscount] AS [keepsalespriceandsetdiscount]
		,[salesline].[goodsforfree_it] AS [goodsforfree_it]
		,[salesline].[servicelinetype_it] AS [servicelinetype_it]
		,[salesline].[bundlelinestatus] AS [bundlelinestatus]
		,[salesline].[bundlelinetype] AS [bundlelinetype]
		,[salesline].[domprocessed] AS [domprocessed]
		,[salesline].[domignore] AS [domignore]
		,[salesline].[domexceptiontype] AS [domexceptiontype]
		,[salesline].[kittingskipupdatehelper] AS [kittingskipupdatehelper]
		,[salesline].[tamrebateexcluderebatemanagement] AS [tamrebateexcluderebatemanagement]
		,[salesline].[subbillrevenuesplit] AS [subbillrevenuesplit]
		,[salesline].[subbillrevenuesplitallocationmethod] AS [subbillrevenuesplitallocationmethod]
		,[salesline].[subbillisrevenuesplitchild] AS [subbillisrevenuesplitchild]
		,[salesline].[subbillissplitbilling] AS [subbillissplitbilling]
		,[salesline].[subbillistermsplit] AS [subbillistermsplit]
		,[salesline].[unbilledrevenuecredit] AS [unbilledrevenuecredit]
		,[salesline].[revrecbundle] AS [revrecbundle]
		,[salesline].[revrecisbundlecomponent] AS [revrecisbundlecomponent]
		,[salesline].[revrecbundlesalesstatus] AS [revrecbundlesalesstatus]
		,[salesline].[isfreeitemline] AS [isfreeitemline]
		,[salesline].[sysdatastatecode] AS [sysdatastatecode]
		,[salesline].[activitynumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [activitynumber]
		,[salesline].[addressrefrecid] AS [addressrefrecid]
		,[salesline].[addressreftableid] AS [addressreftableid]
		,[salesline].[assetid_ru] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [assetid_ru]
		,[salesline].[barcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [barcode]
		,[salesline].[barcodetype] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [barcodetype]
		,[salesline].[confirmeddlv] AS [confirmeddlv]
		,[salesline].[costprice] AS [costprice]
		,[salesline].[countryregionname_ru] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [countryregionname_ru]
		,[salesline].[countyorigdest] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [countyorigdest]
		,[salesline].[creditnoteinternalref_pl] AS [creditnoteinternalref_pl]
		,[salesline].[creditnotereasoncode] AS [creditnotereasoncode]
		,[salesline].[currencycode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencycode]
		,[salesline].[custaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custaccount]
		,[salesline].[custgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custgroup]
		,[salesline].[customerlinenum] AS [customerlinenum]
		,[salesline].[customerref] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customerref]
		,[salesline].[customsdocdate_mx] AS [customsdocdate_mx]
		,[salesline].[customsdocnumber_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customsdocnumber_mx]
		,[salesline].[customsname_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customsname_mx]
		,[salesline].[defaultdimension] AS [defaultdimension]
		,[salesline].[deliveryname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliveryname]
		,[salesline].[deliverypostaladdress] AS [deliverypostaladdress]
		,[salesline].[deliverytaxgroup_br] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliverytaxgroup_br]
		,[salesline].[deliverytaxitemgroup_br] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliverytaxitemgroup_br]
		,[salesline].[dlvmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvmode]
		,[salesline].[dlvterm] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvterm]
		,[salesline].[einvoiceaccountcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [einvoiceaccountcode]
		,[salesline].[expectedretqty] AS [expectedretqty]
		,[salesline].[externalitemid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [externalitemid]
		,[salesline].[intercompanyinventtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyinventtransid]
		,[salesline].[intrastatfulfillmentdate_hu] AS [intrastatfulfillmentdate_hu]
		,[salesline].[inventdelivernow] AS [inventdelivernow]
		,[salesline].[inventdimid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventdimid]
		,[salesline].[inventrefid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventrefid]
		,[salesline].[inventreftransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventreftransid]
		,[salesline].[inventtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventtransid]
		,[salesline].[inventtransidreturn] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventtransidreturn]
		,[salesline].[invoicegtdid_ru] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [invoicegtdid_ru]
		,[salesline].[itembomid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itembomid]
		,[salesline].[itemid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itemid]
		,[salesline].[itemrouteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itemrouteid]
		,[salesline].[ledgerdimension] AS [ledgerdimension]
		,[salesline].[lineamount] AS [lineamount]
		,[salesline].[linedisc] AS [linedisc]
		,[salesline].[lineheader] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [lineheader]
		,[salesline].[linenum] AS [linenum]
		,[salesline].[linepercent] AS [linepercent]
		,[salesline].[manualentrychangepolicy] AS [manualentrychangepolicy]
		,[salesline].[matchingagreementline] AS [matchingagreementline]
		,[salesline].[mcrorderline2pricehistoryref] AS [mcrorderline2pricehistoryref]
		,[salesline].[multilndisc] AS [multilndisc]
		,[salesline].[multilnpercent] AS [multilnpercent]
		,[salesline].[name] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [name]
		,[salesline].[overdeliverypct] AS [overdeliverypct]
		,[salesline].[packingunit] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [packingunit]
		,[salesline].[packingunitqty] AS [packingunitqty]
		,[salesline].[pdscwexpectedretqty] AS [pdscwexpectedretqty]
		,[salesline].[pdscwinventdelivernow] AS [pdscwinventdelivernow]
		,[salesline].[pdscwqty] AS [pdscwqty]
		,[salesline].[pdscwremaininventfinancial] AS [pdscwremaininventfinancial]
		,[salesline].[pdscwremaininventphysical] AS [pdscwremaininventphysical]
		,[salesline].[pdsitemrebategroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pdsitemrebategroupid]
		,[salesline].[port] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [port]
		,[salesline].[postingprofile_ru] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [postingprofile_ru]
		,[salesline].[priceagreementdate_ru] AS [priceagreementdate_ru]
		,[salesline].[priceunit] AS [priceunit]
		,[salesline].[projcategoryid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projcategoryid]
		,[salesline].[projid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projid]
		,[salesline].[projlinepropertyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projlinepropertyid]
		,[salesline].[projtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projtransid]
		,[salesline].[propertynumber_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [propertynumber_mx]
		,[salesline].[psacontractlinenum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [psacontractlinenum]
		,[salesline].[psaprojproposalinventqty] AS [psaprojproposalinventqty]
		,[salesline].[psaprojproposalqty] AS [psaprojproposalqty]
		,[salesline].[purchorderformnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchorderformnum]
		,[salesline].[qtyordered] AS [qtyordered]
		,[salesline].[receiptdateconfirmed] AS [receiptdateconfirmed]
		,[salesline].[receiptdaterequested] AS [receiptdaterequested]
		,[salesline].[refreturninvoicetrans_w] AS [refreturninvoicetrans_w]
		,[salesline].[remaininventfinancial] AS [remaininventfinancial]
		,[salesline].[remaininventphysical] AS [remaininventphysical]
		,[salesline].[remainsalesfinancial] AS [remainsalesfinancial]
		,[salesline].[remainsalesphysical] AS [remainsalesphysical]
		,[salesline].[retailblockqty] AS [retailblockqty]
		,[salesline].[retailvariantid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [retailvariantid]
		,[salesline].[returnarrivaldate] AS [returnarrivaldate]
		,[salesline].[returncloseddate] AS [returncloseddate]
		,[salesline].[returndeadline] AS [returndeadline]
		,[salesline].[returndispositioncodeid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returndispositioncodeid]
		,[salesline].[salescategory] AS [salescategory]
		,[salesline].[salesdelivernow] AS [salesdelivernow]
		,[salesline].[salesgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesgroup]
		,[salesline].[salesid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesid]
		,[salesline].[salesmarkup] AS [salesmarkup]
		,[salesline].[salesprice] AS [salesprice]
		,[salesline].[salesqty] AS [salesqty]
		,[salesline].[salesunit] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [salesunit]
		,[salesline].[serviceorderid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [serviceorderid]
		,[salesline].[shipcarrieraccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrieraccount]
		,[salesline].[shipcarrieraccountcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrieraccountcode]
		,[salesline].[shipcarrierid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarrierid]
		,[salesline].[shipcarriername] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcarriername]
		,[salesline].[shipcarrierpostaladdress] AS [shipcarrierpostaladdress]
		,[salesline].[shippingdateconfirmed] AS [shippingdateconfirmed]
		,[salesline].[shippingdaterequested] AS [shippingdaterequested]
		,[salesline].[sourcedocumentline] AS [sourcedocumentline]
		,[salesline].[statisticvalue_lt] AS [statisticvalue_lt]
		,[salesline].[statprocid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [statprocid]
		,[salesline].[systementrychangepolicy] AS [systementrychangepolicy]
		,[salesline].[taxgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxgroup]
		,[salesline].[taxitemgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxitemgroup]
		,[salesline].[taxwithholdgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxwithholdgroup]
		,[salesline].[taxwithholditemgroupheading_th] AS [taxwithholditemgroupheading_th]
		,[salesline].[transactioncode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transactioncode]
		,[salesline].[transport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transport]
		,[salesline].[underdeliverypct] AS [underdeliverypct]
		,[salesline].[intrastatcommodity] AS [intrastatcommodity]
		,[salesline].[origcountryregionid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [origcountryregionid]
		,[salesline].[origstateid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [origstateid]
		,[salesline].[sourcingcompanyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sourcingcompanyid]
		,[salesline].[sourcinginventsiteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sourcinginventsiteid]
		,[salesline].[sourcinginventlocationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sourcinginventlocationid]
		,[salesline].[sourcingvendaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sourcingvendaccount]
		,[salesline].[orderlinereference_no] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [orderlinereference_no]
		,[salesline].[linecreationsequencenumber] AS [linecreationsequencenumber]
		,[salesline].[satproductcode_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satproductcode_mx]
		,[salesline].[satunitcode_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satunitcode_mx]
		,[salesline].[accountingdistributiontemplate] AS [accountingdistributiontemplate]
		,[salesline].[satcustomsqty_mx] AS [satcustomsqty_mx]
		,[salesline].[satcustomunitofmeasure_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [satcustomunitofmeasure_mx]
		,[salesline].[sattarifffraction_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [sattarifffraction_mx]
		,[salesline].[mcrmarginpercent] AS [mcrmarginpercent]
		,[salesline].[projfundingsource] AS [projfundingsource]
		,[salesline].[planningpriority] AS [planningpriority]
		,[salesline].[inventoryservicereservationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventoryservicereservationid]
		,[salesline].[fintag] AS [fintag]
		,[salesline].[inventoryserviceadjustmentoffsetdatasource] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventoryserviceadjustmentoffsetdatasource]
		,[salesline].[inventoryserviceadjustmentoffsetphysicalmeasure] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventoryserviceadjustmentoffsetphysicalmeasure]
		,[salesline].[pricedisclookupcachekey] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pricedisclookupcachekey]
		,[salesline].[taxid] AS [taxid]
		,[salesline].[createdbyparmid_it] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdbyparmid_it]
		,[salesline].[prepaymentrecid_it] AS [prepaymentrecid_it]
		,[salesline].[eximports_in] AS [eximports_in]
		,[salesline].[eximproductgroup_in] AS [eximproductgroup_in]
		,[salesline].[customsmaterialtype_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customsmaterialtype_mx]
		,[salesline].[customsdocumenttype_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customsdocumenttype_mx]
		,[salesline].[materialdescription_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [materialdescription_mx]
		,[salesline].[identifiercustomsdocument_mx] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [identifiercustomsdocument_mx]
		,[salesline].[domiterations] AS [domiterations]
		,[salesline].[domprocesseddatetime] AS [domprocesseddatetime]
		,[salesline].[domrecversion] AS [domrecversion]
		,[salesline].[tamrebatetransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamrebatetransid]
		,[salesline].[subbillrevenuesplitparentlinerecid] AS [subbillrevenuesplitparentlinerecid]
		,[salesline].[subbillrevenuesplitparentamount] AS [subbillrevenuesplitparentamount]
		,[salesline].[subbilldetaillinerecid] AS [subbilldetaillinerecid]
		,[salesline].[subbilltermschedulelinerecid] AS [subbilltermschedulelinerecid]
		,[salesline].[revrecrevenuescheduleid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [revrecrevenuescheduleid]
		,[salesline].[revrecoccurrences] AS [revrecoccurrences]
		,[salesline].[revrecbundlenetamount] AS [revrecbundlenetamount]
		,[salesline].[revrecbundleparent] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [revrecbundleparent]
		,[salesline].[revrecbundleqty] AS [revrecbundleqty]
		,[salesline].[revrecbundleratio] AS [revrecbundleratio]
		,[salesline].[revreccontractenddate] AS [revreccontractenddate]
		,[salesline].[revreccontractstartdate] AS [revreccontractstartdate]
		,[salesline].[revrecbundlelinedisc] AS [revrecbundlelinedisc]
		,[salesline].[revrecbundlelinepercent] AS [revrecbundlelinepercent]
		,[salesline].[revrecbundleqtyordered] AS [revrecbundleqtyordered]
		,[salesline].[revrecbundleremaininventphysical] AS [revrecbundleremaininventphysical]
		,[salesline].[revrecbundleremainsalesphysical] AS [revrecbundleremainsalesphysical]
		,[salesline].[revrecbundlesalesprice] AS [revrecbundlesalesprice]
		,[salesline].[revrecbundlemainparent] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [revrecbundlemainparent]
		,[salesline].[gupfreeitemlinerecid] AS [gupfreeitemlinerecid]
		,[salesline].[modifieddatetime] AS [modifieddatetime]
		,[salesline].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby]
		,[salesline].[modifiedtransactionid] AS [modifiedtransactionid]
		,[salesline].[createddatetime] AS [createddatetime]
		,[salesline].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby]
		,[salesline].[createdtransactionid] AS [createdtransactionid]
		,[salesline].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid]
		,[salesline].[recversion] AS [recversion]
		,[salesline].[partition] AS [partition]
		,[salesline].[sysrowversion] AS [sysrowversion]
		,[salesline].[recid] AS [recid]
		,[salesline].[tableid] AS [tableid]
		,[salesline].[versionnumber] AS [versionnumber]
		,[salesline].[createdon] AS [createdon]
		,[salesline].[modifiedon] AS [modifiedon]
		,[salesline].[IsDelete] AS [IsDelete]
		,[salesline].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
		,CASE [salesline].[agreementskipautolink]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS agreementskipautolink_$label
		,CASE [salesline].[autocreateintercompanyorders]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS autocreateintercompanyorders_$label
		,CASE [salesline].[blocked]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS blocked_$label
		,CASE [salesline].[bundlelinestatus]
			WHEN 4
				THEN ''Canceled''
			WHEN 3
				THEN ''Invoiced''
			WHEN 2
				THEN ''Delivered''
			WHEN 1
				THEN ''Backorder''
			WHEN 0
				THEN ''None''
			END AS bundlelinestatus_$label
		,CASE [salesline].[bundlelinetype]
			WHEN 3
				THEN ''BundleComponent''
			WHEN 2
				THEN ''NestedBundleParent''
			WHEN 1
				THEN ''BundleParent''
			WHEN 0
				THEN ''None''
			END AS bundlelinetype_$label
		,CASE [salesline].[casetagging]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS casetagging_$label
		,CASE [salesline].[complete]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS complete_$label
		,CASE [salesline].[consignment_mx]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS consignment_mx_$label
		,CASE [salesline].[defaultlinenumberfromlinecreationsequencenumber]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS defaultlinenumberfromlinecreationsequencenumber_$label
		,CASE [salesline].[deliverydatecontroltype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''SalesLeadTime''
			WHEN 2
				THEN ''ATP''
			WHEN 3
				THEN ''ATPPlusIssueMargin''
			WHEN 4
				THEN ''CTP''
			WHEN 5
				THEN ''FullRunCTP''
			END AS deliverydatecontroltype_$label
		,CASE [salesline].[deliverytype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''DropShip''
			END AS deliverytype_$label
		,CASE [salesline].[domexceptiontype]
			WHEN 14
				THEN ''InvalidCoordinatesWhenAzureMapsOnException''
			WHEN 13
				THEN ''InvalidCoordinatesWhenBingMapsOffException''
			WHEN 12
				THEN ''InvalidCoordinatesWhenBingMapsOnException''
			WHEN 11
				THEN ''OtherLineReservationFailure''
			WHEN 10
				THEN ''Generic''
			WHEN 9
				THEN ''QuantityCouldNotBeReserved''
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''NoQuantityAvailable''
			WHEN 2
				THEN ''MaximumRejections''
			WHEN 3
				THEN ''DataModificationConflict''
			WHEN 4
				THEN ''OrderLineSpecificException''
			WHEN 5
				THEN ''InvalidCostValue''
			WHEN 6
				THEN ''NoRoadRoute''
			WHEN 7
				THEN ''BingMapsFailure''
			WHEN 8
				THEN ''MaximumOrdersDataModificationConflict''
			END AS domexceptiontype_$label
		,CASE [salesline].[domignore]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS domignore_$label
		,CASE [salesline].[domprocessed]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Complete''
			WHEN 2
				THEN ''Exception''
			END AS domprocessed_$label
		,CASE [salesline].[goodsforfree_it]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS goodsforfree_it_$label
		,CASE [salesline].[intercompanyorigin]
			WHEN 0
				THEN ''Source''
			WHEN 1
				THEN ''Derived''
			END AS intercompanyorigin_$label
		,CASE [salesline].[inventoryserviceautooffset]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS inventoryserviceautooffset_$label
		,CASE [salesline].[inventreftype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Sales''
			WHEN 2
				THEN ''Purch''
			WHEN 3
				THEN ''Production''
			WHEN 4
				THEN ''ProdLine''
			WHEN 5
				THEN ''InventJournal''
			WHEN 6
				THEN ''CRMQuotation''
			WHEN 7
				THEN ''InventTransfer''
			WHEN 8
				THEN ''FixedAsset''
			END AS inventreftype_$label
		,CASE [salesline].[isfreeitemline]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS isfreeitemline_$label
		,CASE [salesline].[isintegration]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''CDS''
			WHEN 2
				THEN ''Dynamics365Sales''
			WHEN 3
				THEN ''DataEntity''
			END AS isintegration_$label
		,CASE [salesline].[issoftreservedexternally]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS issoftreservedexternally_$label
		,CASE [salesline].[itemreplaced]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS itemreplaced_$label
		,CASE [salesline].[itemtagging]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS itemtagging_$label
		,CASE [salesline].[keepsalespriceandsetdiscount]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS keepsalespriceandsetdiscount_$label
		,CASE [salesline].[kittingskipupdatehelper]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS kittingskipupdatehelper_$label
		,CASE [salesline].[linedeliverytype]
			WHEN 2
				THEN ''DeliveryLine''
			WHEN 1
				THEN ''OrderLineWithMultipleDeliveries''
			WHEN 0
				THEN ''OrderLine''
			END AS linedeliverytype_$label
		,CASE [salesline].[mcrmarginupdated]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS mcrmarginupdated_$label
		,CASE [salesline].[mpsexcludesalesline]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS mpsexcludesalesline_$label
		,CASE [salesline].[mpsfullrunctpstatus]
			WHEN 1
				THEN ''NotReady''
			WHEN 0
				THEN ''Ready''
			END AS mpsfullrunctpstatus_$label
		,CASE [salesline].[mpsupdateexcludesalesline]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS mpsupdateexcludesalesline_$label
		,CASE [salesline].[overridesalestax]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS overridesalestax_$label
		,CASE [salesline].[pallettagging]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS pallettagging_$label
		,CASE [salesline].[pdsbatchattribautores]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS pdsbatchattribautores_$label
		,CASE [salesline].[pdsexcludefromrebate]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS pdsexcludefromrebate_$label
		,CASE [salesline].[pdssamelot]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS pdssamelot_$label
		,CASE [salesline].[pdssamelotoverride]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS pdssamelotoverride_$label
		,CASE [salesline].[reservation]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Automatic''
			WHEN 2
				THEN ''Explosion''
			END AS reservation_$label
		,CASE [salesline].[returnallowreservation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS returnallowreservation_$label
		,CASE [salesline].[returnstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Awaiting''
			WHEN 2
				THEN ''Registered''
			WHEN 3
				THEN ''Quarantine''
			WHEN 4
				THEN ''Received''
			WHEN 5
				THEN ''Invoiced''
			WHEN 6
				THEN ''Canceled''
			END AS returnstatus_$label
		,CASE [salesline].[revrecbundle]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS revrecbundle_$label
		,CASE [salesline].[revrecbundlesalesstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Backorder''
			WHEN 2
				THEN ''Delivered''
			WHEN 3
				THEN ''Invoiced''
			WHEN 4
				THEN ''Canceled''
			END AS revrecbundlesalesstatus_$label
		,CASE [salesline].[revrecisbundlecomponent]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS revrecisbundlecomponent_$label
		,CASE [salesline].[salesorderintegrationcreationtype]
			WHEN 0
				THEN ''Unknown''
			WHEN 1
				THEN ''WinQuote''
			END AS salesorderintegrationcreationtype_$label
		,CASE [salesline].[salessalesordercreationmethod]
			WHEN 0
				THEN ''SalesOrder''
			WHEN 1
				THEN ''RetailStatement''
			END AS salessalesordercreationmethod_$label
		,CASE [salesline].[salesstatus]
			WHEN 4
				THEN ''Canceled''
			WHEN 3
				THEN ''Invoiced''
			WHEN 2
				THEN ''Delivered''
			WHEN 1
				THEN ''Open''
			WHEN 0
				THEN ''None''
			END AS salesstatus_$label
		,CASE [salesline].[salestype]
			WHEN 2
				THEN ''Subscription''
			WHEN 3
				THEN ''Sales''
			WHEN 4
				THEN ''ReturnItem''
			WHEN 5
				THEN ''DEL_Blanket''
			WHEN 6
				THEN ''ItemReq''
			WHEN 7
				THEN ''Prepayment''
			WHEN 1
				THEN ''DEL_Quotation''
			WHEN 0
				THEN ''Journal''
			END AS salestype_$label
		,CASE [salesline].[samples_mx]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS samples_mx_$label
		,CASE [salesline].[scrap]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS scrap_$label
		,CASE [salesline].[servicelinetype_it]
			WHEN 1
				THEN ''Prepayment''
			WHEN 0
				THEN ''None''
			END AS servicelinetype_it_$label
		,CASE [salesline].[shipcarrierdlvtype]
			WHEN 3
				THEN ''PickUp''
			WHEN 2
				THEN ''Air''
			WHEN 1
				THEN ''Ground''
			WHEN 0
				THEN ''Misc''
			END AS shipcarrierdlvtype_$label
		,CASE [salesline].[skipassigninventtransid]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipassigninventtransid_$label
		,CASE [salesline].[skipcreatemarkup]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipcreatemarkup_$label
		,CASE [salesline].[skipdefaultingsourcingvendor]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipdefaultingsourcingvendor_$label
		,CASE [salesline].[skipdeliveryscheduleupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipdeliveryscheduleupdate_$label
		,CASE [salesline].[skipintercompanypurchorderaccountingdistribution]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipintercompanypurchorderaccountingdistribution_$label
		,CASE [salesline].[skippricedisccalc]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skippricedisccalc_$label
		,CASE [salesline].[skippricedisccalcinbulkcreation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skippricedisccalcinbulkcreation_$label
		,CASE [salesline].[skippricedisccalconimport]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skippricedisccalconimport_$label
		,CASE [salesline].[skipupdate]
			WHEN 3
				THEN ''Both''
			WHEN 2
				THEN ''InterCompany''
			WHEN 1
				THEN ''Internal''
			WHEN 0
				THEN ''No''
			END AS skipupdate_$label
		,CASE [salesline].[softreserveblocklevel]
			WHEN 2
				THEN ''Block''
			WHEN 1
				THEN ''Warning''
			WHEN 0
				THEN ''Ignore''
			END AS softreserveblocklevel_$label
		,CASE [salesline].[sourcingorigin]
			WHEN 3
				THEN ''ExternalVendor''
			WHEN 2
				THEN ''Intercompany''
			WHEN 1
				THEN ''Inventory''
			WHEN 0
				THEN ''Unknown''
			END AS sourcingorigin_$label
		,CASE [salesline].[stattriangulardeal]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS stattriangulardeal_$label
		,CASE [salesline].[stockedproduct]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS stockedproduct_$label
		,CASE [salesline].[subbillisrevenuesplitchild]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillisrevenuesplitchild_$label
		,CASE [salesline].[subbillissplitbilling]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillissplitbilling_$label
		,CASE [salesline].[subbillistermsplit]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillistermsplit_$label
		,CASE [salesline].[subbillrevenuesplit]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS subbillrevenuesplit_$label
		,CASE [salesline].[subbillrevenuesplitallocationmethod]
			WHEN 0
				THEN ''VariableAmount''
			WHEN 1
				THEN ''Percentage''
			WHEN 2
				THEN ''EqualAmount''
			WHEN 3
				THEN ''ZeroAmount''
			WHEN 4
				THEN ''ZeroParentAmount''
			END AS subbillrevenuesplitallocationmethod_$label
		,CASE [salesline].[syncintercompanypurchline]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS syncintercompanypurchline_$label
		,CASE [salesline].[syncpurchline]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS syncpurchline_$label
		,CASE [salesline].[systementrysource]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''CopyFromSalesOrder''
			WHEN 2
				THEN ''CopyFromSalesQuotation''
			WHEN 3
				THEN ''Project''
			WHEN 4
				THEN ''SalesQuotation''
			WHEN 5
				THEN ''CopyFromPurchaseOrder''
			WHEN 6
				THEN ''RequestForQuote''
			WHEN 7
				THEN ''PurchaseReq''
			WHEN 8
				THEN ''ManualEntry''
			WHEN 9
				THEN ''Agreement''
			WHEN 11
				THEN ''ProductConfig''
			WHEN 12
				THEN ''RetailPOS''
			END AS systementrysource_$label
		,CASE [salesline].[tamrebateexcluderebatemanagement]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS tamrebateexcluderebatemanagement_$label
		,CASE [salesline].[taxautogenerated]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS taxautogenerated_$label
		,CASE [salesline].[unbilledrevenuecredit]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS unbilledrevenuecredit_$label
	FROM '+@Dataverse+'.dbo.salesline
	WHERE salesline.IsDelete IS NULL '

	exec (@sql)


	-- create view definition  purchtable
	SET @sql = '' + '
	CREATE OR ALTER VIEW [dbo].[purchtable]
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
				THEN ''Vend''
			WHEN 1
				THEN ''Purch''
			END AS autosummarymoduletype_$label
		,CASE [purchtable].[awaitingworkflowtotalscalculation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS awaitingworkflowtotalscalculation_$label
		,CASE [purchtable].[bankdocumenttype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''LetterOfCredit''
			WHEN 2
				THEN ''ImportCollection''
			WHEN 3
				THEN ''LetterOfGuarantee''
			END AS bankdocumenttype_$label
		,CASE [purchtable].[changerequestrequired]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS changerequestrequired_$label
		,CASE [purchtable].[constarget_jp]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS constarget_jp_$label
		,CASE [purchtable].[cxmlorderenable]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS cxmlorderenable_$label
		,CASE [purchtable].[deliverytype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Company''
			END AS deliverytype_$label
		,CASE [purchtable].[documentstate]
			WHEN 20
				THEN ''Rejected''
			WHEN 30
				THEN ''Approved''
			WHEN 35
				THEN ''InExternalReview''
			WHEN 50
				THEN ''Finalized''
			WHEN 40
				THEN ''Confirmed''
			WHEN 0
				THEN ''Draft''
			WHEN 10
				THEN ''InReview''
			END AS documentstate_$label
		,CASE [purchtable].[documentstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Quotation''
			WHEN 2
				THEN ''PurchaseOrder''
			WHEN 3
				THEN ''Confirmation''
			WHEN 4
				THEN ''PickingList''
			WHEN 5
				THEN ''PackingSlip''
			WHEN 6
				THEN ''ReceiptsList''
			WHEN 7
				THEN ''Invoice''
			WHEN 8
				THEN ''ApproveJournal''
			WHEN 9
				THEN ''ProjectInvoice''
			WHEN 10
				THEN ''ProjectPackingSlip''
			WHEN 11
				THEN ''CRMQuotation''
			WHEN 12
				THEN ''Lost''
			WHEN 13
				THEN ''Cancelled''
			WHEN 14
				THEN ''FreeTextInvoice''
			WHEN 15
				THEN ''RFQ''
			WHEN 16
				THEN ''RFQAccept''
			WHEN 17
				THEN ''RFQReject''
			WHEN 18
				THEN ''PurchReq''
			WHEN 19
				THEN ''RFQReSend''
			WHEN 30
				THEN ''ConfirmationRequest''
			WHEN 219
				THEN ''InvoiceRegistration_IN''
			WHEN 220
				THEN ''BillOfEntry_IN''
			WHEN 221
				THEN ''ShippingBill_IN''
			WHEN 101
				THEN ''Invoice4Paym_RU''
			WHEN 102
				THEN ''Facture_RU''
			WHEN 105
				THEN ''FreeTextInvoice4Paym_RU''
			WHEN 150
				THEN ''DeliverySlip_BR''
			WHEN 103
				THEN ''PlSAD''
			WHEN 222
				THEN ''DeliverySlipProject_BR''
			WHEN 20
				THEN ''Note''
			WHEN 21
				THEN ''ProjectPickingList''
			WHEN 22
				THEN ''ITMGoodsInTransitReceive''
			WHEN 23
				THEN ''RevRecRevenueCancelation''
			WHEN 24
				THEN ''RevRecDeferredRevenueInvoice''
			END AS documentstatus_$label
		,CASE [purchtable].[freightsliptype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''UPS''
			END AS freightsliptype_$label
		,CASE [purchtable].[fshautocreated]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS fshautocreated_$label
		,CASE [purchtable].[incltax]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS incltax_$label
		,CASE [purchtable].[intercompanyallowindirectcreation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS intercompanyallowindirectcreation_$label
		,CASE [purchtable].[intercompanydirectdelivery]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS intercompanydirectdelivery_$label
		,CASE [purchtable].[intercompanyorder]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS intercompanyorder_$label
		,CASE [purchtable].[intercompanyorigin]
			WHEN 0
				THEN ''Source''
			WHEN 1
				THEN ''Derived''
			END AS intercompanyorigin_$label
		,CASE [purchtable].[invoiceautonumbering_lt]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS invoiceautonumbering_lt_$label
		,CASE [purchtable].[invoiceregister_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS invoiceregister_lt_$label
		,CASE [purchtable].[isencumbrancerequired]
			WHEN 0
				THEN ''Unknown''
			WHEN 1
				THEN ''No''
			WHEN 2
				THEN ''Yes''
			END AS isencumbrancerequired_$label
		,CASE [purchtable].[isintegration]
			WHEN 3
				THEN ''DataEntity''
			WHEN 2
				THEN ''Dynamics365Sales''
			WHEN 1
				THEN ''CDS''
			WHEN 0
				THEN ''No''
			END AS isintegration_$label
		,CASE [purchtable].[ismodified]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS ismodified_$label
		,CASE [purchtable].[itmdataeventtype]
			WHEN 50
				THEN ''DeletedLite''
			WHEN 49
				THEN ''UpdatedLite''
			WHEN 48
				THEN ''InsertedLite''
			WHEN 47
				THEN ''FinalInsertValidation''
			WHEN 46
				THEN ''FinalUpdateValidation''
			WHEN 45
				THEN ''FinalDeleteValidation''
			WHEN 44
				THEN ''FinalReadValidation''
			WHEN 43
				THEN ''GotDefaultingDependencies''
			WHEN 42
				THEN ''GettingDefaultingDependencies''
			WHEN 41
				THEN ''DefaultedRow''
			WHEN 40
				THEN ''DefaultingRow''
			WHEN 39
				THEN ''DefaultedField''
			WHEN 38
				THEN ''DefaultingField''
			WHEN 37
				THEN ''PostedLoad''
			WHEN 36
				THEN ''PostingLoad''
			WHEN 35
				THEN ''DeletedEntityDataSource''
			WHEN 34
				THEN ''DeletingEntityDataSource''
			WHEN 33
				THEN ''UpdatedEntityDataSource''
			WHEN 32
				THEN ''UpdatingEntityDataSource''
			WHEN 31
				THEN ''InsertedEntityDataSource''
			WHEN 30
				THEN ''InsertingEntityDataSource''
			WHEN 29
				THEN ''FoundEntityDataSource''
			WHEN 28
				THEN ''FindingEntityDataSource''
			WHEN 27
				THEN ''MappedDataSourceToEntity''
			WHEN 26
				THEN ''MappingDataSourceToEntity''
			WHEN 25
				THEN ''MappedEntityToDataSource''
			WHEN 24
				THEN ''MappingEntityToDataSource''
			WHEN 23
				THEN ''InitializedEntityDataSource''
			WHEN 22
				THEN ''InitializingEntityDataSource''
			WHEN 21
				THEN ''PersistedEntity''
			WHEN 20
				THEN ''PersistingEntity''
			WHEN 19
				THEN ''ModifiedFieldValue''
			WHEN 18
				THEN ''ModifyingFieldValue''
			WHEN 17
				THEN ''ValidatedFieldValue''
			WHEN 16
				THEN ''ValidatingFieldValue''
			WHEN 15
				THEN ''ModifiedField''
			WHEN 14
				THEN ''ModifyingField''
			WHEN 13
				THEN ''ValidatedField''
			WHEN 12
				THEN ''ValidatingField''
			WHEN 11
				THEN ''InitializedRecord''
			WHEN 10
				THEN ''InitializingRecord''
			WHEN 9
				THEN ''ValidatedDelete''
			WHEN 8
				THEN ''ValidatingDelete''
			WHEN 7
				THEN ''ValidatedWrite''
			WHEN 6
				THEN ''ValidatingWrite''
			WHEN 5
				THEN ''Deleted''
			WHEN 4
				THEN ''Deleting''
			WHEN 3
				THEN ''Updated''
			WHEN 2
				THEN ''Updating''
			WHEN 1
				THEN ''Inserted''
			WHEN 0
				THEN ''Inserting''
			END AS itmdataeventtype_$label
		,CASE [purchtable].[itmfreightresponsibility]
			WHEN 0
				THEN ''None''
			WHEN 2
				THEN ''BuyerToPayDiff''
			WHEN 1
				THEN ''FactoryToPaySea''
			END AS itmfreightresponsibility_$label
		,CASE [purchtable].[itmimportcostingvendor]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS itmimportcostingvendor_$label
		,CASE [purchtable].[itmmeasurementunit]
			WHEN 5
				THEN ''CubicFeet''
			WHEN 4
				THEN ''Kilogramme''
			WHEN 3
				THEN ''Skids''
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Pounds''
			WHEN 2
				THEN ''CubicMetre''
			END AS itmmeasurementunit_$label
		,CASE [purchtable].[itmoverunder]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS itmoverunder_$label
		,CASE [purchtable].[listcode]
			WHEN 0
				THEN ''IncludeNot''
			WHEN 1
				THEN ''EUTrade''
			WHEN 2
				THEN ''ProductionOnToll''
			WHEN 3
				THEN ''TriangularEUTrade''
			WHEN 4
				THEN ''TriangularProductionOnToll''
			WHEN 50
				THEN ''PropertyMoving_CZ''
			WHEN 51
				THEN ''TriangularIntermediateRole_HU''
			WHEN 52
				THEN ''DEL_EUService''
			WHEN 53
				THEN ''PurchasedOnBehalf_LV''
			END AS listcode_$label
		,CASE [purchtable].[mcrdropshipment]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS mcrdropshipment_$label
		,CASE [purchtable].[onetimesupplier]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS onetimesupplier_$label
		,CASE [purchtable].[onetimevendor]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS onetimevendor_$label
		,CASE [purchtable].[overridesalestax]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS overridesalestax_$label
		,CASE [purchtable].[packingslipautonumbering_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS packingslipautonumbering_lt_$label
		,CASE [purchtable].[packingslipregister_lt]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS packingslipregister_lt_$label
		,CASE [purchtable].[purchaseorderheadercreationmethod]
			WHEN 1
				THEN ''Consignment''
			WHEN 0
				THEN ''Purchase''
			END AS purchaseorderheadercreationmethod_$label
		,CASE [purchtable].[purchasetype]
			WHEN 0
				THEN ''Journal''
			WHEN 1
				THEN ''DEL_Quotation''
			WHEN 2
				THEN ''DEL_Subscription''
			WHEN 3
				THEN ''Purch''
			WHEN 4
				THEN ''ReturnItem''
			WHEN 5
				THEN ''DEL_Blanket''
			END AS purchasetype_$label
		,CASE [purchtable].[purchstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Open''
			WHEN 2
				THEN ''Received''
			WHEN 3
				THEN ''Invoiced''
			WHEN 4
				THEN ''Canceled''
			END AS purchstatus_$label
		,CASE [purchtable].[retailretailstatustype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Document''
			WHEN 2
				THEN ''Sent''
			WHEN 3
				THEN ''PartReceipt''
			WHEN 4
				THEN ''ClosedOk''
			WHEN 5
				THEN ''ClosedDifference''
			WHEN 6
				THEN ''Canceled''
			END AS retailretailstatustype_$label
		,CASE [purchtable].[returnreplacementcreated]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS returnreplacementcreated_$label
		,CASE [purchtable].[settlevoucher]
			WHEN 2
				THEN ''SelectedTransact''
			WHEN 1
				THEN ''OpenTransact''
			WHEN 0
				THEN ''None''
			END AS settlevoucher_$label
		,CASE [purchtable].[skipcreatemarkup]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skipcreatemarkup_$label
		,CASE [purchtable].[skipshipreceiptdatecalculation]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skipshipreceiptdatecalculation_$label
		,CASE [purchtable].[skipupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Internal''
			WHEN 2
				THEN ''InterCompany''
			WHEN 3
				THEN ''Both''
			END AS skipupdate_$label
		,CASE [purchtable].[skipversioning]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skipversioning_$label
		,CASE [purchtable].[systementrysource]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''CopyFromSalesOrder''
			WHEN 2
				THEN ''CopyFromSalesQuotation''
			WHEN 3
				THEN ''Project''
			WHEN 4
				THEN ''SalesQuotation''
			WHEN 5
				THEN ''CopyFromPurchaseOrder''
			WHEN 6
				THEN ''RequestForQuote''
			WHEN 7
				THEN ''PurchaseReq''
			WHEN 8
				THEN ''ManualEntry''
			WHEN 9
				THEN ''Agreement''
			WHEN 11
				THEN ''ProductConfig''
			WHEN 12
				THEN ''RetailPOS''
			END AS systementrysource_$label
		,CASE [purchtable].[unitedvatinvoice_lt]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS unitedvatinvoice_lt_$label
		,CASE [purchtable].[vatnumtabletype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''TaxRegistration''
			WHEN 2
				THEN ''TaxVATNumTable''
			END AS vatnumtabletype_$label
	FROM '+@Dataverse+'.dbo.purchtable
	WHERE purchtable.IsDelete IS NULL
'

	exec (@sql)




	
	-- create view definition  purchline
	SET @sql = '' + '
	CREATE OR ALTER VIEW  purchline 
	AS
	SELECT [purchline].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id]
		,[purchline].[SinkCreatedOn] AS [SinkCreatedOn]
		,[purchline].[SinkModifiedOn] AS [SinkModifiedOn]
		,[purchline].[agreementskipautolink] AS [agreementskipautolink]
		,[purchline].[assettranstypepurch] AS [assettranstypepurch]
		,[purchline].[blocked] AS [blocked]
		,[purchline].[complete] AS [complete]
		,[purchline].[covref] AS [covref]
		,[purchline].[createfixedasset] AS [createfixedasset]
		,[purchline].[deliverytype] AS [deliverytype]
		,[purchline].[editableinworkflow] AS [editableinworkflow]
		,[purchline].[gsthsttaxtype_ca] AS [gsthsttaxtype_ca]
		,[purchline].[intercompanyorigin] AS [intercompanyorigin]
		,[purchline].[isdeleted] AS [isdeleted]
		,[purchline].[isfinalized] AS [isfinalized]
		,[purchline].[isinvoicematched] AS [isinvoicematched]
		,[purchline].[ismodified] AS [ismodified]
		,[purchline].[ispwp] AS [ispwp]
		,[purchline].[itemreftype] AS [itemreftype]
		,[purchline].[linedeliverytype] AS [linedeliverytype]
		,[purchline].[matchingpolicy] AS [matchingpolicy]
		,[purchline].[mcrdropshipment] AS [mcrdropshipment]
		,[purchline].[mcrdropshipstatus] AS [mcrdropshipstatus]
		,[purchline].[operationtype_mx] AS [operationtype_mx]
		,[purchline].[purchasetype] AS [purchasetype]
		,[purchline].[purchstatus] AS [purchstatus]
		,[purchline].[returnstatus] AS [returnstatus]
		,[purchline].[scrap] AS [scrap]
		,[purchline].[skipdistributionupdate] AS [skipdistributionupdate]
		,[purchline].[skipupdate] AS [skipupdate]
		,[purchline].[stattriangulardeal] AS [stattriangulardeal]
		,[purchline].[stockedproduct] AS [stockedproduct]
		,[purchline].[systementrysource] AS [systementrysource]
		,[purchline].[taxautogenerated] AS [taxautogenerated]
		,[purchline].[wfdeliveryduestate] AS [wfdeliveryduestate]
		,[purchline].[wfinvreceivedstate] AS [wfinvreceivedstate]
		,[purchline].[workflowstate] AS [workflowstate]
		,[purchline].[skipcreatemarkup] AS [skipcreatemarkup]
		,[purchline].[purchaseorderlinecreationmethod] AS [purchaseorderlinecreationmethod]
		,[purchline].[syncintercompanysalesline] AS [syncintercompanysalesline]
		,[purchline].[skipdeliveryscheduleupdate] AS [skipdeliveryscheduleupdate]
		,[purchline].[skippricedisccalc] AS [skippricedisccalc]
		,[purchline].[isaddedbychannel] AS [isaddedbychannel]
		,[purchline].[overridesalestax] AS [overridesalestax]
		,[purchline].[skipshipreceiptdatecalculation] AS [skipshipreceiptdatecalculation]
		,[purchline].[isintegration] AS [isintegration]
		,[purchline].[skippricedisccalconimport] AS [skippricedisccalconimport]
		,[purchline].[itmfreightresponsibility] AS [itmfreightresponsibility]
		,[purchline].[itmoverunder] AS [itmoverunder]
		,[purchline].[itmskipupdate] AS [itmskipupdate]
		,[purchline].[itmdataeventtype] AS [itmdataeventtype]
		,[purchline].[psncalendardays] AS [psncalendardays]
		,[purchline].[psncalculatedeliverydate] AS [psncalculatedeliverydate]
		,[purchline].[sysdatastatecode] AS [sysdatastatecode]
		,[purchline].[taxitemgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxitemgroup]
		,[purchline].[taxgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxgroup]
		,[purchline].[accountingdistributiontemplate] AS [accountingdistributiontemplate]
		,[purchline].[activitynumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [activitynumber]
		,[purchline].[addressrefrecid] AS [addressrefrecid]
		,[purchline].[addressreftableid] AS [addressreftableid]
		,[purchline].[assetbookid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [assetbookid]
		,[purchline].[assetgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [assetgroup]
		,[purchline].[assetid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [assetid]
		,[purchline].[barcode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [barcode]
		,[purchline].[barcodetype] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [barcodetype]
		,[purchline].[cfoptable_br] AS [cfoptable_br]
		,[purchline].[confirmeddlv] AS [confirmeddlv]
		,[purchline].[confirmedtaxamount] AS [confirmedtaxamount]
		,[purchline].[confirmedtaxwritecode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [confirmedtaxwritecode]
		,[purchline].[countyorigdest] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [countyorigdest]
		,[purchline].[currencycode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [currencycode]
		,[purchline].[customerref] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [customerref]
		,[purchline].[custpurchaseorderformnum] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [custpurchaseorderformnum]
		,[purchline].[defaultdimension] AS [defaultdimension]
		,[purchline].[deliverydate] AS [deliverydate]
		,[purchline].[deliveryname] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [deliveryname]
		,[purchline].[deliverypostaladdress] AS [deliverypostaladdress]
		,[purchline].[depreciationstartdate] AS [depreciationstartdate]
		,[purchline].[discamount] AS [discamount]
		,[purchline].[discpercent] AS [discpercent]
		,[purchline].[externalitemid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [externalitemid]
		,[purchline].[intercompanyinventtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyinventtransid]
		,[purchline].[intrastatfulfillmentdate_hu] AS [intrastatfulfillmentdate_hu]
		,[purchline].[inventdimid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventdimid]
		,[purchline].[inventinvoicenow] AS [inventinvoicenow]
		,[purchline].[inventreceivednow] AS [inventreceivednow]
		,[purchline].[inventrefid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventrefid]
		,[purchline].[inventreftransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventreftransid]
		,[purchline].[inventtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [inventtransid]
		,[purchline].[itembomid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itembomid]
		,[purchline].[itemid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itemid]
		,[purchline].[itemrouteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itemrouteid]
		,[purchline].[ledgerdimension] AS [ledgerdimension]
		,[purchline].[lineamount] AS [lineamount]
		,[purchline].[linedisc] AS [linedisc]
		,[purchline].[lineheader] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [lineheader]
		,[purchline].[linenumber] AS [linenumber]
		,[purchline].[linepercent] AS [linepercent]
		,[purchline].[manualentrychangepolicy] AS [manualentrychangepolicy]
		,[purchline].[manualmodifiedfield] AS [manualmodifiedfield]
		,[purchline].[matchingagreementline] AS [matchingagreementline]
		,[purchline].[mcrdropshipcomment] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [mcrdropshipcomment]
		,[purchline].[mcrorderline2pricehistoryref] AS [mcrorderline2pricehistoryref]
		,[purchline].[multilndisc] AS [multilndisc]
		,[purchline].[multilnpercent] AS [multilnpercent]
		,[purchline].[name] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [name]
		,[purchline].[overdeliverypct] AS [overdeliverypct]
		,[purchline].[pdscalculationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [pdscalculationid]
		,[purchline].[pdscwinventreceivednow] AS [pdscwinventreceivednow]
		,[purchline].[pdscwqty] AS [pdscwqty]
		,[purchline].[pdscwremaininventfinancial] AS [pdscwremaininventfinancial]
		,[purchline].[pdscwremaininventphysical] AS [pdscwremaininventphysical]
		,[purchline].[planreference] AS [planreference]
		,[purchline].[port] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [port]
		,[purchline].[priceunit] AS [priceunit]
		,[purchline].[procurementcategory] AS [procurementcategory]
		,[purchline].[projcategoryid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projcategoryid]
		,[purchline].[projcontractlineid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projcontractlineid]
		,[purchline].[projid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projid]
		,[purchline].[projlinepropertyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projlinepropertyid]
		,[purchline].[projsalescurrencyid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projsalescurrencyid]
		,[purchline].[projsalesprice] AS [projsalesprice]
		,[purchline].[projsalesunitid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projsalesunitid]
		,[purchline].[projtaxgroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projtaxgroupid]
		,[purchline].[projtaxitemgroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projtaxitemgroupid]
		,[purchline].[projtransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projtransid]
		,[purchline].[projworker] AS [projworker]
		,[purchline].[psaretainscheduleid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [psaretainscheduleid]
		,[purchline].[psatotalretainamount] AS [psatotalretainamount]
		,[purchline].[purchcommitmentline_psn] AS [purchcommitmentline_psn]
		,[purchline].[purchid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchid]
		,[purchline].[purchmarkup] AS [purchmarkup]
		,[purchline].[purchprice] AS [purchprice]
		,[purchline].[purchqty] AS [purchqty]
		,[purchline].[purchreceivednow] AS [purchreceivednow]
		,[purchline].[purchreqid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchreqid]
		,[purchline].[purchreqlinerefid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchreqlinerefid]
		,[purchline].[purchunit] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchunit]
		,[purchline].[qtyordered] AS [qtyordered]
		,[purchline].[rbopackagelinenum] AS [rbopackagelinenum]
		,[purchline].[remainder] AS [remainder]
		,[purchline].[remaininventfinancial] AS [remaininventfinancial]
		,[purchline].[remaininventphysical] AS [remaininventphysical]
		,[purchline].[remainpurchfinancial] AS [remainpurchfinancial]
		,[purchline].[remainpurchphysical] AS [remainpurchphysical]
		,[purchline].[reqattention] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [reqattention]
		,[purchline].[reqplanidsched] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [reqplanidsched]
		,[purchline].[reqpoid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [reqpoid]
		,[purchline].[requester] AS [requester]
		,[purchline].[retaillinenumex1] AS [retaillinenumex1]
		,[purchline].[retailpackageid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [retailpackageid]
		,[purchline].[retailtempvalueex2] AS [retailtempvalueex2]
		,[purchline].[returnactionid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returnactionid]
		,[purchline].[returndispositioncodeid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [returndispositioncodeid]
		,[purchline].[serviceaddress] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [serviceaddress]
		,[purchline].[servicedate] AS [servicedate]
		,[purchline].[shippingdateconfirmed] AS [shippingdateconfirmed]
		,[purchline].[shippingdaterequested] AS [shippingdaterequested]
		,[purchline].[sourcedocumentline] AS [sourcedocumentline]
		,[purchline].[statisticvalue_lt] AS [statisticvalue_lt]
		,[purchline].[statprocid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [statprocid]
		,[purchline].[systementrychangepolicy] AS [systementrychangepolicy]
		,[purchline].[tamitemvendrebategroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamitemvendrebategroupid]
		,[purchline].[tax1099amount] AS [tax1099amount]
		,[purchline].[tax1099fields] AS [tax1099fields]
		,[purchline].[tax1099recid] AS [tax1099recid]
		,[purchline].[tax1099state] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tax1099state]
		,[purchline].[tax1099stateamount] AS [tax1099stateamount]
		,[purchline].[taxservicecode_br] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxservicecode_br]
		,[purchline].[taxwithholdbasecur_th] AS [taxwithholdbasecur_th]
		,[purchline].[taxwithholdgroup_th] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [taxwithholdgroup_th]
		,[purchline].[taxwithholditemgroupheading_th] AS [taxwithholditemgroupheading_th]
		,[purchline].[transactioncode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transactioncode]
		,[purchline].[transport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [transport]
		,[purchline].[underdeliverypct] AS [underdeliverypct]
		,[purchline].[variantid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [variantid]
		,[purchline].[vendaccount] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendaccount]
		,[purchline].[vendgroup] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [vendgroup]
		,[purchline].[creditedvendinvoicetrans] AS [creditedvendinvoicetrans]
		,[purchline].[intrastatcommodity] AS [intrastatcommodity]
		,[purchline].[origcountryregionid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [origcountryregionid]
		,[purchline].[origstateid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [origstateid]
		,[purchline].[intercompanyososourcinginventsiteid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyososourcinginventsiteid]
		,[purchline].[intercompanyososourcinginventlocationid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [intercompanyososourcinginventlocationid]
		,[purchline].[budgetreservationline_psn] AS [budgetreservationline_psn]
		,[purchline].[purchsupplierauxid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [purchsupplierauxid]
		,[purchline].[planningpriority] AS [planningpriority]
		,[purchline].[requestedshipdate] AS [requestedshipdate]
		,[purchline].[confirmedshipdate] AS [confirmedshipdate]
		,[purchline].[shipcalendarid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [shipcalendarid]
		,[purchline].[projsubcontractlinenumber] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [projsubcontractlinenumber]
		,[purchline].[fintag] AS [fintag]
		,[purchline].[eximports_in] AS [eximports_in]
		,[purchline].[eximproductgroup_in] AS [eximproductgroup_in]
		,[purchline].[dlvterm] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvterm]
		,[purchline].[dlvmode] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dlvmode]
		,[purchline].[itmfromport] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmfromport]
		,[purchline].[itmoverundertransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmoverundertransid]
		,[purchline].[itmdate] AS [itmdate]
		,[purchline].[itmarrivalgroupid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmarrivalgroupid]
		,[purchline].[itmcustomsdescid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmcustomsdescid]
		,[purchline].[itmstatusid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmstatusid]
		,[purchline].[itmexfactorydate] AS [itmexfactorydate]
		,[purchline].[itmid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [itmid]
		,[purchline].[itmintostoredate] AS [itmintostoredate]
		,[purchline].[psnleadtime] AS [psnleadtime]
		,[purchline].[tamrebatetransid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [tamrebatetransid]
		,[purchline].[itembasepricerecid] AS [itembasepricerecid]
		,[purchline].[modifieddatetime] AS [modifieddatetime]
		,[purchline].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby]
		,[purchline].[modifiedtransactionid] AS [modifiedtransactionid]
		,[purchline].[createddatetime] AS [createddatetime]
		,[purchline].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby]
		,[purchline].[createdtransactionid] AS [createdtransactionid]
		,[purchline].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid]
		,[purchline].[recversion] AS [recversion]
		,[purchline].[partition] AS [partition]
		,[purchline].[sysrowversion] AS [sysrowversion]
		,[purchline].[recid] AS [recid]
		,[purchline].[tableid] AS [tableid]
		,[purchline].[versionnumber] AS [versionnumber]
		,[purchline].[createdon] AS [createdon]
		,[purchline].[modifiedon] AS [modifiedon]
		,[purchline].[IsDelete] AS [IsDelete]
		,[purchline].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
		,CASE [purchline].[agreementskipautolink]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS agreementskipautolink_$label
		,CASE [purchline].[assettranstypepurch]
			WHEN 0
				THEN ''Acquisition''
			WHEN 1
				THEN ''AcquisitionAdj''
			WHEN 2
				THEN ''PreAcquisition_CZ''
			END AS assettranstypepurch_$label
		,CASE [purchline].[blocked]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS blocked_$label
		,CASE [purchline].[complete]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS complete_$label
		,CASE [purchline].[covref]
			WHEN 4
				THEN ''ProdTrans''
			WHEN 3
				THEN ''SalesOrderLine''
			WHEN 2
				THEN ''FixedAssetsTrans''
			WHEN 1
				THEN ''ProjectTrans''
			WHEN 0
				THEN ''None''
			END AS covref_$label
		,CASE [purchline].[createfixedasset]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS createfixedasset_$label
		,CASE [purchline].[deliverytype]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''DropShip''
			END AS deliverytype_$label
		,CASE [purchline].[editableinworkflow]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS editableinworkflow_$label
		,CASE [purchline].[gsthsttaxtype_ca]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Rebates111''
			WHEN 2
				THEN ''TaxOnAcquisition205''
			WHEN 3
				THEN ''SelfAssessment405''
			END AS gsthsttaxtype_ca_$label
		,CASE [purchline].[intercompanyorigin]
			WHEN 0
				THEN ''Source''
			WHEN 1
				THEN ''Derived''
			END AS intercompanyorigin_$label
		,CASE [purchline].[isaddedbychannel]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS isaddedbychannel_$label
		,CASE [purchline].[isdeleted]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS isdeleted_$label
		,CASE [purchline].[isfinalized]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS isfinalized_$label
		,CASE [purchline].[isintegration]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''CDS''
			WHEN 2
				THEN ''Dynamics365Sales''
			WHEN 3
				THEN ''DataEntity''
			END AS isintegration_$label
		,CASE [purchline].[isinvoicematched]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS isinvoicematched_$label
		,CASE [purchline].[ismodified]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS ismodified_$label
		,CASE [purchline].[ispwp]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS ispwp_$label
		,CASE [purchline].[itemreftype]
			WHEN 2
				THEN ''Purch''
			WHEN 3
				THEN ''Production''
			WHEN 4
				THEN ''ProdLine''
			WHEN 5
				THEN ''InventJournal''
			WHEN 6
				THEN ''CRMQuotation''
			WHEN 7
				THEN ''InventTransfer''
			WHEN 8
				THEN ''FixedAsset''
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Sales''
			END AS itemreftype_$label
		,CASE [purchline].[itmdataeventtype]
			WHEN 50
				THEN ''DeletedLite''
			WHEN 49
				THEN ''UpdatedLite''
			WHEN 48
				THEN ''InsertedLite''
			WHEN 47
				THEN ''FinalInsertValidation''
			WHEN 46
				THEN ''FinalUpdateValidation''
			WHEN 45
				THEN ''FinalDeleteValidation''
			WHEN 44
				THEN ''FinalReadValidation''
			WHEN 43
				THEN ''GotDefaultingDependencies''
			WHEN 42
				THEN ''GettingDefaultingDependencies''
			WHEN 41
				THEN ''DefaultedRow''
			WHEN 40
				THEN ''DefaultingRow''
			WHEN 39
				THEN ''DefaultedField''
			WHEN 38
				THEN ''DefaultingField''
			WHEN 37
				THEN ''PostedLoad''
			WHEN 36
				THEN ''PostingLoad''
			WHEN 35
				THEN ''DeletedEntityDataSource''
			WHEN 34
				THEN ''DeletingEntityDataSource''
			WHEN 33
				THEN ''UpdatedEntityDataSource''
			WHEN 32
				THEN ''UpdatingEntityDataSource''
			WHEN 31
				THEN ''InsertedEntityDataSource''
			WHEN 30
				THEN ''InsertingEntityDataSource''
			WHEN 29
				THEN ''FoundEntityDataSource''
			WHEN 28
				THEN ''FindingEntityDataSource''
			WHEN 27
				THEN ''MappedDataSourceToEntity''
			WHEN 26
				THEN ''MappingDataSourceToEntity''
			WHEN 25
				THEN ''MappedEntityToDataSource''
			WHEN 24
				THEN ''MappingEntityToDataSource''
			WHEN 23
				THEN ''InitializedEntityDataSource''
			WHEN 22
				THEN ''InitializingEntityDataSource''
			WHEN 21
				THEN ''PersistedEntity''
			WHEN 20
				THEN ''PersistingEntity''
			WHEN 19
				THEN ''ModifiedFieldValue''
			WHEN 18
				THEN ''ModifyingFieldValue''
			WHEN 17
				THEN ''ValidatedFieldValue''
			WHEN 16
				THEN ''ValidatingFieldValue''
			WHEN 15
				THEN ''ModifiedField''
			WHEN 14
				THEN ''ModifyingField''
			WHEN 13
				THEN ''ValidatedField''
			WHEN 12
				THEN ''ValidatingField''
			WHEN 11
				THEN ''InitializedRecord''
			WHEN 10
				THEN ''InitializingRecord''
			WHEN 9
				THEN ''ValidatedDelete''
			WHEN 8
				THEN ''ValidatingDelete''
			WHEN 7
				THEN ''ValidatedWrite''
			WHEN 6
				THEN ''ValidatingWrite''
			WHEN 5
				THEN ''Deleted''
			WHEN 4
				THEN ''Deleting''
			WHEN 3
				THEN ''Updated''
			WHEN 2
				THEN ''Updating''
			WHEN 1
				THEN ''Inserted''
			WHEN 0
				THEN ''Inserting''
			END AS itmdataeventtype_$label
		,CASE [purchline].[itmfreightresponsibility]
			WHEN 0
				THEN ''None''
			WHEN 2
				THEN ''BuyerToPayDiff''
			WHEN 1
				THEN ''FactoryToPaySea''
			END AS itmfreightresponsibility_$label
		,CASE [purchline].[itmoverunder]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS itmoverunder_$label
		,CASE [purchline].[itmskipupdate]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS itmskipupdate_$label
		,CASE [purchline].[linedeliverytype]
			WHEN 2
				THEN ''DeliveryLine''
			WHEN 1
				THEN ''OrderLineWithMultipleDeliveries''
			WHEN 0
				THEN ''OrderLine''
			END AS linedeliverytype_$label
		,CASE [purchline].[matchingpolicy]
			WHEN 0
				THEN ''ThreeWayMatch''
			WHEN 1
				THEN ''TwoWayMatch''
			WHEN 2
				THEN ''NoMatch''
			END AS matchingpolicy_$label
		,CASE [purchline].[mcrdropshipment]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS mcrdropshipment_$label
		,CASE [purchline].[mcrdropshipstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''ToBeDropShipped''
			WHEN 2
				THEN ''POCreated''
			WHEN 3
				THEN ''POReleased''
			WHEN 4
				THEN ''POShipped''
			END AS mcrdropshipstatus_$label
		,CASE [purchline].[operationtype_mx]
			WHEN 0
				THEN ''Blank''
			WHEN 2
				THEN ''SalesGoods''
			WHEN 3
				THEN ''ProServices''
			WHEN 6
				THEN ''RentLease''
			WHEN 7
				THEN ''ImportGoodsServices''
			WHEN 8
				THEN ''ImportVirtualTransfer''
			WHEN 85
				THEN ''Other''
			WHEN 87
				THEN ''GlobalOperations''
			END AS operationtype_mx_$label
		,CASE [purchline].[overridesalestax]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS overridesalestax_$label
		,CASE [purchline].[psncalculatedeliverydate]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS psncalculatedeliverydate_$label
		,CASE [purchline].[psncalendardays]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS psncalendardays_$label
		,CASE [purchline].[purchaseorderlinecreationmethod]
			WHEN 0
				THEN ''Purchase''
			WHEN 1
				THEN ''Consignment''
			END AS purchaseorderlinecreationmethod_$label
		,CASE [purchline].[purchasetype]
			WHEN 4
				THEN ''ReturnItem''
			WHEN 5
				THEN ''DEL_Blanket''
			WHEN 3
				THEN ''Purch''
			WHEN 2
				THEN ''DEL_Subscription''
			WHEN 1
				THEN ''DEL_Quotation''
			WHEN 0
				THEN ''Journal''
			END AS purchasetype_$label
		,CASE [purchline].[purchstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Open''
			WHEN 2
				THEN ''Received''
			WHEN 3
				THEN ''Invoiced''
			WHEN 4
				THEN ''Canceled''
			END AS purchstatus_$label
		,CASE [purchline].[returnstatus]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''Awaiting''
			WHEN 2
				THEN ''Registered''
			WHEN 3
				THEN ''Quarantine''
			WHEN 4
				THEN ''Received''
			WHEN 5
				THEN ''Invoiced''
			WHEN 6
				THEN ''Canceled''
			END AS returnstatus_$label
		,CASE [purchline].[scrap]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS scrap_$label
		,CASE [purchline].[skipcreatemarkup]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skipcreatemarkup_$label
		,CASE [purchline].[skipdeliveryscheduleupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipdeliveryscheduleupdate_$label
		,CASE [purchline].[skipdistributionupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipdistributionupdate_$label
		,CASE [purchline].[skippricedisccalc]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS skippricedisccalc_$label
		,CASE [purchline].[skippricedisccalconimport]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skippricedisccalconimport_$label
		,CASE [purchline].[skipshipreceiptdatecalculation]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS skipshipreceiptdatecalculation_$label
		,CASE [purchline].[skipupdate]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Internal''
			WHEN 2
				THEN ''InterCompany''
			WHEN 3
				THEN ''Both''
			END AS skipupdate_$label
		,CASE [purchline].[stattriangulardeal]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS stattriangulardeal_$label
		,CASE [purchline].[stockedproduct]
			WHEN 0
				THEN ''No''
			WHEN 1
				THEN ''Yes''
			END AS stockedproduct_$label
		,CASE [purchline].[syncintercompanysalesline]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS syncintercompanysalesline_$label
		,CASE [purchline].[systementrysource]
			WHEN 0
				THEN ''None''
			WHEN 1
				THEN ''CopyFromSalesOrder''
			WHEN 2
				THEN ''CopyFromSalesQuotation''
			WHEN 3
				THEN ''Project''
			WHEN 4
				THEN ''SalesQuotation''
			WHEN 5
				THEN ''CopyFromPurchaseOrder''
			WHEN 6
				THEN ''RequestForQuote''
			WHEN 7
				THEN ''PurchaseReq''
			WHEN 8
				THEN ''ManualEntry''
			WHEN 9
				THEN ''Agreement''
			WHEN 11
				THEN ''ProductConfig''
			WHEN 12
				THEN ''RetailPOS''
			END AS systementrysource_$label
		,CASE [purchline].[taxautogenerated]
			WHEN 1
				THEN ''Yes''
			WHEN 0
				THEN ''No''
			END AS taxautogenerated_$label
		,CASE [purchline].[wfdeliveryduestate]
			WHEN 0
				THEN ''NotSubmitted''
			WHEN 1
				THEN ''Submitted''
			WHEN 2
				THEN ''PendingApproval''
			WHEN 3
				THEN ''PendingCompletion''
			WHEN 4
				THEN ''Returned''
			WHEN 5
				THEN ''ChangeRequest''
			WHEN 6
				THEN ''Completed''
			WHEN 7
				THEN ''Approved''
			END AS wfdeliveryduestate_$label
		,CASE [purchline].[wfinvreceivedstate]
			WHEN 0
				THEN ''NotSubmitted''
			WHEN 1
				THEN ''Submitted''
			WHEN 2
				THEN ''PendingApproval''
			WHEN 3
				THEN ''PendingCompletion''
			WHEN 4
				THEN ''Returned''
			WHEN 5
				THEN ''ChangeRequest''
			WHEN 6
				THEN ''Completed''
			WHEN 7
				THEN ''Approved''
			END AS wfinvreceivedstate_$label
		,CASE [purchline].[workflowstate]
			WHEN 0
				THEN ''NotSubmitted''
			WHEN 1
				THEN ''Submitted''
			WHEN 2
				THEN ''PendingApproval''
			WHEN 3
				THEN ''PendingCompletion''
			WHEN 4
				THEN ''Returned''
			WHEN 5
				THEN ''ChangeRequest''
			WHEN 6
				THEN ''Completed''
			WHEN 7
				THEN ''Approved''
			END AS workflowstate_$label
	FROM '+@Dataverse+'.dbo.purchline
	WHERE purchline.IsDelete IS NULL
	'

	exec (@sql)

	

	-- create view definition  projpostedtranstable
	SET @sql = '' + '
	CREATE OR ALTER VIEW  projpostedtranstable 
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
	'
	SET @sql2 = '' + '
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
			THEN ''Yes''
		WHEN 0
			THEN ''No''
		END AS iscorrection_$label
	,CASE [projpostedtranstable].[issplittransaction]
		WHEN 1
			THEN ''Yes''
		WHEN 0
			THEN ''No''
		END AS issplittransaction_$label


	,CASE [projpostedtranstable].[projtranstype]
		WHEN 0
			THEN ''None''
		WHEN 1
			THEN ''Revenue''
		WHEN 2
			THEN ''Hour''
		WHEN 3
			THEN ''Expense''
		WHEN 4
			THEN ''Item''
		WHEN 5
			THEN ''OnAccount''
		WHEN 6
			THEN ''WIP''
		WHEN 7
			THEN ''IndirectComponent''
		WHEN 8
			THEN ''Retainage''
		END AS projtranstype_$label


	,CASE [projpostedtranstable].[transactionorigin]
		WHEN 14
			THEN ''ItemRequirement''
		WHEN 15
			THEN ''SalesOrder''
		WHEN 16
			THEN ''ProductionFinished''
		WHEN 17
			THEN ''ProductionConsumed''
		WHEN 18
			THEN ''FeeJournal''
		WHEN 19
			THEN ''EstimateFee''
		WHEN 20
			THEN ''Subscription''
		WHEN 21
			THEN ''Prepayment''
		WHEN 22
			THEN ''Deduction''
		WHEN 23
			THEN ''Milestone''
		WHEN 50
			THEN ''Invoice''
		WHEN 51
			THEN ''InventoryClosing''
		WHEN 52
			THEN ''Adjustment''
		WHEN 53
			THEN ''PostCost''
		WHEN 54
			THEN ''AccrueRevenue''
		WHEN 55
			THEN ''PostEstimate''
		WHEN 56
			THEN ''ReverseEstimate''
		WHEN 57
			THEN ''EliminateEstimate''
		WHEN 58
			THEN ''ReverseElimination''
		WHEN 59
			THEN ''AccrueSubscriptionRev''
		WHEN 63
			THEN ''BeginningBalance''
		WHEN 61
			THEN ''PurchaseRequisition''
		WHEN 60
			THEN ''Timesheet''
		WHEN 64
			THEN ''FreeTextInvoice''
		WHEN 65
			THEN ''VendorInvoice''
		WHEN 66
			THEN ''AdvancedLedgerEntry''
		WHEN 70
			THEN ''PayrollEarningStatement''
		WHEN 71
			THEN ''PayrollPayStatement''
		WHEN 72
			THEN ''ProgressBillingRule''
		WHEN 73
			THEN ''UnitOfDeliveryBillingRule''
		WHEN 74
			THEN ''BudgetReservation''
		WHEN 75
			THEN ''ProjAdvancedJournal''
		WHEN 13
			THEN ''PurchaseOrder''
		WHEN 12
			THEN ''ItemJournal''
		WHEN 10
			THEN ''EstimateAccruedLoss''
		WHEN 9
			THEN ''EliminationInvestment''
		WHEN 8
			THEN ''ExpenseManagement''
		WHEN 7
			THEN ''InvoiceApprovalJournal''
		WHEN 6
			THEN ''InvoiceJournal''
		WHEN 5
			THEN ''GeneralJournal''
		WHEN 4
			THEN ''CostJournal''
		WHEN 1
			THEN ''HourJournal''
		WHEN 0
			THEN ''None''
		END AS transactionorigin_$label
	FROM '+@Dataverse+'.dbo.projpostedtranstable
	WHERE projpostedtranstable.IsDelete IS NULL
'

	exec (@sql + @sql2)		
/*


	-- create view definition  TEMPLATE
	SET @sql = '' + '
	CREATE OR ALTER VIEW  VIEWNAME 
	AS
		SELECT
			Cols
	FROM '+@Dataverse+'.dbo.VIEWNAME
	WHERE VIEWNAME.IsDelete IS NULL
'

	exec (@sql)
*/

GO

