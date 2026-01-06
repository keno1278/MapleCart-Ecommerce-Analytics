-- Project: MapleCart E-Commerce SQL Analytics
-- Analysis: Product Performance & Sales Insights
-- Author: Meshack Oniera | Date: 2025-11-10


-- Query1: Product Performance – Monthly Sales, Revenue & Margin Trends
-- Description:
-- Ahead of a new product launch, this query analyzes MapleCart’s current
-- flagship product to evaluate its monthly performance trends to date.
-- It provides visibility into sales volume, total revenue, and profit margin,
-- helping assess the product’s contribution to overall business growth.


select 
	year(created_at) as yr,
    month(created_at) as mo,
    count(distinct order_id) as number_of_sales,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
    
from maple_orders
where created_at < '2013-01-04'
group by 1,2;




-- =============================================================================
-- Analysis: Website Pathing – Comparing User Flows for Key Products


select 
-- website_session_id,
	maple_pageviews.pageview_url,
	count(distinct maple_pageviews.website_session_id) as sessions,
    count(distinct  maple_orders.order_id) as orders,
      count(distinct  maple_orders.order_id)/count(distinct maple_pageviews.website_session_id) as viewed_product_to_order_rate
from maple_pageviews
	left join maple_orders
		on maple_orders.website_session_id = maple_pageviews.website_session_id
where maple_pageviews.created_at between '2013-02-01' AND '2013-03-01'
	AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
group by pageview_url;


-- =============================================================================
-- Analysis: Product Next-Step Clickthrough (Before vs. After Launch)
-- Purpose:
--   This query helps us understand how users behave after viewing a product page.
--   Specifically, it tracks what page they visit next (for example, /cart or /home)
--   and calculates how often users click through to the next step.
--
-- Context:
--   We just launched a new product, and we want to compare user navigation patterns
--   after the launch to the 3 months before it. This helps measure if the new product
--   improved engagement and conversion behavior from product pages.
--
-- Key Insights Expected:
--   • Which product pages drive more clicks to the next step (especially /cart)
--   • How post-launch user behavior differs from pre-launch
--   • Whether the new product launch improved the path-to-purchase flow






-- =============================================================================
-- Analysis: Product Pathing – Where Do Users Go After Viewing a Product?
--
-- Purpose:
--   Understand how users move through the site immediately after viewing a
--   product page, and compare behavior before vs. after the new product launch.
--
-- Approach:
--   1) Find all relevant product pageviews (with website_session_id)
--   2) Identify the next pageview_id that occurs after each product view
--   3) Look up the pageview_url for that “next step” pageview
--   4) Summarize next-step patterns and compare pre-launch vs post-launch periods
--
-- Output:
--   A breakdown of product pageviews and their next-step destinations
--   (e.g., /cart, /home, /search, exit), split into pre-launch and post-launch
--   periods to show how user paths changed after the new product was introduced.

create TEMPORARY TABLE product_Pageviews
select 
	website_session_id,
    website_pageview_id,
    created_at,
    case
		when created_at < '2013-01-06' THEN 'A. Pre_product_2'
        when created_at >= '2013-01-06' THEN 'B. post_product_2'
        ELSE 'check logic'
	END as Time_Period
from maple_pageviews
where created_at < '2013-04-06'
	AND created_at > '2012-10-06'
    AND pageview_url = '/products';
    
select * from product_Pageviews;



create TEMPORARY TABLE session_w_next_pageview_id
select 
	product_Pageviews.Time_period,
    product_Pageviews.website_session_id,
    min(maple_pageviews.website_pageview_id) as min_next_pageview_id
from  product_Pageviews
	left join maple_pageviews
		on maple_pageviews.website_session_id = product_Pageviews.website_session_id
        AND maple_pageviews.website_pageview_id > product_Pageviews.website_pageview_id
GROUP BY 1,2;

select * from session_w_next_pageview_id;



create TEMPORARY TABLE session_w_next_pageview_url
select 
	session_w_next_pageview_id.Time_period,
    session_w_next_pageview_id.website_session_id,
    maple_pageviews.pageview_url as next_pageview_url
from session_w_next_pageview_id
	left join maple_pageviews
		on maple_pageviews.website_session_id = session_w_next_pageview_id.min_next_pageview_id;
        
select * from session_w_next_pageview_url;




SELECT
    time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)
	/COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
    / COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
	/COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM session_w_next_pageview_url
GROUP BY time_period;



-- Assignment_Cross_Sell_Analysis

-- STEP 1: Identify the relevant /cart page views and their sessions
-- STEP 2: See which of those /cart sessions clicked through to the shipping page
-- STEP 3: Find the orders associated with the /cart sessions. Analyze products purchased
-- STEP 4: Aggregate and analyze a summary of our findings


CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
    CASE
        WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-10-06' THEN 'B. Post_Cross_Sell'
        ELSE 'uh oh...check logic'
    END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM maple_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
  AND pageview_url = '/cart';
  
  
  
-- Step 2: Identify the very next pageview after the cart page
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    MIN(maple_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
LEFT JOIN maple_pageviews
    ON maple_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
    AND maple_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id
HAVING
    MIN(maple_pageviews.website_pageview_id) IS NOT NULL;
    
    
    
-- Step 3: Create table of orders coming from these cart sessions
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
    time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
INNER JOIN maple_orders
    ON sessions_seeing_cart.cart_session_id = maple_orders.website_session_id;
    
    
-- Step 4: Combine cart sessions, next-page behavior, and orders
SELECT
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE 
        WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL 
            THEN 0 ELSE 1 
    END AS clicked_to_another_page,
    CASE 
        WHEN pre_post_sessions_orders.order_id IS NULL 
            THEN 0 ELSE 1 
    END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_sessions_seeing_another_page
    ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
LEFT JOIN pre_post_sessions_orders
    ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY 
    cart_session_id;
    
    
    
    
    
    
    
-- Step 5: Final summary metrics (CTR, orders, revenue, AOV, etc.)
SELECT
    time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page) / COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(placed_order) AS orders_placed,
    SUM(items_purchased) AS products_purchased,
    SUM(items_purchased) / SUM(placed_order) AS products_per_order,
    SUM(price_usd) AS revenue,
    SUM(price_usd) / SUM(placed_order) AS aov,   -- average order value
    SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM (
    SELECT
        sessions_seeing_cart.time_period,
        sessions_seeing_cart.cart_session_id,
        CASE 
            WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL 
                THEN 0 ELSE 1 
        END AS clicked_to_another_page,
        CASE 
            WHEN pre_post_sessions_orders.order_id IS NULL 
                THEN 0 ELSE 1 
        END AS placed_order,
        pre_post_sessions_orders.items_purchased,
        pre_post_sessions_orders.price_usd
    FROM sessions_seeing_cart
    LEFT JOIN cart_sessions_seeing_another_page
        ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
    LEFT JOIN pre_post_sessions_orders
        ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
    ORDER BY 
        cart_session_id
) AS full_data
GROUP BY 
    time_period;
    
-- Summary of Cross-Sell Performance (Pre vs Post Launch)
-- • CTR improved slightly (67.2% → 68.2%), showing stronger engagement.
-- • Products per order increased (1.00 → 1.04), indicating better cross-sell impact.
-- • AOV increased (~$51 → ~$54), meaning higher value per completed order.
-- • Revenue per cart session remained strong with only a small decline.
-- • Overall: Post-launch users browse more and buy more per order, 
--   but total order volume dropped and needs further investigation.




-- ============================================================================
-- Analysis: Product-Level Refund Rates (Pre-Launch Baseline)
-- Goal:
--   Evaluate how frequently each product is being refunded before the new
--   product launch. This helps identify quality issues, customer dissatisfaction,
--   or product-specific risks.

SELECT
    YEAR(maple_order_items.created_at) AS yr,
    MONTH(maple_order_items.created_at) AS mo,

    COUNT(DISTINCT CASE WHEN product_id = 1 THEN maple_order_items.order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN maple_order_refunds.order_item_id ELSE NULL END) AS p1_refund_rt,

    COUNT(DISTINCT CASE WHEN product_id = 2 THEN maple_order_items.order_item_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN maple_order_refunds.order_item_id ELSE NULL END) AS p2_refund_rt,

    COUNT(DISTINCT CASE WHEN product_id = 3 THEN maple_order_items.order_item_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN maple_order_refunds.order_item_id ELSE NULL END) AS p3_refund_rt,

    COUNT(DISTINCT CASE WHEN product_id = 4 THEN maple_order_items.order_item_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN maple_order_refunds.order_item_id ELSE NULL END) AS p4_refund_rt

FROM maple_order_items
LEFT JOIN maple_order_refunds
    ON maple_order_items.order_item_id = maple_order_refunds.order_item_id

WHERE maple_order_items.created_at < '2014-10-15'
GROUP BY 1,2;