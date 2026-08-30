-- =====================================================================
-- OLIST E-COMMERCE — DASHBOARD DATA LAYER
-- Purpose: clean, stable views for Looker Studio drag-and-drop.
-- Grain is explicitly defined per view; do NOT join these views together.
-- =====================================================================

USE olist_ecommerce;

-- ---------------------------------------------------------------------
-- 1) EXECUTIVE KPI
-- Grain: 1 row
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_kpi AS
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_items_sold,
    ROUND((SELECT SUM(price) FROM order_items), 2) AS product_revenue,
    ROUND((SELECT SUM(freight_value) FROM order_items), 2) AS freight_revenue,
    ROUND((SELECT SUM(price + freight_value) FROM order_items), 2) AS total_sales_value,
    ROUND(
        (SELECT SUM(price) FROM order_items)
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_order_value,
    SUM(o.order_status = 'delivered') AS delivered_orders,
    SUM(o.order_status = 'canceled') AS canceled_orders,
    ROUND(
        SUM(o.order_status = 'delivered') * 100.0
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS delivery_rate,
    (
        SELECT ROUND(
            AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1
        )
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
    ) AS avg_delivery_days,
    (
        SELECT COUNT(*)
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    (
        SELECT ROUND(
            SUM(order_delivered_customer_date > order_estimated_delivery_date)
            * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
    ) AS late_delivery_rate,
    (SELECT ROUND(AVG(review_score), 2) FROM order_reviews) AS avg_rating,
    (
        SELECT ROUND(
            SUM(review_score = 5) * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM order_reviews
    ) AS rating_5_pct,
    (
        SELECT ROUND(
            SUM(review_score IN (1,2)) * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM order_reviews
    ) AS rating_1_2_pct,
    (
        SELECT COUNT(*)
        FROM (
            SELECT c.customer_unique_id
            FROM orders o2
            JOIN customers c ON o2.customer_id = c.customer_id
            GROUP BY c.customer_unique_id
            HAVING COUNT(DISTINCT o2.order_id) > 1
        ) x
    ) AS repeat_customers,
    (
        SELECT ROUND(
            COUNT(*) * 100.0 /
            NULLIF((SELECT COUNT(DISTINCT customer_unique_id) FROM customers), 0), 2
        )
        FROM (
            SELECT c.customer_unique_id
            FROM orders o2
            JOIN customers c ON o2.customer_id = c.customer_id
            GROUP BY c.customer_unique_id
            HAVING COUNT(DISTINCT o2.order_id) > 1
        ) x
    ) AS repeat_customer_rate
FROM orders o;

-- fix: correct data types, and exclude canceled orders from revenue figures — 
-- but total_orders/delivered_orders/canceled_orders/delivery_rate still count from ALL orders (so the rate is accurate)
CREATE OR REPLACE VIEW vw_dashboard_kpi AS
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    (SELECT COUNT(*)
     FROM order_items oi
     JOIN orders o2 ON oi.order_id = o2.order_id
     WHERE o2.order_status != 'canceled') AS total_items_sold,
    ROUND((SELECT SUM(oi.price)
           FROM order_items oi
           JOIN orders o2 ON oi.order_id = o2.order_id
           WHERE o2.order_status != 'canceled'), 2) AS product_revenue,
    ROUND((SELECT SUM(oi.freight_value)
           FROM order_items oi
           JOIN orders o2 ON oi.order_id = o2.order_id
           WHERE o2.order_status != 'canceled'), 2) AS freight_revenue,
    ROUND((SELECT SUM(oi.price + oi.freight_value)
           FROM order_items oi
           JOIN orders o2 ON oi.order_id = o2.order_id
           WHERE o2.order_status != 'canceled'), 2) AS total_sales_value,
    ROUND(
        (SELECT SUM(oi.price)
         FROM order_items oi
         JOIN orders o2 ON oi.order_id = o2.order_id
         WHERE o2.order_status != 'canceled')
        / NULLIF(SUM(o.order_status != 'canceled'), 0), 2
    ) AS avg_order_value,
    SUM(o.order_status = 'delivered') AS delivered_orders,
    SUM(o.order_status = 'canceled') AS canceled_orders,
    ROUND(
        SUM(o.order_status = 'delivered') * 100.0
        / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS delivery_rate,
    (
        SELECT ROUND(
            AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1
        )
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
    ) AS avg_delivery_days,
    (
        SELECT COUNT(*)
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    (
        SELECT ROUND(
            SUM(order_delivered_customer_date > order_estimated_delivery_date)
            * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
    ) AS late_delivery_rate,
    (SELECT ROUND(AVG(review_score), 2) FROM order_reviews) AS avg_rating,
    (
        SELECT ROUND(
            SUM(review_score = 5) * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM order_reviews
    ) AS rating_5_pct,
    (
        SELECT ROUND(
            SUM(review_score IN (1,2)) * 100.0 / NULLIF(COUNT(*), 0), 2
        )
        FROM order_reviews
    ) AS rating_1_2_pct,
    (
        SELECT COUNT(*)
        FROM (
            SELECT c.customer_unique_id
            FROM orders o2
            JOIN customers c ON o2.customer_id = c.customer_id
            GROUP BY c.customer_unique_id
            HAVING COUNT(DISTINCT o2.order_id) > 1
        ) x
    ) AS repeat_customers,
    (
        SELECT ROUND(
            COUNT(*) * 100.0 /
            NULLIF((SELECT COUNT(DISTINCT customer_unique_id) FROM customers), 0), 2
        )
        FROM (
            SELECT c.customer_unique_id
            FROM orders o2
            JOIN customers c ON o2.customer_id = c.customer_id
            GROUP BY c.customer_unique_id
            HAVING COUNT(DISTINCT o2.order_id) > 1
        ) x
    ) AS repeat_customer_rate
FROM orders o;

-- ---------------------------------------------------------------------
-- 2) MONTHLY SALES PERFORMANCE
-- Grain: 1 row per month
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_id) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01'),
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');

-- fix: correct the data type and wrap with DATE() + exclude canceled orders:
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS month_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_id) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status != 'canceled'
GROUP BY
    DATE(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')),
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');
    
-- ---------------------------------------------------------------------
-- 3) CATEGORY PERFORMANCE
-- Grain: 1 row per product category
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    COALESCE(
        NULLIF(TRIM(t.product_category_name_english), ''),
        NULLIF(TRIM(s.product_category_name), ''),
        'Uncategorized'
    ) AS category,
    s.units_sold,
    s.product_revenue,
    s.avg_item_price,
    s.product_count,
    r.avg_rating,
    r.review_count
-- SALES PERFORMANCE PER CATEGORY
FROM (
    SELECT
        p.product_category_name,
        COUNT(*) AS units_sold,
        ROUND(SUM(oi.price), 2) AS product_revenue,
        ROUND(AVG(oi.price), 2) AS avg_item_price,
        COUNT(DISTINCT p.product_id) AS product_count
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name
) s
-- CUSTOMER RATING PER CATEGORY
LEFT JOIN (
    SELECT
        oc.product_category_name,
        ROUND(AVG(orv.review_score), 2) AS avg_rating,
        COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT
            oi.order_id,
            p.product_category_name
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        WHERE p.product_category_name IS NOT NULL
    ) oc
    JOIN (
        SELECT
            order_id,
            AVG(review_score) AS review_score
        FROM order_reviews
        GROUP BY order_id
    ) orv
        ON oc.order_id = orv.order_id
    GROUP BY
        oc.product_category_name
    HAVING COUNT(*) >= 50
) r
    ON s.product_category_name = r.product_category_name
-- CATEGORY TRANSLATION
LEFT JOIN product_category_name_translation t
    ON s.product_category_name = t.product_category_name;
    
-- ---------------------------------------------------------------------
-- 4) STATE PERFORMANCE
-- Grain: 1 row per customer state
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_state_performance AS
WITH order_value AS (
    SELECT order_id, SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
)
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(ov.order_value), 2) AS payment_value,
    ROUND(
        SUM(ov.order_value) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_order_value,
    ROUND(
        AVG(r.review_score), 2
    ) AS avg_rating
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_value ov ON o.order_id = ov.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
GROUP BY c.customer_state;

-- fix: exclude canceled orders
CREATE OR REPLACE VIEW vw_state_performance AS
WITH order_value AS (
    SELECT order_id, SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
)
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(ov.order_value), 2) AS payment_value,
    ROUND(
        SUM(ov.order_value) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    ) AS avg_order_value,
    ROUND(
        AVG(r.review_score), 2
    ) AS avg_rating
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_value ov ON o.order_id = ov.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status != 'canceled'
GROUP BY c.customer_state;

-- ---------------------------------------------------------------------
-- 5) PAYMENT PERFORMANCE
-- Grain: 1 row per payment type
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_payment_performance AS
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS payment_value,
    ROUND(AVG(payment_installments), 2) AS avg_installments,
    ROUND(
        COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM order_payments), 0), 2
    ) AS payment_share_pct
FROM order_payments
WHERE payment_type IS NOT NULL 
  AND payment_type != 'not_defined'
GROUP BY payment_type;

-- revisi karna ada yg 'not defined'
CREATE OR REPLACE VIEW vw_payment_performance AS
SELECT 
    payment_type,
    COUNT(order_id) AS payment_records,
    SUM(payment_value) AS payment_value,
    AVG(payment_installments) AS avg_installments
FROM order_payments
WHERE payment_type IS NOT NULL 
  AND payment_type != 'not_defined'
GROUP BY payment_type;

-- ---------------------------------------------------------------------
-- 6) DELIVERY PERFORMANCE
-- Grain: 1 row per month
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_delivery_monthly AS
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS month_date,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1
    ) AS avg_delivery_days,
    SUM(
        order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        SUM(order_delivered_customer_date > order_estimated_delivery_date)
        * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_rate
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01'),
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m');

-- fix: correct the data type
CREATE OR REPLACE VIEW vw_delivery_monthly AS
SELECT
    DATE(DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')) AS month_date,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1
    ) AS avg_delivery_days,
    SUM(
        order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        SUM(order_delivered_customer_date > order_estimated_delivery_date)
        * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_rate
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    DATE(DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')),
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m');

-- ---------------------------------------------------------------------
-- 7) DELIVERY BY STATE
-- Grain: 1 row per state
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_delivery_state AS
SELECT
    c.customer_state AS state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(DATEDIFF(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        )), 1
    ) AS avg_delivery_days,
    SUM(
        o.order_delivered_customer_date > o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        SUM(
            o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_rate
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state;

-- ---------------------------------------------------------------------
-- 8) DELIVERY VS CUSTOMER SATISFACTION
-- Grain: 1 row per delivery status
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_delivery_rating AS
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS reviewed_orders
FROM orders o
JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END;
    
-- Revisi --> untuk nyoba buat maps di Looker Studio
CREATE OR REPLACE VIEW vw_delivery_state AS
SELECT 
    c.customer_state,
    CONCAT('BR-', c.customer_state) AS state_code,
    CONCAT(c.customer_state, ', Brazil') AS state_full_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2) AS avg_delivery_days,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        (SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(o.order_id)) * 100, 
        2
    ) AS late_order_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state;

-- ---------------------------------------------------------------------
-- 9) RATING DISTRIBUTION
-- Grain: 1 row per rating score
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_rating_distribution AS
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM order_reviews), 0), 2
    ) AS rating_share_pct
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- ---------------------------------------------------------------------
-- 10) CUSTOMER TYPE
-- Grain: 1 row per customer type
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_type AS
SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2
    ) AS customer_share_pct
FROM (
    SELECT
        c.customer_unique_id,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) x
GROUP BY customer_type;

-- ---------------------------------------------------------------------
-- 11) TOP PRODUCTS
-- Grain: 1 row per product
-- Looker can sort/limit to Top 10.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'Uncategorized') AS category,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'Uncategorized');

-- ---------------------------------------------------------------------
-- 12) SATISFACTION BY CATEGORY
-- Grain: 1 row per category
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_satisfaction_category AS

SELECT
    COALESCE(
        t.product_category_name_english,
        o.product_category_name,
        'Uncategorized'
    ) AS category_name,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM (
    SELECT DISTINCT
        oi.order_id,
        p.product_category_name
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
) o
LEFT JOIN (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r
    ON o.order_id = r.order_id
LEFT JOIN product_category_name_translation t
    ON o.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        o.product_category_name,
        'Uncategorized'
    )
HAVING COUNT(*) >= 50;

-- fix: change LEFT JOIN to JOIN (so review_count is accurate):
CREATE OR REPLACE VIEW vw_satisfaction_category AS
SELECT
    COALESCE(
        t.product_category_name_english,
        o.product_category_name,
        'Uncategorized'
    ) AS category_name,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM (
    SELECT DISTINCT
        oi.order_id,
        p.product_category_name
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
) o
JOIN (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r
    ON o.order_id = r.order_id
LEFT JOIN product_category_name_translation t
    ON o.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        o.product_category_name,
        'Uncategorized'
    )
HAVING COUNT(*) >= 50;

-- Revision -> for customer-type AOV
CREATE OR REPLACE VIEW customer_type_aov AS
SELECT
    customer_type,
    COUNT(*) AS total_orders, -- <--- this line
    ROUND(AVG(order_value), 2) AS average_order_value
FROM (
    SELECT
        o.order_id,
        c.customer_unique_id,
        CASE
            WHEN customer_order_count = 1
                THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type,
        SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_payments p
        ON o.order_id = p.order_id
    JOIN (
        SELECT
            c2.customer_unique_id,
            COUNT(DISTINCT o2.order_id) AS customer_order_count
        FROM orders o2
        JOIN customers c2
            ON o2.customer_id = c2.customer_id
        GROUP BY c2.customer_unique_id
    ) AS customer_orders
        ON c.customer_unique_id = customer_orders.customer_unique_id
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        customer_order_count
) AS order_level
GROUP BY customer_type
ORDER BY customer_type;

-- ---------------------------------------------------------------------
-- 13) SATISFACTION BY STATE
-- Grain: 1 row per state
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_satisfaction_state AS
SELECT
    c.customer_state AS state,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS reviewed_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING COUNT(*) >= 50;

-- ---------------------------------------------------------------------
-- 14) OPTIONAL: EXECUTIVE INSIGHT TABLE
-- Grain: 1 row per insight/KPI. Useful for a small KPI/summary table.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_insights AS
SELECT
    'Revenue' AS metric,
    'Product revenue' AS metric_group,
    ROUND(SUM(price), 2) AS metric_value
FROM order_items

UNION ALL
SELECT
    'Orders',
    'Sales',
    COUNT(DISTINCT order_id)
FROM orders

UNION ALL
SELECT
    'Average Order Value',
    'Sales',
    ROUND(
        SUM(price) / NULLIF(COUNT(DISTINCT order_id), 0), 2
    )
FROM order_items

UNION ALL
SELECT
    'Average Rating',
    'Customer Satisfaction',
    ROUND(AVG(review_score), 2)
FROM order_reviews;

-- ---------------------------------------------------------------------
-- VIEW: MONTHLY RATING TREND
-- Grain: 1 row per bulan
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_rating_trend AS
SELECT
    DATE(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS month_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_rating
FROM orders o
JOIN order_reviews r 
    ON o.order_id = r.order_id
WHERE o.order_status != 'canceled'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY
    DATE(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')),
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');

-- ---------------------------------------------------------------------
-- VIEW: FREIGHT REVENUE
-- Grain: month, total, avg
-- ---------------------------------------------------------------------
CREATE VIEW vw_freight_revenue_analysis AS
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_freight_per_order
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN customers c 
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY 
    order_month, 
    c.customer_state;


-- For the deck & appendix "From Insight to Execution"!
-- ============================================================
--  BENCHMARK OVERALL OLIST'S BUSINESS
-- ============================================================

CREATE OR REPLACE VIEW vw_national_benchmark AS
WITH 
-- 1. Calculate total orders, late rate (%), and average estimation gap (days) nationally
national_delivery AS (
    SELECT
        COUNT(order_id) AS total_national_orders,
        ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 2) AS national_est_gap_days,
        ROUND(
            SUM(CASE WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date) THEN 1 ELSE 0 END) * 100.0 
            / COUNT(order_delivered_customer_date), 
            2
        ) AS national_late_rate_pct
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),
-- 2. Calculate the average rating score nationally
national_rating AS (
    SELECT
        ROUND(AVG(review_score), 2) AS national_avg_rating
    FROM order_reviews
),
-- 3. Calculate the national 90-day repeat purchase rate using a window function
customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS order_seq,
        LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS next_order_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status != 'canceled'
),
national_repeat AS (
    SELECT
        ROUND(
            COUNT(DISTINCT CASE WHEN DATEDIFF(next_order_timestamp, order_purchase_timestamp) <= 90 THEN customer_unique_id END) * 100.0
            / COUNT(DISTINCT customer_unique_id),
            2
        ) AS national_repeat_rate_90d_pct
    FROM customer_orders
    WHERE order_seq = 1
)
-- 4. Combine all three CTEs into a single master benchmark row
SELECT
    'National Benchmark (All 27 States)' AS zone,
    d.total_national_orders,
    d.national_est_gap_days,        -- Output: -11.88 days
    d.national_late_rate_pct,       -- Output: 8.11%
    r.national_avg_rating,          -- Output: 4.10
    rp.national_repeat_rate_90d_pct -- Output: 2.08%
FROM national_delivery d
CROSS JOIN national_rating r
CROSS JOIN national_repeat rp;

SELECT * FROM vw_national_benchmark;

-- ================================================
-- for the full state-by-state breakdown: 
-- ================================================

WITH state_rating AS (
    -- calculate the overall (on-time & late combined) average rating per state
    SELECT 
        state,
        ROUND(SUM(avg_rating * reviewed_orders) / SUM(reviewed_orders), 2) AS overall_avg_rating
    FROM vw_delivery_rating_by_state
    GROUP BY state
),
all_states AS (
    -- combine data across all 27 states
    SELECT 
        e.state AS zone_name,
        e.total_orders,
        e.avg_estimation_gap_days,
        d.late_order_pct AS late_rate_pct,
        sr.overall_avg_rating AS avg_rating,
        rp.repeat_rate_90d_pct
    FROM vw_estimation_gap_state e
    LEFT JOIN vw_delivery_state d ON e.state = d.customer_state
    LEFT JOIN state_rating sr ON e.state = sr.state
    LEFT JOIN vw_repeat_purchase_90d_state rp ON e.state = rp.state
)

-- show all 27 states
SELECT * FROM all_states
UNION ALL

-- add one Total row (National Benchmark) at the bottom
SELECT
    'National Benchmark (All 27 States)',
    (SELECT SUM(total_orders) FROM vw_estimation_gap_state),
    (SELECT ROUND(SUM(avg_estimation_gap_days * total_orders) / SUM(total_orders), 2) FROM vw_estimation_gap_state),
    (SELECT ROUND(SUM(late_orders) * 100.0 / SUM(total_orders), 2) FROM vw_delivery_state),
    (SELECT ROUND(SUM(avg_rating * reviewed_orders) / SUM(reviewed_orders), 2) FROM vw_delivery_rating_by_state),
    (SELECT ROUND(SUM(repeat_within_90d) * 100.0 / SUM(total_first_time_customers), 2) FROM vw_repeat_purchase_90d_state)

-- sort: states by highest order count, with the 'National' row pinned to the bottom
ORDER BY 
    CASE WHEN zone_name LIKE 'National%' THEN 1 ELSE 0 END, 
    total_orders DESC;
    
-- ============================================================
-- KPI 1: ESTIMATION GAP per state (pre-pilot baseline)
-- Average difference between the delivered date and the estimated date
-- NEGATIVE value = delivered earlier than estimated (good)
-- POSITIVE value = delivered later than estimated (late)
-- ============================================================
CREATE OR REPLACE VIEW vw_estimation_gap_state AS
SELECT
    c.customer_state AS state,
    COUNT(*) AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 2) AS avg_estimation_gap_days,
    ROUND(STDDEV(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 2) AS estimation_gap_stddev
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_estimation_gap_days DESC;

-- check specifically the 5 pilot target states (AL, MA, PI, CE, SE)
SELECT * FROM vw_estimation_gap_state
WHERE state IN ('AL', 'MA', 'PI', 'CE', 'SE');

-- ===========================================================
-- KPI 2: uses vw_delivery_state (the late_order_pct column)
-- ===========================================================

-- ============================================================
-- KPI 3: RATING RECOVERY per state (baseline)
-- the earlier vw_delivery_rating was national-level only; this is the per-state version
-- ============================================================
CREATE OR REPLACE VIEW vw_delivery_rating_by_state AS
SELECT
    c.customer_state AS state,
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS reviewed_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    c.customer_state,
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END
ORDER BY state, delivery_status;

-- check the rating gap (On Time - Late) specifically for the 5 target states
SELECT
    state,
    MAX(CASE WHEN delivery_status = 'On Time' THEN avg_rating END) AS rating_ontime,
    MAX(CASE WHEN delivery_status = 'Late' THEN avg_rating END) AS rating_late,
    ROUND(
        MAX(CASE WHEN delivery_status = 'On Time' THEN avg_rating END) -
        MAX(CASE WHEN delivery_status = 'Late' THEN avg_rating END), 2
    ) AS rating_gap
FROM vw_delivery_rating_by_state
WHERE state IN ('AL', 'MA', 'PI', 'CE', 'SE')
GROUP BY state
ORDER BY rating_gap DESC;

SELECT * FROM vw_delivery_rating_by_state;
-- ============================================================
-- KPI 4: REPEAT PURCHASE within 90 days, per state
-- Measures the % of customers who order again within 90 days of their first order
-- ============================================================
CREATE OR REPLACE VIEW vw_repeat_purchase_90d_state AS
WITH first_order AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status != 'canceled'
    GROUP BY c.customer_unique_id, c.customer_state
),
repeat_check AS (
    SELECT
        fo.customer_unique_id,
        fo.customer_state,
        fo.first_order_date,
        EXISTS (
            SELECT 1
            FROM orders o2
            JOIN customers c2 ON o2.customer_id = c2.customer_id
            WHERE c2.customer_unique_id = fo.customer_unique_id
              AND o2.order_purchase_timestamp > fo.first_order_date
              AND o2.order_purchase_timestamp <= DATE_ADD(fo.first_order_date, INTERVAL 90 DAY)
              AND o2.order_status != 'canceled'
        ) AS repeated_within_90d
    FROM first_order fo
)
SELECT
    customer_state AS state,
    COUNT(*) AS total_first_time_customers,
    SUM(repeated_within_90d) AS repeat_within_90d,
    ROUND(SUM(repeated_within_90d) * 100.0 / COUNT(*), 2) AS repeat_rate_90d_pct
FROM repeat_check
GROUP BY customer_state
ORDER BY repeat_rate_90d_pct DESC;

-- Revision = can either recreate directly or drop first
DROP VIEW IF EXISTS vw_repeat_purchase_90d_state;

-- Re-run
CREATE OR REPLACE VIEW vw_repeat_purchase_90d_state AS
WITH ordered_purchases AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        o.order_purchase_timestamp AS first_order_date,
        LEAD(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS next_order_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS order_rank
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status != 'canceled'
)
SELECT
    customer_state AS state,
    COUNT(*) AS total_first_time_customers,
    SUM(CASE 
        WHEN next_order_date IS NOT NULL 
         AND next_order_date <= DATE_ADD(first_order_date, INTERVAL 90 DAY) 
        THEN 1 ELSE 0 
    END) AS repeat_within_90d,
    ROUND(
        SUM(CASE 
            WHEN next_order_date IS NOT NULL 
             AND next_order_date <= DATE_ADD(first_order_date, INTERVAL 90 DAY) 
            THEN 1 ELSE 0 
        END) * 100.0 / COUNT(*), 
        2
    ) AS repeat_rate_90d_pct
FROM ordered_purchases
WHERE order_rank = 1
GROUP BY customer_state
ORDER BY repeat_rate_90d_pct DESC;

-- check specifically the 5 pilot target states
SELECT * FROM vw_repeat_purchase_90d_state
WHERE state IN ('AL', 'MA', 'PI', 'CE', 'SE');

-- ============================================================
-- Pilot Execution Baseline: SLA Leaks & Retention (AL, MA, PI, CE, SE).
-- Buat lebih ringkas dalam satu dataset (CSV) untuk appendix dalam LOOKER & DECK
-- ============================================================

CREATE OR REPLACE VIEW vw_pilot_baseline_state AS
SELECT 
    e.state,
    e.total_orders,
    e.avg_estimation_gap_days,
    d.late_order_pct AS late_rate_pct,
    r_ontime.avg_rating AS ontime_rating,
    r_late.avg_rating AS late_rating,
    ROUND(r_ontime.avg_rating - r_late.avg_rating, 2) AS rating_drop,
    rp.repeat_rate_90d_pct
FROM vw_estimation_gap_state e
JOIN vw_delivery_state d ON e.state = d.customer_state
LEFT JOIN vw_delivery_rating_by_state r_ontime 
    ON e.state = r_ontime.state AND r_ontime.delivery_status = 'On Time'
LEFT JOIN vw_delivery_rating_by_state r_late 
    ON e.state = r_late.state AND r_late.delivery_status = 'Late'
LEFT JOIN vw_repeat_purchase_90d_state rp ON e.state = rp.state
WHERE e.state IN ('AL', 'MA', 'PI', 'CE', 'SE');

SELECT * FROM vw_pilot_baseline_state;

-- ============================================================
-- Pilot Execution Baseline: SLA Leaks & Retention (AL, MA, PI, CE, SE).
-- Untuk Scorecard di Looker
-- ============================================================

CREATE OR REPLACE VIEW vw_pilot_zone_summary AS
SELECT 
    'Pilot Zone (AL, MA, PI, CE, SE)' AS zone_name,
    3204 AS total_orders,
    -10.26 AS avg_estimation_gap_days,
    17.21 AS late_rate_pct,
    3.91 AS avg_rating,
    1.48 AS repeat_rate_90d_pct;

SELECT * FROM vw_pilot_zone_summary;

-- ---------------------------------------------------------------------
-- VALIDATION: run these after creating the views
-- ---------------------------------------------------------------------
SELECT * FROM vw_dashboard_kpi;
SELECT * FROM vw_monthly_sales ORDER BY month_date;
SELECT * FROM vw_category_performance ORDER BY product_revenue DESC;
SELECT * FROM vw_state_performance ORDER BY payment_value DESC;
SELECT * FROM vw_payment_performance ORDER BY payment_value DESC;
SELECT * FROM vw_delivery_monthly ORDER BY month_date;
SELECT * FROM vw_delivery_state ORDER BY late_delivery_rate DESC;
SELECT * FROM vw_delivery_rating;
SELECT * FROM vw_rating_distribution ORDER BY review_score;
SELECT * FROM vw_customer_type;
SELECT * FROM vw_product_performance ORDER BY product_revenue DESC LIMIT 10;
SELECT * FROM vw_satisfaction_category ORDER BY avg_rating DESC;
SELECT * FROM vw_satisfaction_state ORDER BY avg_rating DESC;
SELECT * FROM vw_dashboard_insights;
SELECT * FROM customer_monthly;
SELECT * FROM customer_type_aov;
SELECT * FROM vw_monthly_payment_trend;
SELECT * FROM vw_monthly_rating_trend;
-- ----------------------------------------------------------------------- -- 

-- untuk line chart customer trend by month
CREATE OR REPLACE VIEW customer_monthly AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
ORDER BY month;

-- untuk customers type AOV
CREATE OR REPLACE VIEW customer_type_aov AS
SELECT
    customer_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM (
    SELECT
        o.order_id,
        c.customer_unique_id,
        CASE
            WHEN customer_order_count = 1
                THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type,
        SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_payments p
        ON o.order_id = p.order_id
    JOIN (
        SELECT
            c2.customer_unique_id,
            COUNT(DISTINCT o2.order_id) AS customer_order_count
        FROM orders o2
        JOIN customers c2
            ON o2.customer_id = c2.customer_id
        GROUP BY c2.customer_unique_id
    ) AS customer_orders
        ON c.customer_unique_id = customer_orders.customer_unique_id
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        customer_order_count
) AS order_level
GROUP BY customer_type
ORDER BY customer_type;

-- untuk linechart paymennt by month
CREATE VIEW vw_monthly_payment_trend AS 
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month, 
    SUM(p.payment_value) AS total_payment_value 
FROM order_payments p 
JOIN orders o ON p.order_id = o.order_id 
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');

-- untuk table payment by installment
CREATE OR REPLACE VIEW vw_payment_value_by_installment AS
SELECT 
    payment_installments,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(payment_value) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM order_payments
WHERE payment_type = 'credit_card' -- Cicilan hanya berlaku untuk credit card
  AND payment_installments > 0
GROUP BY payment_installments
ORDER BY payment_installments ASC;

-- untuk avg payment value 
SELECT AVG(payment_value) AS avg_payment_value
FROM order_payments;

-- payment type = credit card
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders
FROM order_payments
GROUP BY payment_type
ORDER BY total_orders DESC
LIMIT 1;


