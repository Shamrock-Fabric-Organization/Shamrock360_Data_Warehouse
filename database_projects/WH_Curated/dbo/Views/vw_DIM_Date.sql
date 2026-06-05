

CREATE   VIEW [dbo].[vw_DIM_Date]
as
SELECT convert(int, convert(char(8),[DATE],112)) DateKey
, *
from tbl_Dim_Date

GO

