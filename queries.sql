-- USE [Toy_Store_DB]

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
	Concat(Round(100 * SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0  END) / Count(order_id), 2), '%') as [cross_sell_prct] 
FROM orders 
GROUP BY DATENAME(Month, created_at), DATEPART(Month, created_at) 
Order By MIN(DATEPART(Month, created_at)) 



/*
Q9. Calculate the session-to-order conversion rate for each `utm_source`. 
Make sure sessions that never converted are still counted in the denominator.
*/

SELECT * FROM [dbo].[website_sessions]
SELECT * FROM [dbo].[orders]

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

