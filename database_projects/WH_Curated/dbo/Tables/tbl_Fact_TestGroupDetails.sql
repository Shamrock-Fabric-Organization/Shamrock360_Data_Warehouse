CREATE TABLE [dbo].[tbl_Fact_TestGroupDetails] (
    [CompanyId]                         VARCHAR (8000)  NULL,
    [TestGroupId]                       VARCHAR (8000)  NULL,
    [TestId]                            VARCHAR (8000)  NULL,
    [TestSequence]                      BIGINT          NULL,
    [TestDescription]                   VARCHAR (8000)  NULL,
    [TestType]                          VARCHAR (8)     NULL,
    [TestUnitId]                        VARCHAR (8000)  NULL,
    [TestMember_AcceptableQualityLevel] DECIMAL (38, 6) NULL,
    [StandardValue]                     DECIMAL (38, 6) NULL,
    [LowerLimit]                        DECIMAL (38, 6) NULL,
    [UpperLimit]                        DECIMAL (38, 6) NULL,
    [LowerTolerance]                    DECIMAL (38, 6) NULL,
    [UpperTolerance]                    DECIMAL (38, 6) NULL,
    [ActionOnFailure]                   VARCHAR (6)     NULL,
    [MemberValidFrom]                   DATETIME2 (6)   NULL,
    [MemberValidTo]                     DATETIME2 (6)   NULL,
    [CertificateOfAnalysis]             VARCHAR (3)     NULL,
    [testinstrumentid]                  VARCHAR (8000)  NULL,
    [VariableDescription]               VARCHAR (8000)  NULL,
    [PossibleOutcomeId]                 VARCHAR (8000)  NULL,
    [PossibleOutcomeDescription]        VARCHAR (8000)  NULL,
    [OutcomeStatus]                     VARCHAR (4)     NULL,
    [Legal_EntityKey]                   BIGINT          NOT NULL,
    [TestGroupKey]                      BIGINT          NOT NULL
);
GO

