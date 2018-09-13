SET NOCOUNT ON;
SELECT Name FROM master.dbo.sysDatabases WHERE [Name] NOT IN ('master','model','msdb','tempdb')