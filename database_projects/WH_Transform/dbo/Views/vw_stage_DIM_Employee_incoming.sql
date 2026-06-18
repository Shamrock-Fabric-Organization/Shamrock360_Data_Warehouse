-- Auto Generated (Do not modify) FBC5124D6DAC728C808DF478A4CFA04982014F0431B56FA16F18A5BC345BE456
/****** Object:  View [dbo].[vw_stage_DIM_Employee_incoming]    Script Date: 5/21/2026 12:47:30 PM ******/


--select * from [vw_stage_DIM_Employee_incoming]
--order by 2


--drop  VIEW dbo.[vw_stage_DIM_Employee_incoming]	

CREATE         VIEW [dbo].[vw_stage_DIM_Employee_incoming]			
AS			
WITH Numbers AS (
    SELECT n FROM (VALUES
        (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
        (21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
        (41),(42),(43),(44),(45),(46),(47),(48),(49),(50),(51),(52),(53),(54),(55),(56),(57),(58),(59),(60),
        (61),(62),(63),(64),(65),(66),(67),(68),(69),(70),(71),(72),(73),(74),(75),(76),(77),(78),(79),(80),
        (81),(82),(83),(84),(85),(86),(87),(88),(89),(90),(91),(92),(93),(94),(95),(96),(97),(98),(99),(100),
        (101),(102),(103),(104),(105),(106),(107),(108),(109),(110),(111),(112),(113),(114),(115),(116),(117),(118),(119),(120),
        (121),(122),(123),(124),(125),(126),(127),(128),(129),(130),(131),(132),(133),(134),(135),(136),(137),(138),(139),(140),
        (141),(142),(143),(144),(145),(146),(147),(148),(149),(150),(151),(152),(153),(154),(155),(156),(157),(158),(159),(160),
        (161),(162),(163),(164),(165),(166),(167),(168),(169),(170),(171),(172),(173),(174),(175),(176),(177),(178),(179),(180),
        (181),(182),(183),(184),(185),(186),(187),(188),(189),(190),(191),(192),(193),(194),(195),(196),(197),(198),(199),(200)
    ) AS Numbers(n)
),
CharacterProcessing AS (
    SELECT
        dpt.RECID
        , dpt.NAME                                  AS OriginalName
        , n                                         AS Position
        , SUBSTRING(dpt.NAME, n, 1)                 AS CurrentChar
        , CASE
            WHEN n = 1 THEN ' '
            ELSE SUBSTRING(dpt.NAME, n - 1, 1)
          END                                       AS PrevChar
    FROM WH_Raw.dbo.DirPartyTable dpt
    CROSS JOIN Numbers
    WHERE n <= LEN(dpt.NAME)
        AND dpt.NAME IS NOT NULL
),
FormattedNames AS (
    SELECT
        RECID
        , OriginalName
        , STRING_AGG(
            CASE
                WHEN PrevChar IN (' ', '-', '''', '.', '/', '&') THEN UPPER(CurrentChar)
                ELSE LOWER(CurrentChar)
            END,
            ''
          ) WITHIN GROUP (ORDER BY Position)        AS Formatted_Name
    FROM CharacterProcessing
    GROUP BY RECID, OriginalName
)
SELECT
    ABS(CAST(CAST(
        HASHBYTES('SHA2_256',
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                , CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                , CAST(NEWID() AS VARCHAR(36)), '|'
                , CAST(w.personnelnumber AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT))                                     AS EmployeeKey
    , w.personnelnumber                                                 AS Personnel_Number
    , COALESCE(fn.Formatted_Name, dpt.name)                            AS Employee_Name
    , e.employmenttype                                                  AS Employment_Type
    , e.employmenttype_$label                                           AS Employment_Type_Desc
    , CASE WHEN LEN(w.personnelnumber) < 4 THEN 'No' ELSE 'Yes' END    AS IsPerson
    , e.validfrom
    , e.validto
    , 'D365FO'                                                          AS [Source]
    , CAST(e.validfrom AS DATETIME2(3))                                 AS [RecordEffectiveStartDate]
    , CAST(e.validto AS DATETIME2(3))                                   AS [RecordEffectiveEndDate]
    , CASE WHEN GETDATE() >= e.validfrom AND GETDATE() <= e.validto
           THEN 1
           ELSE 0
      END                                                               AS [RecordStatus]
FROM WH_Raw.dbo.dirpartytable dpt
LEFT JOIN FormattedNames fn
    ON dpt.recid = fn.recid
JOIN WH_Raw.dbo.hcmworker w
    ON dpt.recid = w.person
JOIN WH_Raw.dbo.HCMEMPLOYMENT e
    ON w.RECID = e.WORKER

UNION ALL

SELECT
    -1                                          AS [EmployeeKey]
    , 'Unknown'                                 AS Personnel_Number
    , 'Unknown'                                 AS Employee_Name
    , NULL                                      AS Employment_Type
    , NULL                                      AS Employment_Type_Desc
    , NULL                                      AS IsPerson
    , '1900-01-01'                              AS validfrom
    , '2154-12-31'                              AS validto
    , 'D365FO'                                  AS [Source]
    , CAST('1900-01-01' AS DATETIME2(3))        AS [RecordEffectiveStartDate]
    , CAST('2154-12-31' AS DATETIME2(3))        AS [RecordEffectiveEndDate]
    , 1                                         AS [RecordStatus];