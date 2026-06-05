
      CREATE   VIEW dbo.hcmtitle AS 
      SELECT [hcmtitle].[Id] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [Id],[hcmtitle].[SinkCreatedOn] AS [SinkCreatedOn],[hcmtitle].[SinkModifiedOn] AS [SinkModifiedOn],[hcmtitle].[sysdatastatecode] AS [sysdatastatecode],[hcmtitle].[titleid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [titleid],[hcmtitle].[modifieddatetime] AS [modifieddatetime],[hcmtitle].[modifiedby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [modifiedby],[hcmtitle].[modifiedtransactionid] AS [modifiedtransactionid],[hcmtitle].[createddatetime] AS [createddatetime],[hcmtitle].[createdby] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [createdby],[hcmtitle].[createdtransactionid] AS [createdtransactionid],[hcmtitle].[dataareaid] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [dataareaid],[hcmtitle].[recversion] AS [recversion],[hcmtitle].[partition] AS [partition],[hcmtitle].[sysrowversion] AS [sysrowversion],[hcmtitle].[recid] AS [recid],[hcmtitle].[tableid] AS [tableid],[hcmtitle].[versionnumber] AS [versionnumber],[hcmtitle].[createdon] AS [createdon],[hcmtitle].[modifiedon] AS [modifiedon],[hcmtitle].[IsDelete] AS [IsDelete],[hcmtitle].[PartitionId] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8 AS [PartitionId]
      FROM dataverse_stiprod_cds2_workspace_unqce8cf9ab47aff01187066045bdff8.dbo.hcmtitle WHERE hcmtitle.IsDelete IS NULL

GO

