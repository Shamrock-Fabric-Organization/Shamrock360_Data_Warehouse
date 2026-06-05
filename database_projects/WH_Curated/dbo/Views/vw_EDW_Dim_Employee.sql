


CREATE   VIEW [dbo].[vw_EDW_Dim_Employee]
as

select *
from tbl_DIM_Employee

union all

select 
        ABS(CAST(CAST(
        HASHBYTES('SHA2_256', 
            CONCAT(
                CAST(NEWID() AS VARCHAR(36)), '|'
                ,CAST(SYSDATETIME() AS VARCHAR(30)), '|'
                ,CAST(NEWID() AS VARCHAR(36)), '|'
                -- Add row-specific data for extra uniqueness
                ,CAST(Salesman AS VARCHAR(100))
            )
        ) AS BINARY(8)) AS BIGINT)) AS CustomerKey
, 'Legacy-'+RIGHT('00000'+convert(varchar(5),Row_num),5) PersonnelNumber
,Salesman Emplyee_Name
, -1 Employment_Type
, 'Unknown' Employment_Type_Desc
, '' IsPerson
, 'Legacy' Source
, CONVERT(DATETIME2(6), '01/01/1900') RecordEffectiveStartDate
, CONVERT(DATETIME2(6), '12/31/2099') RecordEffectiveEndDate
, 1 RecordStatus

From(
select Salesman, ROW_NUMBER() OVER(Order by Salesman ASC) as Row_num
from
(
select distinct case when [Salesman]='Nathan Turpin' THEN 'Nate Turpin' else [Salesman] end [Salesman]
from [dbo].[tbl_DIM_Accounts]

except 

select Employee_Name
from tbl_DIM_Employee
) s
where not (isnull(Salesman,'') in ('','(X)','DO NOT USE','DO NOT USE (X)') )
) s1

GO

