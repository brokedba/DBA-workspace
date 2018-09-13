SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
:setvar DB  master
:setvar owner INFORMATION_SCHEMA
:setvar tab CHECK_CONSTRAINTS

GO
DECLARE @nt_username nvarchar(128)
SET @nt_username = (SELECT rtrim(convert(nvarchar(128), nt_username))
FROM sys.dm_exec_sessions WHERE spid = @@SPID)
SELECT @nt_username + ' is connected to ' +
rtrim(CONVERT(nvarchar(20), SERVERPROPERTY('servername'))) +' (' +rtrim(CONVERT(nvarchar(20), SERVERPROPERTY('productversion'))) +')'
:setvar SQLCMDMAXFIXEDTYPEWIDTH 100
SET NOCOUNT OFF
GO
:setvar SQLCMDMAXFIXEDTYPEWIDTH
/*SET sqlcmdini=c:\init.sql*/