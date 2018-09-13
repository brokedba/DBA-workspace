SET NOCOUNT ON;

 SELECT  a.session_id ,a.command,s.status session_status,a.status TX_status ,a.blocking_session_id, s.login_name 'blocking user',
          a.wait_type ,a.wait_time ,a.wait_resource,a.transaction_id,
	  CASE s.transaction_isolation_level 
 WHEN 0 THEN 'Unspecified' 
 WHEN 1 THEN 'Read Uncomitted' 
 WHEN 2 THEN 'Read Committed' 
 WHEN 3 THEN 'Repeatable' 
 WHEN 4 THEN 'Serializable' 
 WHEN 5 THEN 'Snapshot' 
 END AS transaction_isolation_level, 
		  a.sql_handle, t.text as text
FROM sys.dm_exec_requests a CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) t
inner JOIN sys.dm_exec_sessions s ON a.blocking_session_id=s.session_id
join  sys.databases d ON a.database_id=d.database_id  
WHERE a.status = N'suspended';  
GO 






SELECT SPID,hostname,loginame,R.dbid,BLOCKED, REPLACE (REPLACE (T.TEXT, CHAR(10), ' '), CHAR (13), ' ' ) AS BATCH  
INTO #T
FROM sys.sysprocesses R CROSS APPLY sys.dm_exec_sql_text(R.SQL_HANDLE) T
GO
WITH BLOCKERS (SPID,hostname,loginame,dbid, BLOCKED, LEVEL, BATCH)
AS
(
SELECT SPID,hostname,loginame,dbid,
BLOCKED,
CAST (REPLICATE ('0', 4-LEN (CAST (SPID AS VARCHAR))) + CAST (SPID AS VARCHAR) AS VARCHAR (1000)) AS LEVEL,
BATCH FROM #T R
WHERE (BLOCKED = 0 OR BLOCKED = SPID)
AND EXISTS (SELECT * FROM #T R2 WHERE R2.BLOCKED = R.SPID AND R2.BLOCKED <> R2.SPID)
UNION ALL
SELECT R.SPID,R.hostname,R.loginame,R.dbid,
R.BLOCKED,
CAST (BLOCKERS.LEVEL + RIGHT (CAST ((1000 + R.SPID) AS VARCHAR (100)), 4) AS VARCHAR (1000)) AS LEVEL,
R.BATCH FROM #T AS R
INNER JOIN BLOCKERS ON R.BLOCKED = BLOCKERS.SPID WHERE R.BLOCKED > 0 AND R.BLOCKED <> R.SPID
)
SELECT N'    ' + REPLICATE (N'|         ', LEN (LEVEL)/4 - 1) +
CASE WHEN (LEN(LEVEL)/4 - 1) = 0
THEN 'HEAD -  '
ELSE '|------  ' END
+ CAST (SPID AS NVARCHAR (10)) + N' '+ ''+ BATCH AS BLOCKING_TREE ,loginame,hostname,
CASE   
       WHEN L.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN l.resource_type  
       WHEN L.resource_type = 'OBJECT' THEN OBJECT_NAME(L.resource_associated_entity_id, SP.dbid)  
       WHEN L.resource_type IN ('KEY', 'PAGE', 'RID') THEN   
           (  
           SELECT OBJECT_NAME([object_id])  
           FROM sys.partitions  
           WHERE sys.partitions.hobt_id =   
             L.resource_associated_entity_id  
           )  
       ELSE 'Unidentified'  END requested_object_name,L.request_mode, L.request_status, r.wait_type,r.wait_time / (1000.0) wait_time, r.cpu_time,r.total_elapsed_time / (1000.0) elapsed,r.status
FROM BLOCKERS SP  
LEFT JOIN ( sys.dm_tran_locks l    
JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id 
INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id ) ON L.request_session_id = SP.spid
ORDER BY LEVEL ASC
GO
DROP TABLE #T
GO 




/*
SELECT substring(login_name,1,30)LoginName, substring(host_name,1,15)Host, request_session_id Session, s.cpu_time Temps, OBJECT_NAME(p.OBJECT_ID)Entite 
FROM sys.dm_tran_locks l JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id 
LEFT JOIN sys.partitions p ON p.hobt_id = l.resource_associated_entity_id 
WHERE s.session_id > 50 
AND resource_associated_entity_id > 0 
AND resource_database_id = DB_ID() 
AND lower(CASE WHEN lower(l.resource_type) = 'object' THEN OBJECT_NAME(l.resource_associated_entity_id) 
ELSE OBJECT_NAME(p.OBJECT_ID) END) like '%' 
group by login_name, host_name, request_session_id, s.cpu_time, OBJECT_NAME(p.OBJECT_ID)

---- query 2
SELECT DTL.resource_type,  
   CASE   
       WHEN DTL.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN DTL.resource_type  
       WHEN DTL.resource_type = 'OBJECT' THEN OBJECT_NAME(DTL.resource_associated_entity_id, SP.[dbid])  
       WHEN DTL.resource_type IN ('KEY', 'PAGE', 'RID') THEN   
           (  
           SELECT OBJECT_NAME([object_id])  
           FROM sys.partitions  
           WHERE sys.partitions.hobt_id =   
             DTL.resource_associated_entity_id  
           )  
       ELSE 'Unidentified'  
   END AS requested_object_name, DTL.request_mode, DTL.request_status,  
   DEST.TEXT, SP.spid, SP.blocked, SP.status, SP.loginame 
FROM sys.dm_tran_locks DTL  
   INNER JOIN sys.sysprocesses SP  
       ON DTL.request_session_id = SP.spid   
   --INNER JOIN sys.[dm_exec_requests] AS SDER ON SP.[spid] = [SDER].[session_id] 
   CROSS APPLY sys.dm_exec_sql_text(SP.sql_handle) AS DEST  
WHERE SP.dbid = DB_ID('virtuo')  
   AND DTL.[resource_type] <> 'DATABASE' 
ORDER BY DTL.[request_session_id];

--- query 3

SET NOCOUNT ON
GO
SELECT SPID, BLOCKED, REPLACE (REPLACE (T.TEXT, CHAR(10), ' '), CHAR (13), ' ' ) AS BATCH
INTO #T
FROM sys.sysprocesses R CROSS APPLY sys.dm_exec_sql_text(R.SQL_HANDLE) T
GO
WITH BLOCKERS (SPID, BLOCKED, LEVEL, BATCH)
AS
(
SELECT SPID,
BLOCKED,
CAST (REPLICATE ('0', 4-LEN (CAST (SPID AS VARCHAR))) + CAST (SPID AS VARCHAR) AS VARCHAR (1000)) AS LEVEL,
BATCH FROM #T R
WHERE (BLOCKED = 0 OR BLOCKED = SPID)
AND EXISTS (SELECT * FROM #T R2 WHERE R2.BLOCKED = R.SPID AND R2.BLOCKED <> R2.SPID)
UNION ALL
SELECT R.SPID,
R.BLOCKED,
CAST (BLOCKERS.LEVEL + RIGHT (CAST ((1000 + R.SPID) AS VARCHAR (100)), 4) AS VARCHAR (1000)) AS LEVEL,
R.BATCH FROM #T AS R
INNER JOIN BLOCKERS ON R.BLOCKED = BLOCKERS.SPID WHERE R.BLOCKED > 0 AND R.BLOCKED <> R.SPID
)
SELECT N'    ' + REPLICATE (N'|         ', LEN (LEVEL)/4 - 1) +
CASE WHEN (LEN(LEVEL)/4 - 1) = 0
THEN 'HEAD -  '
ELSE '|------  ' END
+ CAST (SPID AS NVARCHAR (10)) + N' ' + BATCH AS BLOCKING_TREE
FROM BLOCKERS  
 ORDER BY LEVEL ASC
GO
DROP TABLE #T
GO



Gathering Blocking Information
- Right-click the server object, expand Reports, expand Standard Reports, and then click Activity – All Blocking Transactions. This report shows the transactions at the head of blocking chain.
   If you expand the transaction, the report will show the transactions that are blocked by the head transaction. This report will also show the "Blocking SQL Statement" and the "Blocked SQL Statement."
- Use DBCC INPUTBUFFER(<spid>) to find the last statement that was submitted by a SPID.
- Find blocking transaction nested level : SELECT open_tran FROM master.sys.sysprocesses WHERE SPID=<blocking SPID number>
examine the sys.sysprocesses output to determine the heads of the blocking chains:
Status	          Meaning
---------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------- 
Background	    The SPID is running a background task, such as deadlock detection.
Sleeping	    The SPID is not currently executing. This usually indicates that the SPID is awaiting a command from the application.
Running	            The SPID is currently running on a scheduler.
Runnable	    The SPID is in the runnable queue of a scheduler and waiting to get scheduler time.
Sos_scheduler_yield The SPID was running, but it has voluntarily yielded its time slice on the scheduler to allow another SPID to acquire scheduler time.
Suspended	    The SPID is waiting for an event, such as a lock or a latch.
Rollback	    The SPID is in rollback of a transaction.
Defwakeup	    Indicates that the SPID is waiting for a resource that is in the process of being freed. The waitresource field should indicate the resource in question.

open_tran	Status	Lastwaittype waittype	waittime    Waitresource 
------------- --------- ------------ --------- ------------ -------------- 
1	      suspended LCK_M_X 	0x0005	1297703     PAG: 7:1:897039                                                                                                                                                                                                                                             

DBCC TRACEON (3604) 
DBCC PAGE ( 7 , 1 , 897039 )
DBCC TRACEOFF (3604) 
-- find the object name 
select object_name(656773447);

*/

Print '======================'
Print ' SPID= blocking_session_id'
print ' Kill SPID  // blocking session' 


