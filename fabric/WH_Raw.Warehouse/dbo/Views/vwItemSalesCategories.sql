-- Auto Generated (Do not modify) E8402C50B2B6F94FB35739886A84B0DA1DF7E2DADC99D57C0BC6EB28B2DE9B78

CREATE   VIEW vwItemSalesCategories
as
SELECT IT.DATAAREAID
	,IT.ItemId
	,IT.PRODUCT
	,CASE 
		WHEN EC_L5.Name IS NOT NULL THEN EC_L5.Name
		WHEN EC_L4.Name IS NOT NULL THEN EC_L4.Name
		WHEN EC_L3.Name IS NOT NULL THEN EC_L3.Name
		WHEN EC_L2.Name IS NOT NULL THEN EC_L2.Name
		ELSE EC_L1.Name
	 END AS Level1Category
	,CASE 
		WHEN EC_L5.Name IS NOT NULL THEN EC_L4.Name
		WHEN EC_L4.Name IS NOT NULL THEN EC_L3.Name
		WHEN EC_L3.Name IS NOT NULL THEN EC_L2.Name
		WHEN EC_L2.Name IS NOT NULL THEN EC_L1.Name
		ELSE NULL
	 END AS Level2Category
	,CASE 
		WHEN EC_L5.Name IS NOT NULL THEN EC_L3.Name
		WHEN EC_L4.Name IS NOT NULL THEN EC_L2.Name
		WHEN EC_L3.Name IS NOT NULL THEN EC_L1.Name
		ELSE NULL
	 END AS Level3Category
	,CASE 
		WHEN EC_L5.Name IS NOT NULL THEN EC_L2.Name
		WHEN EC_L4.Name IS NOT NULL THEN EC_L1.Name
		ELSE NULL
	 END AS Level4Category
	,CASE 
		WHEN EC_L5.Name IS NOT NULL
			THEN EC_L1.Name
		ELSE NULL
	 END AS Level5Category
FROM InventTable IT
JOIN EcoResProduct EP
	ON IT.Product = EP.RecId
JOIN EcoResProductCategory EPC
	ON EP.RecId = EPC.Product
JOIN EcoResCategory EC_L1
	ON EPC.Category = EC_L1.RecId
LEFT JOIN EcoResCategory EC_L2
	ON EC_L1.ParentCategory = EC_L2.RecId
LEFT JOIN EcoResCategory EC_L3
	ON EC_L2.ParentCategory = EC_L3.RecId
LEFT JOIN EcoResCategory EC_L4
	ON EC_L3.ParentCategory = EC_L4.RecId
LEFT JOIN EcoResCategory EC_L5
	ON EC_L4.ParentCategory = EC_L5.RecId
JOIN EcoResCategoryHierarchy ECH
	ON EC_L1.CategoryHierarchy = ECH.RecId
WHERE ECH.Name = 'Sales Categories'

--SELECT IT.DATAAREAID
--	,IT.ItemId
--	,IT.PRODUCT
--	,COALESCE(EC_L5.Name, EC_L4.Name,EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level1Category
--	,COALESCE(EC_L4.Name,EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level2Category
--	,COALESCE(EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level3Category
--	,COALESCE(EC_L2.Name,EC_L1.Name) AS Level4Category 
--	,EC_L1.Name AS Level5Category
--FROM InventTable IT
--JOIN EcoResProduct EP
--	ON IT.Product = EP.RecId
--JOIN EcoResProductCategory EPC
--	ON EP.RecId = EPC.Product
--JOIN EcoResCategory EC_L1
--	ON EPC.Category = EC_L1.RecId
--LEFT JOIN EcoResCategory EC_L2
--	ON EC_L1.ParentCategory = EC_L2.RecId
--LEFT JOIN EcoResCategory EC_L3
--	ON EC_L2.ParentCategory = EC_L3.RecId
--LEFT JOIN EcoResCategory EC_L4
--	ON EC_L3.ParentCategory = EC_L4.RecId
--LEFT JOIN EcoResCategory EC_L5
--	ON EC_L4.ParentCategory = EC_L5.RecId
--JOIN EcoResCategoryHierarchy ECH
--	ON EC_L1.CategoryHierarchy = ECH.RecId
--WHERE ECH.Name = 'Sales Categories'

--SELECT IT.DATAAREAID
--	,IT.ItemId
--	,IT.PRODUCT
--	,COALESCE(EC_L5.Name, EC_L4.Name,EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level1Category
--	,COALESCE(EC_L4.Name,EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level2Category
--	,COALESCE(EC_L3.Name,EC_L2.Name,EC_L1.Name) AS Level3Category
--	,COALESCE(EC_L2.Name,EC_L1.Name) AS Level4Category 
--	,EC_L1.Name AS Level5Category
--FROM InventTable IT
--JOIN EcoResProduct EP
--	ON IT.Product = EP.RecId
--JOIN EcoResProductCategory EPC
--	ON EP.RecId = EPC.Product
--JOIN EcoResCategory EC_L1
--	ON EPC.Category = EC_L1.RecId
--LEFT JOIN EcoResCategory EC_L2
--	ON EC_L1.ParentCategory = EC_L2.RecId
--LEFT JOIN EcoResCategory EC_L3
--	ON EC_L2.ParentCategory = EC_L3.RecId
--LEFT JOIN EcoResCategory EC_L4
--	ON EC_L3.ParentCategory = EC_L4.RecId
--LEFT JOIN EcoResCategory EC_L5
--	ON EC_L4.ParentCategory = EC_L5.RecId
--JOIN EcoResCategoryHierarchy ECH
--	ON EC_L1.CategoryHierarchy = ECH.RecId
--WHERE ECH.Name = 'Sales Categories'