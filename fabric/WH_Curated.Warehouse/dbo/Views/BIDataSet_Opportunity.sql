-- Auto Generated (Do not modify) D6894DF587B0ADE32C38CF78340285D87735A7F994C8700E3C564F70AB03CC9A

CREATE view [dbo].[BIDataSet_Opportunity] as

SELECT h.[OpportunityID]
	, h.[RecordType]
	, h.[GMAccountno]
	, h.[Manager]
	, h.[Company]
	, h.[Contact]
	, h.[Opportunity]
	, h.[OpportunityStatus]
	, h.[OpportunityStage]
	, h.[OpportunityIndustry]
	, h.[StartDate]
	, h.[ClosedDate]
	, h.[CloseByDate]
	, h.[Probability]
	, h.[Notes]
	, h.[ProductName]
	, h.[DesiredCharacteristics]
	, h.[EstimatedAnnualVolume]
	, h.[SpecificApplication]
	, h.[TargetPrice]
	, h.[OpportunityPriority]
	, h.[RecordID]
	, h.[RecordEffectiveStartDate]
	, h.[RecordEffectiveEndDate]
	, h.[RecordStatus]
	, h.[Source]
	, h.[OPP_SID]
	, h.[cloudCRMLink] 
	, t.[LOPID]
	, convert(VARCHAR(200), t.[OpportunityType]) [OpportunityType]

	, CONVERT(decimal(18,6), h.[EstimatedAnnualVolume]) * CONVERT(decimal(18,6), h.[TargetPrice])  EstimatedAnnualrevenue
	, CASE
      WHEN UPPER(h.[Manager]) IN ('WKUIPERS','JSTEMMLE','ECAMGOZ','LGIANZIN','JRODRIGU','MTRAN','JHENSKEN','DDEWULF')
           THEN 'BVBA'
      WHEN UPPER(h.[Manager]) IN ('SLIN','WKANG','AYUAN','VYU','JWANG','LLUO','MCHONG','SKWAN')
           THEN 'TEDA'
      ELSE 'US'
    END  AS Office
	, CONVERT(decimal(18,6), h.[Probability]) * (CONVERT(decimal(18,6), h.[EstimatedAnnualVolume]) * CONVERT(decimal(18,6), h.[TargetPrice])) / 100.0 AS [Probable Value]

FROM vw_Opportunity_Header  h
LEFT OUTER JOIN [vw360_Opportunity_OppType]  t
	ON h.OpportunityID = t.LOPID