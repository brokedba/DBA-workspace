SET NOCOUNT ON;
---SET ANSI_WARNINGS OFF; 
:setvar SQLCMDERRORLEVEL 1

print '=========================================================================================='
print ' context: $(DB) owner: $(owner) tab:$(tab)...'
Print 'For NEW VALUES RUN ==>>>example  '':setvar DB master owner:Humanresources tab:employee'''
print'==========================================================================================='
use $(DB)
Go
exec sp_help "$(owner).$(tab)"
go

/*
use AdventureWorks2012
exec sp_help "humanresources.employee"
exec sp_columns "humanresources.employee"

SELECT column_name AS [name],
       IS_NULLABLE AS [null?],
       DATA_TYPE + COALESCE('(' + CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1
                                  THEN 'Max'
                                  ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(5))
                                  END + ')', '') AS [type]
FROM   INFORMATION_SCHEMA.Columns
WHERE  table_name = "CHECK_CONSTRAINTS"
AND  Table_schema="INFORMATION_SCHEMA)";
go

:setvar DB  master
:setvar owner INFORMATION_SCHEMA
:setvar tab CHECK_CONSTRAINTS

--- Indexes
SELECT 
     schemas=OBJECT_SCHEMA_NAME(t.object_id,DB_ID()) ,
     TableName = t.name,
     IndexName = ind.name,
     indextype=ind.type_desc,
     ColumnName = col.name,
     data_type=tp.name,
     MXlength=col.max_length ,Precision=col.precision ,
     NULLABLE=col.is_nullable ,
     ISNULL(ind.is_primary_key, 0) 'Primary Key',
     ind.is_unique ,
     ic.is_included_column,
     col.is_identity 
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
     INNER JOIN 
    sys.types tp ON col.user_type_id = tp.user_type_id
WHERE 
     ind.is_primary_key = 0 
     AND ind.is_unique = 0 
     AND ind.is_unique_constraint = 0 
     AND t.is_ms_shipped = 0 
     and t.name='CHARTE'
ORDER BY 
     t.name, ind.name, ind.index_id, ic.index_column_id;

*/