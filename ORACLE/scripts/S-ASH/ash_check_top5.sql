/* find-expensive.sql (AWR) */
-- gets most expensive queries 
-- (by time spent, change "order by" to use another metric)
-- after a specific date
undefine begin_H end_H num_days
column BEGIN_HOUR format a16
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
column  D_Date new_value   D_Date noprint
select  trunc(sysdate-&&num_days) as D_Date from dual;
prompt  specified Date is : &&D_Date
prompt Specify the starting HOUR and ending HOURS to analyse from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
undefine begin_H end_H num_days begin_m end_m 



select
   to_char(round(sub.BEGIN_TIME, 'MI'), 'YYYY-MM-DD HH24:MI') as begin_time,
   to_char(round(sub.BEGIN_TIME, 'MI'), 'YYYY-MM-DD HH24:MI') as end_time,
   sub.sql_id,
   sub.seconds_total,
   sub.execs_total,
   sub.gets_total,
   sub.CPUTime_total,
   sub.IOWAIT_total,     
   sub.Concurent_total ,
   sub.elapsed_per_exec      
from
   ( -- sub to sort before rownum
     select
      --  BEGIN_INTERVAL_TIME,
        sql_id,
        round(sum(elapsed_time_delta)/1000000) as seconds_total,
        round(SUM(CPU_TIME_DELTA)/1000000) as CPUTime_total,
        round(SUM(IOWAIT_DELTA)/1000000)  as IOWAIT_total,
         round(SUM(CCWAIT_DELTA)/1000000)  as Concurent_total,
        sum(executions_delta) as execs_total,
        sum(buffer_gets_delta) as gets_total,
         round (sum(elapsed_time_delta/executions_delta)/1000000) as elapsed_per_exec,
         min(begin_interval_time) begin_time ,
         min(begin_interval_time) en_time   
     from
        dba_hist_snapshot natural join dba_hist_sqlstat
     where
        begin_interval_time between trunc(sysdate-&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
     group by
        sql_id --,BEGIN_INTERVAL_TIME
     order by
        2,6 desc
   ) sub
where
   rownum < 10
;