USE Master
DECLARE @REGKEY varchar(100);
SET @REGKEY ='SOFTWARE\Microsoft\Microsoft SQL Server\MTLDB\Setup';
EXEC xp_regread 'HKEY_LOCAL_MACHINE',@REGKEY,'SQLPath'
                
 --                'SOFTWARE\Microsoft\MSSQLServer\Setup',