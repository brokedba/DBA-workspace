   undefine sqlid
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
ORDER BY avgelapstime DESC)) b, 
stats$sql_plan_usage c 
WHERE  b.sql_id='&&sqlid'
and a.sql_id= b.sql_id AND a.sql_id = c.sql_id 
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

Prompt  ========= The sql text
break on OLD_HASH_VALUE 
SELECT a.sql_id,a.OLD_HASH_VALUE,a.sql_text "SQL statement"
FROM stats$sqltext a 
WHERE  a.sql_id='&&sqlid'
GROUP BY 
a.sql_text, 
a.sql_id, 
a.piece, 
a.text_subset ,
a.OLD_HASH_VALUE
ORDER BY a.piece
;   

--  SQL Reporting

col Gets      format 9,999,999,990  heading 'Buffer Gets';
col Reads     format 9,999,999,990  heading 'Physical|Reads';
col Rw        format 9,999,999,990  heading 'Rows | Processed';
col pc        format 9,999,999,999  heading 'Parse|Calls'
col cput      format 9,999,999,999  heading 'CPU Time'
col elat      format 9,999,999,999  heading 'Ela Time'
col Execs     format 9,999,999,990  heading 'Executes';
col shm       format 9,999,999,999  heading 'Sharable   |Memory (bytes)';
col vcount    format 9,999,999,999  heading 'Version|Count';
col sorts     format 9,999,999,999  heading 'Sorts'
col inv       format 9,999,999,999  heading 'Invali-|dations';

col GPX       format 9,999,999,990.0  heading 'Gets|per Exec'  just c;
col RPX       format 9,999,999,990.0  heading 'Reads|per Exec' just c;
col RWPX      format 9,999,999,990.0  heading 'Rows|per Exec'  just c;
col PPX       format 9,999,999,999.0  heading 'Parses|per Exec' just c;
col cpupx     format 9,999,999,999.0  heading 'CPU|per Exec'   just c;
col elapx     format 9,999,999,999.0  heading 'Ela|per Exec'   just c;
col spx       format 9,999,999,999.0  heading 'Sorts|per Exec' just c;

col ptg       format 999.99           heading '%Total|Gets';
col ptr       format 999.99           heading '%Total|Reads';
col sql_id    format a13              heading 'SQL ID';
col hashval   format 9999999999999    heading 'Hash Value ';
col sql_text  format a500           heading 'SQL statement:'  wrap;
col rel_pct   format 999.9          heading '% of|Total';
col nl         newline;
--
-- Show SQL statistics

set heading off;

select 'SQL Statistics'                                     nl
     , '~~~~~~~~~~~~~~'                                     nl
     , '-> CPU and Elapsed Time are in seconds (s) for Statement Total and in' nl
     , '   milliseconds (ms) for Per Execute'       nl
     , '                                                       % Snap'  nl
     , '                     Statement Total      Per Execute   Total'  nl
     , '                     ---------------  ---------------  ------'  nl
     , '        Buffer Gets: '                              nl
     , e.buffer_gets - nvl(b.buffer_gets,0)                 gets
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  (e.buffer_gets - nvl(b.buffer_gets,0))
              / (e.executions - nvl(b.executions,0)))       gpx
     , decode(:slr
             , 0, to_number(null)
             , 100*(e.buffer_gets - nvl(b.buffer_gets,0))
              /:slr)                                        ptg
     , '         Disk Reads: '                              nl
     , e.disk_reads - nvl(b.disk_reads,0)                   reads
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  (e.disk_reads - nvl(b.disk_reads,0))
              / (e.executions - nvl(b.executions,0)))       rpx
     , decode(:phyr
             , 0, to_number(null)
             , 100*(e.disk_reads - nvl(b.disk_reads,0))
              /:phyr)                                       ptr
     , '     Rows processed: '                              nl
     , e.rows_processed - nvl(b.rows_processed,0)           rw
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  (e.rows_processed - nvl(b.rows_processed,0))
              / (e.executions - nvl(b.executions,0)))       rwpx
     , '     CPU Time(s/ms): '                              nl 
     , (e.cpu_time - nvl(b.cpu_time,0))/1000000             cput
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  ((e.cpu_time - nvl(b.cpu_time,0))/1000)
              /  (e.executions - nvl(b.executions,0)))      cpupx
     , ' Elapsed Time(s/ms): '                              nl
     , (e.elapsed_time - nvl(b.elapsed_time,0))/1000000     elat
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  ((e.elapsed_time - nvl(b.elapsed_time,0))/1000)
              /  (e.executions - nvl(b.executions,0)))      elapx
     , '              Sorts: '                              nl
     , e.sorts - nvl(b.sorts,0)                             sorts
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  (e.sorts - nvl(b.sorts,0))
              / (e.executions - nvl(b.executions,0)))       spx
     , '        Parse Calls: '                              nl
     , e.parse_calls - nvl(b.parse_calls,0)                 pc
     , decode(e.executions - nvl(b.executions,0)
             ,0, to_number(null)
             ,  (e.parse_calls - nvl(b.parse_calls,0))
              / (e.executions - nvl(b.executions,0)))       ppx
     , '      Invalidations: '                              nl
     , e.invalidations - nvl(b.invalidations,0)             inv
     , '      Version count: '                              nl
     , e.version_count                                      vcount
     , '    Sharable Mem(K): '                              nl
     , e.sharable_mem/1024                                  shm
     , '         Executions: '                              nl
     , e.executions - nvl(b.executions,0)                   execs
     , '             SQL_ID:  '                              nl
     , e.sql_id                                             hashval      
     , '         HASH_VALUE: '                              nl
     , e.old_hash_value                                     hashval                              
  from stats$sql_summary e
     , stats$sql_summary b
 where b.snap_id ='&&begin_snap'
   and b.old_hash_value  = e.old_hash_value
   and b.address(+)         = e.address
   and b.text_subset(+)     = e.text_subset
   and e.snap_id            = '&&end_snap'
   and e.SQL_ID= '&&sqlid';

--  Show all known Plans used between Snap Ids specified

ttitle lef 'Plans in shared pool between Begin and End Snap Ids' -
       skip 1 -
       lef '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' -
       skip 1 -
       lef 'Shows the Execution Plans found in the shared pool between the begin and end' -
       skip 1 -
       lef 'snapshots specified.  The values for Rows, Bytes and Cost shown below are those' -
       skip 1 -
       lef 'which existed at the time the first-ever snapshot captured this plan - these' -
       skip 1 -
       lef 'values often change over time, and so may not be indicative of current values' -
       skip 1 -
       lef '-> Rows indicates Cardinality, PHV is Plan Hash Value' -
       skip 1 -
       lef '-> ordered by Plan Hash Value' -
       skip 2;

set heading off;

select '--------------------------------------------------------------------------------' from dual
union all
select '| Operation                      | PHV/Object Name     |  Rows | Bytes|   Cost |'  as "Optimizer Plan:" from dual
union all
select '--------------------------------------------------------------------------------' from dual
union all
select *
  from (select
       rpad('|'||substr(lpad(' ',1*(depth-1))||operation||
            decode(options, null,'',' '||options), 1, 32), 33, ' ')||'|'||
       rpad(decode(id, 0, '----- '||to_char(plan_hash_value)||' -----'
                     , substr(decode(substr(object_name, 1, 7), 'SYS_LE_', null, object_name)
                       ||' ',1, 20)), 21, ' ')||'|'||
       lpad(decode(cardinality,null,'  ',
                decode(sign(cardinality-1000), -1, cardinality||' ', 
                decode(sign(cardinality-1000000), -1, trunc(cardinality/1000)||'K', 
                decode(sign(cardinality-1000000000), -1, trunc(cardinality/1000000)||'M', 
                       trunc(cardinality/1000000000)||'G')))), 7, ' ') || '|' ||
       lpad(decode(bytes,null,' ',
                decode(sign(bytes-1024), -1, bytes||' ', 
                decode(sign(bytes-1048576), -1, trunc(bytes/1024)||'K', 
                decode(sign(bytes-1073741824), -1, trunc(bytes/1048576)||'M', 
                       trunc(bytes/1073741824)||'G')))), 6, ' ') || '|' ||
       lpad(decode(cost,null,' ',
                decode(sign(cost-10000000), -1, cost||' ', 
                decode(sign(cost-1000000000), -1, trunc(cost/1000000)||'M', 
                       trunc(cost/1000000000)||'G'))), 8, ' ') || '|' as "Explain plan"
          from stats$sql_plan
         where plan_hash_value in (select plan_hash_value
                                     from stats$sql_plan_usage spu
                                    where spu.snap_id   between '&&begin_snap' and '&&end_snap'
                                      and spu.dbid            = &dbid
                                      and spu.instance_number = &instance_number
                                      and spu.SQL_ID='&&sqlid'
                                  --    and spu.old_hash_value  = :old_hash_value
                                 --     and text_subset         = :text_subset
                                      and spu.plan_hash_value > 0
                                  )
          order by plan_hash_value, id
)
union all
select '--------------------------------------------------------------------------------' from dual;

set heading on;