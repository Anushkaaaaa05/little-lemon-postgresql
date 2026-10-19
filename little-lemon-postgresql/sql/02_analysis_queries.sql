-- =====================================================
-- Little Lemon Restaurant Database (PostgreSQL)
-- Part 2: Analytical queries
-- Each query answers one business question.
-- =====================================================


-- Q1. What are the top 5 best-selling menu items by units sold?
-- Concepts: JOIN, GROUP BY, ORDER BY, LIMIT
SELECT m.name, m.category, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN menu_items m ON m.item_id = oi.item_id
GROUP BY m.name, m.category
ORDER BY units_sold DESC
LIMIT 5;


-- Q2. What is total revenue per month?
-- Concepts: DATE_TRUNC, SUM, GROUP BY
SELECT DATE_TRUNC('month', order_date)::date AS month,
       COUNT(*)                              AS orders,
       SUM(total_amount)                     AS revenue
FROM orders
GROUP BY 1
ORDER BY 1;


-- Q3. Which hours of the day are busiest?
-- Concepts: EXTRACT, COUNT
SELECT EXTRACT(HOUR FROM order_date)::int AS order_hour,
       COUNT(*)                           AS total_orders
FROM orders
GROUP BY 1
ORDER BY total_orders DESC;


-- Q4. Which customers have ordered more than once, and how much did they spend?
-- Concepts: HAVING
SELECT c.name,
       COUNT(o.order_id)   AS num_orders,
       SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) > 1
ORDER BY total_spent DESC;


-- Q5. Which menu category earns the most revenue?
-- Concepts: multi-table JOIN, calculated column
SELECT m.category,
       SUM(oi.quantity * m.price) AS revenue,
       ROUND(100.0 * SUM(oi.quantity * m.price)
             / SUM(SUM(oi.quantity * m.price)) OVER (), 1) AS pct_of_total
FROM order_items oi
JOIN menu_items m ON m.item_id = oi.item_id
GROUP BY m.category
ORDER BY revenue DESC;


-- Q6. Rank menu items by revenue within each category.
-- Concepts: CTE, window function RANK() with PARTITION BY
WITH item_revenue AS (
    SELECT m.category, m.name,
           SUM(oi.quantity * m.price) AS revenue
    FROM order_items oi
    JOIN menu_items m ON m.item_id = oi.item_id
    GROUP BY m.category, m.name
)
SELECT category, name, revenue,
       RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
FROM item_revenue
ORDER BY category, rank_in_category;


-- Q7. Month-over-month revenue growth.
-- Concepts: CTE, LAG() window function
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(total_amount) AS revenue
    FROM orders
    GROUP BY 1
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- Q8. Which customers booked a table but never placed an order?
-- Concepts: LEFT JOIN ... IS NULL (anti-join)
SELECT DISTINCT c.customer_id, c.name
FROM customers c
JOIN bookings b      ON b.customer_id = c.customer_id
LEFT JOIN orders o   ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;


-- Q9. What share of ordering customers are repeat customers?
-- Concepts: nested CTEs, conditional aggregation
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS num_orders
    FROM orders
    GROUP BY customer_id
)
SELECT COUNT(*)                                          AS total_customers,
       COUNT(*) FILTER (WHERE num_orders > 1)            AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE num_orders > 1) / COUNT(*), 1) AS repeat_rate_pct
FROM customer_orders;


-- Q10. Do weekends bring more revenue per day than weekdays?
-- Concepts: CASE, EXTRACT(DOW), subquery for daily totals
WITH daily AS (
    SELECT order_date::date AS day,
           EXTRACT(DOW FROM order_date) AS dow,
           SUM(total_amount) AS revenue
    FROM orders
    GROUP BY 1, 2
)
SELECT CASE WHEN dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       ROUND(AVG(revenue), 2) AS avg_daily_revenue
FROM daily
GROUP BY 1;


-- Q11. Top 3 customers by lifetime spend, with their share of total revenue.
-- Concepts: window function over aggregate, DENSE_RANK
WITH spend AS (
    SELECT c.name, SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT name, total_spent,
       ROUND(100.0 * total_spent / SUM(total_spent) OVER (), 1) AS pct_of_revenue,
       DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM spend
ORDER BY spend_rank
LIMIT 3;


-- BONUS: a view for monthly revenue (reusable by dashboards)
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', order_date)::date AS month,
       COUNT(*) AS orders,
       SUM(total_amount) AS revenue
FROM orders
GROUP BY 1;
