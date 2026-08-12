/*
=========================================================
Quality Checks
=========================================================
Script Purpose:

    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schemas. It includes checks for:
    
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:

    - Run these checks after data loading Silver layer.
    - Investigate and resolve any discrepancies found during the checks.
=========================================================
*/


------------*********QUALITY CHECKS*********------------

-- Check for nulls or duplicates in Primary Key
-- Expectation: No Result

SELECT
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL

--> give duplicates |^|

SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL

--> do not have duplicates so blank page



-- NO Repetation --
SELECT 
*
FROM (
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
)t WHERE flag_last = 1 AND cst_id = 29466


--------------------------------------------------------


-- Check for unwanted spaces --
SELECT 
	cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT 
	cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

--=============

SELECT 
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

SELECT 
	cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

--=============

SELECT 
	cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

SELECT 
	cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

-- Data Standarization & Comsistency
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

SELECT * FROM silver.crm_cust_info


------------------- crm.prd.info -------------------------

SELECT 
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

SELECT 
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

--Check for unwanted spaces
--Expectation: No Results
SELECT 
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

SELECT 
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

--Check for NULLs or Negative Numbers
--Expectation: No Results
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL 

SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL 


--Data Standardiztion & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

SELECT DISTINCT prd_line
FROM silver.crm_prd_info

--Check for Invalid Dates
SELECT * FROM bronze.crm_prd_info
WHERE prd_end_date < prd_start

SELECT * FROM silver.crm_prd_info
WHERE prd_end_date < prd_start


------------------- crm_sales_details -------------------------


--Check for invalid dates
SELECT
	NULLIF(sls_order_dt, 0 ) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 --Checking Negative or zero
OR LEN(sls_order_dt) != 8 -- length should be 8
OR sls_order_dt > 20500101 OR sls_order_dt < 19000101 -- Check for outliners by validating the boundaries of the data range

--Check for shipping dates
SELECT
	NULLIF(sls_ship_dt, 0 ) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 --Checking Negative or zero
OR LEN(sls_ship_dt) != 8 -- length should be 8
OR sls_ship_dt > 20500101 OR sls_ship_dt < 19000101 -- Check for outliners by validating the boundaries of the data range

--Check for due dates
SELECT
	NULLIF(sls_due_dt, 0 ) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 --Checking Negative or zero
OR LEN(sls_due_dt) != 8 -- length should be 8
OR sls_due_dt > 20500101 OR sls_due_dt < 19000101 -- Check for outliners by validating the boundaries of the data range

--Check for Invalid Date Orders
SELECT * 
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_ship_dt

SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_ship_dt

--Check Data Consistency: Between Sales,Quantity and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
SELECT DISTINCT
	sls_sales AS old_sls_sales,
	sls_quantity,
	sls_price AS old_sls_price,

	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,

	CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END sls_price

FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
--SOLUTION1: Data Issues will be fixed direct in source system (By business Analyst)
--SOLUTION2: Data issues has to be fixed in data warehouse
-- Rules:-
/* 1. If sales is negative, zero, or null, derive it using Quantity and Price
2. If Price is Zero or null, Calculate it using Sales and Quantity
3. If Price is negative, convert it to a positive value */

SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-->Final Check 
SELECT * FROM silver.crm_sales_details
