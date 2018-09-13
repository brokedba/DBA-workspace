SELECT CONVERT( nvarchar(20), SERVERPROPERTY('servername')) "server\instance", CONVERT(nvarchar(20), SERVERPROPERTY('productversion')) version, rtrim(CAST (@@VERSION as varchar(200))) as Versions ;  
GO  

SELECT *
FROM sys.servers ;   
GO  



SELECT schema_name, schema_owner
FROM information_schema.schemata; 
go

SELECT  s.name,u.*
FROM    sys.schemas s join sys.sysusers u on u.uid=s.schema_id; 
go

/*
select replace(@@SERVERNAME,'\','.')

go
*/