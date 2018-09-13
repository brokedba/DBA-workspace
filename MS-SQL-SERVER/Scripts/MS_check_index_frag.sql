
 SELECT d.name,o.name,a.* FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'DETAILED') a  
 join sys.databases d on a.database_id =d.database_id
 join sys.indexes o on ( a.object_id=o.object_id and a.index_id=o.index_id)
 order by 12 desc
 
 
 /*
 USE AdventureWorks2012;  
GO  
-- Find the average fragmentation percentage of all indexes  
-- in the HumanResources.Employee table.   
SELECT a.index_id, name, avg_fragmentation_in_percent  
FROM sys.dm_db_index_physical_stats (DB_ID(N'AdventureWorks2012'), OBJECT_ID(N'HumanResources.Employee'), NULL, NULL, NULL) AS a  
    JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;   
GO 


-- Reorganize 
ALTER INDEX IX_Employee_OrganizationalLevel_OrganizationalNode ON HumanResources.Employee  
REORGANIZE ;   
GO  

-- Reorganize all indexes on the HumanResources.Employee table.  
ALTER INDEX ALL ON HumanResources.Employee  
REORGANIZE ;   
GO 
 
---Rebuild
ALTER INDEX PK_Employee_BusinessEntityID ON HumanResources.Employee REBUILD;
GO 
USE AdventureWorks2012;
GO
ALTER INDEX ALL ON Production.Product
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,STATISTICS_NORECOMPUTE = ON);
GO

----check how indexes are used in a table 
			SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
			         I.[NAME] AS [INDEX NAME], 
			         USER_SEEKS, 
			         USER_SCANS, 
			         USER_LOOKUPS, 
			         USER_UPDATES 
			FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
			         INNER JOIN SYS.INDEXES AS I 
			           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
			              AND I.INDEX_ID = S.INDEX_ID 
			WHERE   object_name(s.[object_id])='R_EMPLHORAIRE'
			Go
*/