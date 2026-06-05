/****** Object:  View [dbo].[vw_stage_NewVendor]    Script Date: 1/21/2026 12:07:18 PM ******/


    -- Create a view to identify new records not present in the current dimension --needed because the CTAS does not allow the logic used
CREATE       VIEW [dbo].[vw_stage_NewVendor]
AS
SELECT 
    VendorKey
	,[CMPNY]
	,[Vendor_ID]
	,[Vendor_Name]
	,[Vendor_Type]
	,[Address]
	,[City]
	,[State]
	,[ZIP]
	,[Country]
	,[Currency]
	, vendgroup
	, VendGroupName
	, segmentid
	, subsegmentid
	,[Source]
	,CAST('1900-01-01' AS DATETIME2(3)) AS RecordEffectiveStartDate
	,CAST('2099-12-31 00:00:01.000' AS DATETIME2(3)) AS RecordEffectiveEndDate
	,1 AS RecordStatus

FROM vw_stage_DIM_Vendor_incoming AS Source
WHERE NOT EXISTS (
		SELECT 1
		FROM tbl_DIM_Vendor AS Target
		WHERE Target.Vendor_ID = Source.Vendor_ID
			AND Target.CMPNY = Source.CMPNY
			AND Target.RecordStatus = 1
		);

GO

