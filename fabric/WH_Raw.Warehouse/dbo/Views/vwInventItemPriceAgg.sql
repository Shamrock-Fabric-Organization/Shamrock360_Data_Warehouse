-- Auto Generated (Do not modify) A673B938623B6BCEBDFFB4F7084ABF11353549E6012EEE5749980AEB865BAA29



CREATE   VIEW vwInventItemPriceAgg
as
select a.*
, l.price
, l.priceunit
, l.PricePerUnit
, l.unitid
, l.pricetype_$label pricetypedesc
, l.pricecalcid
from
(
select dataareaid, itemid, inventsiteid, activationdate, todate, pricetype, max(createddatetime) createddatetime
from vwInventItemPrice
group by dataareaid, itemid, inventsiteid, activationdate, todate, pricetype
) a
join vwInventItemPrice l
  on a.dataareaid = l.dataareaid
    and a.itemid = l.itemid
	and a.inventsiteid = l.inventsiteid
	and a.activationdate = l.activationdate
	and a.todate = l.todate
	and a.pricetype = l.pricetype
	and a.createddatetime = l.createddatetime