  SET NOCOUNT ON;
---SET ANSI_WARNINGS OFF; 
:setvar SQLCMDERRORLEVEL 1

Print'===================='
Print' Databases Locations'  
Print'===================='
SELECT db_name(database_id) as DatabaseName,name,type_desc,physical_name FROM sys.master_files
Go


Print'===================='
Print'   backup status    '  
Print'===================='
   SELECT db.name, 
case when MAX(b.backup_finish_date) is NULL then 'No Backup' else convert(varchar(100), 
	MAX(b.backup_finish_date)) end AS last_backup_finish_date
FROM sys.databases db
LEFT OUTER JOIN msdb.dbo.backupset b ON db.name = b.database_name AND b.type = 'D'
	WHERE db.database_id NOT IN (2) 
GROUP BY db.name
ORDER BY 2 DESC
go
Print'===================='
Print'   backups location '  
Print'===================='

 SELECT Distinct physical_device_name FROM msdb.dbo.backupmediafamily
 go