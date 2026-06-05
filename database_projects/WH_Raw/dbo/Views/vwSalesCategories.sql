



CREATE   VIEW vwSalesCategories
as
SELECT
    ECH.Name AS HierarchyName,
	EC_L1.RecId AS CategoryRecId,
    CASE 
        WHEN EC_L5.Name IS NOT NULL THEN EC_L5.Name
        WHEN EC_L4.Name IS NOT NULL THEN EC_L4.Name
        WHEN EC_L3.Name IS NOT NULL THEN EC_L3.Name
        WHEN EC_L2.Name IS NOT NULL THEN EC_L2.Name
        ELSE EC_L1.Name
    END AS Level1Category,

    CASE 
        WHEN EC_L5.Name IS NOT NULL THEN EC_L4.Name
        WHEN EC_L4.Name IS NOT NULL THEN EC_L3.Name
        WHEN EC_L3.Name IS NOT NULL THEN EC_L2.Name
        WHEN EC_L2.Name IS NOT NULL THEN EC_L1.Name
        ELSE NULL
    END AS Level2Category,

    CASE 
        WHEN EC_L5.Name IS NOT NULL THEN EC_L3.Name
        WHEN EC_L4.Name IS NOT NULL THEN EC_L2.Name
        WHEN EC_L3.Name IS NOT NULL THEN EC_L1.Name
        ELSE NULL
    END AS Level3Category,

    CASE 
        WHEN EC_L5.Name IS NOT NULL THEN EC_L2.Name
        WHEN EC_L4.Name IS NOT NULL THEN EC_L1.Name
        ELSE NULL
    END AS Level4Category,

    CASE 
        WHEN EC_L5.Name IS NOT NULL THEN EC_L1.Name
        ELSE NULL
    END AS Level5Category


FROM EcoResCategory EC_L1
LEFT JOIN EcoResCategory EC_L2 ON EC_L1.ParentCategory = EC_L2.RecId
LEFT JOIN EcoResCategory EC_L3 ON EC_L2.ParentCategory = EC_L3.RecId
LEFT JOIN EcoResCategory EC_L4 ON EC_L3.ParentCategory = EC_L4.RecId
LEFT JOIN EcoResCategory EC_L5 ON EC_L4.ParentCategory = EC_L5.RecId
JOIN EcoResCategoryHierarchy ECH ON EC_L1.CategoryHierarchy = ECH.RecId
WHERE ECH.Name = 'Sales Categories'
--order by 1,3,4,5,6,7

GO

