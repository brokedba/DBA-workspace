SET NOCOUNT ON;
use mydb
go
-- Create the temp table for further querying

CREATE TABLE #temp(

tbl_id int IDENTITY (1, 1),

tbl_name varchar(128),

rows_num int,

data_space decimal(15,2),

index_space decimal(15,2),

total_size decimal(15,2),

percent_of_db decimal(15,12),

db_size decimal(15,2))

-- Get all tables, names, and sizes

EXEC sp_msforeachtable @command1="insert into #temp(rows_num, data_space, index_space) exec sp_mstablespace '?'",

@command2="update #temp set tbl_name = '?' where tbl_id = (select max(tbl_id) from #temp)"
select * from #temp order by percent_of_db desc
-- Set the total_size and total database size fields

UPDATE #temp

SET total_size = (data_space + index_space), db_size = (SELECT SUM(data_space + index_space) FROM #temp)

-- Set the percent of the total database size

UPDATE #temp

SET percent_of_db = (total_size/db_size) * 100;

-- Get the data
--CTE : basic index information for every index
--join CTE output with the table size information
WITH temp_table(tbl_name,idx_name,last_user_update,user_updates,last_user_seek,last_user_scan,last_user_lookup,user_seeks,user_scans,user_lookups)
AS(
SELECT 
'[' + schema_name(tbl.schema_id) + '].['+object_name(ius.object_id)+']'
,six.name
,ius.last_user_update
,ius.user_updates
,ius.last_user_seek
,ius.last_user_scan
,ius.last_user_lookup
,ius.user_seeks
,ius.user_scans
,ius.user_lookups
FROM
sys.dm_db_index_usage_stats ius 
INNER JOIN sys.tables tbl ON (tbl.OBJECT_ID = ius.OBJECT_ID)
INNER JOIN sys.indexes six ON six.index_id = ius.index_id and six.object_id = tbl.OBJECT_ID
WHERE ius.database_id = DB_ID()

)
select t1.tbl_name,t2.idx_name,t1.rows_num,t1.data_space,t1.index_space,t1.total_size,t1.percent_of_db,t1.db_size,
t2.last_user_update,t2.user_updates,t2.last_user_seek,t2.last_user_scan,t2.last_user_lookup,t2.user_seeks,t2.user_scans,t2.user_lookups from 
#temp t1 LEFT JOIN temp_table t2 ON t1.tbl_name = t2.tbl_name
ORDER BY t1.total_size DESC

-- Comment out the following line if you want to do further querying

DROP TABLE #temp

