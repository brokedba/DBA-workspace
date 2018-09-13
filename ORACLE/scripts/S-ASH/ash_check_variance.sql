-- adapted from  high-var-sql.sql
-- Copyright 2018 Kosseila hd. All rights reserved.  
/*
over a week's work of data gave the following results. Notice how SQL_ID='g3176qdxahvv9' (third from the bottom) 
had only a moderate amount of elapsed time, but a variance much higher that its mean (ratio of 383) such as very short spikes..  problem with that query would not have been noticed by looking only at aggregate performance statistics.
SQL_ID        AVG_SECONDS_PER_HOUR VAR_OVER_MEAN         CT
------------- -------------------- ------------- ----------
g3176qdxahvv9                   42           383         92     --variance 383  too high for a small elapsed time
b72dmps6rp8z8                  209          1116        167
6qv7az2048hk4                 3409         50219        167
a query might usually consume only a second or two of DB time per hour, then suddenly take over the CPUs and cause loss of application functionality. 
*/
prompt ** list of recent Queries that run 50% of the time
undefine days_back
select
   sub1.sql_id,
   round( avg(sub1.seconds_per_quarter) ) as avg_seconds_per_quarter,
    to_char(trunc(round( avg(sub1.seconds_per_quarter) )*100/900,2),'999.99')||'%' as PCTIME_per_quarter,
   round( variance(sub1.seconds_per_quarter)/avg(sub1.seconds_per_quarter) ) as var_over_mean,
   count(*) as count
from
   ( -- sub1
     select  snap_id,sql_id,elapsed_time_delta/1000000 as seconds_per_quarter
     from    dba_hist_snapshot natural join dba_hist_sqlstat
     where        -- look at recent history only
        begin_interval_time > sysdate - &&days_back
     and   -- must have executions to be interesting
        executions_delta > 0
   ) sub1
group by 
   sub1.sql_id
having 
   -- only queries that consume 10 seconds per hour on the average
   avg(sub1.seconds_per_quarter) > 10
and -- only queries that run 50% of the time
    -- assumes hourly snapshots too
     count(*) > ( &&days_back * 24*4) * 0.50
order by
   3
;
undefine days_back
