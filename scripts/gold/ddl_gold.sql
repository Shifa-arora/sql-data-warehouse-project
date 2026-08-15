/*
   DDL Script: Create Gold Views

   Script Purpose:
        This script creates views for the Gold layer in the data warehouse.
        The Gold layer represents the final dimension and fact tables (Star Schema)

        Each view performs transformations and combines data from the silver layer
        to produce a clean, enriched, and business-ready dataset.

   Usage:
        - These views can be queried directly for analytics and reporting.
*/

-- =========================================================================
-- Create Dimension: gold.dim_customers
-- =========================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
--SELECT cst_id, COUNT(*) FROM(
-- Joining the **customers details** table
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) As customer_key, -- making a primary key (Surrogate Key)
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --CRM is the Master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender, -- remove ci.cst_gndr, ca.gen  
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
/* Tip:- After joining table, check if any duplicates were introduced by the join logic */
--)t GROUP BY cst_id HAVING COUNT(*) > 1 -- Empty means not have any duplicate


-- =========================================================================
-- Create Dimension: gold.dim_products
-- =========================================================================

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
--Check Quality (Uniquness)
--SELECT prd_key, COUNT(*) FROM(
-- joining the **Product's detail** table
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start, pn.prd_key) AS product_key,
	--sort the columns into logical groups to improve readability + Rename columns to friendly, meaningful names
	-- As these are dimension we have to create a primary key (Surrogate key)
	pn.prd_id AS product_id,
	pn.prd_key AS producct_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS ctegory_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_date IS NULL --Filter out all historical data 
--)t GROUP BY prd_key
--HAVING COUNT(*) > 1



/*
-- prove where the duplicates come from
SELECT 
    prd_key,
    COUNT(*) AS cnt
FROM silver.crm_prd_info
WHERE prd_end_date IS NULL
GROUP BY prd_key
HAVING COUNT(*) > 1;
--If this returns rows, you've found the problem. in crm_prd_info

SELECT 
    id,
    COUNT(*) AS cnt
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;
*/


-- =========================================================================
-- Create Dimension: gold.fact_sales
-- =========================================================================

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key,    -- remove sd.sls_prd_key
	cu.customer_key,   -- remove sd.sls_cust_id
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.producct_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id

/*
DIM or Fact ?
have Keys --> sls_ord_num, sls_prd_key, sls_cust_id
have Dates --> sls_order_dt, sls_ship_dt, sls_due_dt
have Measures --> sls_sales, sls_quantity, sls_price
These are connencting multiple dim --> Perfect Setup for Fact
*/

/* Building Fact --> Use the dimension's surrogate keys(those we generated) instead of IDs to easily connect fact with dimensions */

--Data LOOKUP -> 



--SELECT COUNT(*) AS total_rows
--silver.crm_sales_details;
