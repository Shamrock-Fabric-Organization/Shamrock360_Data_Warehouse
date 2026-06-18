-- Auto Generated (Do not modify) A9F2AB55BBE1A8542D11BADB390747C527D0E2C3AEF86E6870E94B4DC702020A


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE     VIEW [dbo].[vw_stage_NewPhantomProducts]
AS
SELECT 
    [PhantomProductKey]
	, [CMPNY]
	, [Product_ID]
	, [Phantom_Product]
	, [Commercial_Name]
	, [ActiveFormula_ID]
	, [Business_Line]
	, [Product_Line]
	, [Technology]
	, [Material]
	, [Description_Internal]
	, [Description_External]
	, [Application_Benefit]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus
	,[Source]
FROM vw_stage_DIM_PhantomProduct_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_PhantomProduct AS Target
		WHERE Target.Product_ID = Source.Product_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);