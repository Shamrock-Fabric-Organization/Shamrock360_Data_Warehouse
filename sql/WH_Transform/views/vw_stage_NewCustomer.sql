-- Auto Generated (Do not modify) 535252255A41A8D7B9335B710D5EB4592F32FFB850E03A9DFB25935F595E56CF
/****** Object:  View [dbo].[vw_stage_NewCustomer]    Script Date: 4/6/2026 4:00:40 PM ******/



    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE       VIEW [dbo].[vw_stage_NewCustomer]
AS
SELECT 
    CustomerKey
	,[CMPNY]
	,[Customer_ID]
	,[Invoice_Account]
	,[Legacy_Customer_ID]
	,[GMAccountNo]
	,[GMRecID]
	,[CustomerName]
	,[Harmonized_Name]
	,[Address]
	,[City]
	,[State]
	,[ZIP]
	,[Country]
	,[Territory_ID]
	,[Salesman_ID]
	,[SalesChannel]
	,[Industry_Segment]
	,[Subsegment]
	,[Status]
	,[EffectiveCountry]
	,[Account_Tier]
	,[Longitude]
	,[Latitude]
	,[PaymentTerms]
	,[PhoneNumber]
	, [PurchasingEmail]
	, [InvoicingEmail]
	,[customergroup]
	,[customer_currency]

	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Customer_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Customer AS Target
		WHERE Target.Customer_ID = Source.Customer_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);