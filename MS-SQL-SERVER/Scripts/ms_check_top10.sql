---Return top 10 longest running queries
SELECT TOP (10)
	 qs.total_elapsed_time / qs.execution_count / 1000000.0 AS AverageSeconds
	,qs.total_elapsed_time / 1000000.0 AS TotalSeconds
	,qt.text AS Query
	,o.name AS ObjectName
	,DB_NAME (qt.dbid) AS DatabaseName
FROM
	sys.dm_exec_query_stats qs
		CROSS APPLY
	sys.dm_exec_sql_text(qs.sql_handle) AS qt
		LEFT OUTER JOIN
	sys.objects AS o ON qt.objectid=o.object_id
ORDER BY
	AverageSeconds DESC

---Return top 10 most expensive queries
SELECT TOP 10
	 (total_logical_reads + total_logical_writes) / qs.execution_count AS AverageIO
	,(total_logical_reads + total_logical_writes) AS TotalID
	,qt.text AS Query
	,o.name AS ObjectName
	,DB_NAME(qt.dbid) AS DatabaseName
FROM
	sys.dm_exec_query_stats AS qs
		CROSS APPLY
	sys.dm_exec_sql_text(qs.sql_handle) AS qt
		LEFT OUTER JOIN
	sys.objects AS o ON qt.objectid = o.object_id
ORDER BY 
	AverageIO DESC