CREATE TABLE [dbo].[tbl_DIM_Vendor] (

	[VendorKey] bigint NULL, 
	[CMPNY] varchar(8000) NULL, 
	[Vendor_ID] varchar(8000) NULL, 
	[Vendor_Name] varchar(8000) NULL, 
	[Vendor_Type] varchar(8000) NULL, 
	[Address] varchar(8000) NULL, 
	[City] varchar(8000) NULL, 
	[State] varchar(8000) NULL, 
	[ZIP] varchar(8000) NULL, 
	[Country] varchar(8000) NULL, 
	[Currency] varchar(8000) NULL, 
	[vendgroup] varchar(8000) NULL, 
	[VendGroupName] varchar(8000) NULL, 
	[SegmentID] varchar(8000) NULL, 
	[SubsegmentID] varchar(8000) NULL, 
	[Source] varchar(6) NOT NULL, 
	[RecordEffectiveStartDate] datetime2(3) NULL, 
	[RecordEffectiveEndDate] datetime2(3) NULL, 
	[RecordStatus] int NULL
);