# Olist Brazilian E-Commerce Performance Analysis (2016–2018)
![Data Strategy](https://img.shields.io/badge/Data_Strategy-Strategic_Planning-success?style=for-the-badge)

# Overview 

An end-to-end business analysis of Olist, a Brazilian e-commerce marketplace, covering 99,441 orders between 2016 and 2018 — from raw CSV files to a pilot-ready business recommendation.

Built with SQL in MySQL, visualized in a 6-page Looker Studio dashboard, and packaged into a case-study deck that walks through the full analytical journey: data cleaning → SQL analysis → dashboarding → insight synthesis → a testable hypothesis with defined success metrics.

## The Business Question

On the surface, Olist's business looks healthy: R$13.5M in revenue and strong month-over-month order growth. But growth alone doesn't guarantee a sustainable business — and a closer look shows almost all of that volume comes from customers who never come back.

This project helps answer four main business questions:

1. Is the revenue growth actually diversified, or is it fragile and concentrated?
2. Why do 96.88% of customers only ever buy once?
3. Where is delivery performance actually breaking down, and is it a distance problem or something else?
4. Does delivery reliability meaningfully affect whether a customer comes back?

## Data Source

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), September 2016 – October 2018. 8 raw tables covering orders, order items, payments, reviews, products, customers, sellers, and geolocation were loaded into MySQL.

## Toolkit

![MySQL](https://img.shields.io/badge/MySQL-00000F?style=for-the-badge&logo=mysql&logoColor=white)
![Looker Studio](https://img.shields.io/badge/Looker_Studio-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Canva](https://img.shields.io/badge/Canva-00C4CC?style=for-the-badge&logo=canva&logoColor=white&v=2)

## Analysis Workflow

```text
Raw CSV (8 tables)
↓
Data Import & Validation (MySQL)
↓
Structured SQL Analysis (48 business questions across 6 segments)
↓
Production-Ready Views (14 QA'd SQL views)
↓
Looker Studio Dashboard (6 pages)
↓
Insight Synthesis
↓
Hypothesis-Driven Execution Plan
```

## SQL files:

| File | Covers |
|---|---|
| `sql/01_data_cleaning.sql` | Row-count checks, type/encoding fixes across raw tables |
| `sql/02_sales_and_category.sql` | Revenue trend, category performance, freight cost share |
| `sql/03_customer_behavior.sql` | One-time vs. repeat buyers, AOV by customer type, state performance |
| `sql/04_payment_and_installment.sql` | Payment method mix, installment distribution |
| `sql/05_delivery_performance.sql` | On-time/late delivery, delivery days by state |
| `sql/06_satisfaction_and_rating.sql` | Review score distribution, rating vs. delivery timing |
| `sql/07_pilot_baseline.sql` | Pilot-zone vs. national benchmark diagnostics |

## Headline Numbers

| Metric | Value |
|---|---|
| Total Revenue | R$13.5M |
| Total Orders | 99,441 |
| Average Order Value | R$136.58 |
| Freight Revenue | R$2.24M (14% of sales) |
| One-Time Buyers | 96.88% |
| National Late Delivery Rate | 8.11% |
| Rating, On-Time vs. Late | 4.3 → 2.6 |
| Late Rate in 5 Highest-Leak States | 17.21% (2.1x national) |

## Live Dashboard

[Click here to open the Looker Studio dashboard](https://datastudio.google.com/reporting/0c9bb251-c3fe-4793-8ecf-18ac80927c39)

## Dashboard Preview

![Executive Summary](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/executive%20summary.png)
![Sales Performance](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/sales%20performance.png)
![Customer Analysis](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/customer%20analysis.png)
![Payment Analysis](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/payment%20analysis.png)
![Delivery Performance](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/delivery%20performance.png)
![Customer Satisfaction](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/customer%20satisfaction.png)
![Appendix](https://github.com/baahrull/Olist-Ecommerce-Analysis/blob/main/asset/appendix.png)

## What the Data Showed

**Market Centralization** — Growth stayed steady through 2017 before plateauing. Just 3 categories drive a disproportionate share of revenue, and São Paulo alone generates several times more freight revenue than any other state.

**The Retention Paradox** — Order volume looks healthy month over month, but 96.88% of it comes from single-purchase buyers. One-time buyers even have a slightly *higher* AOV (R$161.82) than repeat buyers (R$148.85) — the business is running almost entirely on new-customer acquisition.

**Payment & Installment Behavior** — Credit card takes 73.92% share and is the only method carrying installments (avg. 3.51x), clustering at either full payment or the 10x max — mid-range installment options are barely used.

**Hidden SLA Leaks** — A 91.89% national on-time rate looks solid, but late deliveries concentrate heavily in specific states. Alagoas and Maranhão post late rates above 20% without ranking among the slowest for average delivery time — this points to bad delivery-date *estimation*, not distance.

**The Churn Driver** — On-time orders average a 4.3 rating; late orders drop to 2.6. With only 8.11% of orders arriving late but 96.88% of customers never returning, delivery reliability is the most direct lever connecting operations to retention.

## Recommendations

- Reduce reliance on São Paulo and the top 3 categories through regional expansion and cross-selling.
- Shift CRM spend from acquisition toward post-purchase re-engagement within 14–30 days of delivery.
- Audit checkout UX for underused mid-range installment options before expanding credit policy.
- Recalibrate delivery-date estimation specifically for the five high-leak states, rather than treating lateness as purely a distance problem.
- Treat delivery reliability as a retention KPI, not just a logistics one.

## Turning This Into a Testable Hypothesis

**Hypothesis:** Inaccurate delivery-date estimation in five high-leak states (AL, MA, PI, CE, SE) is a primary driver of Olist's low repeat-purchase rate — not distance alone.

**Test design:** Recalibrate the estimation model for these five states only, and compare against a matched control group of unadjusted high-late-rate states (e.g. PA, TO, ES) to isolate the effect of estimation accuracy.

| Metric | Baseline | Target |
|---|---|---|
| Estimation Gap | -10.26 days | -12.00 days |
| Late Delivery Rate | 17.21% | < 10.00% |
| Average Rating | 3.91 / 5.0 | > 4.16 / 5.0 |
| 90-Day Repeat Purchase Rate | 1.48% | > 2.10% |

## Caveats

- Dataset covers 2016–2018 only; doesn't reflect current platform behavior.
- No cost/margin data, so profitability beyond revenue and freight couldn't be assessed.
- No marketing spend data, so CAC wasn't factored into the retention read.
- The delivery-to-retention link is a strong correlation from historical data — the pilot itself hasn't been run yet.
- Review text wasn't analyzed, only numeric scores.

## What's Next

1. Run the pilot in the five target states and measure against the targets above.
2. Add cohort-based repeat-purchase tracking over longer windows.
3. Bring in seller-level data to separate marketplace-wide issues from seller-specific ones.
4. Analyze review text alongside the numeric scores.
5. If the pilot validates the hypothesis, roll the estimation fix out nationally.

## Folder Layout

```text
olist-ecommerce-analysis/
├── README.md
├── mysql/
├── dashboard/
└── deck/
└── docss/
```

## Author 

Bahrul Ulum — Development Economics Graduate, Data & Business Analysis Portfolio
