-- =====================================================
-- Little Lemon Restaurant Database (PostgreSQL)
-- Part 1: Schema + sample data
-- Run in psql:  \c little_lemon   then   \i 01_schema_and_data.sql
-- =====================================================

-- Create the database first (run this separately, outside the database):
--   CREATE DATABASE little_lemon;

DROP TABLE IF EXISTS order_items, bookings, orders, menu_items, customers CASCADE;

-- ---------- SCHEMA ----------

CREATE TABLE customers (
    customer_id  SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(100) UNIQUE NOT NULL,
    phone        VARCHAR(20),
    joined_date  DATE NOT NULL
);

CREATE TABLE menu_items (
    item_id   SERIAL PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    category  VARCHAR(50)  NOT NULL,   -- Starters, Mains, Desserts, Drinks
    price     NUMERIC(6,2) NOT NULL CHECK (price > 0)
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id),
    order_date    TIMESTAMP NOT NULL,
    total_amount  NUMERIC(8,2)         -- filled in after order_items are loaded
);

CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id),
    item_id        INT NOT NULL REFERENCES menu_items(item_id),
    quantity       INT NOT NULL CHECK (quantity > 0)
);

CREATE TABLE bookings (
    booking_id    SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id),
    booking_date  TIMESTAMP NOT NULL,
    table_number  INT NOT NULL CHECK (table_number BETWEEN 1 AND 12),
    guests        INT NOT NULL CHECK (guests BETWEEN 1 AND 10)
);

-- ---------- SAMPLE DATA ----------

-- Fixed seed so everyone who runs this gets the same data (and the same findings)
SELECT setseed(0.42);

-- 15 menu items. Items listed first are made more popular in the order data below.
INSERT INTO menu_items (name, category, price) VALUES
    ('Greek Salad',          'Starters', 8.50),
    ('Margherita Pizza',     'Mains',   14.00),
    ('Lemonade',             'Drinks',   3.50),
    ('Grilled Chicken',      'Mains',   17.50),
    ('Hummus & Pita',        'Starters', 7.00),
    ('Pasta Alfredo',        'Mains',   15.00),
    ('Iced Tea',             'Drinks',   3.00),
    ('Lemon Tart',           'Desserts', 6.50),
    ('Grilled Fish',         'Mains',   19.00),
    ('Bruschetta',           'Starters', 6.50),
    ('Tiramisu',             'Desserts', 7.00),
    ('Sparkling Water',      'Drinks',   2.50),
    ('Lamb Kebab',           'Mains',   21.00),
    ('Baklava',              'Desserts', 5.50),
    ('House Red Wine',       'Drinks',   9.00);

-- 30 customers with realistic-looking names
INSERT INTO customers (name, email, phone, joined_date)
SELECT
    fn || ' ' || ln,
    lower(fn || '.' || ln || n || '@example.com'),
    '+1-555-' || lpad((1000 + n)::text, 4, '0'),
    CURRENT_DATE - (200 + floor(random() * 300))::int
FROM (
    SELECT n,
           (ARRAY['Maya','Liam','Sofia','Noah','Aria','Ethan','Zara','Lucas','Nina','Omar'])[1 + (n % 10)] AS fn,
           (ARRAY['Patel','Smith','Garcia','Khan','Brown','Lopez','Nguyen','Ali'])[1 + (n % 8)]            AS ln
    FROM generate_series(1, 30) AS n
) names;

-- 150 orders over the last 180 days.
--  * Customers 1-25 can order (low IDs order far more often); customers 26-30 never order
--  * Order times cluster around lunch (12-14) and dinner (18-21)
INSERT INTO orders (customer_id, order_date)
SELECT
    1 + floor(power(random(), 2) * 25)::int,
    (CURRENT_DATE - floor(random() * 180)::int)
      + ((ARRAY[12,12,13,13,13,14,18,19,19,19,20,20,21])[1 + floor(random() * 13)::int] * INTERVAL '1 hour')
      + (floor(random() * 60)::int * INTERVAL '1 minute')
FROM generate_series(1, 150);

-- 1 to 4 line items per order; low item_ids are picked more often
INSERT INTO order_items (order_id, item_id, quantity)
SELECT
    o.order_id,
    1 + floor(power(random(), 1.5) * 15)::int,
    1 + floor(random() * 3)::int
FROM (SELECT order_id, 1 + floor(random() * 4)::int AS n_items FROM orders) o,
     LATERAL generate_series(1, o.n_items) AS g;

-- Fill in each order's total from its line items
UPDATE orders o
SET total_amount = t.total
FROM (
    SELECT oi.order_id, SUM(oi.quantity * m.price) AS total
    FROM order_items oi
    JOIN menu_items m ON m.item_id = oi.item_id
    GROUP BY oi.order_id
) t
WHERE o.order_id = t.order_id;

-- 80 bookings from any of the 30 customers (so some booked but never ordered)
INSERT INTO bookings (customer_id, booking_date, table_number, guests)
SELECT
    1 + floor(random() * 30)::int,
    (CURRENT_DATE - floor(random() * 120)::int)
      + ((ARRAY[12,13,18,19,20,21])[1 + floor(random() * 6)::int] * INTERVAL '1 hour'),
    1 + floor(random() * 12)::int,
    1 + floor(random() * 8)::int
FROM generate_series(1, 80);

-- ---------- QUICK SANITY CHECK ----------
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'menu_items', COUNT(*) FROM menu_items
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL SELECT 'bookings',   COUNT(*) FROM bookings;
