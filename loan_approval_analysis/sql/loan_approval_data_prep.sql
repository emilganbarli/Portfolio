-- ========================================== DATA PREP ================================================

-- DUPLICATE CHECK
SELECT
	loan_id,
	COUNT(*)
FROM loans_raw
GROUP BY loan_id
HAVING COUNT(*) > 1;

--- RANGE CHECK
-- applicant_income
SELECT
	MIN(applicant_income),
	MAX(applicant_income)
FROM loans_raw
WHERE applicant_income != 0;

-- coapplicant_income
SELECT
	MIN(coapplicant_income),
	MAX(coapplicant_income)
FROM loans_raw
WHERE coapplicant_income != 0;

-- loan amount (in thousands)
SELECT
	MIN(loan_amount),
	MAX(loan_amount)
FROM loans_raw;

-- loan_amount_term (months)
SELECT
	MIN(loan_amount_term),
	MAX(loan_amount_term)
FROM loans_raw;


--- NULL HANDLING
-- gender
SELECT
	gender,
	COUNT(*)
FROM loans_raw
GROUP BY gender; -- male clients is noticeably higher

UPDATE loans_raw
SET gender = 'Male'
WHERE gender IS NULL;

-- married
SELECT
	married,
	COUNT(*)
FROM loans_raw
GROUP BY married; -- 'yes' is higher, so we assume null values are 'yes'

UPDATE loans_raw
SET married = 'Yes'
WHERE married IS NULL;

-- dependents
UPDATE loans_raw
SET dependents = 0
WHERE dependents IS NULL; -- we assume that if it is null then no dependents exist

-- self employed
SELECT
	self_employed,
	COUNT(*)
FROM loans_raw
GROUP BY self_employed; 

UPDATE loans_raw
SET self_employed = 'No'
WHERE self_employed IS NULL 
	AND loan_id IN (
		SELECT
			loan_id
		FROM loans_raw
		WHERE self_employed IS NULL
		LIMIT 28
	)
;

UPDATE loans_raw
SET self_employed = 'Yes'
WHERE self_employed IS NULL 
	AND loan_id IN (
		SELECT
			loan_id
		FROM loans_raw
		WHERE self_employed IS NULL
		LIMIT 4
	)
; -- distributing yes and no to nulls proportionally

-- loan_amount
UPDATE loans_raw
SET loan_amount = (
	SELECT
		AVG(loan_amount)
	FROM loans_raw
	)
WHERE loan_amount IS NULL;

-- loan_amount_term
SELECT
	loan_amount_term,
	COUNT(*)
FROM loans_raw
GROUP BY loan_amount_term
ORDER BY COUNT(*);

UPDATE loans_raw
SET loan_amount_term = 360
WHERE loan_amount_term IS NULL 
	AND loan_id IN (
		SELECT
			loan_id
		FROM loans_raw
		WHERE loan_amount_term IS NULL
		LIMIT 10
	)
;

UPDATE loans_raw
SET loan_amount_term = 180
WHERE loan_amount_term IS NULL 
	AND loan_id IN (
		SELECT
			loan_id
		FROM loans_raw
		WHERE loan_amount_term IS NULL
		LIMIT 4
	) 
; -- distributing 180 and 360 to nulls proportionally

UPDATE loans_raw
SET credit_history = 'Unknown'
WHERE credit_history IS NULL;

SELECT * FROM loans_raw;
-- ========================================= ADDITIONAL FIELDS ===========================================
DROP MATERIALIZED VIEW IF EXISTS loans;
CREATE MATERIALIZED VIEW loans AS
SELECT
	loan_id,
	gender,
	married,
	dependents,
	education,
	self_employed,
	applicant_income,
	CASE 
		WHEN applicant_income < 3333 THEN 'Low'
		WHEN applicant_income < 5833 THEN 'Medium'
		WHEN applicant_income < 10000 THEN 'High'
		ELSE 'Very High'
	END AS applicant_income_category,
	CASE
		WHEN coapplicant_income = 0 THEN 'No'
		ELSE 'Yes'
	END AS coapplicant_status,
	coapplicant_income,
	applicant_income + coapplicant_income AS total_income,
	CASE 
		WHEN coapplicant_income + applicant_income < 4000 THEN 'Low'
		WHEN coapplicant_income + applicant_income < 7000 THEN 'Medium'
		WHEN coapplicant_income + applicant_income < 12000 THEN 'High'
		ELSE 'Very High'
	END AS total_income_cat,
	loan_amount * 1000 AS loan_amount,
	CASE
		WHEN loan_amount <= 100 THEN 'Retail'
		ELSE 'Mortgage'
	END AS loan_type,
	CASE 
		WHEN loan_amount <= 50 THEN 'Low'
		WHEN loan_amount <= 150 THEN 'Medium'
		WHEN loan_amount <= 300 THEN 'High'
		ELSE 'Very High'
	END AS loan_amount_cat,
	loan_amount_term AS loan_term,
	CASE
		WHEN credit_history = '0' THEN 'No'
		WHEN credit_history = '1' THEN 'Yes'
		ELSE credit_history
	END AS credit_history,
	property_area,
	CASE 
		WHEN loan_status = 'Y' THEN 'Approved'
		ELSE 'Rejected'
	END AS loan_status,
	ROUND(loan_amount * 1000.0 / loan_amount_term, 2) AS emi, -- equated monthly installment
	ROUND((loan_amount * 1000.0 / loan_amount_term) 
		/ (applicant_income + coapplicant_income) * 100 ,2) AS dti -- debt to income ratio perc (with total income)
FROM loans_raw;


