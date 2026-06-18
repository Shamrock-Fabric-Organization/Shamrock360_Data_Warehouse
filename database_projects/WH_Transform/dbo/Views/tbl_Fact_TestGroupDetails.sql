
CREATE   VIEW tbl_Fact_TestGroupDetails
AS
    SELECT

    -- Test Group header
         tg.[DATAAREAID]                           AS CompanyId
        ,tg.[TESTGROUPID]                          AS TestGroupId

    -- Test Group Member (test line within the group)
        ,tgm.[TESTID]                              AS TestId
        ,tgm.[TESTSEQUENCE]                        AS TestSequence
        ,tt.[DESCRIPTION]                          AS TestDescription
        ,tt.testtype_$label                        AS TestType      -- 0=Fraction, 1=Integer, 2=Variable
        ,tgm.[TESTUNITID]                          AS TestUnitId
        ,tgm.[ACCEPTABLEQUALITYLEVEL]              AS TestMember_AcceptableQualityLevel
        ,tgm.[STANDARDVALUE]                       AS StandardValue
        ,tgm.[LOWERLIMIT]                          AS LowerLimit
        ,tgm.[UPPERLIMIT]                          AS UpperLimit
        ,tgm.[LOWERTOLERANCE]                      AS LowerTolerance
        ,tgm.[UPPERTOLERANCE]                      AS UpperTolerance
        ,tgm.actiononfailure_$label                AS ActionOnFailure
        ,tgm.[VALIDFROMDATETIME]                   AS MemberValidFrom
        ,tgm.[VALIDTODATETIME]                     AS MemberValidTo
        ,tgm.[certificateofanalysis_$label]        AS CertificateOfAnalysis
        ,tgm.testinstrumentid

    -- Variable definition (NULL for quantitative tests)
        ,tv.[DESCRIPTION]                          AS VariableDescription

    -- Possible outcomes (one row per outcome for variable tests;
    --                    NULL for quantitative tests — limits define pass/fail)
        ,tvo.[VARIABLEOUTCOMEID]                   AS PossibleOutcomeId
        ,tvo.[DESCRIPTION]                         AS PossibleOutcomeDescription
        ,tvo.outcomestatus_$label                       AS OutcomeStatus -- Pass/Fail/NA status of this outcome

        , ISNULL(dle.Legal_EntityKey, -1) Legal_EntityKey
	    , ISNULL(dtg.TestGroupKey, -1) TestGroupKey

    FROM [WH_Raw].[dbo].[INVENTTESTGROUP] tg

    -- Test group members — active effectivity only
    JOIN [WH_Raw].[dbo].[INVENTTESTGROUPMEMBER] tgm
        ON  tgm.[DATAAREAID]          = tg.[DATAAREAID]
        AND tgm.[TESTGROUPID]         = tg.[TESTGROUPID]
        AND (tgm.[VALIDFROMDATETIME]  = '1900-01-01' OR tgm.[VALIDFROMDATETIME] <= GETDATE())
        AND (tgm.[VALIDTODATETIME]    = '1900-01-01' OR tgm.[VALIDTODATETIME]   >= GETDATE())

    -- Test definition (describes what is being tested)
    JOIN [WH_Raw].[dbo].[INVENTTESTTABLE] tt
        ON  tt.[DATAAREAID] = tg.[DATAAREAID]
        AND tt.[TESTID]     = tgm.[TESTID]

    -- Variable description (variable-type tests only)
    LEFT JOIN [WH_Raw].[dbo].[INVENTTESTVARIABLE] tv
        ON  tv.[DATAAREAID] = tg.[DATAAREAID]
        AND tv.[VARIABLEID] = tgm.[VARIABLEID]

    -- Possible outcomes — fans out to one row per outcome for variable tests.
    -- Quantitative tests produce no rows here; they use LowerLimit/UpperLimit.
    LEFT JOIN [WH_Raw].[dbo].[INVENTTESTVARIABLEOUTCOME] tvo
        ON  tvo.[DATAAREAID] = tg.[DATAAREAID]
        AND tvo.[VARIABLEID] = tgm.[VARIABLEID]

LEFT JOIN WH_Transform.dbo.tbl_DIM_Legal_Entity dle
	ON tg.dataareaid = dle.CMPNY
		AND dle.RecordStatus=1

LEFT JOIN WH_Transform.dbo.tbl_DIM_TestGroup dtg
	ON tg.testgroupid = dtg.TestGroupId
		AND tg.dataareaid = dtg.CMPNY
		AND dtg.RecordStatus=1
GO

