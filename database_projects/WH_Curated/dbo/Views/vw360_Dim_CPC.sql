

CREATE view [dbo].[vw360_Dim_CPC] as
select 
	[CPCID],
	[CustomerID],
	'US' as [Office],
	CUSTNO as [Customer No],
	CAST(ShipTo as nvarchar) as [Ship To No],
	PCode as [ProductCode],
	'' as [ProductName],
	'Active' as [CPCStatus],
	'' as [WonReason],
	'' as [LostReason],
	'' as [CPCClassification],
	'' as [OriginalOPID],
	'' as [CPCStage],
	'' as [CPC Descriptive],
	'' as [CPCType],
	'1/1/2000' as [FirstOrderDate],
	'1/1/2000' as [MostRecentOrderDate],
	'0.00' as [MostRecentPrice],
	'' as [Currency],
	'' as [INCOTerms],
	'' as [Application],
	'' as [ApplicationDefinition],
	'' as [ApplicationDescription],
	'' as [DesiredCharacteristics],
	'' as [RegulatoryRequirements],
	'0.00' as [ListPrice],
	'0.00' as [CurrentPrice],
	'n.a.' as [CPCTier],
	'' as [EstimatedAnnualVolume],
	'' as [EAVUnitOfMeasure],
	'' as [EstimatedAnnualRevenue],
	'' as [EARCurrency],
	 [Industry] as [CPCIndustry],
	SubIndustry as [CPCIndustrySubSegment],
	'1/1/2000' as [RecordEffectiveStartDate],
	'12/31/2099' as [RecordEffectiveEndDate],
	'Active' as [RecordStatus],
	'' as [Source],
    'na' as[IsPartOf PLASTICS],
    'na' as [IsPartOf TXTURES],
    'na' as [isPartOf PTFE],
	'na' as [isPartOf_Waxallurgy],
	'na' as [IsPartOf_Emulsions],
    'na' as isPartOf_Lubricants,
    'na' as isPartOf_InksAndCoatings	   
--select *
from tbl_CPCIndustry

GO

