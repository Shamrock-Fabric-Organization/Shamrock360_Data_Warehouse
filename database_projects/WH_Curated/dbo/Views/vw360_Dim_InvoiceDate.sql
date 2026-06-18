-- Auto Generated (Do not modify) 4ADE1B3BAE47BC4DF01BAD5F940102D71E73EA6B601602F5CB5D48193B3DFFED


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