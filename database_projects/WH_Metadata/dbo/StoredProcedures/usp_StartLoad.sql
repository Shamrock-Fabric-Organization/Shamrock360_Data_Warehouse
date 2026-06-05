CREATE   PROC usp_StartLoad @DataSource VARCHAR(8000), @DatabaseName VARCHAR(8000), @SourceTableSchema VARCHAR(8000), @SourceTableName VARCHAR(8000) 
AS
BEGIN
	UPDATE dbo.ingestion_metadata
	SET LoadStatus = 0
	WHERE DataSource = @DataSource
	  AND DatabaseName = @DatabaseName
	  AND SourceTableSchema = @SourceTableSchema
	  AND SourceTableName = @SourceTableName
END

GO

