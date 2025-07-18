/*
===========================================================================
DataWarehouseAnalytics Setup Script with Logging and Enhancements
===========================================================================

This script:
    1. Drops and recreates the 'DataWarehouseAnalytics' database.
    2. Creates 'gold' schema and dimension/fact tables with proper constraints.
    3. Creates metadata logging tables for tracking bulk inserts.
    4. Uses a stored procedure for modular, reusable data loading with auditing.
    5. Adds indexes and constraints for performance and integrity.

IMPORTANT:
    Ensure the CSV files exist and are accessible at the specified path.
    All previous data will be lost as the database will be dropped and recreated.

===========================================================================
*/

-- Use the master context for DB-level operations
USE master;
GO

PRINT 'Step 1: Dropping existing database if it exists...';

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
    PRINT 'Existing DataWarehouseAnalytics database dropped.';
END
ELSE
BEGIN
    PRINT 'No existing DataWarehouseAnalytics database found.';
END;
GO

-- Create new database
PRINT 'Step 2: Creating new DataWarehouseAnalytics database...';
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO
PRINT 'Using new database: DataWarehouseAnalytics';

-- Create schema if not exists
PRINT 'Step 3: Creating schema: gold...';
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'Schema "gold" created.';
END
ELSE
BEGIN
    PRINT 'Schema "gold" already exists.';
END;
GO

-- Metadata Logging Table
PRINT 'Step 4: Creating metadata logging table...';
CREATE TABLE gold.bulk_load_metadata (
    load_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name NVARCHAR(100),
    file_path NVARCHAR(500),
    load_start DATETIME,
    load_end DATETIME,
    rows_inserted INT,
    status NVARCHAR(20),
    error_message NVARCHAR(MAX)
);
GO

-- Creating Tables with Constraints
PRINT 'Step 5: Creating dimension and fact tables...';

CREATE TABLE gold.dim_customers (
    customer_key INT PRIMARY KEY,
    customer_id INT UNIQUE,
    customer_number NVARCHAR(50),
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    country NVARCHAR(50),
    marital_status NVARCHAR(50),
    gender NVARCHAR(50),
    birthdate DATE,
    create_date DATE,
    last_updated DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE gold.dim_products (
    product_key INT PRIMARY KEY,
    product_id INT UNIQUE,
    product_number NVARCHAR(50),
    product_name NVARCHAR(50),
    category_id NVARCHAR(50),
    category NVARCHAR(50),
    subcategory NVARCHAR(50),
    maintenance NVARCHAR(50),
    cost INT,
    product_line NVARCHAR(50),
    start_date DATE,
    last_updated DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE gold.fact_sales (
    order_number NVARCHAR(50) PRIMARY KEY,
    product_key INT FOREIGN KEY REFERENCES gold.dim_products(product_key),
    customer_key INT FOREIGN KEY REFERENCES gold.dim_customers(customer_key),
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount INT,
    quantity TINYINT,
    price INT,
    last_updated DATETIME DEFAULT GETDATE()
);
GO

-- Indexes
PRINT 'Step 6: Creating indexes...';

CREATE INDEX idx_sales_orderdate ON gold.fact_sales(order_date);
CREATE INDEX idx_customers_country ON gold.dim_customers(country);
CREATE INDEX idx_products_category ON gold.dim_products(category);
GO

-- Create Stored Procedure for Dynamic BULK INSERT
PRINT 'Step 7: Creating bulk insert stored procedure...';

CREATE OR ALTER PROCEDURE gold.usp_bulk_insert_data
    @TableName NVARCHAR(100),
    @FilePath NVARCHAR(500)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX),
            @RowCount INT = 0,
            @StartTime DATETIME = GETDATE(),
            @EndTime DATETIME;

    BEGIN TRY
        PRINT 'Starting data load for table: ' + @TableName;

        BEGIN TRANSACTION;

        -- Step A: Truncate target table
        SET @SQL = 'TRUNCATE TABLE gold.' + QUOTENAME(@TableName);
        EXEC sp_executesql @SQL;

        -- Step B: Perform BULK INSERT
        SET @SQL = '
            BULK INSERT gold.' + QUOTENAME(@TableName) + '
            FROM ''' + @FilePath + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );
        ';
        EXEC sp_executesql @SQL;

        -- Step C: Count inserted rows
        SET @SQL = 'SELECT @RC = COUNT(*) FROM gold.' + QUOTENAME(@TableName);
        EXEC sp_executesql @SQL, N'@RC INT OUTPUT', @RC = @RowCount OUTPUT;

        SET @EndTime = GETDATE();

        -- Step D: Log success
        INSERT INTO gold.bulk_load_metadata (
            table_name, file_path, load_start, load_end, rows_inserted, status
        )
        VALUES (
            @TableName, @FilePath, @StartTime, @EndTime, @RowCount, 'Success'
        );

        COMMIT TRANSACTION;

        PRINT 'Successfully loaded ' + CAST(@RowCount AS NVARCHAR) + ' rows into ' + @TableName;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        SET @EndTime = GETDATE();

        -- Step E: Log failure
        INSERT INTO gold.bulk_load_metadata (
            table_name, file_path, load_start, load_end, rows_inserted, status, error_message
        )
        VALUES (
            @TableName, @FilePath, @StartTime, @EndTime, 0, 'Failed', ERROR_MESSAGE()
        );

        PRINT 'Error occurred while loading ' + @TableName + ': ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- Load Data into Tables
PRINT 'Step 8: Loading data using the bulk insert procedure...';

EXEC gold.usp_bulk_insert_data 'dim_customers', 'datasets/csv-files/gold.dim_customers.csv';
EXEC gold.usp_bulk_insert_data 'dim_products', '/datasets/csv-files/gold.dim_products.csv';
EXEC gold.usp_bulk_insert_data 'fact_sales', '/datasets/csv-files/gold.fact_sales.csv';
GO

PRINT 'All data load operations completed successfully.';
