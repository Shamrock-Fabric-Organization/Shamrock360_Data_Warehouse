-- Auto Generated (Do not modify) D87B912DF17AFB234058BDAA518F9B6CA2204EA13177853F1C272796DDFAAC2B



CREATE   VIEW [dbo].[vwAgingBuckets] as
WITH AgingBucket AS (
    SELECT 
        CAST(AgingBucketKey AS INT) AS AgingBucketKey,
        CAST(FromDays AS INT) AS FromDays,
        CAST(ToDays AS INT) AS ToDays,
        CAST(Description AS VARCHAR(10)) AS Description
    FROM (VALUES 
        (1, -999998, 0, N'Current'),
        (2, 1, 30, N'1 - 30'),
        (3, 31, 60, N'31 - 60'),
        (4, 61, 90, N'61 - 90'),
        (5, 91, 999998, N'91+'),
        (6, 999999, 999999, N'Closed')
    ) AS v(AgingBucketKey, FromDays, ToDays, Description)
)
SELECT * FROM AgingBucket