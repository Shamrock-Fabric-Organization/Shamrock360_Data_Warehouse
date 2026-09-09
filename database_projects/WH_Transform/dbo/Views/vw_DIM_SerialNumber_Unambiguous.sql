-- ============================================================
-- View:    vw_DIM_SerialNumber_Unambiguous
-- Purpose: Serial-number lookup for facts whose own row cannot supply an item,
--          or whose serial resolves only to an 'Unknown' placeholder member.
--          Exposes ONLY serials that map to exactly one live dimension row for
--          a given company, so it can never fan a fact out. Serials tied to
--          more than one item are deliberately absent -- there is no correct
--          key to pick, and -1 is the honest answer.

-- ============================================================
CREATE OR ALTER VIEW [dbo].[vw_DIM_SerialNumber_Unambiguous]
AS
SELECT CMPNY
     , SerialNumber
     , MIN(SerialNumberKey) AS SerialNumberKey
FROM WH_Transform.dbo.tbl_DIM_SerialNumber
WHERE RecordStatus = 1
GROUP BY CMPNY, SerialNumber
HAVING COUNT(*) = 1;