
CREATE   PROC [dbo].[usp_EndLoadSuccess] @DataSource VARCHAR(8000), @DatabaseName VARCHAR(8000), @SourceTableSchema VARCHAR(8000), @SourceTableName VARCHAR(8000) 
AS
BEGIN
	UPDATE dbo.ingestion_metadata
	SET LastLoadDateTime = GETDATE()
		,FullLoadComplete = 1
		,LoadStatus = 1
	WHERE DataSource = @DataSource
	  AND DatabaseName = @DatabaseName
	  AND SourceTableSchema = @SourceTableSchema
	  AND SourceTableName = @SourceTableName
END
GO
