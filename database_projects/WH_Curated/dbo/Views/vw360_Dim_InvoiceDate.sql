

CREATE view [dbo].[vw360_Dim_InvoiceDate] AS
select *,


	
	(
		select  
		[Fiscal_Day_#] 
		from tbl_Dim_Date 
		where CONVERT(VARCHAR(10),GETDATE(),101) = CONVERT(VARCHAR(10),DATE,101)
	)
	as [CurrentFiscalDay#],
	
	(
		select  
		[Fiscal_Yr] 
		from tbl_Dim_Date
		where CONVERT(VARCHAR(10),GETDATE(),101) = CONVERT(VARCHAR(10),DATE,101)
	)
	as [Current Fiscal Yr]

	from 

tbl_Dim_Date

GO

