
-- Q1. Find the total number of orders and total revenue (price_usd) placed in calendar year 2014. 

SELECT 
	COUNT(order_id) as [Total Orders],
	Round(SUM(price_usd), 2) as [Total Revenue]
FROM [dbo].[orders]
Where created_at >= '2014-01-01' AND created_at <= '2015-01-01';


/*
Q2. Count the number of sessions by utm_source, sorted from highest to lowest. 
Make sure NULL sources show up as their own readable category rather than disappearing.
*/

SELECT 
	utm_source,
	COUNT(*) as [session_count]
FROM [dbo].[website_sessions]
GROUP BY utm_source
Order By [session_count] DESC;


--Q3.Find the average order value (`price_usd`) broken out by `device_type`.


SELECT
	ws.device_type,
	Round(AVG(o.price_usd), 2) as [AOV] 
FROM orders o
JOIN [website_sessions] ws
ON o.website_session_id = ws.website_session_id 
Group By ws.device_type


/*
Q4.For each product, count how many times it has appeared as a line item across all orders. 
Only show products ordered more than 1,000 times, sorted descending.
*/

SELECT 
	p.product_id, 
	p.product_name, 
	COUNT(oi.product_id) as [count of product]
FROM products p 
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(oi.product_id) > 1000
ORDER BY [count of product] DESC;


/*
Q5. Using a `CASE` statement, classify every session into `'Paid Search'` (gsearch/bsearch), 
`'Social'` (socialbook), or `'Direct/Organic'` (NULL source). Count sessions per category.
*/

With cte_table as 
(
SELECT

	CASE WHEN utm_source = 'gsearch' or utm_source = 'bsearch' THEN 'Paid Search'
		  WHEN utm_source = 'socialbook' THEN 'Social'
		  WHEN utm_source IS Null THEN 'Direct/Organic'
		  ELSE 'Other'
	END  AS [traffic_type]

FROM [dbo].[website_sessions]
)

SELECT 
	traffic_type,
	Count(*) as [session_count]
FROM cte_table
Group By [traffic_type]
Order By [session_count] DESC;


--Q6. Find the number of refunds and total refund amount, broken out by month, for calendar year 2014.

SELECT
	
	DATENAME(Month, created_at) As [month name],
	COUNT(refund_amount_usd) as [number of refunds],
	ROUND(SUM(refund_amount_usd), 2) as [total amount refunded]

FROM [dbo].[order_item_refunds]
Where YEAR(created_at) = '2014'
GROUP BY DATENAME(Month, created_at), DATEPART(Month, created_at)
Order By MIN(created_at) ASC




--Q7. Build a monthly trend of order volume and revenue across the entire dataset.

SELECT  
	
	DATEPART(Month, created_at) as [month Number],
	DATENAME(Month, created_at) as [Month Name],
	COUNT(items_purchased) as [volume],
	ROUND(SUM(price_usd), 2) as [revenue]
FROM dbo.orders
GROUP BY DATENAME(Month, created_at) , DATEPART(Month, created_at)
Order By MIN(DATEPART(Month, created_at)) 



--Q8.For each month, calculate the percentage of orders that were "cross-sell" orders (i.e. `items_purchased > 1`).

SELECT * FROM orders

SELECT 
	
	DATEPART(Month, created_at) as [month Number],
	DATENAME(Month, created_at) as [Month name],
	Count(order_id) as [count],
    SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0  END) as [real_count],
	Concat(Round(100 * CAST(SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0  END) AS FLOAT) / Count(order_id), 2), '%') as [cross_sell_prct] 
FROM orders 
GROUP BY DATENAME(Month, created_at), DATEPART(Month, created_at) 
Order By MIN(DATEPART(Month, created_at)) 



/*
Q9. Calculate the session-to-order conversion rate for each `utm_source`. 
Make sure sessions that never converted are still counted in the denominator.
*/

SELECT 
	COALESCE(ws.utm_source, '(direct/none)') AS utm_source,
	Count(DISTINCT ws.website_session_id) as sessions, 
	count(DISTINCT os.order_id) as orders,
	CONCAT(ROUND(100 * CAST(count(DISTINCT os.order_id) AS FLOAT) / Count(DISTINCT ws.website_session_id), 2), '%') AS [Conversion_rate]

FROM [website_sessions] ws
LEft Join orders os 
ON ws.website_session_id = os.website_session_id
GROUP BY utm_source
ORDER BY [Conversion_rate] DESC;



-- Q10. Using a subquery, find which products generate more total revenue than the *average* product's total revenue.


SELECT
     p.product_name,
	ROUND(SUM(oi.price_usd),2) As [Revenue]

FROM order_items oi
Join products p
ON p.product_id = oi.product_id
GROUP BY p.product_name
HAVING SUM(oi.price_usd) > 

    (
		SELECT
			AVG(product_revenue)
		FROM
		(
			SELECT
				SUM(price_usd) as [product_revenue]
			FROM order_items
			Group BY product_id
		  ) as product_totals
    );



-- Q11. Using a CTE, calculate monthly revenue, monthly COGS, and the resulting gross margin percentage.


With monthly AS(
	
	SELECT
		FORMAT(created_at, 'yyyy-MM') AS [month_number],
		ROUND(SUM(price_usd), 0) AS [Revenue],
		ROUND(SUM(cogs_usd), 0) AS [Cost]

	FROM [dbo].[orders]
	GROUP BY FORMAT(created_at, 'yyyy-MM')
)

SELECT 
    month_number,
	Revenue, 
	Cost,
	CONCAT(ROUND((Revenue - Cost) * 100 / Nullif(Revenue, 0),2), '%') AS [Margin]

FROM monthly 
ORDER BY month_number;



/* Q12. Using a correlated subquery (e.g. `EXISTS`), flag each order line item as refunded or not, 
	    then calculate the refund rate (% of items refunded) by product. 
  */

SELECT 
	p.product_id			AS [id],
	p.product_name			AS [product_name],
	COUNT(*)				AS [items_sold],
	Count(order_item_refunds.order_item_id)		AS [items_refunded],
	CONCAT(ROUND(100 * COUNT(order_item_refunds.order_item_id) / COUNT(*), 0), '%') AS [return_rate_pct]

FROM order_items 
JOIN products p 
ON order_items.product_id = p.product_id
LEFT JOIN order_item_refunds 
ON order_items.order_item_id = order_item_refunds.order_item_id

GROUP BY p.product_id, p.product_name
ORDER BY p.product_id



-- Q13.Calculate a running (cumulative) total of daily revenue across the full date range using a window function.

WITH DailyRevenue AS (
    SELECT 
        CAST(created_at AS Date) AS SaleDate,
        ROUND(SUM(price_usd), 0) AS [revenue]
    FROM orders
    GROUP BY CAST(created_at AS Date)
)
SELECT 
    FORMAT(SaleDate, 'yyyy.MM.dd') AS [Date],
    SUM(revenue) OVER (ORDER BY SaleDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS [cumulative_revenue]
From DailyRevenue
ORDER BY SaleDate;


-- Q14.For each calendar year, rank products by total revenue and identify the #1 product each year using `RANK()` or `DENSE_RANK()`.

WITH product_year AS(
	SELECT 
       FORMAT(CAST(ord.created_at AS Date), 'yyyy') AS SaleDate,
		prd.product_id AS [product_ID],
		prd.product_name AS [product_name],
		ROUND(SUM(price_usd),0) AS [revenue]
	FROM order_items ord
	JOIN products prd 
		ON ord.product_id = prd.product_id
	GROUP BY FORMAT(CAST(ord.created_at AS Date), 'yyyy'), prd.product_id, prd.product_name
), 

ranked AS(
	SELECT 
		*,
		DENSE_RANK() OVER( PARTITION BY SaleDate  ORDER BY [revenue] DESC) AS [revenue_rank]
	FROM product_year
)

SELECT 
	SaleDate,
	product_id,
	revenue
FROM ranked
WHERE [revenue_rank] = 1
ORDER BY SaleDate, product_id;


-- Q15.Calculate month-over-month revenue growth percentage using LAG().

WITH calcs AS(

	SELECT 
		FORMAT(Cast(created_at AS DATE), 'yyyy-MM') AS SaleDate,
		ROUND(SUM(price_usd), 0) AS [Revenue]
	FROM orders
	GROUP BY FORMAT(Cast(created_at AS DATE), 'yyyy-MM')
),
	Lag_val AS(
		SELECT 
			*,
			LAG([Revenue]) OVER (ORDER BY SaleDate) AS [prev_month]
 		FROM calcs
  ),

	growth AS (
		SELECT 
			*,
			ROUND(100 * (Revenue - [prev_month]) / [prev_month], 2) AS [growth_%]	
		FROM Lag_val
)

SELECT
	*
FROM growth;



/* Q16. For each user, determine their first-ever order month (their "cohort"). 
	Then, for each cohort, calculate what percentage of users in that cohort went on to place more than one order (repeat purchase rate).
*/

WITH user_first_order AS(
	SELECT 
		[user_id], 
		MIN(CAST(created_at AS DATE)) AS first_order_date
    FROM orders
    GROUP BY user_id
),
cohort AS(
	SELECT 
		ufo.user_id AS users,
		FORMAT(ufo.first_order_date, 'yyyy-MM') AS cohort_month,
		COUNT(o.order_id) AS total_orders
	FROM user_first_order ufo
		JOIN orders o ON ufo.user_id = o.user_id
	GROUP BY ufo.user_id, FORMAT(ufo.first_order_date, 'yyyy-MM')
)
SELECT
    cohort_month,
    COUNT(users) AS [users_in_cohort],
	SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS [repeated_purchases],
	ROUND(100 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) / COUNT(users), 2) AS [rept_purc_pct]


FROM cohort
GROUP BY cohort_month
ORDER BY cohort_month;


-- **Q17.For each `utm_source`, find the top 3 landing pages (a session's *first* pageview) by session volume, using `ROW_NUMBER()`.

WITH first_pages  AS(

	SELECT 
		website_session_id,
		MIN(website_pageview_id) AS first_pageview_id
	FROM website_pageviews
	GROUP BY website_session_id
), 
calcs AS(
	
	SELECT
		s.utm_source,
		p.pageview_url,
		COUNT(fp.website_session_id) AS [session_volume]
	FROM first_pages fp
	JOIN website_pageviews p ON fp.website_session_id = p.website_session_id
	JOIN website_sessions s ON s.website_session_id = fp.website_session_id
	GROUP BY s.utm_source, 
			 p.pageview_url
), 
ranking AS(

	SELECT
		*, 
		ROW_NUMBER() OVER (PARTITION BY utm_source ORDER BY [session_volume] DESC) AS [rank]
	FROM calcs
)
SELECT * FROM ranking 
WHERE [rank] <= 3;


/*
	Q18. As a data-quality check, use `ROW_NUMBER()` to identify any duplicate `order_items` rows — 
		   i.e., the same `order_id` + `product_id` + `price_usd` combination appearing more than once.
*/
	
WITH cte AS(
	
		SELECT
			*, 
			ROW_NUMBER() OVER (PARTITiON BY order_id, product_id, price_usd 
								ORDER BY created_at) as [rnk]
		FROM order_items	
	)
SELECT * FROM CTE WHERE rnk > 1;



/*Q19.  
		Build a landing-page conversion funnel. For each distinct landing page (`/lander-1` through `/lander-5`), 
		calculate the percentage of sessions that reached `/cart`, then `/shipping`, then `/billing` (or `/billing-2`), 
		then `/thank-you-for-your-order`. Which landing page converts best, and at which funnel step does the biggest drop-off happen?
*/


WITH cte1 AS (
    SELECT 
        MIN(website_pageview_id) AS first_pageview_id,
        website_session_id
    FROM website_pageviews
    GROUP BY website_session_id
),
first_pv AS (
    SELECT 
        cte1.website_session_id,
        w.pageview_url AS landing_page
    FROM cte1 
    JOIN website_pageviews w 
        ON cte1.first_pageview_id = w.website_pageview_id
    WHERE w.pageview_url LIKE '/lander%'     
),
session_funnel_flags AS (
    SELECT 
        f.website_session_id,
        f.landing_page,                        
        MAX(CASE WHEN w.pageview_url = '/cart' THEN 1 ELSE 0 END) AS to_cart,
        MAX(CASE WHEN w.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS to_shipping,
        MAX(CASE WHEN w.pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS to_billing,
        MAX(CASE WHEN w.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS to_purchased
    FROM first_pv f
	JOIN website_pageviews w 
		ON f.website_session_id = w.website_session_id
    GROUP BY f.website_session_id, f.landing_page   
)
SELECT 
	landing_page,
	ROUND(100 * (CAST(SUM(to_cart) AS FLOAT) - COUNT(landing_page)) / COUNT(landing_page), 2)  AS landing_to_cart_chg_pct,
	ROUND(100 * (CAST(SUM(to_shipping) AS FLOAT) - SUM(to_cart)) / SUM(to_cart), 2)  AS cart_to_shipping_chg_pct,
	ROUND(100 * (CAST(SUM(to_billing) AS FLOAT) - SUM(to_shipping)) / SUM(to_shipping), 2)  AS shipping_to_billing_chg_pct,
	ROUND(100 * (CAST(SUM(to_purchased) AS FLOAT) - SUM(to_billing)) / SUM(to_billing), 2)  AS billing_to_order_chg_pct

FROM session_funnel_flags
GROUP BY landing_page
ORDER BY landing_page;



/*	Q20. Compare acquisition channels on a customer-lifetime basis: for each `utm_source` a user was *first* acquired through, 
		 calculate average revenue per user and repeat purchase rate across that user's entire history (not just their first order).
*/

