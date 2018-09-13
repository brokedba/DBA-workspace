CREATE DATABASE [DemoDB]
 CONTAINMENT = NONE  ---or PARTIAL for contained DB
 ON  PRIMARY 
( NAME = N'DemoDB', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL11.MTLDB\MSSQL\DATA\DemoDB.mdf' , SIZE = 5120KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [Data] DEFAULT
( NAME = N'DemoDB_data', FILENAME = N'E:\Components\DemoDB_data.ndf' , SIZE = 5120KB , FILEGROWTH = 1024KB ), 
( NAME = N'DemoDB_data2', FILENAME = N'E:\Components\DemoDB_data2.ndf' , SIZE = 5120KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [index] 
( NAME = N'DemoDB_index', FILENAME = N'E:\Components\DemoDB_index.ndf' , SIZE = 5120KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DemoDB_log', FILENAME = N'E:\Components\DemoDB_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

USE [DemoDB]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'Data') ALTER DATABASE [DemoDB] MODIFY FILEGROUP [Data] DEFAULT
GO


/*switch to a contained instance */
EXEC sys.sp_configure 'contained database authentication', '1'
GO
RECONFIGURE WITH OVERRIDE
GO

/* switch to a contained Database */
USE [master]
GO
ALTER DATABASE [DemoDB] SET CONTAINMENT = PARTIAL WITH NO_WAIT
GO

/*Create a contained USER */
