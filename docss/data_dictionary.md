# Data Dictionary

## 1. Raw Olist Datasets

The project starts from 8 raw CSV tables from the [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), imported into MySQL as-is before any cleaning.

### customers

| Field | Description |
|---|---|
| customer_id | Technical ID linking a customer to a specific order |
| customer_unique_id | Permanent ID representing the same real person across multiple orders |
| customer_zip_code_prefix | First digits of the customer's zip code |
| customer_city | Customer's city |
| customer_state | Customer's state (2-letter Brazilian state code) |

### orders

| Field | Description |
|---|---|
| order_id | Unique order identifier |
| customer_id | Links to customers |
| order_status | delivered, shipped, processing, canceled, etc. |
| order_purchase_timestamp | When the order was placed |
| order_approved_at | When payment was approved |
| order_delivered_carrier_date | When the order was handed to the carrier |
| order_delivered_customer_date | When the order reached the customer |
| order_estimated_delivery_date | Delivery date promised to the customer at purchase |

### order_items

| Field | Description |
|---|---|
| order_id | Links to orders |
| order_item_id | Line-item number within an order |
| product_id | Links to products |
| seller_id | Links to sellers |
| shipping_limit_date | Seller's shipping deadline |
| price | Item price |
| freight_value | Shipping cost for that item |

### order_payments

| Field | Description |
|---|---|
| order_id | Links to orders |
| payment_sequential | Sequence number when an order has multiple payments |
| payment_type | credit_card, boleto, voucher, debit_card |
| payment_installments | Number of installments |
| payment_value | Amount paid |

### products

| Field | Description |
|---|---|
| product_id | Unique product identifier |
| product_category_name | Category name (Portuguese) |
| product_name_lenght | Character length of the product name |
| product_description_lenght | Character length of the product description |
| product_photos_qty | Number of product photos |
| product_weight_g | Product weight in grams |
| product_length_cm / height_cm / width_cm | Product dimensions |

### sellers

| Field | Description |
|---|---|
| seller_id | Unique seller identifier |
| seller_zip_code_prefix | First digits of the seller's zip code |
| seller_city | Seller's city |
| seller_state | Seller's state |

### product_category_name_translation

| Field | Description |
|---|---|
| product_category_name | Category name in Portuguese |
| product_category_name_english | Category name translated to English |

### order_reviews

| Field | Description |
|---|---|
| review_id | Unique review identifier |
| order_id | Links to orders |
| review_score | Rating from 1–5 |
| review_comment_title / review_comment_message | Free-text review content |
| review_creation_date | When the review was submitted |
| review_answer_timestamp | When Olist responded to the review |

## 2. Rebuilt Table

### orders (final, cleaned)

The original `orders` import silently dropped rows when date columns were parsed directly as `DATETIME` from the raw CSV. It was rebuilt via an intermediate `orders_raw` (all-text columns) and converted with `STR_TO_DATE()` into a `orders_final` table, which replaced the broken `orders` table. Same fields as above, with all date columns as proper `DATETIME` and 99,441 rows restored.

## 3. Dashboard Data Layer (Views)

Grain and purpose of each production view built for Looker Studio (see `sql/08_dashboard_views.sql`):

| View | Grain | Purpose |
|---|---|---|
| `vw_dashboard_kpi` | 1 row | Executive summary KPIs (revenue, orders, delivery, rating, retention) |
| `vw_monthly_sales` | 1 row per month | Revenue and order trend over time |
| `vw_category_performance` | 1 row per category | Revenue, units sold, and rating per product category |
| `vw_state_performance` | 1 row per state | Customers, orders, and payment value per state |
| `vw_payment_performance` | 1 row per payment type | Usage and value share by payment method |
| `vw_delivery_monthly` | 1 row per month | On-time vs. late delivery trend |
| `vw_delivery_state` | 1 row per state | Late delivery rate per state |
| `vw_delivery_rating` | 1 row per delivery status | National rating: on-time vs. late |
| `vw_delivery_rating_by_state` | 1 row per state × delivery status | Rating gap between on-time and late, per state |
| `vw_rating_distribution` | 1 row per rating (1–5) | Review score distribution |
| `vw_customer_type` | 1 row per customer type | One-time vs. repeat customer split |
| `customer_type_aov` | 1 row per customer type | AOV comparison: one-time vs. repeat |
| `vw_product_performance` | 1 row per product | Top products by revenue/units |
| `vw_satisfaction_category` | 1 row per category | Average rating per category |
| `vw_satisfaction_state` | 1 row per state | Average rating per state |
| `vw_monthly_rating_trend` | 1 row per month | Average rating trend over time |
| `vw_dashboard_insights` | 1 row | Pre-aggregated headline callouts for the Executive Summary page |
| `vw_national_benchmark` | 1 row | National baseline for the pilot framework (est. gap, late rate, rating, 90-day repeat rate) |
| `vw_estimation_gap_state` | 1 row per state | Delivery estimation gap (days) per state |
| `vw_repeat_purchase_90d_state` | 1 row per state | 90-day repeat purchase rate per state |
| `vw_pilot_baseline_state` | 1 row per pilot state | Baseline metrics for the 5 pilot states (AL, MA, PI, CE, SE) |
| `vw_pilot_zone_summary` | 1 row | Aggregated pilot-zone vs. national comparison |
| `vw_payment_value_by_installment` | 1 row per installment count | Payment value distribution by installment bracket |

