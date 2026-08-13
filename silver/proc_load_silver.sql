/*
=============================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==============================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Transform, Load) process to populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
  -Truncates Silver tables.
  -Inserts transformed and cleansed data from Bronze into Silver tables.
Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.
Usage Example:
  EXEC Silver.load_silver;
=============================================
*/


--EXEC silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.crm_cust_info;
	END;

	INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date 
	)
	-- Cleaning and Loading crm_crust_info --
	SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_fristname,
		TRIM(cst_lastname) AS cst_lastname,
	
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			ELSE 'n/a'
		END cst_marital_status,
	
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END cst_gndr,
		cst_create_date
	FROM (
		SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
	)t WHERE flag_last = 1


	----------------------------------------------------


	IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.crm_prd_info;
	END;

	INSERT INTO silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start,
		prd_end_date
	)
	SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1, 5),'-', '_') AS cat_id,
		SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
		prd_nm,
		ISNULL(prd_cost, 0) AS prd_cost,
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start AS DATE) AS prd_start,
		CAST(LEAD(prd_start) OVER(PARTITION BY prd_key ORDER BY prd_start) -1 AS DATE) AS prd_end_date    -- Calculate end date as one day before the next start date --> Data Enrichment            
	FROM bronze.crm_prd_info
	/*
	-- keep the products whose extracted product key is found in the sales table.
	WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) IN  
	-- (SELECT distinct id FROM bronze.erp_px_cat_g1v2) --> To check in px_cat csv file which have different id 
	(SELECT sls_prd_key FROM bronze.crm_sales_details)

	/*
	-- Only return products whose cat_id is NOT found in bronze.crm_sales_details.sls_prd_key
	WHERE REPLACE(SUBSTRING(prd_key, 1, 5),'-', '_') NOT IN  
	-- (SELECT distinct id FROM bronze.erp_px_cat_g1v2) --> To check in px_cat csv file which have different id 
	(SELECT sls_prd_key FROM bronze.crm_sales_details)
	*/
	*/


	-------------------------------------------------------


	IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.crm_prd_info;
	END;

	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,

		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,

		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,

		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,

		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,

		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE sls_price
		END sls_price
	FROM bronze.crm_sales_details;

	--SELECT * FROM bronze.crm_cust_info
	--WHERE sls_ord_num != TRIM(sls_ord_num)
	--WHERE sls_prd_key NOT IN (SELECT sls_prd_key FROM silver.crm_prd_info)
	--WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)


	--===================erp======================


	IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.erp_cust_az12;
	END;

	INSERT INTO silver.erp_cust_az12 (
		cid,
		bdate,
		gen
	)
	SELECT
		cid,
		bdate,
		gen
	FROM (
		SELECT 
			CASE 
				WHEN cid LIKE 'NAS%' 
					THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END AS cid,

			CASE 
				WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END AS bdate,

			CASE 
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen,

			ROW_NUMBER() OVER (
				PARTITION BY 
					CASE 
						WHEN cid LIKE 'NAS%' 
							THEN SUBSTRING(cid, 4, LEN(cid))
						ELSE cid
					END
				ORDER BY bdate DESC
			) AS rn

		FROM bronze.erp_cust_az12
	) t
	WHERE rn = 1;

	---DATA QUALITY---
	/*
	SELECT DISTINCT
	bdate
	FROM silver.erp_cust_az12
	WHERE bdate < '1924-01-01' OR bdate > GETDATE()
	--WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
			--ELSE cid
		--END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)


	/*SELECT DISTINCT 
	CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END
	FROM bronze.erp_cust_az12*/
	SELECT DISTINCT 
	CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END
	FROM silver.erp_cust_az12
	--SELECT * FROM bronze.erp_cust_az12
	*/


	-------------------------------------------------------


	IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.erp_loc_a101;
	END;

	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
	)
	SELECT
		cid,
		cntry
	FROM (
		SELECT
			REPLACE(cid, '-', '') AS cid,

			CASE 
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry,

			ROW_NUMBER() OVER (
				PARTITION BY REPLACE(cid, '-', '')
				ORDER BY 
					CASE 
						WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 1
						ELSE 0
					END
			) AS rn

		FROM bronze.erp_loc_a101
	) t
	WHERE rn = 1;

	-- WHERE REPLACE(cid,'-','') NOT IN (SELECT cst_key FROM silver.crm_cust_info)

	--- DATA CHECK ---
	--SELECT cst_key FROM silver.crm_cust_info

	/*-- Data Standarization & Consistency --
	SELECT DISTINCT cntry AS old,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
			WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry
	FROM bronze.erp_loc_a101 ORDER BY cntry

	SELECT DISTINCT cntry FROM silver.erp_loc_a101
	*/


	-------------------------------------------------------


	IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	BEGIN
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
	END;

	INSERT INTO silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
	)

	SELECT 
		id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2

	/*
	SELECT cat_id FROM silver.crm_prd_info
	-- Check for unwanted Spaces
	SELECT * FROM bronze.erp_px_cat_g1v2 WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)
	-- Data Standarization & Consistency
	SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2
	SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2
	*/

	--SELECT * FROM silver.erp_px_cat_g1v2
END
