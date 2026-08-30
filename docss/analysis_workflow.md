# Analysis Workflow

This project follows a 7-step pipeline, from raw CSV files to a pilot-ready business hypothesis.

## 1. Data Import & Validation

8 raw CSV tables were loaded into MySQL. Row counts, NULLs, and referential integrity (e.g. every `order_id` in `order_items` matching a row in `orders`) were checked before any analysis began.

Script: `sql/01_data_cleaning.sql`

## 2. Data Cleaning

A mismatch was found between `orders` and `order_items`/`order_payments` — around 2,200–2,980 orders referenced in the child tables had no match in `orders`. Root-cause: importing date columns directly as `DATETIME` silently dropped malformed rows on import. Fixed by re-importing `orders` as all-text (`orders_raw`), then converting to proper `DATETIME` with `STR_TO_DATE()` into a clean `orders` table — restoring all 99,441 rows.

## 3. Structured SQL Analysis

48 business questions were answered across 6 segments:

| Segment | Script | Questions |
|---|---|---|
| Sales Performance | `sql/02_sales_performance.sql` | Q1–Q9 |
| Product Performance | `sql/03_product_performance.sql` | Q10–Q17 |
| Customer Analysis | `sql/04_customer_analysis.sql` | Q18–Q25 |
| Payment Analysis | `sql/05_payment_analysis.sql` | Q26–Q31 |
| Delivery Performance | `sql/06_delivery_performance.sql` | Q32–Q40 |
| Customer Satisfaction | `sql/07_satisfaction_analysis.sql` | Q41–Q48 |

Each query is paired with a written business insight and query-logic explanation.

## 4. Production-Ready Views

14+ SQL views were built and QA'd for the dashboard layer — catching issues like a `LEFT JOIN` that inflated `review_count`, and revenue figures that needed canceled orders excluded.

Script: `sql/08_dashboard_views.sql` — see `data_dictionary.md` for the full view list and grain.

## 5. Dashboard Deployment

The views were connected to a 6-page interactive dashboard in Looker Studio: Executive Summary, Sales Performance, Customer Analysis, Payment Analysis, Delivery Performance, and Customer Satisfaction.

## 6. Insight Synthesis

Five findings were distilled into one causal narrative — revenue and order volume are healthy, but 96.88% of customers never return, and the data points to delivery reliability as the likely driver: on-time orders average a 4.3 rating vs. 2.6 for late ones, and lateness is concentrated in 5 specific states rather than being purely distance-related. See `problems_recommendations.md`.

## 7. Hypothesis & Pilot Framework

The insight was converted into a testable hypothesis: inaccurate delivery estimation in the 5 highest-leak states (AL, MA, PI, CE, SE) — not distance — is a primary driver of low repeat-purchase rate. A pilot design, control group, and success metrics were defined to test it. See `metric_definitions.md` for the target thresholds.
