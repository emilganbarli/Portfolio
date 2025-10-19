# TelSis Churn Analysis

## About the Project
This project analyzes customer churn behavior for a fictional telecom company, **TelSis**.  
The goal is to identify key factors driving churn and to visualize actionable insights through an interactive Tableau dashboard.  
The workflow covers **data preparation (SQL)**, **business analysis (SQL)**, and **visual storytelling (Tableau)**.

## Data
The dataset contains **6,600+ customer records** with details such as:
- Contract type, payment method, and service usage
- Monthly charges, tenure, and customer satisfaction
- Demographics (gender, age, location)

Source file: `data/telsis_data.csv`

## SQL Queries
1. **Data Preparation (`01_telsis_data_prep.sql`)**  
   - Cleaned missing values, standardized field names  
   - Created new analytical fields (e.g., tenure groups, churn flag, service counts)  

2. **Business Questions (`02_business_questions.sql`)**  
   - Contains 15 analytical queries exploring churn rate by demographics, contract type, and service features  
   - Results guided the Tableau visual design and key metrics  

## Tableau Dashboard

[![Preview 1](tableau/preview_1.png)](https://public.tableau.com/views/telsis_churn/ChurnDashboard)
[![Preview 2](tableau/preview_2.png)](https://public.tableau.com/views/telsis_churn/ChurnDashboard)
[![Preview 3](tableau/preview_3.png)](https://public.tableau.com/views/telsis_churn/ChurnDashboard)
[![Preview 4](tableau/preview_4.png)](https://public.tableau.com/views/telsis_churn/ChurnDashboard)
Option B — 2×2 grid (uses HTML for sizing):
