--- Business Questions ---
-- 1) What is the overall churn rate and how many customers does it represent?
SELECT
	COUNT(customer_id) AS customers,
	COUNT(customer_id) FILTER(WHERE churn_flag = 1) AS churned_customers,
	ROUND(COUNT(customer_id) FILTER(WHERE churn_flag = 1) * 100.0 /
	COUNT(customer_id), 2) AS churn_rate
FROM telsis_mw;

-- 2) Breaking down the churn reasons. Top 3 most frequent.
SELECT
	churn_reason,
	COUNT(customer_id) AS churned_customers
FROM telsis_mw
WHERE churn_flag = 1
GROUP BY churn_reason 
ORDER BY COUNT(customer_id) DESC
LIMIT 3;

-- 3) For each churn category, what percentage of total churn do they represent?
WITH churned AS (	
	SELECT
		COALESCE(churn_category, 'Unknown') AS churn_category
	FROM telsis_mw
	WHERE churn_flag = 1
)
SELECT
	churn_category,
	COUNT(*) AS churned_customers,
	SUM(COUNT(*)) OVER() AS total_churned,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS perc
FROM churned
GROUP BY churn_category
ORDER BY COUNT(*) DESC;

-- 4) Which 5 states have the highest churn rate?
SELECT
	state,
	COUNT(*) FILTER(WHERE churn_flag = 1) * 100.0 / COUNT(*) AS perc 
FROM telsis_mw
GROUP BY state
ORDER BY perc DESC 
LIMIT 5;

-- 5) Comparison of churn rates by gender.
SELECT
	gender,
	COUNT(*) AS total_customers,
	SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) AS churned_customers,
	ROUND(SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM telsis_mw 
GROUP BY gender; -- this question can be handled with ctes or count filter as well

-- 6) By age bucket what is the churn rate?
SELECT
	age_bucket,
	ROUND(COUNT(*) FILTER(WHERE churn_flag = 1) * 100.0 / COUNT(*), 2) churn_rate
FROM telsis_mw 
GROUP BY age_bucket
ORDER BY 2 DESC;

-- 7) Within each gender, what is the most common churn category
WITH ranked AS (
SELECT
	gender,
	churn_category,
	COUNT(*) AS churned_n,
	DENSE_RANK() OVER(PARTITION BY gender 
		ORDER BY COUNT(*) DESC) AS rnk
FROM telsis_mw
WHERE churn_flag = 1
GROUP BY gender, churn_category
)
SELECT 
	gender,
	churn_category,
	churned_n,
	rnk
FROM ranked
WHERE rnk = 1;	

-- 8) What is the churn rate by contract type (month-to-month, one year, two year)
SELECT
	contract_type,
	ROUND(COUNT(*) FILTER(WHERE churn_flag = 1) * 100.0 / NULLIF(COUNT(*), 0), 2) AS churn_rate
FROM telsis_mw
GROUP BY contract_type
ORDER BY churn_rate DESC;

-- 9) How does churn vary by number of customer service calls (0, 1, 2, 3+)
SELECT
	cs_calls_bucket,
	COUNT(*)
FROM telsis_mw
WHERE churn_flag = 1
GROUP BY cs_calls_bucket
ORDER BY cs_calls_bucket;

-- 10) For customers with international plans, compare churn between those who actively use vs those who do not
SELECT
	DISTINCT intl_usage_status
FROM telsis_mw;

SELECT
	intl_usage_status,
	COUNT(*) AS customers_n,
	COUNT(*) FILTER(WHERE churn_flag = 1) AS churned_n,
	ROUND(COUNT(*) FILTER(WHERE churn_flag = 1) * 100.0 / NULLIF(COUNT(*), 0), 2) AS churn_rate
FROM telsis_mw
WHERE intl_usage_status IN ('plan+active', 'plan+inactive')
GROUP BY intl_usage_status;

-- 11) Average monthly charge of churned vs retained customers
WITH churn_groups AS (
	SELECT 
		customer_id,
		CASE
			WHEN churn_flag = 1 THEN 'Churned' ELSE 'Retained' END AS churn_status,
			monthly_charge
	FROM telsis_mw
)
SELECT
	churn_status,
	ROUND(AVG(monthly_charge), 2) AS avg_monthly_charge
FROM churn_groups 
GROUP BY churn_status;

-- 12) Rank churned customers by total charges within each state (find top 1 customer)
WITH ranked AS (
	SELECT
		state,
		customer_id,
		total_charges,
		ROW_NUMBER() OVER(PARTITION BY state 
			ORDER BY total_charges DESC) AS rn
	FROM telsis_mw
	WHERE churn_flag = 1
)
SELECT
	state,
	customer_id,
	total_charges,
	rn
FROM ranked
WHERE rn = 1
ORDER BY total_charges DESC;
	
-- 13) Compare churn rate between revenue levels
SELECT
	MIN(total_charges),
	MAX(total_charges),
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY total_charges)
FROM telsis_mw;

WITH rev_segmentation AS (
SELECT
	churn_flag,
	total_charges,
	CASE 
	WHEN total_charges <= 1500 THEN 'Low'
	WHEN total_charges <=2500 THEN 'Medium'
	ELSE 'High' 
	END AS revenue_segment
FROM telsis_mw
)
SELECT 
	revenue_segment,
	COUNT(*) AS customers_n,
	COUNT(*) FILTER(WHERE churn_flag = 1) AS churned_n,
	ROUND(COUNT(*) FILTER(WHERE churn_flag = 1) * 100.0 /
		NULLIF(COUNT(*), 0), 2) AS churn_rate
FROM rev_segmentation
GROUP BY revenue_segment;

-- 14) Count of churned customers above average monthly charge (and their perc in total churned customers)
SELECT
	COUNT(*) AS churned_n,
	(SELECT COUNT(*) FROM telsis_mw WHERE churn_flag = 1),
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM telsis_mw WHERE churn_flag = 1), 2) AS perc
FROM telsis_mw
WHERE churn_flag = 1
	AND monthly_charge > (
	SELECT
		AVG(monthly_charge) 
	FROM telsis_mw
	);

-- 15)
WITH churned AS (
  SELECT customer_id, cs_calls, churn_flag
  FROM telsis_mw
  WHERE churn_flag = 1
),
ranked AS (
  SELECT
    customer_id,
    cs_calls,
    RANK() OVER(ORDER BY cs_calls DESC) AS rnk
  FROM churned
)
SELECT
  customer_id,
  cs_calls,
  rnk,
  CASE
    WHEN cs_calls >= 5 THEN 'High callers'
    ELSE 'Normal callers'
  END AS caller_type
FROM ranked
ORDER BY rnk
LIMIT 10;

-- 15) Do customers with longer tenure churn less?
WITH tenure_quartiles AS (
SELECT
	customer_id,
	tenure_months, 
	churn_flag,
	NTILE(4) OVER(ORDER BY tenure_months) AS quartile
FROM telsis_mw
)
SELECT 
	CASE quartile
		WHEN 1 THEN 'Q1 (shortest tenure)'
		WHEN 2 THEN 'Q2'
		WHEN 3 THEN 'Q3'
		WHEN 4 THEN 'Q4 (longest tenure)'
		ELSE 'Check'
	END	AS tenure_grp,
	COUNT(*) AS customers_n,
	SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) AS churned_n,
	ROUND(SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 100.0 /
	COUNT(*), 2) AS churn_rate
FROM tenure_quartiles
GROUP BY quartile
ORDER BY quartile;


