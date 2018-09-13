:setvar sqlcmdheaders           400    -- "page size"
:setvar sqlcmdcolwidth          150     -- line width
:setvar sqlcmdmaxfixedtypewidth  40     -- max column width (fixed length)
:setvar sqlcmdmaxvartypewidth    32     -- max column width (varying length)

SELECT login_name ,COUNT(session_id) AS session_count   
FROM sys.dm_exec_sessions   
GROUP BY login_name;  
Go
---------long runing SQL
USE master;  
GO  
SELECT creation_time ,cursor_id   
    ,convert(varchar(20),name)name ,c.session_id ,convert(varchar(20),login_name)login_name   
FROM sys.dm_exec_cursors(0) AS c   
JOIN sys.dm_exec_sessions AS s   
   ON c.session_id = s.session_id   
WHERE DATEDIFF(mi, c.creation_time, GETDATE()) > 5;  

/* exec sp_who 
go
 SELECT c.session_id 
 , c.auth_scheme 
 , CASE WHEN n.node_state_desc = 'ONLINE DAC' THEN 
 '*** DAC ***' 
 ELSE 
 'NORMAL' 
 END AS ConnectionType 
 , r.scheduler_id 
 , s.login_name 
 , db_name(s.database_id) AS database_name 
 , CASE s.transaction_isolation_level 
 WHEN 0 THEN 'Unspecified' 
 WHEN 1 THEN 'Read Uncomitted' 
 WHEN 2 THEN 'Read Committed' 
 WHEN 3 THEN 'Repeatable' 
 WHEN 4 THEN 'Serializable' 
 WHEN 5 THEN 'Snapshot' 
 END AS transaction_isolation_level 
 , s.status AS SessionStatus 
 , r.status AS RequestStatus 
 , st.text AS LastSQLStatement 
 , r.cpu_time 
 , r.reads 
 , r.writes 
 , r.logical_reads 
 , r.total_elapsed_time 
 FROM sys.dm_exec_connections c 
 CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) st 
 INNER JOIN sys.dm_exec_sessions s 
 ON c.session_id = s.session_id 
 INNER JOIN sys.dm_os_nodes n 
 ON n.node_id = c.node_affinity 
 LEFT JOIN sys.dm_exec_requests r 
 ON c.session_id = r.session_id 
order by database_name
Go


*/