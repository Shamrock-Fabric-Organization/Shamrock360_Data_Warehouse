CREATE TABLE [dbo].[mtbl_EDW_DIM_TradeAgreement] (

	[TradeAgreementKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[AgreementID] varchar(8000) NULL, 
	[JournalName] varchar(8000) NULL, 
	[AgreementName] varchar(8000) NULL, 
	[PostedDate] datetime2(6) NULL, 
	[Posted] varchar(8000) NULL, 
	[DefaultRelation] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);