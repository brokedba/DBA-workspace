-- Check state of files in database
-- All filegroups and files should be online
-- Nothing should show as recovery pending
Select DF.name As [File Name],
    DS.name As [FileGroup Name],
    DF.type_desc As [File Type],
    DF.state_desc As [File State],
    DF.size As [File Size],
	DF.max_size as [File maxSize],
	(case df.max_size when -1 then 0 else Df.max_size-df.size end) as [Free],
	(case df.is_read_only when 1 then 'YES' else 'NO' end) as [Read_only]  
From demodb.sys.database_files DF
Left Join DemoDB.sys.data_spaces DS On DS.data_space_id = DF.data_space_id;


/*
USE [DemoDB]
GO
ALTER DATABASE [DemoDB]  REMOVE FILE [DemoDB-OldData]
GO
ALTER DATABASE [DemoDB] REMOVE FILEGROUP [OldData]
GO

*/