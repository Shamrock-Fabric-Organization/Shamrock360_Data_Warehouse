CREATE TABLE [dbo].[tbl_OPMGRFLD] (
    [LOPID]          VARCHAR (15)   NULL,
    [ACCOUNTNO]      VARCHAR (20)   NULL,
    [RECTYPE]        VARCHAR (1)    NULL,
    [FNAME]          VARCHAR (40)   NULL,
    [FVALUE]         CHAR (8000)    NULL,
    [NOTES]          VARCHAR (8000) NULL,
    [LINKEDDOC]      VARCHAR (8000) NULL,
    [U_FNAME]        VARCHAR (40)   NULL,
    [recid]          VARCHAR (15)   NULL,
    [SnapShotDate]   DATETIME2 (6)  NULL,
    [DataUpdateDate] DATETIME2 (6)  NULL,
    [Source]         VARCHAR (10)   NULL,
    [OPF_SID]        INT            NULL
);


GO

