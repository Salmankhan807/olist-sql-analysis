-- =====================================================================
-- Olist E-commerce Sales Analytics (MySQL 8.0)
-- Dataset: Brazilian E-Commerce Public Dataset by Olist (Kaggle)
-- Sections: 1) Schema  2) Data loading  3) Quality checks and views
--           4) Analysis queries
-- Note: change the file paths in section 2 to match your own folder.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS olist_analytics;
USE olist_analytics;

-- =====================================================================
-- 1) SCHEMA
-- =====================================================================

CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE order_items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- review_id is not unique in the source data, so a surrogate key is used
CREATE TABLE order_reviews (
    review_pk INT AUTO_INCREMENT PRIMARY KEY,
    review_id VARCHAR(32),
    order_id VARCHAR(32) NOT NULL,
    review_score TINYINT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- =====================================================================
-- 2) DATA LOADING
-- Requires: SET GLOBAL local_infile = 1; and OPT_LOCAL_INFILE=1 in the
-- Workbench connection (Advanced tab). The geolocation file is skipped.
-- Run each LOAD once only (order_reviews has no natural key, so a
-- repeated load would duplicate rows).
-- =====================================================================

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;                                   -- expect 99441

-- Blank dates in the CSV are converted to NULL with NULLIF
LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp = NULLIF(@purchase, ''),
    order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');   -- expect 99441

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;                                   -- expect 3095

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @cat, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_category_name = NULLIF(@cat, ''),
    product_name_length = NULLIF(@name_len, ''),
    product_description_length = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@length, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(@width, '');       -- expect 32951

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;                                   -- expect 112650

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;                                   -- expect 103886

LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;                                   -- expect 71

-- Warnings about a trailing '\r' in datetime values are harmless
LOAD DATA LOCAL INFILE 'D:/PROJECTS/Olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, @title, @message, review_creation_date, review_answer_timestamp)
SET review_comment_title = NULLIF(@title, ''),
    review_comment_message = NULLIF(@message, '');   -- expect 99223

-- Row count verification
SELECT 'customers' AS tbl, COUNT(*) AS n FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM product_category_name_translation;

-- =====================================================================
-- 3) DATA QUALITY CHECKS AND CLEAN VIEWS
-- =====================================================================

-- Check 1: order status distribution (only 'delivered' counts as revenue)
SELECT order_status, COUNT(*) AS total
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- Check 2: delivered orders with no delivery date (logically inconsistent)
SELECT COUNT(*) AS bad_rows
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Check 3: products with no category
SELECT COUNT(*) AS no_category
FROM products
WHERE product_category_name IS NULL;

-- Check 4: categories missing an English translation
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;

-- Fix: add the two missing translations
INSERT INTO product_category_name_translation
VALUES ('pc_gamer', 'pc_gamer'),
       ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers');

-- Clean view: products with English category, 'unknown' when missing
CREATE VIEW product_info AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, 'unknown') AS category,
       p.product_weight_g
FROM products p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name;

-- Clean view: delivered orders that have a delivery date
CREATE VIEW delivered_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;   -- expect 96470 rows

-- =====================================================================
-- 4) ANALYSIS
-- All revenue = product price only (excludes freight), delivered orders.
-- =====================================================================

-- Q1: Monthly revenue and orders
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue
FROM delivered_orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Q2: Top 10 categories by revenue
SELECT pi.category,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue
FROM delivered_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN product_info pi ON oi.product_id = pi.product_id
GROUP BY pi.category
ORDER BY revenue DESC
LIMIT 10;

-- Q3: Delivery performance
SELECT COUNT(*) AS delivered_orders,
       ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_days_to_deliver,
       ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)), 1) AS avg_days_early,
       ROUND(100 * SUM(order_delivered_customer_date > order_estimated_delivery_date) / COUNT(*), 1) AS pct_late
FROM delivered_orders;

-- Q4: Effect of late delivery on review score
SELECT CASE
         WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'late'
         ELSE 'on_time'
       END AS delivery_status,
       COUNT(*) AS reviews,
       ROUND(AVG(r.review_score), 2) AS avg_score
FROM delivered_orders o
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY delivery_status;

-- Q5: Repeat customers (CTE). customer_unique_id identifies the real person.
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS order_count
    FROM delivered_orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS total_customers,
       SUM(order_count > 1) AS repeat_customers,
       ROUND(100 * SUM(order_count > 1) / COUNT(*), 1) AS repeat_pct
FROM customer_orders;

-- Q6: Month-over-month revenue growth (window function: LAG)
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
           ROUND(SUM(oi.price), 2) AS revenue
    FROM delivered_orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
WHERE month >= '2017-01'
ORDER BY month;

-- Q7: Top 10 sellers by revenue (window function: RANK)
SELECT RANK() OVER (ORDER BY SUM(oi.price) DESC) AS rnk,
       oi.seller_id,
       COUNT(DISTINCT oi.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue
FROM delivered_orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY oi.seller_id
ORDER BY rnk
LIMIT 10;

-- Q8: Seller revenue concentration by decile (NTILE, chained CTEs)
WITH seller_rev AS (
    SELECT oi.seller_id,
           SUM(oi.price) AS revenue
    FROM delivered_orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY oi.seller_id
),
bucketed AS (
    SELECT revenue,
           NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM seller_rev
)
SELECT decile,
       COUNT(*) AS sellers,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_total
FROM bucketed
GROUP BY decile
ORDER BY decile;

-- Q9: Payment methods (total_paid includes freight)
SELECT p.payment_type,
       COUNT(DISTINCT p.order_id) AS orders,
       ROUND(SUM(p.payment_value), 2) AS total_paid,
       ROUND(100 * SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER (), 1) AS pct_of_total,
       ROUND(AVG(p.payment_installments), 1) AS avg_installments
FROM delivered_orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY total_paid DESC;
