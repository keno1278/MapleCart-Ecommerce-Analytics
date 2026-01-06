
-- Project: MapleCart E-Commerce SQL Analytics
-- Analysis: Channel Portfolio Management & Cross-Channel Optimization
-- Author: Meshack Oniera | Date: 2025-11-10
--
-- Description:
-- This analysis evaluates MapleCart’s marketing channel mix performance.
-- It compares sessions, orders, and conversion efficiency across ad content,
-- campaigns, and traffic sources — helping identify which channels drive
-- the best volume and ROI, and where cross-channel bid optimization can improve.

-- =============================================================================

-- 	Query1
-- Analyzing Channel Portfolios
select 
	utm_content,
    count(distinct maple_sessions.website_session_id) as Sessions,
    count(distinct maple_orders.order_id) as Orders,
    count(distinct maple_orders.order_id)/ count(distinct maple_sessions.website_session_id) as Conversion_Rate
from maple_sessions
	left join maple_orders
		on maple_orders.website_session_id = maple_sessions.website_session_id
where maple_sessions.created_at between '2014-01-01' AND '2014-02-01'
group by 1
order by Sessions desc;
-----------------------------------------------------------------------------------------------
--  Insight Summary (January 2014)
--  • Google Ads: High volume, consistent performance (6–8% CVR)
--  • Bing Ads: Lower volume but best conversion efficiency (up to 11%)
--  • Social Ads: High impressions, poor conversions (1%)
--  • Recommendation: Reallocate 10–15% of low-performing social spend toward Bing/Google campaigns with >8% CVR for optimal ROI.




-- 	Query2
-- Analysis: Channel Characteristics – Comparing Gsearch vs Bsearch (Nonbrand)

-- Description:
-- This analysis compares key channel characteristics between the newly launched
-- Bing Search (bsearch) and the established Google Search (gsearch) nonbrand campaigns.
-- Focus is on mobile traffic volume to determine which channel drives higher
-- engagement from mobile users.

select 
	utm_content,
	count(distinct maple_sessions.website_session_id) as Sessions,
    count(distinct case when device_type = 'mobile' Then maple_sessions.website_session_id ELSE NULL END) AS mobile_session,
     count(distinct case when device_type = 'mobile' Then maple_sessions.website_session_id ELSE NULL END)/
     count(distinct maple_sessions.website_session_id) as PCT_Mobile
from maple_sessions
where created_at > '2012-08-22'
AND created_at < '2012-11-30'
AND utm_campaign = 'nonbrand'
group by 1;




-- Analysis: Direct & Organic Traffic Segmentation

select * from maple_sessions;


select 
	case
		When http_referer IS NULL Then 'Direct_type_in'
        when http_referer = 'https://www.gsearch.com' Then 'gsearch_organic'
         when http_referer = 'https://www.bsearch.com' Then  'bsearch_organic'
         Else 'Other'
	End,
    count(distinct website_session_id) as sessions 
    
from maple_sessions

where website_session_id Between 100000 AND 115000
AND utm_source IS NULL

group by 1
order by 2 desc;



-- Analyzing seasonality & business patterns
-- Here we want to see what happened in the year '2012', so we can better prepare for the year '2013'

select 
	year(maple_sessions.created_at) as yr,
    week(maple_sessions.created_at) as wk,
    min(date(maple_sessions.created_at)) as weekstart,
    count(distinct maple_sessions.website_session_id) as sessions,
    count(distinct maple_orders.order_id) as orders
from maple_sessions
	left join maple_orders
		on maple_orders.website_session_id = maple_sessions.website_session_id
where maple_sessions.created_at < '2013-01-01'
group by 1,2;

-- Insight Summary 
-- we found something interesting in this query, our most traffic occur during the end of the year from the '2012-11-18' - '2012-11-25'
-- That's Black friday drove those traffic




-- We want to analyze website session volume by hour of the day and week, so we can staff appropriately. 
-- Considering the fact that we want to add a live chat session.

select 
	hr,
    -- round(avg(website_sessions),1) as avg_sessions,
    round(avg(case when wkday = 0 then website_sessions else null end),1) as mon,
	round(avg(case when wkday = 1 then website_sessions else null end),1) as Tue,
    round(avg(case when wkday = 2 then website_sessions else null end),1) as Wed,
    round(avg(case when wkday = 3 then website_sessions else null end),1) as Thur,
    round(avg(case when wkday = 4 then website_sessions else null end),1) as Fri,
    round(avg(case when wkday = 5 then website_sessions else null end),1) as Sat,
    round(avg(case when wkday = 6 then website_sessions else null end),1) as Sun
from (
select 
	date(created_at) as Created_date,
    weekday(created_at) as wkday,
    hour(created_at) as hr,
    count(distinct website_session_id) as website_sessions
from maple_sessions
where created_at between '2012-09-15' AND '2012-11-15'
group by 1,2,3
) AS daily_hourly_sessions
group by 1;
