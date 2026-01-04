-- ========================================= SQL Highlights ============================================
-- 1) Approval rate within each credit history group
SELECT
	credit_history,
	ROUND(SUM(CASE WHEN loan_status = 'Approved' THEN 1 END) * 100.0 / COUNT(*), 2) AS approval_rate
FROM loans
GROUP BY credit_history
ORDER BY credit_history DESC;

-- 2) Composition of approvals (what % of all approvals come from each group)
WITH approved AS (
  SELECT credit_history
  FROM loans
  WHERE loan_status='Approved'
		AND credit_history != 'Unknown'
)
SELECT
  credit_history,
  ROUND(COUNT(*)*100.0 / (SELECT COUNT(*) FROM approved),2) AS share_of_approvals,
  COUNT(*) AS approved_count
FROM approved
WHERE credit_history != 'Unknown'
GROUP BY credit_history
ORDER BY share_of_approvals DESC;
		/* Applicants with credit history are approved ~80% of the time vs ~8% without. 
		   Also, if 'Unknown' credit history is ignored, ~98% of approved applications come from 'Yes' group. */

-- 3) Income brackets vs Approval Probability
WITH income_bins AS (
	SELECT
		CASE
			WHEN total_income < 4000 THEN 'Low Income'
			WHEN total_income BETWEEN 4000 AND 7000 THEN 'Mid Income'
			ELSE 'High Income'
		END AS income_group,
		loan_status
	FROM loans
)

SELECT
	income_group,
	ROUND(
		SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
	,2) AS approval_rate,
	COUNT(*) AS applicants
FROM income_bins
GROUP BY income_group
ORDER BY approval_rate DESC;
	/* There is no big difference between approval rates of different income groups 
	  since the applicants with bigger income tend to apply for bigger loans */

-- 4) Debt-to-income(DTI) and Rejection Patterns
WITH dti_groups AS (
	SELECT
		CASE
			WHEN dti < 5 THEN 'Low DTI'
			WHEN total_income BETWEEN 5 AND 10 THEN 'Moderate DTI'
			ELSE 'High DTI'
		END AS dti_band,
		loan_status
	FROM loans
)

SELECT
	dti_band,
	ROUND(
		SUM(CASE WHEN loan_status = 'Approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
	,2) AS approval_rate,
	COUNT(*) AS applicants
FROM dti_groups
GROUP BY dti_band
ORDER BY approval_rate DESC;

-- 5) Applicants with the highest loan-to-income (yearly) ratio (risk exposure)
WITH loan_risk AS (
	SELECT
		loan_id,
		applicant_income,
		loan_amount,
		ROUND(loan_amount / NULLIF(applicant_income*12, 0), 2) AS lti,
		loan_status
	FROM loans
)

SELECT
	loan_id,
	loan_status,
	lti,
	RANK() OVER(ORDER BY lti DESC) AS risk_rank
FROM loan_risk
WHERE lti IS NOT NULL
	AND lti < 10 -- ignore outliers
ORDER BY lti DESC
LIMIT 10;