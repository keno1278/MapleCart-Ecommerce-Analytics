-- Project: MapleCart E-Commerce SQL Analytics
-- Analysis: Analyzing Traffic Sources 
-- Author: Meshack Oniera | Date: 2025-11-02




-- Query 1: Sessions - Orders Conversion Rate

USE maplecart_ca;

SELECT 
	utm_content,
    count(distinct m_s.website_session_id) as sessions,
    count(distinct m_o.website_session_id) as orders,
    count(distinct m_o.website_session_id)/count(distinct m_s.website_session_id) as sessions_to_orders_conv_rt
FROM maple_sessions as m_s
Left join maple_orders as m_o
on m_o.website_session_id =  m_s.website_session_id
WHERE m_s.website_session_id BETWEEN 1000 AND 2000
Group by 1
Order by 2 Desc;

-- INSIGHT SUMMARY:
-- -----------------------------------------------------------
-- g_ad_1 drove 975 sessions with a 3.6% conversion rate — highest so far.
-- The NULL group likely represents direct visitors or missing UTM tracking.
-- g_ad_2 generated traffic but no orders.
-- b_ad_2 also had minimal performance.
-- Recommendation: Continue investing in sg_ad_1; review campaign tagging 




-- Query 2: Identify Top Traffic Sources Before April 12, 2012
select 
utm_source,
utm_campaign,
http_referer,
count(distinct website_session_id) as no_of_sessions
from maple_sessions 
WHERE created_at < '2012-04-12'
group by utm_source,
utm_campaign,
http_referer
ORDER BY no_of_sessions Desc;




-- Query 3: Evaluate Gsearch (Nonbrand) Conversion Performance
-- -----------------------------------------------------------
-- Goal: Check if gsearch_nonbrand sessions are converting efficiently.
-- Business logic: To be profitable, session-order conversion must reach >= 4%.
-- If below 4% - reduce bids; if above 4% → increase bids to capture more volume.
select 
	count(distinct m_s.website_session_id) as sessions,
	count(distinct m_o.order_id) as orders,
    count(distinct m_o.order_id)/count(distinct m_s.website_session_id) as session_order_conv_rt
    FROM maple_sessions as m_s
    Left join maple_orders as m_o
    on m_o.website_session_id =  m_s.website_session_id
    WHERE  m_s.created_at < '2012-04-14'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand';
        
-- INSIGHT SUMMARY:
-- -----------------------------------------------------------   
-- Reduce gsearch nonbrand bid costs until efficiency improves.





-- ===========================================================
-- Query 4: Bid Optimization & Trend Analysis
-- -----------------------------------------------------------
-- Goal:
-- Evaluate gsearch_nonbrand campaign performance by device type
-- (desktop vs mobile) to inform bid adjustments.

select 
	m_s.device_type,
    count(distinct m_s.website_session_id) as sessions,
    count(distinct m_o.order_id) as orders,
    count(distinct m_o.order_id)/count(distinct m_s.website_session_id)as convr_rt
    from
    maple_sessions as m_s
    left join maple_orders as m_o
    on m_o.website_session_id =  m_s.website_session_id
    where m_s.created_at < '2012-05-11'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
	group by 1;
    
-- INSIGHT SUMMARY
-- -----------------------------------------------------------
-- Desktop: 3.7% conversion rate — close to target efficiency (keep bids steady).
-- Mobile: 1.0% conversion rate — significantly below target (reduce bids).
-- Recommendation:
--  1) Maintain desktop bids for consistent ROI.
--  2) Reduce mobile bids to improve ROAS or review mobile UX/landing page.





-- Query 5 — Weekly Session Trend: gsearch_nonbrand
-- -----------------------------------------------------------
-- Goal:
-- Track weekly session trends for desktop vs mobile to measure
-- the traffic impact of the 2012-05-19 desktop bid-up.
-- Baseline window: 2012-04-15 → 2012-06-09

select 
	-- year(created_at) as Yr,
    -- week(created_at) as Wk,
    min(date(created_at)) as week_start_date,
    count(distinct case when device_type = 'mobile' Then website_session_id ELSE NULL END) as mobile_sessions,
	count(distinct case when device_type = 'desktop' Then website_session_id ELSE NULL END) as desktop_sessions
from   maple_sessions
where created_at < '2012-06-09'
		AND created_at > '2012-04-15'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        Group by year(created_at),
		week(created_at);
	
-- INSIGHT SUMMARY
-- -----------------------------------------------------------
-- • Desktop sessions increased sharply post-2012-05-19 (bid-up period).
-- • Mobile sessions stayed relatively stable - bid impact isolated to desktop.
-- • Suggests that higher bids effectively boosted desktop visibility & volume.
