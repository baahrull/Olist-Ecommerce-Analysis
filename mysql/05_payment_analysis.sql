-- ========================================================================================== --
-- Segment 4: Payment Analysis
-- ========================================================================================== --
-- checking data quality for order_payments, since order_payments is the core dataset for this segment.

-- DQ1 = row count
-- confirm total rows match the raw data
SELECT COUNT(*) AS total_rows FROM order_payments;

-- DQ2 = check for nulls
-- confirm the core payment columns have no blank values that could break the payment aggregations.
SELECT
    COUNT(*) AS total_rows,
    SUM(order_id IS NULL OR order_id = '') AS null_order_id,
    SUM(payment_sequential IS NULL) AS null_payment_sequential,
    SUM(payment_type IS NULL OR payment_type = '') AS null_payment_type,
    SUM(payment_installments IS NULL) AS null_installments,
    SUM(payment_value IS NULL) AS null_payment_value
FROM order_payments;

-- DQ3 = check payment types
-- confirm the payment categories in the database match the original data structure, with no odd categories introduced during import.
SELECT payment_type, COUNT(*) AS total_payments
FROM order_payments
GROUP BY payment_type
ORDER BY total_payments DESC;

-- DQ4 = check payment values
-- MIN, MAX, and AVG give a picture of the transaction value range, 
-- while the negative-value check confirms there's no payment value that's logically impossible.
SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    ROUND(AVG(payment_value), 2) AS avg_payment
FROM order_payments;
-- then check for negative values
SELECT COUNT(*) AS negative_payment
FROM order_payments
WHERE payment_value < 0;

-- DQ5 = check installments
-- confirm installment counts fall within a valid range, and get a sense of the installment range before moving into Q29–Q30.
SELECT
    MIN(payment_installments) AS min_installment,
    MAX(payment_installments) AS max_installment,
    ROUND(AVG(payment_installments), 2) AS avg_installment
FROM order_payments;
-- also check for any failed-payment cases
SELECT COUNT(*) AS invalid_installment
FROM order_payments
WHERE payment_installments <= 0;

-- since there are some invalid_installment rows, check whether the issue traces to payment_type or payment_value
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_installments <= 0;
-- there are 2 records with payment_installments = 0. Both use credit_card and still have a payment_value, 
-- meaning this is inherent to the RAW data, not something broken during import.

-- DQ6 = check for duplicate payment records
-- payment_sequential distinguishes multiple payments within a single order, 
-- so the combination of both columns is a more accurate duplicate check than order_id alone.
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) AS unique_payment_keys
FROM order_payments;

-- DQ7 = check referential integrity against orders 
-- every payment should have an order_id that exists in the orders table, since the relationship runs orders -> order_payments.
SELECT COUNT(*) AS orphan_payments
FROM order_payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- DQ8 = check for multiple payments within a single order
-- checks how many orders have more than one payment record. 
-- important because Q27/Q28 later need to be careful not to count payments as if they were orders.
-- since the Olist dataset does allow a single order to use more than one payment method.
SELECT
    COUNT(*) AS total_orders,
    SUM(total_payments > 1) AS orders_multiple_payment,
    MAX(total_payments) AS max_payment_per_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS total_payments
    FROM order_payments
    GROUP BY order_id
) x;
-- Data quality checks done — all clear, dataset ready for Segment 4 analysis.

-- ========================================================================================================== -- 
-- ===== BUSINESS ANALYSIS — SEGMENT 4: PAYMENT ANALYSIS — ANSWERING THE QUESTIONS DEFINED ABOVE ===== --
-- ========================================================================================================== -- 

	-- Q26. Which payment method is used the most?
SELECT
    payment_type,
    COUNT(*) AS total_payment
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment DESC;
-- Business insight: credit card is the most-used payment method, 
					-- with 76,795 payment records, far ahead of boleto's 19,784 records.

-- Logic: GROUP BY payment_type groups transactions by payment method.
		-- COUNT(*) counts the number of payment records per method.
		-- ORDER BY total_payment DESC sorts from highest to lowest count.

	-- Q27. What is the total transaction value by payment method?
SELECT
    payment_type, SUM(payment_value) AS total_transaction
FROM order_payments
GROUP BY payment_type
ORDER BY total_transaction DESC;
-- Business insight: credit card has the largest total transaction value, around R$125.42M, far above boleto's R$28.69M. 
                -- This shows credit card isn't just the most-used payment method by count, 
                -- it also dominates by transaction value. 
                -- This dominance confirms credit card is Olist's primary payment method, 
					-- both by frequency of use and total payment value.

-- Logic: GROUP BY payment_type groups transactions by payment method, 
		-- then SUM(payment_value) totals the transaction value for each method. 
		-- ORDER BY DESC sorts from largest to smallest total value,
		-- so the method with the largest transaction value is immediately visible.

	-- Q28. Which payment method generates the highest transaction value?
SELECT
    payment_type,
    SUM(payment_value) AS total_transaction
FROM order_payments
GROUP BY payment_type
ORDER BY total_transaction DESC
LIMIT 1;
-- Business insight: based on Q27 and Q28, credit_card is the payment method generating the highest transaction value, 
				-- at around R$125.42M. This is far ahead of boleto in second place at around R$28.69M. 
            -- This further confirms credit card as the dominant payment method in Olist's transaction activity, 
				-- both by usage count and total payment value.

-- Logic: data is grouped by payment_type, then SUM(payment_value) calculates the total transaction value for each method. 
		-- After sorting from largest to smallest, LIMIT 1 takes only the method with the highest total. 
		-- Since Q28 only needs the single winner, LIMIT 1 is used so the result doesn't list every method.

	-- Q29. What is the average number of installments by payment method?
SELECT
    payment_type,
    ROUND(AVG(payment_installments), 2) AS avg_installments
FROM order_payments
GROUP BY payment_type
ORDER BY avg_installments DESC;
-- Business insight: credit card has the highest average installment count at 3.51x,
					-- while boleto, voucher, debit card, and not_defined each average 1x. 
					-- This difference shows the installment feature in the Olist dataset is mainly tied to credit card usage,
                -- while the other payment methods are essentially used as single payments.
					-- This makes credit card the most relevant method for analyzing installment payment behavior.

-- Logic: data is grouped by payment_type, then AVG(payment_installments) calculates the average installment count per method.
		-- ROUND(..., 2) makes the result easier to read, then it's sorted from highest to lowest average installment count.

	-- Q30. Do customers who use installments have a higher average transaction value?
SELECT
CASE
	WHEN payment_installments > 1 THEN 'Installment'
	ELSE 'Non-Installment'
    END AS payment_category,
    ROUND(AVG(payment_value), 2) AS avg_transaction
FROM order_payments
GROUP BY payment_category
ORDER BY avg_transaction DESC;
-- Business insight: customers using installments have an average transaction value of R$196.76, 
				-- higher than non-installment transactions at just R$112.42. In the Olist data, 
            -- installment payments tend to be used for larger transactions compared to one-time payments. 
            -- This difference shows an association between installment usage and higher transaction value, 
				-- though this shows a correlation and doesn't prove that using installments directly causes a higher transaction value.

-- Logic: CASE WHEN splits payment records into two groups based on installment count, 
		-- then AVG(payment_value) calculates the average transaction value for each group.
		-- this makes it easy to see directly whether installment payments have a higher average transaction value.
		-- payment_installments > 1 is used as the cutoff because we want to isolate installment behavior specifically.
        -- payment_installments > 1 = installment. payment_installments = 1 = paid in full.
        
	-- Q31. What is the usage distribution of credit card, boleto, voucher, and debit card?
SELECT
    payment_type,
    COUNT(*) AS total_payment,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_payments), 2) AS percentage
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment DESC;
-- Business insight: the payment method distribution shows a very strong dominance by credit card, 
					-- which accounts for around 73.92% of all payment records. Boleto is second at 19.04%, 
                -- while voucher and debit card sit at just 5.56% and 1.47% respectively. 
                -- Together, credit card and boleto cover around 93% of all payment method usage, 
                -- showing these two methods are Olist customers' primary choices.

-- Logic: data is grouped by payment_type, then COUNT(*) counts the usage of each method. 
		-- that count is divided by the total number of payment records and multiplied by 100 to get the percentage, 
		-- so each method's share can be compared proportionally.

-- ================================== Segment 4 Business Insight Summary: Payment Analysis ======================================== -- 
-- Olist's payment ecosystem relies heavily on credit card, with notably prominent installment usage. 
-- This shows payment flexibility is an important part of supporting customer transactions. 
-- Meanwhile, boleto, debit card, and voucher serve as alternatives catering to different payment preferences. 
-- From a business standpoint, Olist needs to maintain the reliability of credit-card payments,
-- while also optimizing the installment feature, since both play an important role in sustaining conversion and transaction value.
-- ================================== Segment 4 Business Insight Summary: Payment Analysis ======================================== --
