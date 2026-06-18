CREATE TABLE [dbo].[tbl_DIM_Batch] (

	[BatchKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[BatchID] varchar(8000) NULL, 
	[ProductID] varchar(8000) NULL, 
	[CountryOfOrigin] varchar(8000) NULL, 
	[DispositionCode] varchar(8000) NULL, 
	[ProductionDate] datetime2(6) NULL, 
	[FGTestedDate] datetime2(6) NULL, 
	[ExpirationDate] datetime2(6) NULL, 
	[BestBeforeDate] datetime2(6) NULL, 
	[ShelfAdviceDate] datetime2(6) NULL, 
	[VendorBatchDate] datetime2(6) NULL, 
	[VendorExpirationDate] datetime2(6) NULL, 
	[VendorBatchID] varchar(8000) NULL, 
	[BatchNoteName] varchar(8000) NULL, 
	[BatchNote] varchar(8000) NULL, 
	[BatchNoteCreatedBy] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);