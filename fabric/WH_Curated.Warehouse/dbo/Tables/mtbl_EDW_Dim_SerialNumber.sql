CREATE TABLE [dbo].[mtbl_EDW_Dim_SerialNumber] (

	[SerialNumberKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[SerialNumber] varchar(8000) NULL, 
	[ProdDate] datetime2(6) NULL, 
	[Description] varchar(8000) NULL, 
	[RFIDTagID] varchar(8000) NULL, 
	[SerialNumberNoteName] varchar(8000) NULL, 
	[SerialNumberNote] varchar(8000) NULL, 
	[SeralNumberNoteCreatedBy] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);