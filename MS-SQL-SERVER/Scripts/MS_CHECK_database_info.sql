SELECT 
          SERVERPROPERTY('MachineName') as Host,
          SERVERPROPERTY('InstanceName') as Instance,
          SERVERPROPERTY('Edition') as Edition, /*shows 32 bit or 64 bit*/
          SERVERPROPERTY('ProductLevel') as ProductLevel, /* RTM or SP1 etc*/
          Case SERVERPROPERTY('IsClustered') when 1 then 'CLUSTERED' else
      'STANDALONE' end as ServerType,
          @@VERSION as Version 
----TABLES          
USE BILODEAU
SELECT  count(*) nbr_tables  from sys.tables  ;
EXEC sp_msforeachtable  'sp_mstablespace ''?''';
select * from #temp

------INDEX
SELECT OBJECT_SCHEMA_NAME(p.object_id) AS [Schema]
    , OBJECT_NAME(p.object_id) AS [Table]
    , i.name AS Index_NAME
    , p.partition_number
    , p.rows AS [Row Count]
    , i.type_desc AS [Index Type],
    USER_SEEKS, 
    USER_SCANS, 
	USER_LOOKUPS, 
	USER_UPDATES 
FROM sys.partitions p
left outer JOIN sys.indexes i ON (p.object_id = i.object_id AND p.index_id = i.index_id)
inner join    SYS.DM_DB_INDEX_USAGE_STATS AS S  ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
WHERE OBJECT_SCHEMA_NAME(p.object_id) = 'dbo'
ORDER BY [Schema], [Table], Index_NAME


--DMV To view Missing indexes 
use BILODEAU
   SELECT statement TABLENAME,equality_columns,CONVERT (decimal (28,1),
igs.avg_total_user_cost * igs.avg_user_impact * (igs.user_seeks + igs.user_scans)
) AS improvement_measure,included_columns,user_seeks,user_scans,avg_total_user_cost,avg_user_impact,last_user_seek,
'CREATE INDEX missing_index_' + CONVERT (varchar, ig.index_group_handle) + '_' + CONVERT (varchar, id.index_handle)
+ ' ON ' + id.statement
+ ' (' + ISNULL (id.equality_columns,'')
+ CASE WHEN id.equality_columns IS NOT NULL AND id.inequality_columns IS NOT NULL THEN ',' ELSE '' END 
+ ISNULL (id.inequality_columns, '')+ ')'+ ISNULL (' INCLUDE (' + id.included_columns + ')', '') AS create_index_statement  
   from sys.dm_db_missing_index_group_stats AS igs
   JOIN 
   sys.dm_db_missing_index_groups as ig ON igs.group_handle=ig.index_group_handle
   JOIN
   sys.dm_db_missing_index_details as id ON ig.index_handle=id.index_handle
   where DB_NAME(database_id) like 'BILODEAU%'
   declare @Mydb varchar(20)
   set @Mydb='BILODEAU'
   ---Use Database tuning advisor based on activity sample (using a trace on day activity) 
   
-- DMV   to view unused index
    SELECT  DB_NAME(database_id) dbname,statement,equality_columns,OBJECT_NAME(object_id),included_columns,user_seeks,user_scans,avg_total_user_cost,avg_user_impact,last_user_seek  
   from sys.dm_db_missing_index_group_stats AS igs
   JOIN 
   sys.dm_db_missing_index_groups as ig ON igs.group_handle=ig.index_group_handle
   JOIN
   sys.dm_db_missing_index_details as id ON ig.index_handle=id.index_handle
   where DB_NAME(database_id) like @Mydb
   order by statement,avg_user_impact
---  Index Fragmentation			              
SELECT d.name,object_name(o.object_id) Tab,o.name,  a.* FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'DETAILED') a  
 join sys.databases d on a.database_id =d.database_id
 join sys.indexes o on ( a.object_id=o.object_id and a.index_id=o.index_id)
 order by 13 desc