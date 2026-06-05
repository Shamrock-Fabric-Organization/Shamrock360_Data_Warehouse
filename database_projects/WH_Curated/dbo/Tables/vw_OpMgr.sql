CREATE TABLE [dbo].[vw_OpMgr] (
    [OPID]        VARCHAR (15)   NULL,
    [RECTYPE]     VARCHAR (3)    NULL,
    [ACCOUNTNO]   VARCHAR (20)   NULL,
    [USERID]      VARCHAR (8)    NULL,
    [FLAGS]       VARCHAR (10)   NULL,
    [COMPANY]     VARCHAR (40)   NULL,
    [CONTACT]     VARCHAR (40)   NULL,
    [NAME]        VARCHAR (50)   NULL,
    [STATUS]      VARCHAR (50)   NULL,
    [CYCLE]       VARCHAR (50)   NULL,
    [STAGE]       VARCHAR (30)   NULL,
    [SOURCE]      VARCHAR (30)   NULL,
    [F1]          VARCHAR (20)   NULL,
    [F2]          VARCHAR (20)   NULL,
    [F3]          VARCHAR (20)   NULL,
    [STARTDATE]   DATETIME2 (3)  NULL,
    [CLOSEDDATE]  DATETIME2 (3)  NULL,
    [CLOSEBY]     DATETIME2 (3)  NULL,
    [FORAMT]      FLOAT (53)     NULL,
    [FORPROB]     SMALLINT       NULL,
    [CLOSEAMT]    FLOAT (53)     NULL,
    [NOTES]       VARCHAR (8000) NULL,
    [PRODUCTNAME] VARCHAR (50)   NULL,
    [UDESCHAR]    VARCHAR (80)   NULL,
    [UEAV]        INT            NULL,
    [USPECAPP]    VARCHAR (80)   NULL,
    [UTPRICE]     FLOAT (53)     NULL,
    [UTSPROJID]   VARCHAR (20)   NULL,
    [U_STAGE]     VARCHAR (30)   NULL,
    [recid]       VARCHAR (15)   NULL
);


GO

