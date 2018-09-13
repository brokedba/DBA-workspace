Select
S.[name] as 'Dependent_Tables'
From
sys.objects S inner join sys.sysreferences R
on S.object_id = R.rkeyid
Where
S.[type] = 'U' AND
R.fkeyid = OBJECT_ID('tablename')
-- Another method

SELECT DISTINCT name, so.type 
FROM sys.objects AS so 
INNER JOIN sys.sql_expression_dependencies AS sed 
ON so.object_id = sed.referencing_id 
WHERE sed.referenced_id = OBJECT_ID('[tablename]');