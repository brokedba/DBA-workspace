-- show size of all databases and database files
-- uncommenet out the following 4 lines if used in  sqlcmd
SET NOCOUNT ON;
---SET ANSI_WARNINGS OFF; 
---:setvar SQLCMDERRORLEVEL 1
:setvar sqlcmdheaders            40     -- "page size"
:setvar sqlcmdcolwidth          132     -- line width
:setvar sqlcmdmaxfixedtypewidth  32     -- max column width (fixed length)
:setvar sqlcmdmaxvartypewidth    32     -- max column width (varying length)




IF Object_id(N'tempdb..#tempTbl') IS NOT NULL
DROP TABLE #temptbl


CREATE TABLE #tempTbl
( DBName VARCHAR(50),
  DBFileName VARCHAR(50),
  PhysicalFileName NVARCHAR(260),
  FileSizeMB decimal(18,1)
)



declare @cmd1 varchar(500)
set @cmd1 ='
insert into #tempTbl
SELECT ''?'' as DBName
   ,cast(f.name as varchar(25)) as DBFileName
   ,f.Filename as PhysicalFileName
   ,cast (round((f.size*8)/1024.0,2) as decimal(18,2)) as FileSizeinMB
FROM ?..SYSFILES f
'
exec sp_MSforeachdb @command1=@cmd1


select *
from #tempTbl
order by DBName

select case when (GROUPING(DBName)=1) then '*** Total size ***'
       else isnull(DBname, 'UNKNOWN')
       end AS DBName
      ,SUM(FileSizeMB) As FileSizeMBSum
from #tempTbl
group by DBName with ROLLUP
order by FileSizeMBSum

EXECUTE master.sys.sp_MSforeachdb 'USE [?]; EXEC sp_spaceused' --total space per Db
EXECUTE master.sys.sp_MSforeachdb 'USE [?]; EXEC sp_helpfile'  --file size per DB