--check step job name 

SELECT *
FROM msdb.dbo.sysjobs
WHERE
job_id = dbo.GetJobIdFromProgramName ('SQLAgent - TSQL JobStep (Job 0xFB668E27919DA3489E3DD97061F25B31 : Step 1) ') 