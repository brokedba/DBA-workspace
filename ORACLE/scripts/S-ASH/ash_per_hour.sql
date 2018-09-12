/* aas-per-hour.sql (AWR)
 the variance/mean value (ACT_VAR_MEAN) spiked very high (95.4) at around 14:00 .
SAMPLE_HOUR          CPU_AVG   WAIT_AVG    ACT_AVG ACT_VAR_MEAN
----------------- ---------- ---------- ---------- ------------
2008-04-16 07:00         1.4         .4        1.8           .6
2008-04-16 08:00         1.8         .5        2.3            1
2008-04-16 09:00         2.3         .5        2.8          1.3
2008-04-16 10:00         2.6         .6        3.2          2.3
2008-04-16 11:00         3.5         .6        4.1          2.3
2008-04-16 12:00         2.4         .6          3          1.1
2008-04-16 13:00         2.3         .6        2.9            1
2008-04-16 14:00         3.7        2.7        6.4         95.4   <== spike in variance
2008-04-16 15:00         3.1         .7        3.8          1.9
2008-04-16 16:00         2.9         .7        3.6          1.6
2008-04-16 17:00         2.3         .4        2.7           .9
2008-04-16 18:00         2.1         .6        2.7          2.6

indicates a large amount of variability over that hour, perhaps a brief but intense spike in the AAS metric. For more detail run ASH_per_min specifying 60*nb of hours backward
 */
column sample_hour format a16
select
   to_char(round(sub1.sample_time, 'HH24'), 'YYYY-MM-DD HH24:MI') as sample_hour,
   round(avg(sub1.on_cpu),1) as cpu_avg,
   round(avg(sub1.waiting),1) as wait_avg,
   round(avg(sub1.active_sessions),1) as act_avg,
   round( (variance(sub1.active_sessions)/avg(sub1.active_sessions)),1) as act_var_mean
from
   ( -- sub1: one row per second, the resolution of SAMPLE_TIME
     select
        sample_id,
        sample_time,
        sum(decode(session_state, 'ON CPU', 1, 0))  as on_cpu,
        sum(decode(session_state, 'WAITING', 1, 0)) as waiting,
        count(*) as active_sessions
     from
        dba_hist_active_sess_history
     where
        sample_time > sysdate - (&hours/24)
     group by
        sample_id,
        sample_time
   ) sub1
group by
   round(sub1.sample_time, 'HH24')
order by
   round(sub1.sample_time, 'HH24')
;