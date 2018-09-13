SELECT * from sys.configurations order by NAME
PRINT 'OR'
SP_CONFIGURE 'show advanced options',1
go
RECONFIGURE with OVERRIDE
go
SP_CONFIGURE
go

/* 
EXEC sp_configure ['option',.,..]
*/