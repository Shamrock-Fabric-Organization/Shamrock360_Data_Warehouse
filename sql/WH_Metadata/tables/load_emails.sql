SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[load_emails](
	[DataSource] [varchar](1000) NULL,
	[SuccessEMails] [varchar](1000) NULL,
	[FailureEMails] [varchar](1000) NULL
) ON [PRIMARY]
GO
