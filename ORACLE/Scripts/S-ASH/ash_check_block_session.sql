/* Find- blocking session history (AWR)

-- gets most expensive queries 
-- (by time spent, change "order by" to use another metric)
-- after a specific date
undefine begin_H end_H num_days begin_m end_m
column BEGIN_HOUR format a16
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
column  D_Date new_value   D_Date noprint
select  trunc(sysdate-&&num_days) as D_Date from dual;
prompt  specified Date is : &&D_Date
prompt Specify the starting HOUR and ending HOURS to analyse from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set verify off
COLUMN  BLOKER_USER FORMAT  a10
COLUMN  BLOKED_USER FORMAT  a10
COLUMN  BLOKED_TABLE FORMAT   a20
COLUMN   BLOCKER_PROGRAM FORMAT   a20
COLUMN   BLOCKED_PROGRAM FORMAT   a20
COLUMN   BLOCKED_SQL_TEXT FORMAT   a33
COLUMN   BLOCKER_SQL_TEXT ON FORMAT a25
SET LINES 220

select
  --   min (blocker.sample_time) Time, 
    min (blocker.sample_time)       as begin_time,    
    max(blocker.sample_time)       as end_time,
    -- Session causing the block
    blocker.session_id          as bloker_sid,
    blocker.session_serial#   as blocker_serial#,
    max(Blker_USERS.username)              as bloker_user,
    --blocker.machine           as blocker_machine,
   -- blocker.program           as blocker_program,
  --  blocker.sql_id              as bloker_sqlid,
   --- blocker.sql_child_number as blocker_sql_child_number,
  --  ' -> '                      as is_blocking,    
    -- Sesssion being blocked
    blocked.session_id         as bloked_sid,
    blocked.session_serial#  as blocked_serial#,
    max(blked_users.username)            as bloked_user,
   -- blocked.machine          as blocked_machine,
    --blocked.program          as blocked_program,
   --- blocked.blocking_session as blocking_session,
    blocked.sql_id             as bloked_sqlid,
    --blocked.sql_child_number as blocked_sql_child_number,
    max(sys_obj.object_name)               as bloked_table,
   max(dbms_rowid.rowid_create(1, blocked.current_obj# ,  blocked.current_file#,  blocked.current_block# ,blocked.current_row# )) as blocked_rowid,
    -- Blocker * Blocked SQL Text  rowid_type => 1, object_number => blocked.current_obj# ,relative_fno  => blocked.current_file#, block_number  => blocked.current_block# ,row_number=>blocked.current_row#
    --  max(to_char(blocker_sql.sql_text))      as blocker_sql_text,
    --  max(blocker.xid) tx_id,
    max(to_char(blocked_sql.sql_text))      as blocked_sql_text,
    count(blocked.TIME_WAITED) time_waited
from
    v$active_session_history blocker
    inner join    v$active_session_history blocked  on blocker.session_id = blocked.blocking_session
    inner join    SASH_OBJS sys_obj on sys_obj.object_id = blocked.current_obj#
    left outer join  sash_sqltxt blocked_sql on blocked_sql.sql_id = blocked.sql_id  and blocked_sql.dbid = blocked.dbid 
    left outer join  sash_sqltxt blocker_sql  on blocker_sql.sql_id = blocker.sql_id and blocker_sql.dbid = blocker.dbid
    inner  join SASH_USERS blker_users on blocker.user_id =blker_USERS.user_id
    inner  join DBA_USERS  Blked_users on  blocked.user_id =blked_users.user_id
where
    blocker.sample_time   between trunc(sysdate-&&num_days)+&&begin_H/24+&&begin_m/1440 and trunc(sysdate -&&num_days)+&&end_H/24+&&end_m/1440
    and blocker.user_id>0 and blocked.TIME_WAITED>0 and blocker.sample_time=blocked.sample_time and blocked.event='enq: TX – row lock contention' 
     ----between to_timestamp('START_TIME', 'YYYY-MM-DD HH24:MI:SS.FF3') and to_timestamp('END_TIME', 'YYYY-MM-DD HH24:MI:SS.FF3') 
     group by blocked.session_id,blocker.session_id,blocked.sql_id,blocker.session_serial#,blocked.session_serial#
order by  blocked.sql_id,12 desc ;
---begin_time;
