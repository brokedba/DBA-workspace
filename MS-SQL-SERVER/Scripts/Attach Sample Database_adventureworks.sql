-- If using zip file download (contains both data and log file)

Use Master
GO
CREATE DATABASE AdventureWorks2012 
ON (FILENAME = 'C:\SampleDB\AdventureWorks2012_Data.mdf'), -- Data file path
(FILENAME = 'C:\SampleDB\AdventureWorks2012_Log.ldf') -- Log file path
FOR ATTACH;

--If using Data file download (contains only Data file)
Use Master
GO
CREATE DATABASE AdventureWorks2012 
ON (FILENAME = 'C:\SampleDB\AdventureWorks2012_Data.mdf') -- Data file path
FOR ATTACH_REBUILD_LOG;
--OR

CREATE DATABASE AdventureWorks2012_Data
ON (FILENAME = N'C:\SQLData\AdventureWorks2012_Data.mdf')
FOR ATTACH_REBUILD_LOG 
Go


DBCC CHECKDB ('AdventureWorks2012_Data')
GO


/*

You could try to detach the database, copy the files to new names at a command prompt, then attach both DBs.

In SQL:

USE master;
GO 
EXEC sp_detach_db
    @dbname = N'OriginalDB';
GO
At Command prompt (I've simplified the file paths for the sake of this example):

copy c:\OriginalDB.mdf c:\NewDB.mdf
copy c:\OriginalDB.ldf c:\NewDB.ldf
In SQL again:

USE master;
GO
CREATE DATABASE OriginalDB
    ON (FILENAME = 'C:\OriginalDB.mdf'),
       (FILENAME = 'C:\OriginalDB.ldf')
    FOR ATTACH;
GO
CREATE DATABASE NewDB
    ON (FILENAME = 'C:\NewDB.mdf'),
       (FILENAME = 'C:\NewDB.ldf')
    FOR ATTACH;
GO
*/
