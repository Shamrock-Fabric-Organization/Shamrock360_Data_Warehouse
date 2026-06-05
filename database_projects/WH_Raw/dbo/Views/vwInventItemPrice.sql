/*
============================================================
  vwInventItemPrice
  Target:   Fabric Warehouse / AXDB
  Version:  v2.0 (2026-04-23)

  CHANGES FROM v1.0
  -----------------
  + Deduplication added to InventItemPrice reads.
    Root cause: multiple InventItemPrice records can exist for
    the same DATAAREAID + ITEMID + INVENTDIMID + ACTIVATIONDATE
    + PRICETYPE (e.g., from re-activations or data corrections).
    Fix: ROW_NUMBER() OVER (PARTITION BY natural key
         ORDER BY MODIFIEDDATETIME DESC, RECID DESC)
    keeps the most recently created/modified record per key.
  + Dedup applied to both the main join and the ToDate
    self-join subquery for consistency.
  + PARTITION excluded from all SELECT lists (Fabric rule).
  + Leading-comma column list style applied.

  LOGIC
  -----
  ToDate derivation: for each item+site+pricetype+activationdate,
  the ToDate = (next activation date - 2ms), or 2154-12-31 if
  no later activation exists.

  CurrentActiveCost = 1 when today falls within
  [ActivationDate, ToDate] for that price record.
============================================================
*/

CREATE   VIEW [dbo].[vwInventItemPrice]
AS

WITH

-- Deduplicated InventItemPrice: one row per natural key,
-- most recently modified/created record wins.
iip_dedup AS (
    SELECT
         [DATAAREAID]
        ,[RECID]
        ,[CREATEDDATETIME]
        ,[MODIFIEDDATETIME]
        ,[ACTIVATIONDATE]
        ,[COSTINGTYPE]
        ,[costingtype_$label]
        ,[INVENTDIMID]
        ,[ITEMID]
        ,[LASTPRICEUNIQUENESSALLOWANCE]
        ,[MARKUP]
        ,[MARKUPSECCUR_RU]
        ,[PRICE]
        ,[PRICEALLOCATEMARKUP]
        ,[priceallocatemarkup_$label]
        ,[PRICECALCID]
        ,[PRICEQTY]
        ,[PRICESECCUR_RU]
        ,[PRICETYPE]
        ,[pricetype_$label]
        ,[PRICEUNIT]
        ,[STDCOSTTRANSDATE]
        ,[STDCOSTVOUCHER]
        ,[UNITID]
        ,[VERSIONID]
        ,[createdby]
        ,[createdon]
        ,[createdtransactionid]
        ,[modifiedby]
        ,[modifiedon]
        ,[modifiedtransactionid]
        ,ROW_NUMBER() OVER (
            PARTITION BY [DATAAREAID], [ITEMID], [INVENTDIMID], [ACTIVATIONDATE], [PRICETYPE]
            ORDER BY [MODIFIEDDATETIME] DESC, [RECID] DESC
         ) AS _rn
    FROM [INVENTITEMPRICE]
)

SELECT
     iip.[DATAAREAID]
    ,iip.[RECID]
    ,iip.[CREATEDDATETIME]
    ,iip.[MODIFIEDDATETIME]
    ,iip.[ACTIVATIONDATE]
    ,iip.[COSTINGTYPE]
    ,iip.[costingtype_$label]
    ,iip.[INVENTDIMID]
    ,iip.[ITEMID]
    ,iip.[LASTPRICEUNIQUENESSALLOWANCE]
    ,iip.[MARKUP]
    ,iip.[MARKUPSECCUR_RU]
    ,iip.[PRICE]
    ,iip.[PRICEALLOCATEMARKUP]
    ,iip.[priceallocatemarkup_$label]
    ,iip.[PRICECALCID]
    ,iip.[PRICEQTY]
    ,iip.[PRICESECCUR_RU]
    ,iip.[PRICETYPE]
    ,iip.[pricetype_$label]
    ,iip.[PRICEUNIT]
    ,iip.[STDCOSTTRANSDATE]
    ,iip.[STDCOSTVOUCHER]
    ,iip.[UNITID]
    ,iip.[VERSIONID]
    ,id.[INVENTSITEID]
    ,t.[TODATE]
    ,CASE WHEN iip.[PRICEUNIT] <> 0
          THEN iip.[PRICE] / iip.[PRICEUNIT]
          ELSE NULL
     END                                             AS PricePerUnit
    ,CASE WHEN GETDATE() BETWEEN iip.[ACTIVATIONDATE] AND t.[TODATE]
          THEN 1
          ELSE 0
     END                                             AS CurrentActiveCost
    ,iip.[createdby]
    ,iip.[createdon]
    ,iip.[createdtransactionid]
    ,iip.[modifiedby]
    ,iip.[modifiedon]
    ,iip.[modifiedtransactionid]

FROM (SELECT * FROM iip_dedup WHERE _rn = 1) iip

JOIN [INVENTDIM] id
    ON  id.[INVENTDIMID] = iip.[INVENTDIMID]
    AND id.[DATAAREAID]  = iip.[DATAAREAID]

LEFT JOIN (
    -- ToDate: for each item+site+pricetype+activationdate, find the
    -- next activation date and subtract 2ms.  Open-ended = 2154-12-31.
    SELECT
         a.[DATAAREAID]
        ,a.[ITEMID]
        ,a.[PRICETYPE]
        ,a.[INVENTSITEID]
        ,a.[ACTIVATIONDATE]
        ,ISNULL(DATEADD(ms, -2, MIN(m.[ACTIVATIONDATE])), '2154-12-31') AS TODATE
    FROM (
        SELECT
             iip2.[DATAAREAID]
            ,iip2.[ITEMID]
            ,iip2.[PRICETYPE]
            ,id2.[INVENTSITEID]
            ,iip2.[ACTIVATIONDATE]
        FROM (SELECT * FROM iip_dedup WHERE _rn = 1) iip2
        JOIN [INVENTDIM] id2
            ON  id2.[INVENTDIMID] = iip2.[INVENTDIMID]
            AND id2.[DATAAREAID]  = iip2.[DATAAREAID]
    ) a
    LEFT JOIN (
        SELECT
             iip3.[DATAAREAID]
            ,iip3.[ITEMID]
            ,iip3.[PRICETYPE]
            ,id3.[INVENTSITEID]
            ,iip3.[ACTIVATIONDATE]
        FROM (SELECT * FROM iip_dedup WHERE _rn = 1) iip3
        JOIN [INVENTDIM] id3
            ON  id3.[INVENTDIMID] = iip3.[INVENTDIMID]
            AND id3.[DATAAREAID]  = iip3.[DATAAREAID]
    ) m
        ON  m.[ITEMID]       = a.[ITEMID]
        AND m.[INVENTSITEID] = a.[INVENTSITEID]
        AND m.[PRICETYPE]    = a.[PRICETYPE]
        AND m.[DATAAREAID]   = a.[DATAAREAID]
        AND m.[ACTIVATIONDATE] > a.[ACTIVATIONDATE]
    GROUP BY
         a.[DATAAREAID]
        ,a.[ITEMID]
        ,a.[PRICETYPE]
        ,a.[INVENTSITEID]
        ,a.[ACTIVATIONDATE]
) t
    ON  t.[ITEMID]       = iip.[ITEMID]
    AND t.[INVENTSITEID] = id.[INVENTSITEID]
    AND t.[PRICETYPE]    = iip.[PRICETYPE]
    AND t.[DATAAREAID]   = iip.[DATAAREAID]
    AND t.[ACTIVATIONDATE] = iip.[ACTIVATIONDATE]

;

GO

