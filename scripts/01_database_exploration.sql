/*
===============================================================================
Database Exploration Script
===============================================================================

Purpose:
    - Explore tables and schemas.
    - Inspect column-level metadata for all or specific tables.
    - Show row counts and relationships (PK/FK).

Target Schema: gold

===============================================================================
*/

-- List all tables in the current database (optionally filter by schema)
PRINT 'Step 1: Listing all user-defined tables in the gold schema...';

SELECT
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_SCHEMA = 'gold'   -- remove or comment this line to include all schemas
ORDER BY TABLE_NAME;
GO

-- Show row counts for each table (only in 'gold' schema)
PRINT 'Step 2: Displaying row counts per table in schema gold...';

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
  AND s.name = 'gold'
GROUP BY s.name, t.name
ORDER BY TotalRows DESC;
GO

-- Show column metadata for all tables in gold schema
PRINT 'Step 3: Retrieving column metadata for all tables in schema gold...';

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT,
    COLLATION_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

-- Show primary key constraints in gold schema
PRINT 'Step 4: Listing primary key constraints for gold schema...';

SELECT
    t.name AS TableName,
    i.name AS PrimaryKeyName,
    c.name AS ColumnName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE s.name = 'gold'
ORDER BY TableName;
GO

-- Show foreign key constraints in gold schema
PRINT 'Step 5: Listing foreign key relationships for gold schema...';

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ParentTable,
    c1.name AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    c2.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE SCHEMA_NAME(OBJECTPROPERTY(fk.object_id, 'SchemaId')) = 'gold'
ORDER BY ParentTable, ForeignKeyName;
GO

-- View column data types and row counts dynamically (Table Summary View)
PRINT 'Step 6: Building dynamic summary for all tables...';

PRINT 'Database exploration completed successfully.';
