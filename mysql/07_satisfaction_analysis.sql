-- ========================================================================================== --
-- Segment 6: Customer Satisfaction
-- ========================================================================================== --

-- Q41. What is Olist's average review score?
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_reviews;
-- Insight: overall, customers give an average rating of 4.09 out of 5, showing Olist's customer satisfaction is generally high. 
		-- however, this average alone doesn't show how the rating distribution is shaped, 
		-- so Q42 follows up by looking at the 1–5 rating breakdown.

-- Logic: AVG(review_score) calculates the average across all ratings. ROUND(..., 2) limits the result to 2 decimal places.
		-- the full order_reviews table is used since Q41 is meant to establish Olist's overall customer satisfaction baseline.
        
-- Q42. What is the distribution of ratings 1–5?
SELECT review_score, COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_reviews),
    2) AS percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;
-- Insight: the rating distribution shows Olist's customer satisfaction skews positive, 
		-- with 57.78% of reviews giving a 5 and 19.29% giving a 4. 
		-- however, 14.69% of reviews still fall in the 1–2 range, 
		-- indicating a group of customers who had a less satisfying experience.

-- Logic: GROUP BY review_score splits ratings into 1, 2, 3, 4, 5.
		-- COUNT(*) counts the reviews at each score.
		-- the subquery SELECT COUNT(*) gets the overall review total to use as the denominator.
		-- ORDER BY review_score keeps the results in order from rating 1 to 5.
        
-- Q43. How many customers gave a rating of 1?
SELECT COUNT(*) AS total_rating_1
FROM order_reviews
WHERE review_score = 1;
-- Insight: there are 11,424 reviews with a rating of 1, or 11.51% of all reviews. 
		-- this shows that even though Olist's overall satisfaction is relatively high,
		-- there's a group of customers who had a very unsatisfying experience, and the cause needs to be identified.

-- Q44. How many reviews gave a rating of 5?
SELECT COUNT(*) AS total_rating_5
FROM order_reviews
WHERE review_score = 5;
-- Insight: 57,328 reviews, or 57.78% of all reviews, gave a rating of 5 — making it the most dominant rating category.
		-- compared to the 11,424 reviews with a rating of 1, rating-5 reviews are roughly 5x more common. 
		-- this reinforces the finding that Olist's overall customer experience skews positive.

-- Logic: WHERE review_score = 5 filters to only the highest-score reviews.
		-- COUNT(*) counts those reviews.

-- Q45. Which product category has the highest average rating?
SELECT oc.product_category_name,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS total_reviews
FROM (SELECT DISTINCT oi.order_id, p.product_category_name
    FROM order_items oi
    JOIN products p
	ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
) AS oc
JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) AS r
ON oc.order_id = r.order_id
GROUP BY oc.product_category_name
HAVING COUNT(*) >= 50
ORDER BY avg_rating DESC;
-- Insight: the livros_interesse_geral category has the highest average rating at 4.46 out of 5, based on 508 observations. 
		-- this shows orders involving that category have relatively high satisfaction
        -- compared to other categories meeting the minimum observation threshold.

-- Logic: order_reviews -> order_items via order_id to identify which product was reviewed.
		-- order_items -> products via product_id to get the category.
		-- AVG(review_score) gives the average rating per category.
		-- COUNT(*) gives the number of reviews used.
		-- HAVING COUNT(*) >= 50 avoids categories with too few observations.
		-- ORDER BY avg_rating DESC surfaces the highest-rated category first.
		-- GROUP BY is needed because order_reviews has 99,224 rows but only around 98,673 unique orders. 
					-- meaning some order_id values appear more than once.
                    
-- Q46. Which category has the lowest average rating?
SELECT oc.product_category_name,
    ROUND(AVG(r.review_score), 2) AS avg_rating, COUNT(*) AS total_reviews
FROM (SELECT DISTINCT oi.order_id, p.product_category_name
    FROM order_items oi
    JOIN products p
	ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT NULL
) AS oc
JOIN (SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) AS r
ON oc.order_id = r.order_id
GROUP BY oc.product_category_name
HAVING COUNT(*) >= 50
ORDER BY avg_rating ASC;
-- Insight: the moveis_escritorio category has the lowest average rating at 3.62 out of 5, with 1,263 observations. 
		-- this shows customer experience for orders tied to that category is relatively less satisfying 
        -- compared to other categories. Given the sizeable observation count, 
		-- this category is worth prioritizing for further investigation,
		-- particularly around product quality, customer expectations, seller performance, and delivery performance.

-- Logic: order_items -> products to get the category 
		-- DISTINCT avoids double-counting within an order-category pair
		-- order_reviews to get the rating -> AVG() for the average 
		-- HAVING >= 50 keeps a minimum observation count 
		-- ORDER BY ASC surfaces the lowest first.

-- Q47. Is late delivery associated with lower ratings?
SELECT CASE
	WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
	THEN 'Late'
	ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS total_orders
FROM orders o
JOIN (SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) AS r
	ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery_status
ORDER BY avg_rating DESC;
-- Insight: late orders have a much lower average rating — 2.57 versus 4.29 for orders that arrived on time.
		-- the 1.72-point gap shows a strong relationship between delivery punctuality and customer satisfaction.

-- Logic: CASE WHEN groups orders into "Late" and "On Time" based on delivery punctuality. 
	-- ratings are then joined via order_id and averaged for each group. 
	-- comparing the two groups
	-- shows whether late delivery is associated with a difference in customer satisfaction.

-- Q48. Which state has the highest customer satisfaction?
SELECT c.customer_state, ROUND(AVG(r.review_score), 2) AS avg_rating, COUNT(*) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN (SELECT order_id,
	AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING COUNT(*) >= 50
ORDER BY avg_rating DESC;
-- Insight: SP (São Paulo) has the highest average rating at 4.25/5, across 40,273 orders. 
		-- this shows customer satisfaction in SP is relatively high, and the result is fairly robust given the very large order count backing it. 
        -- for comparison, AP and AM also sit around 4.24, but with far fewer orders. 
		-- the Olist dataset has a very large customer concentration in São Paulo, 
		-- so the SP result is more representative than states with a small observation count.

-- Logic: orders links each order to its customer, then customers supplies the state.
	-- after summarizing ratings per order_id, GROUP BY customer_state calculates AVG(review_score) 
	-- to get the average satisfaction per state. 
	-- HAVING >= 50 keeps the ranking from being skewed by states with very few orders.

-- =========================================================================DONE==================================================================================================== --  
