 undefine begin_snap end_snap
 
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
 WHERE STAT_NAME in ('DB CPU')
 GROUP BY STAT_NAME
 UNION                                                                             
 SELECT stat_name,sum(TIME_SEC),NULL,ROUND(sum(TIME_SEC)/60,2), min(SNAP_ID) BEGIN_SNAP, max(snap_id)END_SNAP, NULL,NULL                                               
 FROM DB_TIME B    
  WHERE STAT_NAME in ('DB time')                                                                    
 GROUP BY STAT_NAME
 UNION
 SELECT 'DB WAIT TIME',SUM(B1.TIME_SEC)- MAX(M.TIME_SEC),ROUND((SUM(B1.TIME_SEC)-max(M.TIME_SEC))*100/SUM(B1.TIME_SEC),2) ,ROUND((SUM(B1.TIME_SEC)-max(M.TIME_SEC))/60,2) , min(B1.SNAP_ID), max(B1.snap_id), NULL,NULL
   FROM DB_TIME B1,(select sum(TIME_SEC) TIME_SEC FROM TIME_MODEL WHERE STAT_NAME='DB CPU') M
  WHERE B1.STAT_NAME='DB time' 
 ORDER BY 3 DESC
 / 
 
 PROMPT *************************** SNAPSHOT WAIT STATS *********************************
COLUMN METRIC_NAME FOR A35
COLUMN METRIC_UNIT FOR A25
COLUMN WAIT_TYPE FOR a25
--SET COLSEP '|'                                      
CLEAR BREAK COMPUTE;
--BREAK ON WAIT_TYPE ON BEGIN_TIME ON END_TIME ON BEGIN_SNAP ON END_SNAP
--COMPUTE SUM OF WAIT_SEC_DELTA ON WAIT_TYPE   --- FOR THE detailed INNER QUERY per snapID
BREAK ON BEGIN_TIME ON END_TIME ON BEGIN_SNAP ON END_SNAP;

COL AVG_WAIT_MS FORMAT 99,990.9
COL TIME_WAITED_SECS FORmat 9999,990.99
COL TIME_WAITED_MIN  FORMAT 999,990.99
COL PCT_TIME FORMAT 90.99
COL WAIT_SEC_DELTA FOR 99,990.99
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
  