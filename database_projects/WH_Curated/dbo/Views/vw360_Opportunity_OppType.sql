-- Auto Generated (Do not modify) 9CBEFCD488AD5EB66FC308442EAB1688C22508BB39F123473F83A3F0FC61C614

CREATE view [dbo].[vw360_Opportunity_OppType] as

select 
LOPID,
FVALUE as OpportunityType
from [tbl_OPMGRFLD]

where 
RECTYPE = 'X'
and FNAME = 'OppType'
--and RecordStatus = '1'
--and RecordStatus = '1'