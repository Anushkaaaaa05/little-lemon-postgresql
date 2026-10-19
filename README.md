# Little Lemon Restaurant: PostgreSQL Analysis

A 5-table PostgreSQL database for a restaurant, plus 11 analytical queries that answer
business questions about sales, customers and bookings. Built to practise SQL for
data and product analyst work: joins, CTEs, window functions and views.

> **Note:** all data is synthetic, generated in SQL with `generate_series()` and `random()`
> (fixed seed, so results are reproducible). Findings below describe this sample dataset.

## Database diagram
![ERD](images/erd.png)

| Table | Purpose |
|---|---|
| `customers` | Who the customers are |
| `menu_items` | Menu with category and price |
| `orders` | One row per order (customer, timestamp, total) |
| `order_items` | Line items linking orders to menu items |
| `bookings` | Table reservations |

## Business questions answered
1. Top-selling menu items (units sold)
2. Monthly revenue
3. Busiest hours of the day
4. Customers who ordered more than once, and their spend
5. Revenue share by menu category
6. Item ranking within each category (`RANK`, `PARTITION BY`)
7. Month-over-month revenue growth (`LAG`)
8. Customers who booked but never ordered (`LEFT JOIN ... IS NULL`)
9. Repeat-customer rate (`FILTER`)
10. Weekend vs weekday revenue
11. Top customers and their share of revenue (`DENSE_RANK`, window `SUM`)

## Key findings
- **Mains drive revenue:** Mains bring in 61.5% of revenue, followed by Starters (19.2%), Drinks (11.1%) and Desserts (8.2%).
- **Greek Salad is the best seller** at 110 units, well ahead of Margherita Pizza (74), though Grilled Fish earns the most revenue among Mains.
- **Two demand peaks:** orders cluster at lunch (12-2 PM, 45% of orders, peaking at 1 PM) and dinner (6-9 PM, 55%, peaking at 7 PM).
- **Weekends are stronger:** average daily revenue is about 13% higher on weekends ($79.80 vs $70.79).
- **Revenue is concentrated:** the top customer accounts for 19.1% of revenue and the top 3 for about 35%.
- **Bookings that never convert:** 5 of the 30 customers booked a table but never placed an order, which is a follow-up opportunity.
- **Repeat rate is 96%** (24 of 25 ordering customers). This is high because the data is simulated.
- *Caveat:* April and October are partial months, so their month-over-month growth figures are not meaningful.

## How to run
**pgAdmin:** create a database named `little_lemon`, open the Query Tool on it, load and run
`sql/01_schema_and_data.sql`, then run the queries in `sql/02_analysis_queries.sql` one at a time.

**psql:**
```sql
CREATE DATABASE little_lemon;
\c little_lemon
\i sql/01_schema_and_data.sql
\i sql/02_analysis_queries.sql
```

## Skills demonstrated
PostgreSQL, data modelling, joins, aggregations, CTEs, window functions
(`RANK`, `DENSE_RANK`, `LAG`, `SUM() OVER`), `FILTER`, views, synthetic data generation

## Author
[Anushka Srivastava] | [https://www.linkedin.com/in/anushka-srivastava05]
