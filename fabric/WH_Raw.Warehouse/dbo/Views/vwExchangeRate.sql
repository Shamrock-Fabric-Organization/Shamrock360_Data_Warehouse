-- Auto Generated (Do not modify) 8EF74670B29E9571A8CEC39922198C0FF52CDC136B7820F03C39F9908631CB4B


CREATE   VIEW vwExchangeRate
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