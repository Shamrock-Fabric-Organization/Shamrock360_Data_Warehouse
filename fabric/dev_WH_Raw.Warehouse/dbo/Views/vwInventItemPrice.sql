-- Auto Generated (Do not modify) D1EB39788C2A7355C96CE80FBD164C6FDF31E42E989B2B2600C05F9386E3E8DC
/****** Object:  View [dbo].[vwInventItemPrice]    Script Date: 10/30/2025 9:23:55 AM ******/


--InventItemPrice code
CREATE     View [dbo].[vwInventItemPrice]
as
select iip.*
, id.inventsiteid
, t.todate
, CASE WHEN [PRICEUNIT] <> 0 THEN ([PRICE] / [PRICEUNIT]) ELSE NULL END  PricePerUnit
, CASE WHEN GETDATE() BETWEEN IIP.ACTIVATIONDATE AND T.TODATE THEN 1 ELSE 0 END CurrentActiveCost
from 
(inventitemprice iip
join inventdim id
  on iip.inventdimid = id.inventdimid
    and iip.dataareaid = id.dataareaid
)
left join
--logic to get the ToDate 
(select a.dataareaid, a.itemid, a.pricetype, a.inventsiteid, a.activationdate, isnull(dateadd(ms, -2, min(m.activationdate)), '12/31/2154') todate
from 
	(select iip.dataareaid, iip.itemid, iip.pricetype, id.inventsiteid, iip.activationdate
	 from inventitemprice iip
	join inventdim id
	  on iip.inventdimid = id.inventdimid
		and iip.dataareaid = id.dataareaid
	) a
	left join
		(select iip2.dataareaid, iip2.itemid, iip2.pricetype, id2.inventsiteid, iip2.activationdate 
		 from inventitemprice iip2
		 join inventdim id2
		   on iip2.inventdimid = id2.inventdimid
			 and iip2.dataareaid = id2.dataareaid
		) m
	on a.itemid = m.itemid
	  and a.inventsiteid = m.inventsiteid
	  and a.pricetype = m.pricetype
	  and a.dataareaid = m.dataareaid
	  and a.activationdate < m.activationdate
	group by a.dataareaid, a.itemid, a.pricetype, a.inventsiteid, a.activationdate
		) t
on iip.itemid = t.itemid
  and id.inventsiteid = t.inventsiteid
  and iip.pricetype = t.pricetype
  and iip.dataareaid = t.dataareaid
  and iip.activationdate = t.activationdate