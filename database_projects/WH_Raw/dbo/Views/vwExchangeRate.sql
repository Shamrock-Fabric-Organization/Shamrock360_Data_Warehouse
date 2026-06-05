
create   view vwExchangeRate
as
select ert.description exchangeratetype
, ercp.fromcurrencycode 
, ercp.tocurrencycode
, er.validfrom 
, er.validto
, exchangerate OrigExchangeRate
, ( 1 / (exchangerate / 100.0)) ExchangeRate
, er.exchangeratecurrencypair
from exchangerate er
join exchangeratecurrencypair ercp
  on ercp.recid = er.exchangeratecurrencypair
join exchangeratetype ert
  on ert.recid = ercp.exchangeratetype

union 

select ert.description exchangeratetype
, ercp.tocurrencycode fromcurrencycode 
, ercp.fromcurrencycode tocurrencycode
, er.validfrom 
, er.validto
, exchangerate OrigExchangeRate
, (exchangerate / 100.0) ExchangeRate
, er.exchangeratecurrencypair
from exchangerate er
join exchangeratecurrencypair ercp
  on ercp.recid = er.exchangeratecurrencypair
join exchangeratetype ert
  on ert.recid = ercp.exchangeratetype

GO

