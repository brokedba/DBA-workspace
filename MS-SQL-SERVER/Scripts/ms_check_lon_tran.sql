-- TableResults only shows the oldest open tran
-- useful running in a loop to load the oldest
-- tran over time.
 
--create a temp table
CREATE TABLE #OpenTranStatus (
ActiveTransaction varchar(25),
Details sql_variant
);
 
-- Execute the command, putting the results in the table.
INSERT INTO #OpenTranStatus
EXEC ('DBCC OPENTRAN (virtuo) with tableresults')
SELECT * FROM #OpenTranStatus
DROP TABLE #OpenTranStatus