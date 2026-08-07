/*
=========================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
=========================================================
Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions:
  - Truncates the bronze tables before loading data.
  - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  EXEC bronze.load_bronze;
==============================================================

*/


-- DIFFERENCE BETWEEN INSERT AND BULK INSERT --
--INSERT --> Insert one or a few rows -> SQL values, another table, or query
--BULK INSERT --> Import a large number of rows from a file -> External file (CSV, TXT, etc.)


/*************IMPORTANT TO EXECUTE *****************/
--EXEC bronze.load_bronze;


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	SET @batch_start_time = GETDATE();
	BEGIN TRY
			PRINT '=========================';
			PRINT 'Loading Bronze Layer';
			PRINT '=========================';

	
			PRINT '-----------------------------';
			PRINT 'Loading CRM Tables';
			PRINT '-----------------------------';

			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.crm_cust_info';

			-- TRUNCATE -> Quickly delete all rows from a table, resetting it to an empty state
			TRUNCATE TABLE bronze.crm_cust_info; --Making table empty

			PRINT '>> Inserting Table: bronze.crm_cust_info';
			BULK INSERT bronze.crm_cust_info  -- loading data from scratch
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',     --FILE Delimeter --> , ; | # "
				TABLOCK                -- SQL Server locks the whole table during the import, which can make large imports faster.
			);

			SET @end_time = GETDATE();
			PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			-- DATEDIFF() --> Calculates the difference between two dates, returns days, months, or years
			
			PRINT '>> -----------';

			-- CHECK QUALITY OF BRONZE TABLE 
			--> Quality Check -> Check that the data has not shifted and is in the correct columns
			--SELECT * FROM bronze.crm_cust_info;
			--SELECT COUNT(*) FROM bronze.crm_cust_info

			-----------------------------

			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.crm_prd_info';
			TRUNCATE TABLE bronze.crm_prd_info; --Making table empty

			PRINT '>> Inserting Table: bronze.crm_prd_info';
			BULK INSERT bronze.crm_prd_info  -- loading data from scratch
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',     --FILE Delimeter --> , ; | # "
				TABLOCK
			);
			SET @end_time = GETDATE();
			PRINT '>> LoadDuration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>--------------';
			--SELECT COUNT(*) FROM bronze.crm_prd_info

			-----------------------------

			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.crm_sales_details';
			TRUNCATE TABLE bronze.crm_sales_details; --Making table empty

			PRINT '>> Inserting Table: bronze.crm_sales_details';
			BULK INSERT bronze.crm_sales_details  -- loading data from scratch
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',     --FILE Delimeter --> , ; | # "
				TABLOCK
			);
			SET @end_time = GETDATE();
			PRINT '>> LoadDuration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>--------------';
			--SELECT COUNT(*) FROM bronze.crm_sales_details

			PRINT '-----------------------------';
			PRINT 'Loading ERP Tables';
			PRINT '-----------------------------';


			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.erp_cust_az12';
			TRUNCATE TABLE bronze.erp_cust_az12; --Making table empty

			PRINT '>> Inserting Table: bronze.erp_cust_az12';
			BULK INSERT bronze.erp_cust_az12  -- loading data from scratch
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',     --FILE Delimeter --> , ; | # "
				TABLOCK
			);
			SET @end_time = GETDATE();
			PRINT '>> LoadDuration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>--------------';
			--SELECT COUNT(*) FROM bronze.erp_cust_az12

			-----------------------------

			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.erp_loc_a101';
			TRUNCATE TABLE bronze.erp_loc_a101; --Making table empty

			PRINT '>> Inserting Table: bronze.erp_loc_a101';
			BULK INSERT bronze.erp_loc_a101  -- loading data from scratch
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',     --FILE Delimeter --> , ; | # "
				TABLOCK
			);
			SET @end_time = GETDATE();
			PRINT '>> LoadDuration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>--------------';
			--SELECT COUNT(*) FROM bronze.erp_loc_a101

			-----------------------------

			SET @start_time = GETDATE();
			PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
			TRUNCATE TABLE bronze.erp_px_cat_g1v2;

			PRINT '>> Inserting Table: bronze.erp_px_cat_g1v2';
			BULK INSERT bronze.erp_px_cat_g1v2
			FROM 'D:\SQL Learning\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
			);
			SET @end_time = GETDATE();
			PRINT '>> LoadDuration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT '>>--------------';
			--SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2

		END TRY
		---------- if there is any error in try then catch is going to run ----------
		BEGIN CATCH
			PRINT '====================='
			PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
			PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
			PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
			----- TRACK ETL DURATION -> Helps the identify bottlenecks, optimize performance, monitor trends, detect issues ---------
			PRINT '====================='
		END CATCH
		SET @batch_end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
END

/*********************CREATED STORED PROCEDURE***********************/

-- (hint: Save frequently used SQL code in stored procedures in database

--CREATE OR ALTER PROCEDURE bronze.load_bronze AS (As first line)
--> BEGIN END
