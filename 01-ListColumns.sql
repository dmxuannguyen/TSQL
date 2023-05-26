/*************************************************************************
**
**		Query below lists all table columns in a database.
**
*************************************************************************/

select schema_name(tab.schema_id) as schema_name,
    tab.name as table_name, 
    col.column_id,
    col.name as column_name, 
    t.name as data_type,    
    col.max_length,
    col.precision
from sys.tables as tab
    inner join sys.columns as col
        on tab.object_id = col.object_id
    left join sys.types as t
    on col.user_type_id = t.user_type_id
order by schema_name,
    table_name, 
    column_id;

/*
Columns
schema_name - schema name
table_name - table name
column_id - table column id, starting at 1 for each table
column_name - name of column
data_type - column data type
max_length - data type max length
precision - data type precision
*/

/*
One row represents one table column
Scope of rows: all columns in all tables in a database
Ordered by schema, table name, column id
*/

-----------------------------------------------

/*
Fetch Column Names of Table using SQL Query
The INFORMATION_SCHEMA.COLUMNS table returns information about all columns within a Database. A SELECT statement needs to be executed over the table and the Table Name whose Column names needs to be fetched is displayed in WHERE clause.
Syntax
*/
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Your Table Name'
ORDER BY ORDINAL_POSITION

-----------------------------------------------
