Set verify off
set feed off
set echo off
-- alter sequence PERFSTAT.STATS$SNAPSHOT_ID nocache;
column module for a20
column instart_fmt noprint;
column  report_name new_value   report_name
column  instance_number new_value   instance_number noprint
column  dbid        new_value   dbid  noprint
select dbid,instance_number from v$database,v$instance;

--  Set up the binds for dbid and instance_number
variable dbid       number;
variable inst_num   number;
begin
  :dbid      :=  &dbid;
  :inst_num  :=  &instance_number;
end;
/

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
--
-- List available snapshots
set heading off
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
        snap_id                 snap_id,
        lead(snap_id,1) over(order by snap_id)  next_snap,
        snap_level,snap_time
     from   stats$snapshot
     where  dbid        = :dbid
     and    instance_number = :inst_num
     and    trunc(snap_time) >= trunc(sysdate-&&num_days)
 order by   snap_id;
set heading ON
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
variable bid        number;
variable eid        number;
begin
  :bid       :=  &begin_snap;
  :eid       :=  &end_snap;
end;
/

--  Error reporting

whenever sqlerror exit;
declare

  cursor cspid(vspid stats$snapshot.snap_id%type) is
     select snap_time
          , startup_time
          , session_id
          , serial#
       from stats$snapshot
      where snap_id         = vspid
        and instance_number = :inst_num
        and dbid            = :dbid;

  bsnapt  stats$snapshot.startup_time%type;
  bstart  stats$snapshot.startup_time%type;
  bsesid  stats$snapshot.session_id%type;
  bseria  stats$snapshot.serial#%type;
  esnapt  stats$snapshot.startup_time%type;
  estart  stats$snapshot.startup_time%type;
  esesid  stats$snapshot.session_id%type;
  eseria  stats$snapshot.serial#%type;

begin
  -- Check Begin Snapshot id is valid, get corresponding instance startup time
  open cspid(:bid);
  fetch cspid into bsnapt, bstart, bsesid, bseria;
  if cspid%notfound then
    raise_application_error(-20200,
      'Begin Snapshot Id '||:bid||' does not exist for this database/instance');
  end if;
  close cspid;

  -- Check End Snapshot id is valid and get corresponding instance startup time
  open cspid(:eid);
  fetch cspid into esnapt, estart, esesid, eseria;
  if cspid%notfound then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid||' does not exist for this database/instance');
  end if;
  if esnapt <= bsnapt then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid||' must be greater than Begin Snapshot Id '||:bid);
  end if;
  close cspid;

  -- Check startup time is same for begin and end snapshot ids
  if ( bstart != estart) then
    raise_application_error(-20200,
      'The instance was shutdown between snapshots '||:bid||' and '||:eid);
  end if;

  -- Check sessions are same for begin and end snapshot ids
  if (bsesid != esesid or bseria != eseria) then
      dbms_output.put_line('WARNING: SESSION STATISTICS WILL NOT BE PRINTED, as session statistics');
      dbms_output.put_line('captured in begin and end snapshots are for different sessions');
      dbms_output.put_line('(Begin Snap sid,serial#: '||bsesid||','||bseria||',  End Snap sid,serial#: '||esesid||','||eseria||').');
      dbms_output.put_line('');
  end if;

end;
/
whenever sqlerror continue;

undefine CLASS
COLUMN METRIC_NAME FOR A35
COLUMN METRIC_UNIT FOR A25
COLUMN WAIT_TYPE FOR a25

PROMPT *************************** CURRENT TIME STATS *********************************
select  CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then 'SQL Service Response Time (secs)'
            WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
            ELSE METRIC_NAME
            END METRIC_NAME,
       CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((AVERAGE / 100),2)
            WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),2)
            ELSE ROUND(AVERAGE,2)
            END AVERAGE,
       CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((MAXVAL / 100),2)
            WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),2)
            ELSE ROUND(MAXVAL,2)
            END MAXIMUM,
            to_char(trunc(max(BEGIN_TIME),'MI'),'DD-MON-YY HH24:MI') BEGIN_TIME,to_char(trunc(MAX(END_TIME),'MI'),'DD-MON-YY HH24:MI')END_TIME
from    SYS.V_$SYSMETRIC_SUMMARY 
where   METRIC_NAME in ('CPU Usage Per Sec',
                      'CPU Usage Per Txn',
                      'Database CPU Time Ratio',
                      'Database Wait Time Ratio',
                      'Executions Per Sec',
                      'Executions Per Txn',
                      'Response Time Per Txn',
                      'SQL Service Response Time',
                      'User Transaction Per Sec')
GROUP BY METRIC_NAME,MINVAL,MAXVAL,AVERAGE  
ORDER BY SUBSTR(METRIC_NAME,-1) DESC,METRIC_NAME                    
                      /
                      
PROMPT *************************** CURRENT WAIT STATS *********************************
col WAIT_CLASS for a25
select  WAIT_CLASS,
        TOTAL_WAITS,
        round(100 * (TOTAL_WAITS / SUM_WAITS),2) PCT_WAITS,
        ROUND((TIME_WAITED / 100),2) TIME_WAITED_SECS,
        round(100 * (TIME_WAITED / SUM_TIME),2) PCT_TIME,
        BEGIN_TIME,END_TIME
from
(select 
        b.WAIT_CLASS,
        SUM(a.WAIT_COUNT) TOTAL_WAITS ,
        SUM(a.TIME_WAITED)TIME_WAITED,
        to_char(trunc(min(a.begin_time),'MI'),'DD-MON-YY HH24:MI') BEGIN_TIME,to_char(trunc(max(a.end_time),'MI'),'DD-MON-YY HH24:MI') END_TIME
from    v$waitclassmetric_history a,V$SYSTEM_WAIT_CLASS b
where   WAIT_CLASS != 'Idle'
and a.wait_class# = b.wait_class# 
GROUP BY b.wait_class),
(select  sum(a.WAIT_COUNT) SUM_WAITS,
        sum(a.TIME_WAITED) SUM_TIME
from    v$waitclassmetric_history a,V$SYSTEM_WAIT_CLASS b
where   b.WAIT_CLASS != 'Idle'
and a.wait_class# = b.wait_class#  )
order by 5 desc;


PROMPT ***************************** SNAPSHOT TIME STATS *******************************
 ----to_char(to_date(TIME_SEC,'sssss'),'hh24:mi:ss'  
 with TIME_MODEL AS (
 SELECT n.stat_name,t.snap_id,s.snap_time,Value/1000000 Value, ROUND((value-LAG(value) OVER (PARTITION BY n.stat_name order by s.snap_id))/1000000,2) TIME_SEC
 FROM STATS$SYS_TIME_MODEL T ,STATS$TIME_MODEL_STATNAME N, stats$snapshot s                                                           
      WHERE  STAT_NAME in ('sql execute elapsed time','DB CPU','parse time elapsed','hard parse elapsed time',              
                           'PL/SQL execution elapsed time',        
                           'hard parse (sharing criteria) elaps',  
                           'hard parse (bind mismatch) elapsed',   
                           'PL/SQL compilation elapsed time',      
                           'connection management call elapsed',   
                           'sequence load elapsed time',           
                           'repeated bind elapsed time',           
                           'failed parse elapsed time' ,
                           'failed parse (out of shared memory) elapsed tim',
                           'Java execution elapsed time',
                           'repeated bind elapsed time',
                           'RMAN cpu time (backup/restore'
                            )  
      AND T.snap_id=s.snap_id                     
      AND T.STAT_ID=N.STAT_ID  
      AND s.snap_id BETWEEN &&begin_snap AND &&end_snap
      ),
  DB_TIME AS ( SELECT STAT_NAME,ROUND((value-LAG(value) OVER (PARTITION BY n.stat_name order by T.snap_id))/1000000 ,2) TIME_SEC,snap_id
  FROM STATS$SYS_TIME_MODEL T ,STATS$TIME_MODEL_STATNAME N
  WHERE  STAT_NAME in('DB time','background elapsed time','background cpu time')        
  and T.STAT_ID=N.STAT_ID
  and  T.snap_id BETWEEN &&begin_snap AND &&end_snap  )    
 SELECT STAT_NAME,
        sum(TIME_SEC)TIME_WAITED_SECS,
        ROUND(SUM(TIME_SEC)*100/(SELECT SUM(TIME_SEC) FROM  DB_TIME WHERE STAT_NAME='DB time'),2) PCT_TIME,
        ROUND(sum(TIME_SEC)/60,2)TIME_WAITED_MIN,
        min(SNAP_ID) BEGIN_SNAP, max(snap_id)END_SNAP, min(snap_time)BEGIN_TIME, max(snap_time) END_TIME
 FROM   TIME_MODEL
 GROUP BY STAT_NAME
 UNION                                                                             
 SELECT stat_name,sum(TIME_SEC),NULL,ROUND(sum(TIME_SEC)/60,2), min(SNAP_ID) BEGIN_SNAP, max(snap_id)END_SNAP, NULL,NULL                                               
 FROM DB_TIME B                                                                        
 GROUP BY STAT_NAME
 UNION
 SELECT 'DB WAIT TIME',SUM(B1.TIME_SEC)- MAX(M.TIME_SEC),ROUND((SUM(B1.TIME_SEC)-max(M.TIME_SEC))*100/SUM(B1.TIME_SEC),2) ,ROUND((SUM(B1.TIME_SEC)-max(M.TIME_SEC))/60,2) , min(B1.SNAP_ID), max(B1.snap_id), NULL,NULL
   FROM DB_TIME B1,(select sum(TIME_SEC) TIME_SEC FROM TIME_MODEL WHERE STAT_NAME='DB CPU') M
  WHERE B1.STAT_NAME='DB time' 
 ORDER BY 3 DESC
 /  
                        
PROMPT *************************** SNAPSHOT WAIT STATS *********************************

--SET COLSEP '|'                                      
CLEAR BREAK COMPUTE;
--BREAK ON WAIT_TYPE ON BEGIN_TIME ON END_TIME ON BEGIN_SNAP ON END_SNAP
--COMPUTE SUM OF WAIT_SEC_DELTA ON WAIT_TYPE   --- FOR THE detailed INNER QUERY per snapID
BREAK ON BEGIN_TIME ON END_TIME ON BEGIN_SNAP ON END_SNAP;

COL AVG_WAIT_MS FORMAT 99,990.9
COL TIME_WAITED_SECS FORmat 9999,990.99
COL TIME_WAITED_MIN  FORMAT 999,990.99
COL PCT_TIME FORMAT 90.99
COL WAIT_SEC_DELTA FOR 999,990.99
COL EVENT FOR A38
select WAIT_TYPE,sum(WAITS_DELTA) WAITS,ROUND(SUM(WAITS_DELTA)*100/SUM(SUM(WAITS_DELTA))OVER (),2) PCT_WAITS,sum(WAIT_SEC_DELTA) TIME_WAITED_SECS,ROUND(sum(WAIT_SEC_DELTA)/60,2) TIME_WAITED_MIN,ROUND(SUM(WAIT_SEC_DELTA)*100/SUM(SUM(WAIT_SEC_DELTA))OVER (),2) PCT_TIME,ROUND(AVG(TRIM(AVG_WAIT_MS)),2) AVG_WAIT_MS,min(SNAP_ID) BEGIN_SNAP,max(snap_id)END_SNAP,min(snap_time)BEGIN_TIME,max(snap_time) END_TIME
FROM  
(
WITH system_event AS                                                                    
    (SELECT --CASE                                                                        
             -- WHEN s.wait_class IN ('User I/O', 'System I/O') THEN e.event ELSE s.wait_class END  wait_type
               s.wait_class  wait_type, e.*                                                        
        FROM STATS$SYSTEM_EVENT e, v$system_event s  
        where e.event_id=s.event_id        
        )                                                                      
SELECT wait_type,s1.snap_time,s1.snap_id, SUM(l.total_waits)TOTAL_WAITS,
   --  LAG(SUM(l.total_waits))OVER (PARTITION BY WAIT_TYPE ORDER BY s1.snap_id)PREV_WAITS,
       SUM(l.total_waits)-LAG(SUM(l.total_waits))OVER (PARTITION BY WAIT_TYPE ORDER BY s1.snap_id) WAITS_DELTA, 
       ROUND(SUM(l.time_waited_micro) / 1000000/3600 , 2)  time_waited_hours,                                
    -- LAG(ROUND(SUM(l.time_waited_micro) / 1000000/3600 , 2))   OVER (PARTITION BY WAIT_TYPE ORDER BY s1.snap_id) time_waited_hours_prev,   
       ROUND(SUM(l.time_waited_micro) / 1000000,2) -LAG(ROUND(SUM(l.time_waited_micro) / 1000000,2))OVER ( PARTITION BY WAIT_TYPE ORDER BY s1.snap_id) WAIT_SEC_DELTA ,                                                          
       ROUND(SUM(l.time_waited_micro) / SUM(l.total_waits) / 1000, 2)                                avg_wait_ms                                                               
     -- , ROUND( SUM(l.time_waited_micro)-LAG(SUM(l.time_waited_micro)) OVER (PARTITION BY WAIT_TYPE ORDER BY s1.snap_id) * 100 / SUM(SUM(l.time_waited_micro)-LAG((sum(l.time_waited_micro)) OVER (PARTITION BY WAIT_TYPE ORDER BY s1.snap_id)), 2)                                  
     --   PCT_TIME                                                                           
FROM stats$snapshot s1,(SELECT wait_type,snap_id,event, total_waits, time_waited_micro                           
      FROM system_event e                                                               
 /*     UNION                                                                             
      SELECT 'CPU',snap_id,N.stat_name, NULL, VALUE                                              
      FROM STATS$SYS_TIME_MODEL T ,STATS$TIME_MODEL_STATNAME N                                                           
      WHERE stat_name IN ('background cpu time', 'DB CPU')
      and T.STAT_ID=N.STAT_ID
*/
      ) l                           
WHERE wait_type <> 'Idle' 
AND s1.snap_id 
 BETWEEN &&begin_snap AND &&end_snap   
AND s1.snap_id =l.snap_id                                                             
 GROUP BY wait_type,s1.snap_id,s1.snap_time                                            
ORDER BY wait_type,snap_id,WAIT_SEC_DELTA  
)  
GROUP BY WAIT_TYPE
ORDER BY PCT_TIME DESC                                 
/                                                                                                                                
                           
BREAK ON EVENT  SKIP PAGE ;
COMPUTE SUM LABEL TOTAL_Min OF WT_MIN ON EVENT;
 -- TTITLE LEFT 'EVENT: ' EVENT SKIP 2    
                           
                           
Prompt ********************************** CHOSE WHICH WAIT_CLASS TO INVESTIGATE **************************************************
Prompt System I/O  Network Commit User I/O Other Concurrency Application Configuration Administrative Queueing

undefine wait_class
COL WAIT_MIN FOR 99,990.99

SELECT l.*,round(WAIT_SEC_DELTA/60,2) WAIT_MIN from 
(
SELECT                                                                 
w1.event,                                                              
s1.snap_time,                                                          
s1.snap_id,                                                            
--w1.total_waits,                                                        
-- LAG(w1.total_waits)OVER (PARTITION BY w1.event ORDER BY s1.snap_id) prev_val,                                   
w1.total_waits -LAG(w1.total_waits)OVER (PARTITION BY w1.event ORDER BY s1.snap_id) waits,                                   
ROUND((w1.time_waited_micro) / 1000000,2)-LAG(ROUND((w1.time_waited_micro) / 1000000,2)) OVER (PARTITION BY w1.event ORDER BY s1.snap_id) WAIT_SEC_DELTA  
FROM stats$snapshot s1,                                                
stats$system_event w1                                                  
WHERE s1.snap_id BETWEEN &begin_snap AND &end_snap                     
AND s1.snap_id = w1.snap_id                                            
AND EXISTS (SELECT 1 FROM v$system_event s where w1.event_id=s.event_id and s.wait_class = '&wait_class')        
ORDER BY event,snap_id 
) l
WHERE WAIT_SEC_DELTA >1
ORDER BY SUM(WAIT_SEC_DELTA) OVER (PARTITION BY EVENT) DESC,event,snap_id;     
PROMPT
PROMPT
PROMPT  ********************************* STATSPACK STATS REPORT *********************************************  

--  Call statspack to calculate certain statistics

clear break compute;
repfooter off;
ttitle off;
btitle off;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 newpage 1 recsep off;
set trimspool on trimout on define "&" concat "." serveroutput on;
define avwt_fmt     = 99990.99
define linesize_fmt = 85
--  Must not be modified
--  Bytes to megabytes
define btomb = 1048576;
--  Bytes to kilobytes
define btokb = 1024;
--  Centiseconds to seconds
define cstos = 100;
--  Microseconds to milli-seconds
define ustoms = 1000;
--  Microseconds to seconds
define ustos = 1000000;
define top_n_events = 5;
define total_event_time_s_th = .001;
define pct_cpu_diff_th = 5;

--  Get the database info to display in the report

set termout off;
column para       new_value para;
column versn      new_value versn;
column host_name  new_value host_name;
column db_name    new_value db_name;
column inst_name  new_value inst_name;
column btime      new_value btime;
column etime      new_value etime;
column sutime     new_value sutime;

select parallel       para
     , version        versn
     , host_name      host_name
     , db_name        db_name
     , instance_name  inst_name
     , to_char(snap_time, 'YYYYMMDD HH24:MI:SS')   btime
     , to_char(s.startup_time, 'DD-Mon-YY HH24:MI') sutime
  from stats$database_instance di
     , stats$snapshot          s
 where s.snap_id          = :bid
   and s.dbid             = :dbid
   and s.instance_number  = :inst_num
   and di.dbid            = s.dbid
   and di.instance_number = s.instance_number
   and di.startup_time    = s.startup_time;
variable para       varchar2(9);
variable versn      varchar2(10);
variable host_name  varchar2(64);
variable db_name    varchar2(20);
variable inst_name  varchar2(20);
variable btime      varchar2(25);
variable etime      varchar2(25);
variable sutime     varchar2(19);
begin
  :para      := '&para';
  :versn     := '&versn';
  :host_name := '&host_name';
  :db_name   := '&db_name';
  :inst_name := '&inst_name';
  :btime     := '&btime';
  :etime     := '&etime';
  :sutime    := '&sutime';
end;
/

set termout off heading off verify off;
variable lhtr   number;
variable bfwt   number;
variable tran   number;
variable chng   number;
variable ucal   number;
variable urol   number;
variable ucom   number;
variable rsiz   number;
variable phyr   number;
variable phyrd  number;
variable phyrdl number;
variable phyrc  number;
variable phyw   number;
variable prse   number;
variable hprs   number;
variable recr   number;
variable gets   number;
variable slr    number;
variable rlsr   number;
variable rent   number;
variable srtm   number;
variable srtd   number;
variable srtr   number;
variable strn   number;
variable call   number;
variable lhr    number;
variable bsp    varchar2(512);
variable esp    varchar2(512);
variable bbc    varchar2(512);
variable ebc    varchar2(512);
variable blb    varchar2(512);
variable elb    varchar2(512);
variable bs     varchar2(512);
variable twt    number;
variable logc   number;
variable prscpu number;
variable prsela number;
variable tcpu   number;
variable exe    number;
variable bspm   number;
variable espm   number;
variable bfrm   number;
variable efrm   number;
variable blog   number;
variable elog   number;
variable bocur  number;
variable eocur  number;
variable bpgaalloc number;
variable epgaalloc number;
variable bsgaalloc number;
variable esgaalloc number;
variable bnprocs   number;
variable enprocs   number;
variable timstat   varchar2(20);
variable statlvl   varchar2(40);
-- OS Stat
variable bncpu  number;
variable encpu  number;
variable bpmem  number;
variable epmem  number;
variable blod   number;
variable elod   number;
variable itic   number;
variable btic   number;
variable iotic  number;
variable rwtic  number;
variable utic   number;
variable stic   number;
variable vmib   number;
variable vmob   number;
variable oscpuw number;
-- OS Stat derived
variable ttic   number;
variable ttics  number;
variable cpubrat number;
variable cpuirat number;
-- Time Model
variable dbtim   number;
variable dbcpu   number;
variable bgela   number;
variable bgcpu   number;
variable prstela number;
variable sqleela number;
variable conmela number;
variable bncpu   number;
-- RAC variables
variable dmsd   number;
variable dmfc   number;
variable dmsi   number;
variable pmrv   number;
variable pmpt   number;
variable npmrv   number;
variable npmpt   number;
variable dbfr   number;
variable dpms   number;
variable dnpms   number;
variable glsg   number;
variable glag   number;
variable glgt   number;
variable gccrrv   number;
variable gccrrt   number;
variable gccrfl   number;
variable gccurv   number;
variable gccurt   number;
variable gccufl   number;
variable gccrsv   number;
variable gccrbt   number;
variable gccrft   number;
variable gccrst   number;
variable gccusv   number;
variable gccupt   number;
variable gccuft   number;
variable gccust   number;
variable msgsq    number;
variable msgsqt   number;
variable msgsqk   number;
variable msgsqtk  number;
variable msgrq    number;
variable msgrqt   number;

begin
  STATSPACK.STAT_CHANGES
   ( :bid,    :eid
   , :dbid,   :inst_num
   , :para                     -- End of IN arguments
   , :lhtr,   :bfwt
   , :tran,   :chng
   , :ucal,   :urol
   , :rsiz
   , :phyr,   :phyrd
   , :phyrdl, :phyrc
   , :phyw,   :ucom
   , :prse,   :hprs
   , :recr,   :gets
   , :slr
   , :rlsr,   :rent
   , :srtm,   :srtd
   , :srtr,   :strn
   , :lhr
   , :bbc,    :ebc
   , :bsp,    :esp
   , :blb
   , :bs,     :twt
   , :logc,   :prscpu
   , :tcpu,   :exe
   , :prsela
   , :bspm,   :espm
   , :bfrm,   :efrm
   , :blog,   :elog
   , :bocur,  :eocur
   , :bpgaalloc,   :epgaalloc
   , :bsgaalloc,   :esgaalloc
   , :bnprocs,     :enprocs
   , :timstat,     :statlvl
   , :bncpu,  :encpu           -- OS Stat
   , :bpmem,  :epmem
   , :blod,   :elod
   , :itic,   :btic
   , :iotic,  :rwtic
   , :utic,   :stic
   , :vmib,   :vmob
   , :oscpuw
   , :dbtim,  :dbcpu           -- Time Model
   , :bgela,  :bgcpu
   , :prstela,:sqleela
   , :conmela
   , :dmsd,   :dmfc            -- begin RAC
   , :dmsi
   , :pmrv,   :pmpt 
   , :npmrv,  :npmpt 
   , :dbfr
   , :dpms,   :dnpms 
   , :glsg,   :glag 
   , :glgt
   , :gccrrv, :gccrrt, :gccrfl 
   , :gccurv, :gccurt, :gccufl 
   , :gccrsv
   , :gccrbt, :gccrft 
   , :gccrst, :gccusv 
   , :gccupt, :gccuft 
   , :gccust
   , :msgsq,  :msgsqt
   , :msgsqk, :msgsqtk
   , :msgrq,  :msgrqt          -- end RAC
   );
   :call    := :ucal + :recr;
   -- total ticks (cs)
   :ttic    := :btic + :itic;
    -- total ticks (s)
   :ttics   := :ttic/100;
   -- Busy to total CPU  ratio
   :cpubrat := :btic / :ttic;
   :cpuirat := :itic / :ttic;
end;
/

-- Print stat consistency warnings

set termout on;
set heading off;

select 'WARNING: statistics_level setting changed between begin/end snaps: Time Model'
     , '         data is INVALID'
  from dual
 where :statlvl = 'INCONSISTENT_BASIC';

select 'WARNING: timed_statistics setting changed between begin/end snaps: TIMINGS'
     , '         ARE INVALID'
  from dual
 where :timstat = 'INCONSISTENT';

set heading on;   
--  Standard formatting

column chr4n      format a4      newline
column ch5        format a5
column ch5        format a5
column ch6        format a6
column ch6n       format a6      newline
column ch7        format a7
column ch7n       format a7      newline
column ch9        format a9
column ch14n      format a14     newline
column ch16t      format a16              trunc
column ch17       format a17
column ch17n      format a17     newline
column ch18n      format a18     newline
column ch19       format a19
column ch19n      format a19     newline
column ch21       format a21
column ch21n      format a21     newline
column ch22       format a22
column ch22n      format a22     newline
column ch23       format a23
column ch23n      format a23     newline
column ch24       format a24
column ch24n      format a24     newline
column ch25       format a25
column ch25n      format a25     newline
column ch20       format a20
column ch20n      format a20     newline
column ch32n      format a32     newline
column ch40n      format a40     newline
column ch42n      format a42     newline
column ch43n      format a43     newline
column ch52n      format a52     newline  just r
column ch53n      format a53     newline
column ch59n      format a59     newline  just r
column ch78n      format a78     newline
column ch80n      format a80     newline

column num3       format             999                 just left
column num3_2     format             999.99
column num3_2n    format             999.99     newline
column num4c      format           9,999
column num4c_2    format           9,999.99
column num4c_2n   format           9,999.99     newline
column num5c      format          99,999   
column num6c      format         999,999   
column num6c_2    format         999,999.99
column num6c_2n   format         999,999.99     newline
column num6cn     format         999,999        newline
column num7c      format       9,999,999
column num7c_2    format       9,999,999.99
column num8c      format      99,999,999
column num8cn     format      99,999,999        newline
column num8c_2    format      99,999,999.99
column num8cn     format      99,999,999        newline
column num9c      format     999,999,999
column num9cn     format     999,999,999        newline
column num10c     format   9,999,999,999

set heading off
select 'Host'      ch5
     , 'Name:'     ch7, nvl(:host_name, ' ')  ch16t
     , 'Num CPUs:' ch9, nvl(:bncpu, to_number(null))      num3
     , '      '
     , 'Phys Memory (MB):' ch17, decode(:bpmem, null, to_number(null), :bpmem/1024/1024) num6c
     , '~~~~'              chr4n
  from sys.dual;
set heading on;


--  Print snapshot information

column inst_num   noprint
column instart_fmt new_value INSTART_FMT noprint;
column instart    new_value instart noprint;
column session_id new_value SESSION noprint;
column ela        new_value ELA     noprint;
column btim       new_value btim    heading 'Start Time' format a19 just c;
column etim       new_value etim    heading 'End Time'   format a19 just c;
column xbid        format 999999990;
column xeid        format 999999990;
column dur        heading 'Duration(mins)' format 999,990.00 just r;
column sess_id    new_value sess_id noprint;
column serial     new_value serial  noprint;
column bbgt       new_value bbgt noprint;
column ebgt       new_value ebgt noprint;
column bdrt       new_value bdrt noprint;
column edrt       new_value edrt noprint;
column bet        new_value bet  noprint;
column eet        new_value eet  noprint;
column bsmt       new_value bsmt noprint;
column esmt       new_value esmt noprint;
column bvc        new_value bvc  noprint;
column evc        new_value evc  noprint;
column bpc        new_value bpc  noprint;
column epc        new_value epc  noprint;
column bspr       new_value bspr noprint;
column espr       new_value espr noprint;
column bslr       new_value bslr noprint;
column eslr       new_value eslr noprint;
column bsbb       new_value bsbb noprint;
column esbb       new_value esbb noprint;
column bsrl       new_value bsrl noprint;
column esrl       new_value esrl noprint;
column bsiw       new_value bsiw noprint;
column esiw       new_value esiw noprint;
column bcrb       new_value bcrb noprint;
column ecrb       new_value ecrb noprint;
column bcub       new_value bcub noprint;
column ecub       new_value ecub noprint;
column blog       format 99,999;
column elog       format 99,999;
column ocs        format 99,999.0;
column comm       format a10 trunc;
column nl         Format a100 newline;
column nl11       format a11 newline;
column nl16       format a16 newline;
column exec       format 999,999,999;  
column tran       format 9,999,999;

set heading off;
select 'Snapshot       Snap Id     Snap Time      Sessions Cursors  Executions Transactions Curs/Sess' nl
     , '~~~~~~~~    ---------- ------------------ -------- -------- ---------- ------------ ----------'    nl
     , 'Begin Snap:'                                          nl11
     , b.snap_id                                                xbid
     , to_char(b.snap_time, 'dd-Mon-yy hh24:mi:ss')             btim
     , :blog                                                    blog
     , :bocur                                                   blog
     , to_number(b.ucomment)                                    exec
     , to_number(b.ucomment)                                    tran
     , :bocur/:blog                                             ocs
     , '  End Snap:'                                            nl11
     , e.snap_id                                                xeid
     , to_char(e.snap_time, 'dd-Mon-yy hh24:mi:ss')             etim
     , :elog                                                    elog
     ,:eocur                                                    elog
     , to_number(b.ucomment)                                    exec
     , to_number(b.ucomment)                                    tran
     , :eocur/:elog                                             ocs
     , '   Elapsed:     '                                     nl16
     , round(((e.snap_time - b.snap_time) * 1440 * 60), 0)/60   dur  -- mins
     , '(mins)'
     , b.ucomment                                               comm
     , b.ucomment                                               comm
     , :exe                                                    exec 
     , :tran                                                   tran  
     , b.instance_number                                        inst_num
     , to_char(b.startup_time, 'dd-Mon-yy hh24:mi:ss')          instart_fmt
     , b.session_id
     , round(((e.snap_time - b.snap_time) * 1440 * 60), 0)      ela  -- secs
     , to_char(b.startup_time,'YYYYMMDD HH24:MI:SS')            instart
     , e.session_id                                             sess_id
     , e.serial#                                                serial
     , b.buffer_gets_th                                         bbgt
     , e.buffer_gets_th                                         ebgt
     , b.disk_reads_th                                          bdrt
     , e.disk_reads_th                                          edrt
     , b.executions_th                                          bet
     , e.executions_th                                          eet
     , b.sharable_mem_th                                        bsmt
     , e.sharable_mem_th                                        esmt
     , b.version_count_th                                       bvc
     , e.version_count_th                                       evc
     , b.parse_calls_th                                         bpc
     , e.parse_calls_th                                         epc
     , b.seg_phy_reads_th                                       bspr
     , e.seg_phy_reads_th                                       espr
     , b.seg_log_reads_th                                       bslr
     , e.seg_log_reads_th                                       eslr
     , b.seg_buff_busy_th                                       bsbb
     , e.seg_buff_busy_th                                       esbb
     , b.seg_rowlock_w_th                                       bsrl
     , e.seg_rowlock_w_th                                       esrl
     , b.seg_itl_waits_th                                       bsiw
     , e.seg_itl_waits_th                                       esiw
     , b.seg_cr_bks_rc_th                                       bcrb
     , e.seg_cr_bks_rc_th                                       ecrb
     , b.seg_cu_bks_rc_th                                       bcub
     , e.seg_cu_bks_rc_th                                       ecub
  from stats$snapshot b
     , stats$snapshot e
 where b.snap_id         = :bid
   and e.snap_id         = :eid
   and b.dbid            = :dbid
   and e.dbid            = :dbid
   and b.instance_number = :inst_num
   and e.instance_number = :inst_num
   and b.startup_time    = e.startup_time
   and b.snap_time       < e.snap_time;
set heading on;

variable btim    varchar2 (20);
variable etim    varchar2 (20);
variable ela     number;
variable instart varchar2 (18);
variable bbgt    number;
variable ebgt    number;
variable bdrt    number;
variable edrt    number;
variable bet     number;
variable eet     number;
variable bsmt    number;
variable esmt    number;
variable bvc     number;
variable evc     number;
variable bpc     number;
variable epc     number;
variable spctim number;
variable pct_sp_oss_cpu_diff number;
begin
   :btim    := '&btim'; 
   :etim    := '&etim'; 
   :ela     :=  &ela;
   :instart := '&instart';
   :bbgt    := &bbgt;
   :ebgt    := &ebgt;
   :bdrt    := &bdrt;
   :edrt    := &edrt;
   :bet     := &bet;
   :eet     := &eet;
   :bsmt    := &bsmt;
   :esmt    := &esmt;
   :bvc     := &bvc;
   :evc     := &evc;
   :bpc     := &bpc;
   :epc     := &epc;
   -- Statspack total CPU time (secs) - assumes Begin CPU count and End 
   -- CPU count are identical
   :spctim := :ela * :encpu;
   -- Statspack to OS Stat CPU percentage
   select decode(:ttics, null, 0, 0, 0
                ,100*(abs(:spctim-round(:ttics))/:spctim))
     into :pct_sp_oss_cpu_diff 
     from sys.dual;
end;
/

--
set heading off;

--
--  Cache Sizes

column chr50  format a50 newline;
column chr28  format a28 newline;
column val  format a10 just r;
column chr16 format a16;

select 'Cache Sizes                       Begin        End'            chr50
     , '~~~~~~~~~~~                  ---------- ----------'            chr50
     , '               Buffer Cache:'                                  chr28
     , lpad(to_char(round(:bbc/1024/1024),'999,999') || 'M', 10)       val
     , lpad(decode( :ebc, :bbc, null
                   , to_char(round(:ebc/&&btomb), '999,999') || 'M'), 10) val
     , ' Std Block Size:'                                              chr16
     , lpad(to_char((:bs/1024)          ,'999') || 'K',10)             val
     , '           Shared Pool Size:'                                  chr28
     , lpad(to_char(round(:bsp/1024/1024),'999,999') || 'M',10)        val
     , lpad(decode( :esp, :bsp, null
                  , to_char(round(:esp/&&btomb), '999,999') || 'M'), 10) val
     , '     Log Buffer:'                                              chr18
     , lpad(to_char(round(:blb/1024)     ,'999,999') || 'K', 10)       val
  from sys.dual;


--
--  Load Profile
 set linesize &&linesize_fmt;
column dscr     format a28 newline;
column val      format 9,999,999,999,990.99;
column sval     format 99,990.99;
column svaln    format 99,990.99 newline;
column totcalls new_value totcalls noprint
column pctval   format 990.99;
column bpctval  format 99990.99;

select 'Load Profile                            Per Second       Per Transaction'
      ,'~~~~~~~~~~~~                       ---------------       ---------------'
      ,'                  Redo size:' dscr, round(:rsiz/:ela,2)  val
                                          , round(:rsiz/:tran,2) val
      ,'              Logical reads:' dscr, round(:slr/:ela,2)  val
                                          , round(:slr/:tran,2) val
      ,'              Block changes:' dscr, round(:chng/:ela,2)  val
                                          , round(:chng/:tran,2) val
      ,'             Physical reads:' dscr, round(:phyr/:ela,2)  val
                                          , round(:phyr/:tran,2) val
      ,'            Physical writes:' dscr, round(:phyw/:ela,2)  val
                                          , round(:phyw/:tran,2) val
      ,'                 User calls:' dscr, round(:ucal/:ela,2)  val
                                          , round(:ucal/:tran,2) val
      ,'                     Parses:' dscr, round(:prse/:ela,2)  val
                                          , round(:prse/:tran,2) val
      ,'                Hard parses:' dscr, round(:hprs/:ela,2)  val
                                          , round(:hprs/:tran,2) val
      ,'                      Sorts:' dscr, round((:srtm+:srtd)/:ela,2)  val
                                          , round((:srtm+:srtd)/:tran,2) val
      ,'                     Logons:' dscr, round(:logc/:ela,2)  val
                                          , round(:logc/:tran,2) val
      ,'                 Executions:' dscr, round(:exe/:ela,2)   val
                                          , round(:exe/:tran,2)  val
      ,'               Transactions:' dscr, round(:tran/:ela,2)  val
      , '                           ' dscr
      ,'  % Blocks changed per Read:' dscr,  round(100*:chng/:slr,2)  pctval
      ,'   Recursive Call %:'         chr20, round(100*:recr/:call,2) bpctval
      ,' Rollback per transaction %:' dscr,  round(100*:urol/:tran,2) pctval
      ,'      Rows per Sort:'         chr20, decode((:srtm+:srtd)
                                                   ,0,to_number(null)
                                                   ,round(:srtr/(:srtm+:srtd),2)) bpctval
 from sys.dual;

--
--  Instance Efficiency Percentages

column ldscr  format a50
column chr20  format a20
column nl format a60 newline

select 'Instance Efficiency Percentages'               ldscr
      ,'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'               ldscr
      ,'            Buffer Nowait %:'                  dscr
      , round(100*(1-:bfwt/:gets),2)                   pctval
      ,'      Redo NoWait %:'                          chr20
      , decode(:rent,0,to_number(null), round(100*(1-:rlsr/:rent),2))  pctval
      ,'            Buffer  Hit   %:'                  dscr
      , round(100*(1 - :phyrc/:gets),2)                pctval
      ,'   In-memory Sort %:'                          chr20
      , decode((:srtm+:srtd),0,to_number(null),
                               round(100*:srtm/(:srtd+:srtm),2))       pctval
      ,'            Library Hit   %:'                  dscr
      , round(100*:lhtr,2)                             pctval
      ,'       Soft Parse %:'                          chr20
      , round(100*(1-:hprs/:prse),2)                   pctval
      ,'         Execute to Parse %:'                  dscr
      , round(100*(1-:prse/:exe),2)                    pctval
      ,'        Latch Hit %:'                          chr20
      , round(100*(1-:lhr),2)                          pctval
      ,'Parse CPU to Parse Elapsd %:'                  dscr
      , decode(:prsela, 0, to_number(null)
                      , round(100*:prscpu/:prsela,2))  pctval
      ,'    % Non-Parse CPU:'                          chr20
      , decode(:tcpu, 0, to_number(null)
                    , round(100*(1-(:prscpu/:tcpu)),2))  pctval
  from sys.dual;

-- Setup vars in case snap < 5 taken
define b_total_cursors = 0
define e_total_cursors = 0
define b_total_sql     = 0
define e_total_sql     = 0
define b_total_sql_mem = 0
define e_total_sql_mem = 0

column b_total_cursors new_value b_total_cursors noprint
column e_total_cursors new_value e_total_cursors noprint
column b_total_sql     new_value b_total_sql     noprint
column e_total_sql     new_value e_total_sql     noprint
column b_total_sql_mem new_value b_total_sql_mem noprint
column e_total_sql_mem new_value e_total_sql_mem noprint

select  ' Shared Pool Statistics        Begin   End'        nl
      , '                               ------  ------'
      , '             Memory Usage %:'                 dscr
      , 100*(1-:bfrm/:bspm)                            pctval
      , 100*(1-:efrm/:espm)                            pctval
      , '    % SQL with executions>1:'                 dscr
      , 100*(1-b.single_use_sql/b.total_sql)           pctval
      , 100*(1-e.single_use_sql/e.total_sql)           pctval
      , '  % Memory for SQL w/exec>1:'                 dscr
      , 100*(1-b.single_use_sql_mem/b.total_sql_mem)   pctval
      , 100*(1-e.single_use_sql_mem/e.total_sql_mem)   pctval
      , nvl(b.total_cursors, 0)                        b_total_cursors
      , nvl(e.total_cursors, 0)                        e_total_cursors
      , nvl(b.total_sql, 0)                            b_total_sql
      , nvl(e.total_sql, 0)                            e_total_sql
      , nvl(b.total_sql_mem, 0)                        b_total_sql_mem
      , nvl(e.total_sql_mem, 0)                        e_total_sql_mem
  from stats$sql_statistics b
     , stats$sql_statistics e
 where b.snap_id         = :bid
   and e.snap_id         = :eid
   and b.instance_number = :inst_num
   and e.instance_number = :inst_num
   and b.dbid            = :dbid
   and e.dbid            = :dbid;

variable b_total_cursors number;
variable e_total_cursors number;
variable b_total_sql     number;
variable e_total_sql     number;
variable b_total_sql_mem number;
variable e_total_sql_mem number;
begin
  :b_total_cursors := &&b_total_cursors;
  :e_total_cursors := &&e_total_cursors;
  :b_total_sql     := &&b_total_sql;
  :e_total_sql     := &&e_total_sql;
  :b_total_sql_mem := &&b_total_sql_mem;
  :e_total_sql_mem := &&e_total_sql_mem;
end;
/


--
--

set heading on;
repfooter center -
   '-------------------------------------------------------------';

--
--  Top N Wait Events

col idle     noprint;
col event    format a41          heading 'Top &&top_n_events Timed Events|~~~~~~~~~~~~~~~~~~|Event' trunc;
col waits    format 999,999,990  heading 'Waits';
col time     format 99,999,990   heading 'Time (s)';
col pctwtt   format 999.9        heading '%Total|Call|Time';
col avwait   format 99990        heading 'Avg|wait|(ms)';

select event
     , waits
     , time
     , avwait
     , pctwtt
  from (select event, waits, time, pctwtt, avwait
          from (select e.event                               event
                     , e.total_waits - nvl(b.total_waits,0)  waits
                     , (e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000  time
                     , decode ( (e.total_waits - nvl(b.total_waits, 0)), 0, to_number(NULL)
                             ,    ( (e.time_waited_micro - nvl(b.time_waited_micro,0)) / &&ustoms )
                                / (e.total_waits - nvl(b.total_waits,0))
                             )        avwait
                     , decode(:twt + :tcpu*10000, 0, 0,
                                100
                              * (e.time_waited_micro - nvl(b.time_waited_micro,0))
                              / (:twt + :tcpu*10000)                        
                              )                              pctwtt
                 from stats$system_event b
                    , stats$system_event e
                where b.snap_id(+)          = :bid
                  and e.snap_id             = :eid
                  and b.dbid(+)             = :dbid
                  and e.dbid                = :dbid
                  and b.instance_number(+)  = :inst_num
                  and e.instance_number     = :inst_num
                  and b.event(+)            = e.event
                  and e.total_waits         > nvl(b.total_waits,0)
                  and e.event not in (select event from stats$idle_event)
               union all
               select 'CPU time'                              event
                    , to_number(null)                         waits
                    , :tcpu/100                               time
                    , to_number(null)                         avwait
                    , decode(:twt + :tcpu*10000, 0, 0,
                               100
                             * :tcpu*10000 
                             / (:twt + :tcpu*10000)
                            )                                 pctwait
                 from dual
                where :tcpu > 0
               )
         order by time desc, waits desc
       )
 where rownum <= &&top_n_events;
--
--

set space 1 termout on newpage 1;
whenever sqlerror exit;

set heading off;
repfooter off;

-- Performance Summary continued

set newpage 0;

ttitle off;

select 'Host CPU  ' || decode(:bncpu, :encpu, '(CPUs: '|| :bncpu || ')',  '(Begin CPUs: '|| :bncpu || ' End CPUs: '|| :encpu || ')') ch78n
     , '~~~~~~~~              Load Average'                                              ch78n
     , '                      Begin     End      User  System    Idle     WIO     WCPU'  ch78n
     , '                    ------- -------   ------- ------- ------- ------- --------'  ch78n
     , '                   '
     , round(:blod,2)          pctval
     , round(:elod,2)          pctval
     , ' '
     , 100*(:utic   / :ttic)   pctval
     , 100*(:stic   / :ttic)   pctval
     , 100*(:itic   / :ttic)   pctval
     , 100*(:iotic  / :ttic)   pctval
     , 100*(:oscpuw / :ttic)   pctval
  from sys.dual
 where :ttic > 0;

set newpage 1;

select 'Note: There is a ' || round(:pct_sp_oss_cpu_diff) || '% discrepancy between the OS Stat total CPU time and'
     , '      the total CPU time estimated by Statspack'
     , '          OS Stat CPU time: ' || round(:ttics)  || '(s) (BUSY_TIME + IDLE_TIME)'
     , '        Statspack CPU time: ' || :spctim || '(s) (Elapsed time * num CPUs in end snap)'
  from sys.dual
 where &pct_cpu_diff_th < :pct_sp_oss_cpu_diff
   and :ttics > 0;

select 'Instance CPU'                               ch40n
     , '~~~~~~~~~~~~'                               ch40n
     , '              % of total CPU for Instance:' ch45n, 100* ((:dbcpu+:bgcpu)/1000000)
                                                              / (:ttics)               pctval
     , '              % of busy  CPU for Instance:' ch45n, 100* ((:dbcpu+:bgcpu)/1000000)
                                                              / ((:btic)/100)          pctval
     , '  %DB time waiting for CPU - Resource Mgr:' ch45n, decode(:rwtic, 0, to_number(null), 
                                                           100*(round(:rwtic/:dbtim)) )  pctval
  from sys.dual
 where :dbtim    > 0
   and :btic/100 > 0;

column kpersec format 999,999,999.9
select 'Virtual Memory Paging' ch78n
     , '~~~~~~~~~~~~~~~~~~~~~' ch78n
     , '                     KB paged out per sec: ' ch43n, (:vmob/1024)/:ela  kpersec
     , '                     KB paged  in per sec: ' ch43n, (:vmib/1024)/:ela  kpersec
  from sys.dual
 where :vmob + :vmib > 0;

col bpctval format 999999999.9
repfooter center -
   '-------------------------------------------------------------';
col memsz format 9,999,999.9
select 'Memory Statistics                       Begin          End' ch79n
     , '~~~~~~~~~~~~~~~~~                ------------ ------------' ch79n
     , '                  Host Mem (MB):' ch32n, :bpmem/&&btomb memsz, :epmem/&&btomb memsz
     , '                   SGA use (MB):' ch32n, :bsgaalloc/&&btomb memsz, :esgaalloc/&&btomb memsz
     , '                   PGA use (MB):' ch32n, :bpgaalloc/&&btomb memsz, :epgaalloc/&&btomb memsz
     , '    % Host Mem used for SGA+PGA:' ch32n, 100*(:bpgaalloc + :bsgaalloc)/:bpmem bpctval
                                               , 100*(:epgaalloc + :esgaalloc)/:epmem bpctval
  from sys.dual
 where :bpmem !=0;

repfooter off

--
--

set space 1 termout on newpage 0;
whenever sqlerror exit;
repfooter center -
   '-------------------------------------------------------------';

--
--  SQL Memory stats

set heading off;

ttitle lef 'SQL Memory Statistics  '-
           'DB/Inst: ' db_name '/' inst_name '  '-
           'Snaps: ' format 99999999 begin_snap '-' format 99999999 end_snap -
       skip 2;

select '                                   Begin            End         % Diff'            ch78n
     , '                          -------------- -------------- --------------'            ch78n
     , '   Avg Cursor Size (KB): ' ch25n, :b_total_sql_mem/&&btokb/:b_total_cursors        num8c_2
                                        , :e_total_sql_mem/&&btokb/:e_total_cursors        num8c_2
                                        , 100*(  (:e_total_sql_mem/&&btokb/:e_total_cursors)
                                               - (:b_total_sql_mem/&&btokb/:b_total_cursors)
                                              )
                                             /(:e_total_sql_mem/&&btokb/:e_total_cursors)   num8c_2
     , ' Cursor to Parent ratio: ' ch25n, :b_total_cursors/:b_total_sql                     num8c_2
                                        , :e_total_cursors/:e_total_sql                     num8c_2
                                        , 100*( (:e_total_cursors/:e_total_sql)
                                               -(:b_total_cursors/:b_total_sql)
                                              )
                                             /(:e_total_cursors/:e_total_sql)               num8c_2
     , '          Total Cursors: ' ch25n, :b_total_cursors                                  num10c
                                        , :e_total_cursors                                  num10c
                                        , 100*( (:e_total_cursors)
                                               -(:b_total_cursors)
                                              )
                                             /(:e_total_cursors)                            num8c_2
     , '          Total Parents: ' ch25n, :b_total_sql                                      num10c
                                        , :e_total_sql                                      num10c
                                        , 100*( (:e_total_sql)
                                               -(:b_total_sql)
                                              )
                                             /(:e_total_sql)                                num8c_2
  from sys.dual
 where :b_total_cursors > 0
   and :e_total_cursors > 0;
   
set heading on ;
PROMPT
PROMPT ***********************  Segment Statistics **************************************************
PROMPT
-- choose The number of top segments to display in each of the High-Load Segment
-- sections of the report
define top_n_segstat = 5;
-- Logical Reads
ttitle lef 'Segments by Logical Reads  ' -
           'DB/Inst: ' db_name '/' inst_name '  '-
           'Snaps: ' format 99999999 begin_snap '-' format 99999999 end_snap -
       skip 1 -
           '-> End Segment Logical Reads Threshold: '   format 99999999 eslr -
       skip 1 - 
           '-> Pct Total shows % of logical reads for each top segment compared with total' -
       skip 1 -
           '   logical reads for all segments captured by the Snapshot' -
       skip 2;

column owner           heading "Owner"           format a10    trunc
column tablespace_name heading "Tablespace"      format a10    trunc
column object_name     heading "Object Name"     format a20    trunc
column subobject_name  heading "Subobject|Name"  format a12    trunc
column object_type     heading "Obj.|Type"       format a5     trunc
col    ratio           heading "  Pct|Total"     format a5

column logical_reads heading "Logical|Reads" format 999,999,999

select n.owner
     , n.tablespace_name
     , n.object_name
     , case when length(n.subobject_name) < 11 then
              n.subobject_name
            else
              substr(n.subobject_name,length(n.subobject_name)-9)
       end subobject_name
     , n.object_type
     , r.logical_reads
     , substr(to_char(r.ratio * 100,'999.9MI'), 1, 5) ratio
  from stats$seg_stat_obj n
     , (select *
          from (select e.dataobj#
                     , e.obj#
                     , e.ts#
                     , e.dbid
                     , e.logical_reads - nvl(b.logical_reads, 0) logical_reads
                     , ratio_to_report(e.logical_reads - nvl(b.logical_reads, 0)) over () ratio
                  from stats$seg_stat e
                     , stats$seg_stat b
                 where b.snap_id(+)                              = :bid
                   and e.snap_id                                 = :eid
                   and b.dbid(+)                                 = :dbid
                   and e.dbid                                    = :dbid
                   and b.instance_number(+)                      = :inst_num
                   and e.instance_number                         = :inst_num
                   and b.ts#(+)                                  = e.ts#
                   and b.obj#(+)                                 = e.obj#
                   and b.dataobj#(+)                             = e.dataobj#
                   and e.logical_reads - nvl(b.logical_reads, 0) > 0
                 order by logical_reads desc) d
          where rownum <= &&top_n_segstat) r
 where n.dataobj# = r.dataobj#
   and n.obj#     = r.obj#
   and n.ts#      = r.ts#
   and n.dbid     = r.dbid
   and         7 <= (select snap_level from stats$snapshot where snap_id = :bid)
 order by logical_reads desc;


-- Physical Reads
set newpage 2
ttitle lef 'Segments by Physical Reads  '-
           'DB/Inst: ' db_name '/' inst_name '  '-
           'Snaps: ' format 99999999 begin_snap '-' format 99999999 end_snap -
       skip 1 -
           '-> End Segment Physical Reads Threshold: '   espr -
       skip 2

column physical_reads heading "Physical|Reads" format 999,999,999

select n.owner
     , n.tablespace_name
     , n.object_name
     , case when length(n.subobject_name) < 11 then
              n.subobject_name
            else
              substr(n.subobject_name,length(n.subobject_name)-9)
       end subobject_name
     , n.object_type
     , r.physical_reads
     , substr(to_char(r.ratio * 100,'999.9MI'), 1, 5) ratio
  from stats$seg_stat_obj n
     , (select *
          from (select e.dataobj#
                     , e.obj#
                     , e.ts#
                     , e.dbid
                     , e.physical_reads - nvl(b.physical_reads, 0) physical_reads
                     , ratio_to_report(e.physical_reads - nvl(b.physical_reads, 0)) over () ratio
                  from stats$seg_stat e
                     , stats$seg_stat b
                 where b.snap_id(+)                                = :bid
                   and e.snap_id                                   = :eid
                   and b.dbid(+)                                   = :dbid
                   and e.dbid                                      = :dbid
                   and b.instance_number(+)                        = :inst_num
                   and e.instance_number                           = :inst_num
                   and b.ts#(+)                                    = e.ts#
                   and b.obj#(+)                                   = e.obj#
                   and b.dataobj#(+)                               = e.dataobj#
                   and e.physical_reads - nvl(b.physical_reads, 0) > 0
                 order by physical_reads desc) d
          where rownum <= &&top_n_segstat) r
 where n.dataobj# = r.dataobj#
   and n.obj#     = r.obj#
   and n.ts#      = r.ts#
   and n.dbid     = r.dbid
   and         7 <= (select snap_level from stats$snapshot where snap_id = :bid)
 order by physical_reads desc;


-- Row Lock Waits
set newpage 0
ttitle lef 'Segments by Row Lock Waits  '-
           'DB/Inst: ' db_name '/' inst_name '  '-
           'Snaps: ' format 99999999 begin_snap '-' format 99999999 end_snap -
       skip 1 -
           '-> End Segment Row Lock Waits Threshold: '   esrl -
       skip 2

column row_lock_waits heading "Row|Lock|Waits" format 999,999,999

select n.owner
     , n.tablespace_name
     , n.object_name
     , case when length(n.subobject_name) < 11 then
              n.subobject_name
            else
              substr(n.subobject_name,length(n.subobject_name)-9)
       end subobject_name
     , n.object_type
     , r.row_lock_waits
     , substr(to_char(r.ratio * 100,'999.9MI'), 1, 5) ratio
  from stats$seg_stat_obj n
     , (select *
          from (select e.dataobj#
                     , e.obj#
                     , e.ts#
                     , e.dbid
                     , e.row_lock_waits - nvl(b.row_lock_waits, 0) row_lock_waits
                     , ratio_to_report(e.row_lock_waits - nvl(b.row_lock_waits, 0)) over () ratio
                  from stats$seg_stat e
                     , stats$seg_stat b
                 where b.snap_id(+)                                = :bid
                   and e.snap_id                                   = :eid
                   and b.dbid(+)                                   = :dbid
                   and e.dbid                                      = :dbid
                   and b.instance_number(+)                        = :inst_num
                   and e.instance_number                           = :inst_num
                   and b.ts#(+)                                    = e.ts#
                   and b.obj#(+)                                   = e.obj#
                   and b.dataobj#(+)                               = e.dataobj#
                   and e.row_lock_waits - nvl(b.row_lock_waits, 0) > 0
                 order by row_lock_waits desc) d
          where rownum <= &&top_n_segstat) r
 where n.dataobj# = r.dataobj#
   and n.obj#     = r.obj#
   and n.ts#      = r.ts#
   and n.dbid     = r.dbid
   and         7 <= (select snap_level from stats$snapshot where snap_id = :bid)
 order by row_lock_waits desc;   
PROMPT ************* Row lock statistics + Initial Transaction Slots 
set linesize 180  
Col Object for a25
SELECT  DECODE(GROUPING(Object_name),1, 'All Objects', Object_name)  AS "Object",
 sum(ITL_Waits) "ITL Waits",sum(Buffer_Busy_Waits) "Buffer Busy Waits",
 sum(Row_Lock_Waits)"Row Lock Waits",
 sum(Physical_Reads) "Physical Reads",
 sum(Logical_Reads) "Logical Reads"
  ,min(snap_id)begin_snap,max(snap_id)end_snap,min(snap_time) BEGIN_TIME,max(snap_time) END_TIME                                                        
 FROM
 (Select o.object_name   ,
    a.ITL_WAITS-LAG(a.ITL_WAITS) OVER (PARTITION BY o.object_name order by s.snap_id) ITL_Waits , 
    a.BUFFER_BUSY_WAITS-LAG(a.BUFFER_BUSY_WAITS) OVER (PARTITION BY o.object_name order by s.snap_id) Buffer_Busy_Waits,                                                                                                          
    a.ROW_LOCK_WAITS-LAG(a.ROW_LOCK_WAITS) OVER (PARTITION BY o.object_name order by s.snap_id) Row_Lock_Waits,                                                                                                       
    decode(sign(a.PHYSICAL_READS-LAG(a.PHYSICAL_READS) OVER (PARTITION BY o.object_name order by s.snap_id)),-1,0,a.PHYSICAL_READS-LAG(a.PHYSICAL_READS) OVER (PARTITION BY o.object_name order by s.snap_id)) Physical_Reads,
    decode(sign(a.PHYSICAL_WRITES-LAG(a.PHYSICAL_WRITES) OVER (PARTITION BY o.object_name order by s.snap_id)),-1,0,a.PHYSICAL_WRITES-LAG(a.PHYSICAL_WRITES) OVER (PARTITION BY o.object_name order by s.snap_id)) Logical_Reads
  ,s.snap_time,s.snap_id                                                              
  from stats$seg_stat a,dba_objects o,stats$snapshot s        
 where o.owner like upper('&owner')                                                                                         
 and a.snap_id=s.snap_id                                                                                                   
 and o.object_id=a.OBJ#                                                                                                     
 --and o.object_name='FGBALA'                                                                                                
 and a.snap_id between &begin_snap and &end_snap
 order by o.object_name,snap_TIME  )                          
WHERE ITL_Waits>0 or Buffer_Busy_Waits>0   
group by  rollup(object_name)                              
order by  "Row Lock Waits" DESC                       
/


PROMPT *********UNDO statistics

 select TO_CHAR(MIN(Begin_Time),'DD-MON-YYYY HH24:MI:SS')
                 "Begin Time",
    TO_CHAR(MAX(End_Time),'DD-MON-YYYY HH24:MI:SS')
                 "End Time",
    SUM(Undoblks)    "Total Undo Blocks Used",
    SUM(Txncount)    "Total Num Trans Executed",
    MAX(Maxquerylen)  "Longest Query(in secs)",
    MAX(Maxconcurrency) "Highest Concurrent TrCount",
    SUM(Ssolderrcnt)  "1155_Error_cnt",
    SUM(Nospaceerrcnt) "Nospace_Err_cnt"
from STATS$UNDOSTAT
WHERE snap_id between &begin_snap and &end_snap
/


set termout off;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
set termout on ;
undefine begin_snap
undefine end_snap
undefine dbid
undefine inst_num
undefine num_days
undefine report_name
undefine top_n_sql
undefine top_pct_sql
undefine top_n_events
undefine top_n_segstat
undefine btime
undefine etime
undefine num_rows_per_hash
whenever sqlerror continue;   
set linesize 180   
                                             