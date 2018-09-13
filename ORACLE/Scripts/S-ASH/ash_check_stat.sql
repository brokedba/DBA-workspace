set verify off
-- gets basic DBA_HIST_SQLSTAT data for a single sql_id
-- assumes that each AWR snap is one-hour (used in names, not math)
/*
   SNAP_ID BEGIN_HOUR       EXECS_PER_HOUR GETS_PER_HOUR GETS_PER_EXEC SECONDS_PER_HOUR
---------- ---------------- -------------- ------------- ------------- ----------------
      1872 2008-04-03 10:00        1563634      17540545            11             4503  --- consumed more than whole CPU 4503> 3600(1 hour)
*/
undefine begin_H end_H num_days begin_m end_m
column BEGIN_HOUR format a16
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
column  D_Date new_value   D_Date noprint
select  trunc(sysdate-&&num_days) as D_Date from dual;
prompt  specified Date is : &&D_Date
prompt Specify the starting HOUR and ending HOURS to analyse from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


select
   snap_id,
   to_char(begin_interval_time,'YYYY-MM-DD HH24:MI') as begin_hour,
   round(CPU_TIME_DELTA/1000000) as CPUTime_per_quarter,
    round(CCWAIT_DELTA/1000000)  as Concurent_per_quarter,
   executions_delta as execs_per_quarter,
   buffer_gets_delta as gets_per_quarter,
   round(buffer_gets_delta/executions_delta) as gets_per_exec,
   round(elapsed_time_delta/1000000) as seconds_per_quarter
from
   dba_hist_snapshot natural join dba_hist_sqlstat
where
   begin_interval_time between trunc(sysdate -&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
and
   sql_id = '&sql_id'
and
   executions_delta > 0
order by
   snap_id
;