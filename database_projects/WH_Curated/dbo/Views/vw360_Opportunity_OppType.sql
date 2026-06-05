
CREATE view [dbo].[vw360_Opportunity_OppType] as

select 
LOPID,
FVALUE as OpportunityType
from [tbl_OPMGRFLD]

where 
RECTYPE = 'X'
and FNAME = 'OppType'
--and RecordStatus = '1'

GO

