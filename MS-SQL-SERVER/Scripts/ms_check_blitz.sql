---Urgent issues
exec sp_Blitz @IgnorePrioritiesAbove = 50,@OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'BlitzResults';

--- Index check 
EXEC sp_BlitzIndex @DatabaseName='Medipay_c158_QA' 
EXEC dbo.sp_BlitzIndex @DatabaseName='Medipay_c158_QA', @SchemaName='dbo', @TableName='tblAuditREM';

---- Real-Time Performance Advice
EXEC sp_BlitzFirst  @Seconds=60, @OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'BlitzFirstResults',@OutputTableNameFileStats='BlitzFirstResults_FileStats',@OutputTableNamePerfmonStats='BlitzFirstResults_PerfmonStats',@OutputTableNameWaitStats='BlitzFirstResults_WaitStats'


----- Find the Most Resource-Intensive Queries
Exec sp_BlitzCache @ExpertMode = 1,@OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'BlitzCacheResults';
--
select * from dbo.BlitzCacheResults
--More Info
EXEC sp_BlitzCache @OnlySqlHandles = '0x03000F0095555D02960B1600ED9F00000100000000000000'; 

------ maintanance Solution
EXECUTE dbo.DatabaseIntegrityCheck @Databases = 'USER_DATABASES',@CheckCommands = 'CHECKDB'

---SNAPSHOT VIEWS
DECLARE @CheckDateStart VARCHAR(50) = '2016-09-22 11:46 -07:00';
DECLARE @CheckDateEnd VARCHAR(50) = DATEADD(DAY, 1, CAST(@CheckDateStart AS DATETIMEOFFSET));
SELECT wait_type, SUM(wait_time_ms_delta / 60 / 1000) AS wait_time_minutes, SUM(waiting_tasks_count_delta) AS waiting_tasks
FROM DBAtools.dbo.BlitzFirstResults_WaitStats_Deltas d
WHERE d.CheckDate BETWEEN @CheckDateStart AND @CheckDateEnd
AND ServerName = 'MCRORAT02\SQL2016'
GROUP BY wait_type
HAVING SUM(waiting_tasks_count_delta) > 0
ORDER BY 2 DESC;

SELECT object_name, counter_name, MIN(CheckDate) AS CheckDateMin, MAX(CheckDate) AS CheckDateMax,
   MIN(cntr_value) AS cntr_value_min, MAX(cntr_value) AS cntr_value_max,
   (1.0 * MAX(cntr_value) - MIN(cntr_value)) / (DATEDIFF(ss,MIN(CheckDate), MAX(CheckDate))) AS BatchRequestsPerSecond
FROM DBAtools.dbo.BlitzFirstResults_PerfmonStats d
WHERE d.CheckDate BETWEEN @CheckDateStart AND @CheckDateEnd
AND ServerName = 'MCRORAT02\SQL2016'
GROUP BY object_name, counter_name
ORDER BY 1, 2;

SELECT DatabaseName, TypeDesc, FileLogicalName, DatabaseID, FileID,
   MIN(CheckDate) AS CheckDateMin, MAX(CheckDate) AS CheckDateMax,
   MAX(num_of_reads) - MIN(num_of_reads) AS Reads,
   (MAX(bytes_read) - MIN(bytes_read)) / 1024.0 / 1024 AS ReadsMB,
   ISNULL((MAX(bytes_read * 1.0) - MIN(bytes_read)) / NULLIF((MAX(num_of_reads) - MIN(num_of_reads)),0) / 1024, 0) AS ReadSizeAvgKB,
   ISNULL((MAX(io_stall_read_ms) - MIN(io_stall_read_ms)) / NULLIF((MAX(num_of_reads * 1.0) - MIN(num_of_reads)), 0), 0) AS ReadAvgStallMS,
   MAX(num_of_writes) - MIN(num_of_writes) AS Writes,
   (MAX(bytes_written) - MIN(bytes_written)) / 1024.0 / 1024 AS WritesMB,
   ISNULL((MAX(bytes_written * 1.0) - MIN(bytes_written)) / NULLIF((MAX(num_of_writes) - MIN(num_of_writes)),0) / 1024, 0) AS WriteSizeAvgKB,
   ISNULL((MAX(io_stall_write_ms) - MIN(io_stall_write_ms)) / NULLIF((MAX(num_of_writes * 1.0) - MIN(num_of_writes)), 0), 0) AS WriteAvgStallMS
FROM DBAtools.dbo.BlitzFirstResults_FileStats d
WHERE d.CheckDate BETWEEN @CheckDateStart AND @CheckDateEnd
AND ServerName = 'MCRORAT02\SQL2016'
GROUP BY DatabaseName, TypeDesc, FileLogicalName, DatabaseID, FileID
HAVING MAX(num_of_reads) > MIN(num_of_reads) OR MAX(num_of_writes) > MIN(num_of_writes)
ORDER BY DatabaseName, TypeDesc, FileLogicalName, DatabaseID, FileID;