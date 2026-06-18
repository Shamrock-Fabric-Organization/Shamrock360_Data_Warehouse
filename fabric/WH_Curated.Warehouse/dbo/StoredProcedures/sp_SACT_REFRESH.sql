Create   procedure [dbo].[sp_SACT_REFRESH]
as

  Update [dbo].tbl_SampleDashboardData
  set SnapShotDate = GetDate()AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time'
      ,DataUpdateDate = GetDate()AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time'
	  ,Source = 'DWApollo'