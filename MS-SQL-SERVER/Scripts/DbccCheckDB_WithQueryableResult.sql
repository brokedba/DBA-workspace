-- For SQL Server 2012 
 
-- Executes CheckDB for the actual database and 
-- stores the result into a temporary table for further 
-- analysis. Minimum error state levels to report can 
-- be configurated. 
/*Things to look for that mean repair won’t be able to fix everything are:

CHECKDB stops early and complains about system table pre-checks failing (errors 7984 – 7988 inclusive)
CHECKDB reports any metadata corruption (8992, 8995 errors)
CHECKDB reports any errors on PFS page headers (8939, 8946 errors with a possible 8998 error as well)

*/
 
-- Pre Clean 
IF NOT OBJECT_ID('tempdb..#CheckDB') IS NULL  
    DROP TABLE #CheckDB; 
GO  
 
 
-- Configuration values for reports. 
DECLARE @MinState int, @MinStatus int, @MinLevel int; 
SET @MinState = 1;   -- Minimum state to report 
SET @MinStatus = 0;  -- Minimum status to report 
SET @MinLevel = 10;  -- Minimum level to report 
 
 
-- Creating temporary table for CheckDB result. 
CREATE TABLE #CheckDB 
    ([Error] int 
    ,[Level] int 
    ,[State] int 
    ,[MessageText] varchar(7000) 
    ,[RepairLevel] int 
    ,[Status] int 
    ,[DbId] int 
    ,[DbFragId] int 
    ,[ObjectID] int 
    ,[IndexId] int 
    ,[PartitionId] int 
    ,[AllocUnitId] int 
    ,[RidDbId] int 
    ,[RidPruId] int 
    ,[File] int 
    ,[Page] int 
    ,[Slot] int 
    ,[RefDbID] int 
    ,[RefPruId] int 
    ,[RefFile] int 
    ,[RefPage] int 
    ,[RefSlot] int 
    ,[Allocation] int); 
 
-- Execute CheckDB and insert result to temp table 
INSERT INTO #CheckDB 
    ([Error], [Level], [State], [MessageText], [RepairLevel], 
     [Status], [DbId], [DbFragId], [ObjectID], [IndexId], [PartitionId], 
     [AllocUnitId], [RidDbId], [RidPruId], [File], [Page], [Slot], [RefDbID], 
     [RefPruId], [RefFile], [RefPage], [RefSlot], [Allocation]) 
EXEC ('DBCC CHECKDB(0) WITH TABLERESULTS'); 
 
-- Show final summary message first with total count of errors 
-- and warnings. 
SELECT [MessageText] 
FROM #CheckDB 
WHERE [Error] = 8989; 
 
-- Overview per states with count of occurence 
SELECT CDB.Error, CDB.Level, CDB.State, CDB.Status, 
       CDB.RepairLevel, COUNT(*) AS CountOccurence 
FROM #CheckDB AS CDB 
WHERE CDB.State >= @MinState 
      AND CDB.Status >= @MinStatus 
      AND CDB.Level >= @MinLevel 
GROUP BY CDB.Error, CDB.Level, CDB.State, 
         CDB.Status, CDB.RepairLevel; 
 
-- Selection of report details 
SELECT OBJ.name AS ObjName, OBJ.type_desc AS ObjType, 
       IDX.Name AS IndexName, 
       ALU.type_desc AS AllocationType, 
       CDB.Error, CDB.Level, CDB.State, CDB.Status, 
       CDB.RepairLevel, MessageText 
FROM #CheckDB AS CDB 
     LEFT JOIN sys.objects AS OBJ 
         ON CDB.ObjectId = OBJ.object_id 
     LEFT JOIN sys.indexes AS IDX 
         ON CDB.ObjectId = IDX.object_id 
            AND CDB.IndexID = IDX.index_id 
     LEFT JOIN sys.allocation_units AS ALU 
         ON CDB.AllocUnitId = ALU.allocation_unit_id 
WHERE CDB.State >= @MinState 
      AND CDB.Status >= @MinStatus 
      AND CDB.Level >= @MinLevel 
ORDER BY ObjType, ObjName, IndexName; 
GO 
 
-- Post cleanup. 
DROP TABLE #CheckDB; 
GO