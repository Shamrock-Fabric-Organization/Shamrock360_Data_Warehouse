-- Auto Generated (Do not modify) 842422AFDF7E92CCC06B44458067FCEAC3F92AF2960F68C01D5205523055BCA4



CREATE   view [dbo].[vw_Opportunity_Header] as

select
[OpportunityID],
[RecordType],
[GMAccountno],
[Manager],
[Company],
[Contact],
[Opportunity],
[OpportunityStatus],
[OpportunityStage],
[OpportunityIndustry],
[StartDate],
[ClosedDate],
[CloseByDate],
[Probability],
[Notes],
[ProductName],
[DesiredCharacteristics],
[EstimatedAnnualVolume],
[SpecificApplication],
[TargetPrice],
[OpportunityPriority],
[RecordID],
[RecordEffectiveStartDate],
[RecordEffectiveEndDate],
[RecordStatus],
[Source],
[OPP_SID],
[cloudCRMLink]
from [tbl_OpportunityList] 
where 
RecordStatus='1' 
and Manager in ('RLEVITT','JPADDOCK','AHAQQ','JSANKOVI','JOES','NTURPIN','JWITTIG','JWOLFE','MARKV','MVITRONE','CMOSELEY','SKWAN','JVERA','VYU','MCHONG','LLUO','SLIN','AYUAN','WKANG','JWANG')
--and OpportunityStatus = 'Open'

union all

select
[OpportunityID],
[RecordType],
[GMAccountno],
[Manager],
[Company],
[Contact],
[Opportunity],
[OpportunityStatus],
[OpportunityStage],
[OpportunityIndustry],
[StartDate],
[ClosedDate],
[CloseByDate],
[Probability],
[Notes],
[ProductName],
[DesiredCharacteristics],
[EstimatedAnnualVolume]*2.2046 as [EstimatedAnnualVolume],
[SpecificApplication],
[TargetPrice]* 1.078786/2.2046 as [TargetPrice],
[OpportunityPriority],
[RecordID],
[RecordEffectiveStartDate],
[RecordEffectiveEndDate],
[RecordStatus],
[Source],
[OPP_SID],
[cloudCRMLink]
from [tbl_OpportunityList] 
where 
RecordStatus='1' 
and Manager in ('WKUIPERS','ECAMGOZ','JSTEMMLE','LGIANZIN','JRODRIGU','MOLEJNIC')