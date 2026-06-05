-- Auto Generated (Do not modify) B28F5D7CF38D99DFA9CCAEFEF5178D1819E6990B4F6472D66C2CF2DCE16EFD32
/****** Object:  View [dbo].[vw_stage_DIM_Batch_incoming]    Script Date: 4/17/2026 1:45:04 PM ******/
/****** Object:  View [dbo].[vw_stage_DIM_Customer_incoming]    Script Date: 9/2/2025 1:02:23 PM ******/
--drop  VIEW dbo.[vw_stage_DIM_Batch_incoming]	

CREATE       VIEW [dbo].[vw_stage_DIM_Batch_incoming]			
AS			
SELECT 		
    ABS(CAST(CAST(
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(NEWID() AS VARCHAR(36)), '|'
            ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
            ,CAST(NEWID() AS VARCHAR(36)), '|'
            -- Add row-specific data for extra uniqueness
            ,CAST(ib.inventbatchid AS VARCHAR(100))
        )
    ) AS BINARY(8)) AS BIGINT)) AS BatchKey
    , ib.dataareaid CMPNY
    , ib.inventbatchid BatchID
    , ib.itemid  ProductID
    , ib.pdscountryoforigin1 CountryOfOrigin
    , ib.pdsdispositioncode DispositionCode
    , ib.proddate  ProductionDate
    , ib.pdsfinishedgoodsdatetested FGTestedDate
    , ib.expdate  ExpirationDate
    , ib.pdsbestbeforedate BestBeforeDate
    , ib.pdsshelfadvicedate  ShelfAdviceDate
    , ib.pdsvendbatchdate  VendorBatchDate
    , ib.pdsvendexpirydate  VendorExpirationDate
    , ib.pdsvendbatchid VendorBatchID
      ------,manufacturerid
      ------,originmanufacturerid
      ------,qmscertofanalysisqualityorderid
    , dr.name BatchNoteName
    , dr.NOTES BatchNote
    , dr.createdby BatchNoteCreatedBy
	,'D365FO'	 Source
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveStartDate
	,CONVERT(datetime2(3), NULL)	 RecordEffectiveEndDate
	,CONVERT(int, NULL)	 RecordStatus

  FROM WH_Raw.dbo.inventbatch ib
    LEFT JOIN (SELECT REFRECID
                , STRING_AGG(NOTES, ' === ') NOTES
                , STRING_AGG(NAME, ' === ') NAME
                , STRING_AGG(CREATEDBY, ' === ') CREATEDBY 
                FROM WH_Raw.dbo.DOCUREF 
                WHERE REFTABLEID = 26477 --INVENTBATCH    
                  AND TYPEID='Note'
                GROUP BY REFRECID) dr
        ON dr.REFRECID = ib.RECID
 
UNION ALL

SELECT -1 [BatchKey]
, 'Unknown' CMPNY
, 'Unknown' BatchID
, 'Unknown' ProductID
, NULL CountryOfOrigin
, NULL DispositionCode
, NULL  ProductionDate
, NULL FGTestedDate
, NULL  ExpirationDate
, NULL BestBeforeDate
, NULL  ShelfAdviceDate
, NULL  VendorBatchDate
, NULL  VendorExpirationDate
, NULL VendorBatchID

, NULL BatchNoteName
, NULL BatchNote
, NULL BatchNoteCreatedBy

, 'D365FO' [Source]
, NULL [RecordEffectiveStartDate]
, NULL [RecordEffectiveEndDate]
, NULL [RecordStatus]