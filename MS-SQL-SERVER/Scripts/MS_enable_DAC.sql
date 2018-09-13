Use master
GO
/* 0 = Allow Local Connection, 1 = Allow Remote Connections*/ 
sp_configure 'remote admin connections', 1 
GO
RECONFIGURE
GO

--Connect  SQLCMD -S [SQL Server Name] -U [User Name] -P [Password] -A   / or SSMS ADMIN:server\instance

/*  HIDEN SYSTEM TABLES:

 SELECT * FROM sys.sysrscols
GO
SELECT * FROM sys.sysrowsets
GO
SELECT * FROM sys.sysallocunits
GO
SELECT * FROM sys.sysfiles1
GO
SELECT * FROM sys.syspriorities
GO
SELECT * FROM sys.sysdbfrag
GO
SELECT * FROM sys.sysfgfrag
GO
SELECT * FROM sys.syspru
GO
SELECT * FROM sys.sysbrickfiles
GO
SELECT * FROM sys.sysphfg
GO
SELECT * FROM sys.sysprufiles
GO
SELECT * FROM sys.sysftinds
GO
SELECT * FROM sys.sysowners
GO
SELECT * FROM sys.sysdbreg
GO
SELECT * FROM sys.sysprivs
GO
SELECT * FROM sys.sysschobjs
GO
SELECT * FROM sys.syslogshippers
GO
SELECT * FROM sys.syscolpars
GO
SELECT * FROM sys.sysxlgns
GO
SELECT * FROM sys.sysxsrvs
GO
SELECT * FROM sys.sysnsobjs
GO
SELECT * FROM sys.sysusermsgs
GO
SELECT * FROM sys.syscerts
GO
SELECT * FROM sys.sysrmtlgns
GO
SELECT * FROM sys.syslnklgns
GO
SELECT * FROM sys.sysxprops
GO
SELECT * FROM sys.sysscalartypes
GO
SELECT * FROM sys.systypedsubobjs
GO
SELECT * FROM sys.sysidxstats
GO
SELECT * FROM sys.sysiscols
GO
SELECT * FROM sys.sysendpts
GO
SELECT * FROM sys.syswebmethods
GO
SELECT * FROM sys.sysbinobjs
GO
SELECT * FROM sys.sysaudacts
GO
SELECT * FROM sys.sysobjvalues
GO
SELECT * FROM sys.sysclsobjs
GO
SELECT * FROM sys.sysrowsetrefs
GO
SELECT * FROM sys.sysremsvcbinds
GO
SELECT * FROM sys.sysxmitqueue
GO
SELECT * FROM sys.sysrts
GO
SELECT * FROM sys.sysconvgroup
GO
SELECT * FROM sys.sysdesend
GO
SELECT * FROM sys.sysdercv
GO
SELECT * FROM sys.syssingleobjrefs
GO
SELECT * FROM sys.sysmultiobjrefs
GO
SELECT * FROM sys.sysguidrefs
GO
SELECT * FROM sys.syschildinsts
GO
SELECT * FROM sys.syscompfragments
GO
SELECT * FROM sys.sysftstops
GO
SELECT * FROM sys.sysqnames
GO
SELECT * FROM sys.sysxmlcomponent
GO
SELECT * FROM sys.sysxmlfacet
GO
SELECT * FROM sys.sysxmlplacement
GO
SELECT * FROM sys.sysobjkeycrypts
GO
SELECT * FROM sys.sysasymkeys
GO
SELECT * FROM sys.syssqlguides
GO
SELECT * FROM sys.sysbinsubobjs
GO
SELECT * FROM sys.syssoftobjrefs
GO
*/