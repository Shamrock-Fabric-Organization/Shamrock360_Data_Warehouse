-- Auto Generated (Do not modify) 366F13C829EE89F2AC314B574A24DF5F5C583E829DBAECCCC626EC9001B7AFEE


CREATE   VIEW [dbo].[vw_DIM_Date]
as
SELECT convert(int, convert(char(8),[DATE],112)) DateKey
, *
from tbl_Dim_Date