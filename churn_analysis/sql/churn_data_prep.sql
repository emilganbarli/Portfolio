-- Duplicate check
SELECT
	COUNT(customer_id),
	COUNT(DISTINCT customer_id)
FROM telsis;
-- gender check
SELECT
	DISTINCT gender
FROM telsis;
-- age range check
SELECT
	MIN(age),
	MAX(age)
FROM telsis;


-- data prep
CREATE MATERIALIZED VIEW IF NOT EXISTS 	telsis_mw	AS 

SELECT
	-- key
	TRIM(customer_id) AS customer_id,
	
	-- numerics
	account_length_in_months AS tenure_months,
	local_calls,
	local_mins,
	intl_calls,
	intl_mins,
	COALESCE(extra_international_charges, 0) AS ext_intl_charges,
	COALESCE(extra_data_charges, 0) AS ext_data_charges,
	avg_monthly_gb_download AS avg_mo_gb,
	monthly_charge,
	total_charges,
	number_of_customers_in_group AS num_customers_grp,
	customer_service_calls AS cs_calls,
	

	-- booleans
	CASE churn_label
		WHEN true THEN 1 
		WHEN false THEN 0
		ELSE NULL
		END AS churn_flag,
	intl_active,
	intl_plan,
	unlimited_data_plan,
	under_30,
	senior,
	"group" AS grp,
	device_protection_online_backup AS device_protection,

	-- demographics
	age,
	LOWER(TRIM(gender)) AS gender,
	UPPER(TRIM(state)) AS state,

	-- phone number normalization regexp_replace
	REGEXP_REPLACE(COALESCE(phone_number, ''), '\D', '', 'g') AS phone_number,

	-- contracts, payments
	LOWER(TRIM(contract_type)) AS contract_type,
	LOWER(TRIM(payment_method)) AS payment_method,

	-- churn reasons
	NULLIF(LOWER(TRIM(churn_category)), '') AS churn_category,
	NULLIF(LOWER(TRIM(churn_reason)), '') AS churn_reason,

	-- addtional fields
	CASE   
		WHEN age <= 30 THEN 'adult'  -- min is 19
		WHEN age <= 55 THEN 'middle aged'
		WHEN age > 55 THEN 'elder'
		ELSE NULL
	END AS age_bucket,
	
	CASE  
		WHEN account_length_in_months IS NULL THEN NULL
		WHEN account_length_in_months < 13 THEN '00-12'
		WHEN account_length_in_months < 25 THEN '13-24'
		WHEN account_length_in_months < 37 THEN '25-36'
		WHEN account_length_in_months < 49 THEN '37-48'
		WHEN account_length_in_months < 61 THEN '49-60'
		ELSE '60+'
	END AS tenure_bucket,
	
	CASE  
		WHEN customer_service_calls IS NULL THEN NULL
		WHEN customer_service_calls >= 3 THEN '3+'
		ELSE customer_service_calls :: text
	END AS cs_calls_bucket,

	CASE 
		WHEN LOWER(TRIM(intl_plan :: text)) = 'true' AND LOWER(TRIM(intl_active :: text)) = 'true' THEN 'plan+active'
		WHEN LOWER(TRIM(intl_plan :: text)) = 'true' AND LOWER(TRIM(intl_active :: text)) = 'false' THEN 'plan+inactive'
		WHEN LOWER(TRIM(intl_plan :: text)) = 'false' AND LOWER(TRIM(intl_active :: text)) = 'true' THEN 'no plan+active' -- who doesn't have a plan but use intl
		WHEN LOWER(TRIM(intl_plan :: text)) = 'false' AND LOWER(TRIM(intl_active :: text)) = 'false' THEN 'no plan+inactive'
		ELSE 'unknown'
		END AS intl_usage_status

FROM telsis;

