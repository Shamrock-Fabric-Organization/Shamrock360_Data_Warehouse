CREATE TABLE [dbo].[mtbl_EDW_DIM_Vendor] (
    [VendorKey]                BIGINT         NULL,
    [CMPNY]                    VARCHAR (8000) NULL,
    [Vendor_ID]                VARCHAR (8000) NULL,
    [Vendor_Name]              VARCHAR (8000) NULL,
    [Vendor_Type]              VARCHAR (8000) NULL,
    [Address]                  VARCHAR (8000) NULL,
    [City]                     VARCHAR (8000) NULL,
    [State]                    VARCHAR (8000) NULL,
    [ZIP]                      VARCHAR (8000) NULL,
    [Country]                  VARCHAR (8000) NULL,
    [Currency]                 VARCHAR (8000) NULL,
    [vendgroup]                VARCHAR (8000) NULL,
    [VendGroupName]            VARCHAR (8000) NULL,
    [SegmentID]                VARCHAR (8000) NULL,
    [SubsegmentID]             VARCHAR (8000) NULL,
    [Source]                   VARCHAR (6)    NOT NULL,
    [RecordEffectiveStartDate] DATETIME2 (3)  NULL,
    [RecordEffectiveEndDate]   DATETIME2 (3)  NULL,
    [RecordStatus]             INT            NULL
);


GO

