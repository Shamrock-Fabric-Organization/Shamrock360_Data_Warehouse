CREATE TABLE [dbo].[tbl_Fact_Call_Reports] (
    [USERID]         VARCHAR (8)   NULL,
    [ACCOUNTNO]      VARCHAR (255) NULL,
    [SRECTYPE]       VARCHAR (1)   NULL,
    [RECTYPE]        VARCHAR (10)  NULL,
    [ONDATE]         DATETIME2 (6) NULL,
    [ONTIME]         VARCHAR (5)   NULL,
    [ACTVCODE]       VARCHAR (3)   NULL,
    [RESULTCODE]     VARCHAR (3)   NULL,
    [STATUS]         VARCHAR (2)   NULL,
    [DURATION]       VARCHAR (14)  NULL,
    [UNITS]          VARCHAR (255) NULL,
    [REF]            VARCHAR (80)  NULL,
    [LINKRECID]      VARCHAR (15)  NULL,
    [LOPRECID]       VARCHAR (255) NULL,
    [CREATEBY]       VARCHAR (8)   NULL,
    [CREATEON]       DATETIME2 (6) NULL,
    [CREATEAT]       VARCHAR (5)   NULL,
    [LASTUSER]       VARCHAR (8)   NULL,
    [LASTDATE]       DATETIME2 (6) NULL,
    [LASTTIME]       VARCHAR (5)   NULL,
    [recid]          VARCHAR (15)  NULL,
    [EXT]            VARCHAR (5)   NULL,
    [COMPLETEDID]    VARCHAR (15)  NULL,
    [NUMBER1]        VARCHAR (255) NULL,
    [NUMBER2]        VARCHAR (255) NULL,
    [SnapShotDate]   DATETIME2 (6) NULL,
    [DataUpdateDate] DATETIME2 (6) NULL,
    [Source]         VARCHAR (10)  NULL,
    [ACT_SID]        INT           NULL
);


GO

