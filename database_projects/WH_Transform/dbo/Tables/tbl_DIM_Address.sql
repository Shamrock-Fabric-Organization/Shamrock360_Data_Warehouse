CREATE TABLE [dbo].[tbl_DIM_Address] (

	[AddressKey] bigint NULL, 
	[AddressRecId] bigint NULL, 
	[Location] bigint NULL, 
	[Street] varchar(8000) NULL, 
	[City] varchar(8000) NULL, 
	[State] varchar(max) NULL, 
	[ZipCode] varchar(8000) NULL, 
	[Country] varchar(max) NULL, 
	[ValidFrom] datetime2(6) NULL, 
	[ValidTo] datetime2(6) NULL, 
	[LocationName] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);