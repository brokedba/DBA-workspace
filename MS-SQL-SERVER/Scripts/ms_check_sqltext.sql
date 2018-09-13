SET NOCOUNT ON;
---SET ANSI_WARNINGS OFF; 
---:setvar SQLCMDERRORLEVEL 1

print '=========================================================================================='
print ' context: $(DB) owner: $(owner) ...'
Print 'For NEW VALUES RUN ==>>>example  '':setvar sqlid xxxx'''
print'==========================================================================================='
use $(DB)
SELECT * FROM sys.dm_exec_sql_text($(sqlid));  
GO
:setvar sqlid 0
  