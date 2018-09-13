SELECT HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE');
SELECT HAS_PERMS_BY_NAME('SqL_USER_C', 'LOGIN', 'IMPERSONATE'); 
SELECT HAS_PERMS_BY_NAME(db_name(), 'DATABASE', 'ANY'); --current has any permission in current DB
SELECT HAS_PERMS_BY_NAME(QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name),'OBJECT', 'SELECT') AS have_select, * FROM sys.tables  
SELECT HAS_PERMS_BY_NAME('Sales.SalesPerson', 'OBJECT', 'INSERT');  
SELECT * FROM sys.securable_classes ORDER BY class;   