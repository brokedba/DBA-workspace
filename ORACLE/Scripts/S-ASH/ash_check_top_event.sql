undefine begin_H end_H num_days begin_m end_m
set feed off 
column BEGIN_HOUR format a16
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
column  D_Date new_value   D_Date noprint
select  trunc(sysdate-&&num_days) as D_Date from dual;
prompt  specified Date is : &&D_Date
prompt Specify the starting HOUR and ending HOUR to analyse from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set echo off
set feed off 
set verify off

prompt per SQL_ID

col EVENT for a40
col WAIT_CLASS for a12
col sql_id for a13
col USERNAME for a10
select * from (
      -- sub1: one row per sampled ASH observation second
      select min(sample_time) begin_time,max(sample_time) end_time,WAIT_CLASS,event, nvl(sql_id,'-------------') sql_id, count(*) count,sum(TIME_WAITED) time_waited, trunc(avg(time_waited),2)  avg_time_waited
  From v$active_session_history   --- 1 second samples
  --  FROM dba_hist_active_sess_history    -- 10 seconds samples  
     Where  sample_time between trunc(sysdate -&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
     and user_id>0  and WAIT_CLASS != 'Idle' and  SESSION_STATE = 'WAITING' and event != 'null event'
      Group by WAIT_CLASS,event, sql_id
      Order by 7 desc
      ) subl 
      where 
   rownum < 10
;
prompt *** per session_ID SQL_ID


col username for a15
select * from (
      -- sub1: one row per sampled ASH observation second
      select min(sample_time) begin_time,max(sample_time) end_time,session_id,dba_users.username,WAIT_CLASS,sql_id,sum(TIME_WAITED) time_waited,trunc(avg(time_waited),2)  avg_time_waited,count(*) count,event
  From v$active_session_history ,dba_users  --- 1 second samples
     -- FROM dba_hist_active_sess_history    -- 10 seconds samples
     Where  sample_time between trunc(sysdate -&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
     and v$active_session_history.user_id>0  and WAIT_CLASS != 'Idle' and  SESSION_STATE = 'WAITING' and event != 'null event' and dba_users.user_id=v$active_session_history.user_id
      Group by WAIT_CLASS,event, sql_id,session_id,dba_users.username
      Order by 8 desc
      ) subl 
      where 
   rownum < 10
;


/*

            select min(sample_time) begin_time,max(sample_time) end_time,session_id,dba_users.username,WAIT_CLASS,sql_id,sum(TIME_WAITED) time_waited,trunc(avg(time_waited),2)  avg_time_waited,count(*) count,event
  From v$active_session_history ,dba_users  --- 1 second samples
     -- FROM dba_hist_active_sess_history    -- 10 seconds samples
     Where  sample_time between trunc(sysdate -&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
     and v$active_session_history.user_id>0  and WAIT_CLASS != 'Idle' and  SESSION_STATE = 'WAITING' and event = '&event' and dba_users.user_id=v$active_session_history.user_id
      Group by WAIT_CLASS,event, sql_id,session_id,dba_users.username,session_serial#
      Order by 8 desc
/
*/
set feed on



 