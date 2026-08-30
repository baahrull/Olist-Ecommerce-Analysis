# Metric Definitions

## Sales

| Metric | Definition |
|---|---|
| Total Revenue | Sum of `price` across all order items (excludes freight) |
| Freight Revenue | Sum of `freight_value` across all order items |
| Total Sales Value | Total Revenue + Freight Revenue |
| Total Orders | Count of distinct `order_id` in `orders` |
| Average Order Value (AOV) | Total Revenue ÷ Total Orders |
| Total Items Sold | Row count of `order_items` (1 row = 1 item sold) |

## Product

| Metric | Definition |
|---|---|
| Category Revenue | Sum of `price` for all items in a category |
| Units Sold (category/product) | Count of order-item rows for a category or product |
| Average Item Price | Average `price` across items in a product or category |

## Customer

| Metric | Definition |
|---|---|
| Unique Customers | Count of distinct `customer_unique_id` (the person-level ID, not the per-order `customer_id`) |
| One-Time Customer | A `customer_unique_id` with exactly 1 order |
| Repeat Customer | A `customer_unique_id` with more than 1 order |
| Repeat Customer Rate | Repeat Customers ÷ Total Unique Customers |
| 90-Day Repeat Purchase Rate | % of customers whose 2nd order happens within 90 days of their 1st order |

## Payment

| Metric | Definition |
|---|---|
| Payment Type Share | Count of payment records for a type ÷ Total payment records |
| Average Installments | Average `payment_installments` for a payment type |
| Installment Transaction | A payment with `payment_installments` > 1 |

## Delivery

| Metric | Definition |
|---|---|
| Delivery Days | `order_delivered_customer_date` − `order_purchase_timestamp`, in days |
| Late Order | A delivered order where `order_delivered_customer_date` > `order_estimated_delivery_date` |
| Late Delivery Rate | Late Orders ÷ Delivered Orders |
| On-Time Rate | 1 − Late Delivery Rate |
| Estimation Gap (days) | `order_delivered_customer_date` − `order_estimated_delivery_date`, averaged. Negative = delivered earlier than promised (safe buffer); positive = delivered later than promised |

## Satisfaction

| Metric | Definition |
|---|---|
| Average Rating | Average `review_score` (1–5 scale) |
| Rating 5 % | Reviews with score 5 ÷ Total reviews |
| Rating 1–2 % | Reviews with score 1 or 2 ÷ Total reviews |
| On-Time vs. Late Rating | Average rating split by whether the linked order was delivered late |

## Pilot Framework

| Metric | Definition |
|---|---|
| Pilot Zone | The 5 states with the highest late-delivery rate: AL, MA, PI, CE, SE |
| National Benchmark | Same metrics calculated across all 27 states, used as the pilot's success target |
| Success Target: Late Rate | < 10.00% (down from the pilot zone's 17.21% baseline) |
| Success Target: Avg Rating | > 4.16 (national baseline) |
| Success Target: 90-Day Repeat Rate | > 2.10% (national baseline) |
