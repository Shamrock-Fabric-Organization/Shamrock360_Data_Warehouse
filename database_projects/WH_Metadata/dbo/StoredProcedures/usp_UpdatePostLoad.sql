CREATE   PROC usp_UpdatePostLoad @DataSource VARCHAR(8000), @DatabaseName VARCHAR(8000), @SourceTableSchema VARCHAR(8000), @SourceTableName VARCHAR(8000) 
AS
BEGIN
	UPDATE dbo.ingestion_metadata
	SET LastLoadDateTime = GETDATE()
		,FullLoadComplete = 1
END

GO

