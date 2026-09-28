# Marketing Attribution & Customer Acquisition Funnel Analysis


> **Status:** In progress. SQL analysis is complete; Power BI dashboard is under development.

## Business Question
Which marketing channels, products, and customer behaviors drive revenue, profitability, and repeat purchases for an online retailer?

## Dataset
- **Source:** Refer [All_Datasets] 
- **Size:** 6 relational tables (1.73 Million rows)
- **Description:** Transactional and web-analytics data for an online store, covering:
  - `orders` — order-level revenue, COGS, and items purchased
  - `order_items` — individual line items per order
  - `order_item_refunds` — refunded line items and amounts
  - `products` — product catalog
  - `website_sessions` — visits with traffic source (`utm_source`) and device type
  - `website_pageviews` — page-level activity within each session

## Tools Used
- SQL (Microsoft SQL Server / T-SQL) — data querying, aggregation, and analysis using joins, CTEs, subqueries, CASE logic, and window functions (`LAG`, `DENSE_RANK`, `ROW_NUMBER`, running totals)
- Power BI — interactive dashboard _(in progress)_

## Key Findings
_Results will be added once the analysis outputs and dashboard are finalized._

Analysis completed so far covers:
1. **Sales performance:** 2014 order volume and revenue, monthly trends, month-over-month growth, and cumulative daily revenue.
2. **Marketing and conversion:** traffic by source and channel group (Paid Search / Social / Direct-Organic), session-to-order conversion rate by source, and top landing pages per source.
3. **Product and customer behavior:** best-selling products, top revenue product by year, refund rates by product, cross-sell rate, gross margin, and repeat-purchase rate by customer cohort.

## Recommendations
_To be added after findings are validated and the dashboard is complete._

## Files
- `queries.sql` — 17 SQL queries covering sales, marketing, product, refund, and customer-cohort analysis
- `Datasets/` — source data files
- Power BI dashboard — _coming soon_

## Methodology
The analysis is written entirely in T-SQL and progresses from foundational aggregations to advanced techniques. Early queries cover revenue, traffic by source, average order value by device, and product demand. Later queries use CTEs, correlated subqueries, and window functions to calculate gross margin, month-over-month growth, cumulative revenue, yearly product rankings, cohort-based repeat purchase rates, and landing-page performance.

Conversion rates are calculated with a `LEFT JOIN` from sessions to orders, so sessions that never converted remain in the denominator. `NULL` traffic sources are grouped as direct/organic so no sessions are dropped from channel analysis.

The SQL results will feed a Power BI dashboard for visualization. Limitations: findings are not yet finalized, and the analysis is limited to the data in the provided tables.
