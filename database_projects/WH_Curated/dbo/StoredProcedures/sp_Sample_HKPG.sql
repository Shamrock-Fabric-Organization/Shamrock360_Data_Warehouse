create   procedure [dbo].[sp_Sample_HKPG]
as
Update [dbo].tbl_crm_Sample
set	SNAPSHOTDATE = GetDate()AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time'
	,DataUpdateDate = GetDate()AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time'		
	,Source = 'SAMP';