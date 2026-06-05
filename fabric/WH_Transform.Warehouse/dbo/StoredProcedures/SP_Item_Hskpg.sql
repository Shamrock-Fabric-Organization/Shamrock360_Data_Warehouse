CREATE procedure [dbo].[SP_Item_Hskpg]
as

----------				Update [dbo].[tbl_DIM_Item] 
----------				set Start_Date = GetDate()AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time'
----------			    ,End_Date = '2099-12-31 00:00:01.000'
----------				,Record_Status = 1
----------				,Source = 'D365';     
				
----------Truncate table tbl_DIM_Item;