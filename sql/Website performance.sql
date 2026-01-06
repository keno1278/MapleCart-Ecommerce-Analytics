-- =====================================================================
-- Project: MapleCart E-Commerce SQL Analytics
-- Analysis: Website Performance - Top Viewed Pages
-- Author: Meshack Oniera | Date: 2025-11-03
-- =====================================================================

USE maplecart_ca;

CREATE TEMPORARY TABLE first_pageview
select 
	website_session_id,
    min(website_pageview_id) as min_pv_id
from maple_pageviews
group by 1;


select 
    maple_pageviews.pageview_url as landing_page,
    COUNT(distinct first_pageview.website_session_id) AS sessions_hitting_this_lander
from first_pageview
    left join maple_pageviews 
    on first_pageview.min_pv_id = maple_pageviews.website_pageview_id
    group by 1;
 
 
-- Query 2: Most Viewed Pages Ranked by Sessions
-- ---------------------------------------------------------------
-- Purpose: Identify which website pages receive the highest traffic volume.

select * from maple_pageviews;

select pageview_url,
count(distinct website_pageview_id) as pvs
from maple_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc;


-----------------------------------------------------------------------------------------------
-- Query 3: Landing Page Bounce Rate by Session
--  Business Question:
--    • Which landing pages have the highest bounce rates?
--    • Are certain marketing campaigns or entry points less effective?
--
--  Steps:
--    1️ Identify the first pageview per session
--    2️ Tag the corresponding landing page
--    3️ Count total pageviews per session to identify "bounces"
--  ️ 4  Summarize total sessions vs bounced sessions by landing page
--  Purpose:
--    This analysis helps MapleCart understand which entry pages attract users but fail
--    to retain them beyond a single interaction, revealing optimization opportunities.

create TEMPORARY TABLE first_pageviews
select 
	website_session_id,
    min(website_pageview_id) as min_pageview_id
from maple_pageviews
where created_at < '2012-06-14'
group by 1;


select * from first_pageviews;

create TEMPORARY TABLE sessions_home_landing_page
select 
	first_pageviews.website_session_id,
    maple_pageviews.pageview_url as landing_page
from first_pageviews
	left join maple_pageviews
		on maple_pageviews.website_pageview_id = first_pageviews.min_pageview_id
where maple_pageviews.pageview_url = '/home';

select * from sessions_home_landing_page;


Create TEMPORARY TABLE Bounced_sessions
select 
	shlp.website_session_id,
    shlp.landing_page,
    count(distinct maple_pageviews.website_pageview_id) as count_of_pages_viewed
from sessions_home_landing_page as shlp
	left join maple_pageviews
		on shlp.website_session_id = maple_pageviews.website_session_id
group by 
shlp.website_session_id,
shlp.landing_page

Having 
count(distinct maple_pageviews.website_pageview_id) = 1;


select * from Bounced_sessions;

select 
	count(distinct sessions_home_landing_page.website_session_id) as Sessions,
    count(distinct Bounced_sessions.website_session_id) as Bounced_sessions,
    count(distinct Bounced_sessions.website_session_id)/count(distinct sessions_home_landing_page.website_session_id) as Bounced_Rate
from sessions_home_landing_page
	left join Bounced_sessions
		on Bounced_sessions.website_session_id = sessions_home_landing_page.website_session_id;
        
        
        

-- =============================================================================
-- Query 4 Analysis: Conversion Funnel (/lander-2  ➜  /cart) — Mr Fuzzy Only
-- Goal:
--   1) Build a mini funnel from /lander-2 to /cart
--   2) Show reach by step and drop-off rates
--   3) Restrict to /lander-2 traffic only
--   4) Focus on customers interested in "Mr Fuzzy" (mr-fuzzy pages only)
-- Notes:
--   Start by running Section A to see the raw pageviews we care about.
--   Then un-comment the flag columns (Section A) to reveal funnel steps.

select * from maple_pageviews;
select * from maple_sessions;

select maple_sessions.website_session_id,
maple_pageviews.pageview_url,
case when pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
case when pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrFuzzy_page,
case when pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
case when pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
case when pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
case when pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page

from maple_sessions
	left join maple_pageviews
		on maple_sessions.website_session_id = maple_pageviews.website_session_id
Where maple_sessions.utm_source = 'gsearch'
	AND maple_sessions.utm_campaign = 'nonbrand'
    AND maple_sessions.created_at > '2012-08-05'
     AND maple_sessions.created_at < '2012-09-05'
order by  maple_sessions.website_session_id;



Create TEMPORARY TABLE session_level_made_it_flags
select 
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrFuzzy_page) AS mrFuzzy_page_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
    from(
select 
maple_sessions.website_session_id,
maple_pageviews.pageview_url,
case when pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
case when pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrFuzzy_page,
case when pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
case when pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
case when pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
case when pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page

from maple_sessions
	left join maple_pageviews
		on maple_sessions.website_session_id = maple_pageviews.website_session_id
Where maple_sessions.utm_source = 'gsearch'
	AND maple_sessions.utm_campaign = 'nonbrand'
    AND maple_sessions.created_at > '2012-08-05'
     AND maple_sessions.created_at < '2012-09-05'
order by  maple_sessions.website_session_id
) AS pageview_level
Group by 
	website_session_id;
    

select * from session_level_made_it_flags;
    
    

select
Count(distinct website_session_id) as Sessions,
count(distinct case when product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
count(distinct case when mrFuzzy_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrFuzzy,
count(distinct case when cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
count(distinct case when shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
count(distinct case when billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
count(distinct case when thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
from
	session_level_made_it_flags;



