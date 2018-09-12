set verify off
set feed off
-- alter sequence PERFSTAT.STATS$SNAPSHOT_ID nocache;
column module for a20
column instart_fmt noprint;
column  report_name new_value   report_name
column  instance_number new_value   instance_number
column  dbid        new_value   dbid
select dbid,instance_number from v$database,v$instance;
undefine num_days
prompt
prompt
prompt Specify the Begin and End Snapshot Ids 
set termout on;
prompt
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt  most recent(n) days of snapshots being listed.
prompt
column num_days new_value num_days noprint;
select    'Listing '
       || decode( nvl('&&num_days', to_number('3.14','9D99','nls_numeric_characters=''.,'''))
                , to_number('3.14','9D99','nls_numeric_characters=''.,'''), 'all Completed Snapshots'
                , 0                                                       , 'no snapshots'
                , 1                                                       , 'the last day''s Completed Snapshots'
                , 'the last &num_days days of Completed Snapshots')
     , nvl('&&num_days', to_number('3.14','9D99','nls_numeric_characters=''.,'''))  num_days 
  from dual;
set heading on

     select
        snap_id                 end_snap,
        lead(snap_id,1) over(order by snap_id)  next_snap,
        snap_level,snap_time
     from   stats$snapshot
     where  dbid        = &dbid
     and    instance_number = &instance_number
     and    trunc(snap_time) >= trunc(sysdate-&&num_days)
 order by   snap_id;

clear break;
ttitle off;

undefine begin_snap end_snap

prompt
prompt
prompt Specify the Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Begin Snapshot Id specified: &&begin_snap
prompt
prompt End   Snapshot Id specified: &&end_snap
prompt
  
prompt ********* TOP SQL ********
   
SELECT a.sql_id,b.avgcputime "CPU time (s/exec)", b.avgelapstime "Elaps. time (s/exec)",
  --a.sql_text "SQL statement",
MAX (c.COST) "Cost", b.executions "Execs", b.TIME "Last Active",b.executions "Executions", b.module "Module" ,a.text_subset
FROM stats$sqltext a, 
(SELECT DISTINCT sql_id, snap_id, executions, avgcputime, avgelapstime, module, 
TO_CHAR (last_active_time, 'dd-mm-yy hh24:mi') TIME 
FROM (SELECT DISTINCT sql_id, ROWNUM, snap_id, executions, 
ROUND (cpu_time / (executions * 1000000), 2) avgcputime, 
ROUND (elapsed_time / (executions * 1000000), 2) avgelapstime, 
module, last_active_time 
FROM stats$sql_summary 
WHERE executions != 0 
-- To get SQL of application only 
/*AND module IN (SELECT DISTINCT module FROM stats$sql_summary WHERE LOWER (module) LIKE 'yourappname%')  */
--AND TO_CHAR (last_active_time, 'DD.MM.YYYY') = TO_CHAR (SYSDATE-&&num_days, 'DD.MM.YYYY') 
AND snap_id in ( '&&begin_snap','&&end_snap')
ORDER BY avgelapstime DESC) 
WHERE ROWNUM <= 10) b, 
stats$sql_plan_usage c 
WHERE LOWER (a.text_subset) NOT LIKE 'insert%' AND a.sql_id= b.sql_id AND a.sql_id = c.sql_id 
GROUP BY 
--a.sql_text, 
a.sql_id, 
b.avgcputime, 
b.avgelapstime, 
b.executions, 
b.TIME, 
b.module, 
--a.piece, 
a.text_subset 
ORDER BY b.avgelapstime DESC
--, a.piece
; 

prompt ********* TOP SQL WITHOUT PLAN COST********

SELECT a.sql_id,b.avgcputime "CPU time (s/exec)", b.avgelapstime "Elaps. time (s/exec)", b.executions "Execs", b.TIME "Last Active",b.executions "Executions", 
b.module "Module" ,a.text_subset
FROM stats$sqltext a, (SELECT DISTINCT sql_id, snap_id, executions, avgcputime, avgelapstime, module, 
TO_CHAR (last_active_time, 'dd-mm-yy hh24:mi') TIME 
FROM (SELECT DISTINCT sql_id, ROWNUM, snap_id, executions, 
ROUND (cpu_time / (executions * 1000000), 2) avgcputime, 
ROUND (elapsed_time / (executions * 1000000), 2) avgelapstime, 
module, last_active_time 
FROM stats$sql_summary 
WHERE executions != 0 
-- To get SQL of application only 
/*AND module IN (SELECT DISTINCT module FROM stats$sql_summary WHERE LOWER (module) LIKE 'yourappname%')  */
--AND TO_CHAR (last_active_time, 'DD.MM.YYYY') = TO_CHAR (SYSDATE-&&num_days, 'DD.MM.YYYY') 
AND snap_id in ( '&&begin_snap','&&end_snap')
ORDER BY avgelapstime DESC) 
WHERE ROWNUM <= 5) b
WHERE LOWER (a.text_subset) NOT LIKE 'insert%' AND a.sql_id= b.sql_id 
GROUP BY 
--a.sql_text, 
a.sql_id, 
b.avgcputime, 
b.avgelapstime, 
b.executions, 
b.TIME, 
b.module, 
--a.piece, 
a.text_subset 
ORDER BY b.avgelapstime DESC
--, a.piece
;
prompt
prompt ******** HOURLY  TOP ELAPSED TIME PER EXEC ********
COLUMN BUFFER_GETS_PER_EXEC HEADING 'BUFFER_GETS|/EXEC'
COLUMN ROWS_PROCESSED_PER_EXEC HEADING 'ROWS_PROCESSED|/EXEC'
COLUMN CPU_SEC_PER_EXEC HEADING 'CPU_SEC|/EXEC'
COLUMN ELAPSED_SEC_PER_EXEC HEADING 'ELAPSED_SEC|/EXEC'
COLUMN IO_WAIT_PER_EXEC HEADING 'IO_WAIT|/EXEC'
COLUMN CONCURRENCY_WAIT_PER_EXEC HEADING 'CONCURRENCY_WAIT|/EXEC'
COLUMN READS_PER_EXEC HEADING 'READS|/EXEC'
column  D_Date new_value   D_Date noprint
select  trunc(sysdate-&&num_days) as D_Date from dual;
prompt  specified Date is : &&D_Date
prompt Specify the starting HOUR and ending HOURS to analyse from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
undefine begin_H end_H
col TEXT_SUBSET format a32
col SQL_TEXT format a90
set linesize 200
set pagesize 2000
alter session set nls_date_format = 'DD-MON-YY hh24:mi:ss';
prompt
prompt **** TOP ELAPSED
prompt
select * from
(
 select SQL_ID, OLD_HASH_VALUE, EXECUTIONS
 --, ROUND(READS/EXECUTIONS,2) READS_PER_EXEC
 --  , ROUND(WRITES/EXECUTIONS,2) WRITES_PER_EXEC
   ,ROUND(BUFFER_GETS/EXECUTIONS,2) BUFFER_GETS_PER_EXEC
   , ROUND((CPU/1000000)/EXECUTIONS,2) CPU_SEC_PER_EXEC
 , ROUND((ELAPSED/1000000)/EXECUTIONS,2) ELAPSED_SEC_PER_EXEC
 ,ROUND((ELAPSED/1000000),2) ELAPSED_TOTAL
  ,COST
 ,ROUND(ROWS_PROCESSED/EXECUTIONS,2) ROWS_PROCESSED_PER_EXEC
 ,ROUND((USER_IO_WAIT_TIME/1000000)/EXECUTIONS,2) IO_WAIT_PER_EXEC
  , TEXT_SUBSET
  ,TIME
 -- , SQL_TEXT
 from
 (
 select sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, sum.SQL_TEXT, sum(EXECUTIONS) EXECUTIONS, sum(DISK_READS) READS, sum(DIRECT_WRITES) WRITES, sum(CPU_TIME) CPU, sum(ELAPSED_TIME) ELAPSED
 ,sum(BUFFER_GETS) BUFFER_GETS,sum(ROWS_PROCESSED) ROWS_PROCESSED,sum(USER_IO_WAIT_TIME) USER_IO_WAIT_TIME,TO_CHAR (sum.last_active_time, 'dd-mm-yy hh24:mi') TIME,MAX(COST) COST  
 from
 PERFSTAT.STATS$SQL_SUMMARY sum,
 PERFSTAT.STATS$SNAPSHOT snap,
  PERFSTAT.stats$sql_plan_usage plan
 where sum.snap_id=snap.snap_id
 and
 -- Last hour
-- SNAP_TIME  ; sysdate -1/24
 -- Last day
 -- SNAP_TIME  ; sysdate -1
 -- Yesterday
  SNAP_TIME between trunc(sysdate -&&num_days)+&&begin_H/24 and trunc(sysdate -&&num_days)+&&end_H/24
 --SNAP_TIME between to_date('14-MAY-2015 08:00:00','DD-MON-YYYY HH24:MI:SS') and to_date('14-MAY-2015 20:00:00','DD-MON-YYYY HH24:MI:SS')
and plan.sql_id=sum.sql_id and plan.last_active_time=sum.last_active_time
 group by sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, SQL_TEXT,sum.last_active_time
 )
 where EXECUTIONS != 0
 order by ELAPSED_SEC_PER_EXEC desc
)
 --- limit the amount of rows returned
where rownum < 10
;
prompt
prompt **** TOP CPU
prompt
select * from
(
 select SQL_ID, OLD_HASH_VALUE, EXECUTIONS
  -- , ROUND(READS/EXECUTIONS,2) READS_PER_EXEC
  -- , ROUND(WRITES/EXECUTIONS,2) WRITES_PER_EXEC
    ,ROUND(BUFFER_GETS/EXECUTIONS,2) BUFFER_GETS_PER_EXEC
   ,ROUND((CPU/1000000)/EXECUTIONS,2) CPU_SEC_PER_EXEC
   ,ROUND((ELAPSED/1000000)/EXECUTIONS,2) ELAPSED_SEC_PER_EXEC
  ,ROUND((ELAPSED/1000000),2) ELAPSED_TOTAL
  ,COST
  ,ROUND(ROWS_PROCESSED/EXECUTIONS,2) ROWS_PROCESSED_PER_EXEC
  ,ROUND((USER_IO_WAIT_TIME/1000000)/EXECUTIONS,2) IO_WAIT_PER_EXEC
  , TEXT_SUBSET
  ,TIME
 -- , SQL_TEXT
 from
 (
 select sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, sum.SQL_TEXT, sum(EXECUTIONS) EXECUTIONS, sum(DISK_READS) READS, sum(DIRECT_WRITES) WRITES, sum(CPU_TIME) CPU, sum(ELAPSED_TIME) ELAPSED
 ,sum(BUFFER_GETS) BUFFER_GETS,sum(ROWS_PROCESSED) ROWS_PROCESSED,sum(USER_IO_WAIT_TIME) USER_IO_WAIT_TIME,TO_CHAR (sum.last_active_time, 'dd-mm-yy hh24:mi') TIME ,MAX(COST) COST 
 from
 PERFSTAT.STATS$SQL_SUMMARY sum,
 PERFSTAT.STATS$SNAPSHOT snap,
  PERFSTAT.stats$sql_plan_usage plan
 where sum.snap_id=snap.snap_id
 and
 -- Last hour
-- SNAP_TIME  ; sysdate -1/24
 -- Last day
 -- SNAP_TIME  ; sysdate -1
 -- Yesterday
  SNAP_TIME between trunc(sysdate -&&num_days)+&&begin_H/24 and trunc(sysdate -&&num_days)+&&end_H/24
 --SNAP_TIME between to_date('14-MAY-2015 08:00:00','DD-MON-YYYY HH24:MI:SS') and to_date('14-MAY-2015 20:00:00','DD-MON-YYYY HH24:MI:SS')
 and plan.sql_id=sum.sql_id and plan.last_active_time=sum.last_active_time
 group by sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, SQL_TEXT,sum.last_active_time
 )
 where EXECUTIONS != 0
 order by CPU_SEC_PER_EXEC desc
)
 --- limit the amount of rows returned
where rownum < 10
;
prompt **** TOP IO WAIT or CONCURENCY
undefine METRIC
prompt choose IO_WAIT_PER_EXEC or CONCURRENCY_WAIT_PER_EXEC   
select * from
(
 select SQL_ID, OLD_HASH_VALUE, EXECUTIONS
   , ROUND(READS/EXECUTIONS,2) READS_PER_EXEC
  -- , ROUND(WRITES/EXECUTIONS,2) WRITES_PER_EXEC
    ,ROUND(BUFFER_GETS/EXECUTIONS,2) BUFFER_GETS_PER_EXEC
   ,ROUND((USER_IO_WAIT_TIME/1000000)/EXECUTIONS,2) IO_WAIT_PER_EXEC
   ,ROUND((CONCURRENCY_WAIT_TIME/1000000)/EXECUTIONS,2) CONCURRENCY_WAIT_PER_EXEC
    ,COST
    ,ROUND(ROWS_PROCESSED/EXECUTIONS,2) ROWS_PROCESSED_PER_EXEC
   , ROUND((CPU/1000000)/EXECUTIONS,2) CPU_SEC_PER_EXEC
 , ROUND((ELAPSED/1000000)/EXECUTIONS,2) ELAPSED_SEC_PER_EXEC
 ,ROUND((ELAPSED/1000000),2) ELAPSED_TOTAL
  , TEXT_SUBSET
  ,TIME
 -- , SQL_TEXT
 from
 (
 select sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, sum.SQL_TEXT, sum(EXECUTIONS) EXECUTIONS , sum(DISK_READS) READS, sum(DIRECT_WRITES) WRITES, sum(CPU_TIME) CPU, sum(ELAPSED_TIME) ELAPSED
 ,sum(BUFFER_GETS) BUFFER_GETS,sum(ROWS_PROCESSED) ROWS_PROCESSED,sum(USER_IO_WAIT_TIME) USER_IO_WAIT_TIME,sum(CONCURRENCY_WAIT_TIME) CONCURRENCY_WAIT_TIME,TO_CHAR (sum.last_active_time, 'dd-mm-yy hh24:mi') TIME,MAX(COST) COST
 from
 PERFSTAT.STATS$SQL_SUMMARY sum,
 PERFSTAT.STATS$SNAPSHOT snap,
 PERFSTAT.stats$sql_plan_usage plan
 where sum.snap_id=snap.snap_id
 and
 -- Last hour
-- SNAP_TIME  ; sysdate -1/24
 -- Last day
 -- SNAP_TIME  ; sysdate -1
 -- Yesterday
  SNAP_TIME between trunc(sysdate -&&num_days)+&&begin_H/24 and trunc(sysdate -&&num_days)+&&end_H/24
 --SNAP_TIME between to_date('14-MAY-2015 08:00:00','DD-MON-YYYY HH24:MI:SS') and to_date('14-MAY-2015 20:00:00','DD-MON-YYYY HH24:MI:SS')
 and plan.sql_id=sum.sql_id and plan.last_active_time=sum.last_active_time
 group by sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, SQL_TEXT,sum.last_active_time
 )
 where EXECUTIONS != 0
 order by &METRIC desc
)
 --- limit the amount of rows returned
where rownum < 10
;

prompt **** TOP IO WAIT or CONCURENCY WITHOUT PLAN INFO
select * from
(
 select SQL_ID, OLD_HASH_VALUE, EXECUTIONS
   , ROUND(READS/EXECUTIONS,2) READS_PER_EXEC
  -- , ROUND(WRITES/EXECUTIONS,2) WRITES_PER_EXEC
    ,ROUND(BUFFER_GETS/EXECUTIONS,2) BUFFER_GETS_PER_EXEC
   ,ROUND((USER_IO_WAIT_TIME/1000000)/EXECUTIONS,2) IO_WAIT_PER_EXEC
   ,ROUND((CONCURRENCY_WAIT_TIME/1000000)/EXECUTIONS,2) CONCURRENCY_WAIT_PER_EXEC
   --- ,COST
    ,ROUND(ROWS_PROCESSED/EXECUTIONS,2) ROWS_PROCESSED_PER_EXEC
   , ROUND((CPU/1000000)/EXECUTIONS,2) CPU_SEC_PER_EXEC
 , ROUND((ELAPSED/1000000)/EXECUTIONS,2) ELAPSED_SEC_PER_EXEC
 ,ROUND((ELAPSED/1000000),2) ELAPSED_TOTAL
  , TEXT_SUBSET
  ,TIME
 -- , SQL_TEXT
 from
 (
 select sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, sum.SQL_TEXT, sum(EXECUTIONS) EXECUTIONS , sum(DISK_READS) READS, sum(DIRECT_WRITES) WRITES, sum(CPU_TIME) CPU, sum(ELAPSED_TIME) ELAPSED
 ,sum(BUFFER_GETS) BUFFER_GETS,sum(ROWS_PROCESSED) ROWS_PROCESSED,sum(USER_IO_WAIT_TIME) USER_IO_WAIT_TIME,sum(CONCURRENCY_WAIT_TIME) CONCURRENCY_WAIT_TIME,TO_CHAR (sum.last_active_time, 'dd-mm-yy hh24:mi') TIME
 --,MAX(COST) COST
 from
 PERFSTAT.STATS$SQL_SUMMARY sum,
 PERFSTAT.STATS$SNAPSHOT snap
 --, PERFSTAT.stats$sql_plan_usage plan
 where sum.snap_id=snap.snap_id
 and
 -- Last hour
-- SNAP_TIME  ; sysdate -1/24
 -- Last day
 -- SNAP_TIME  ; sysdate -1
 -- Yesterday
  SNAP_TIME between trunc(sysdate -&&num_days)+&&begin_H/24 and trunc(sysdate -&&num_days)+&&end_H/24
 --SNAP_TIME between to_date('14-MAY-2015 08:00:00','DD-MON-YYYY HH24:MI:SS') and to_date('14-MAY-2015 20:00:00','DD-MON-YYYY HH24:MI:SS')
 ---and plan.sql_id=sum.sql_id and plan.last_active_time=sum.last_active_time
 group by sum.SQL_ID, sum.OLD_HASH_VALUE, sum.TEXT_SUBSET, SQL_TEXT,sum.last_active_time
 )
 where EXECUTIONS != 0
 order by &METRIC desc
)
 --- limit the amount of rows returned
where rownum < 10
;


select e.class                                 "E.CLASS"
     , e.wait_count  - nvl(b.wait_count,0)     "Waits"
     , e.time        - nvl(b.time,0)           "Total Wait Time (cs)"
     , (e.time       - nvl(b.time,0)) /
       (e.wait_count - nvl(b.wait_count,0))    "Avg Time (cs)"
  from stats$waitstat  b
     , stats$waitstat  e
 where b.snap_id         = &&begin_snap
   and e.snap_id         = &&End_Snap
   and b.dbid            = &&DbId
   and e.dbid            = &&DbId
   and b.dbid            = e.dbid
   and b.instance_number = &&Instance_Number
   and e.instance_number = &&Instance_Number
   and b.instance_number = e.instance_number
   and b.class           = e.class
   and b.wait_count      < e.wait_count
 order by 3 desc, 2 desc;