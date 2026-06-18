CREATE TABLE [dbo].[tbl_OPMGRFLD] (

	[LOPID] varchar(15) NULL, 
	[ACCOUNTNO] varchar(20) NULL, 
	[RECTYPE] varchar(1) NULL, 
	[FNAME] varchar(40) NULL, 
	[FVALUE] char(8000) NULL, 
	[NOTES] varchar(8000) NULL, 
	[LINKEDDOC] varchar(8000) NULL, 
	[U_FNAME] varchar(40) NULL, 
	[recid] varchar(15) NULL, 
	[SnapShotDate] datetime2(6) NULL, 
	[DataUpdateDate] datetime2(6) NULL, 
	[Source] varchar(10) NULL, 
	[OPF_SID] int NULL
);