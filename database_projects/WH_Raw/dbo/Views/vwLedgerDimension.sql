

CREATE   VIEW vwLedgerDimension AS
SELECT LD.LedgerDimension
, GL.VALUE  GL_Account
, BU.VALUE Business_Unit
, D.VALUE Department
, PL.VALUE Product_Line
, S.VALUE Site
FROM
(
SELECT DISTINCT dimensionattributevaluecombination as LedgerDimension 
FROM DimensionAttributeValueGroupCombination
) LD
LEFT JOIN vwStageLedgerDimension GL
  ON LD.LedgerDimension = GL.LEDGERDIMENSION
    AND GL.DIMENSIONNAME = 'MainAccount'
LEFT JOIN vwStageLedgerDimension BU
  ON LD.LedgerDimension = BU.LEDGERDIMENSION
    AND BU.DIMENSIONNAME = 'BusinessUnit'
LEFT JOIN vwStageLedgerDimension D
  ON LD.LedgerDimension = D.LEDGERDIMENSION
    AND D.DIMENSIONNAME = 'Department'
LEFT JOIN vwStageLedgerDimension PL
  ON LD.LedgerDimension = PL.LEDGERDIMENSION
    AND PL.DIMENSIONNAME = 'ProductLine'
LEFT JOIN vwStageLedgerDimension S
  ON LD.LedgerDimension = S.LEDGERDIMENSION
    AND S.DIMENSIONNAME = 'Site'

GO

