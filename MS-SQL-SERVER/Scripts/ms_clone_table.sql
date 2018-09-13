---from http://dba.stackexchange.com/questions/18059/copy-complete-structure-of-a-table

IF TYPE_ID(N'TestTableType') IS NULL 
 create type TestTableType as table (ObjectID int)
go
      SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Drop stored procedure if it already exists
IF EXISTS (  SELECT *     FROM INFORMATION_SCHEMA.ROUTINES    WHERE SPECIFIC_SCHEMA = N'dbo'     AND SPECIFIC_NAME = N'util_CopyTable' )
   DROP PROCEDURE dbo.[util_CopyTable]
GO

    --*************************************************************************************************'
--    La procedura crea lo script di una tabella
--    Tabella   : xxxxx
--    Creata da : E.Mantovanelli
--    Data creazione : 28-06-2012
--    Data modifica: 28-06-2012
--*************************************************************************************************'

/*
    --      ID----|-----Data-----|--    User        ---------   | ----  Note
                        20-11-2013      E.Mantovanelli                  distinzione schema delle tabelle
                                                                        estrazione da db selezionato
                                                                        aggiunta estrazione partizione
                         28-05-2016     Michael Freidgeim         Fixed TEXT column support and added ability to Create Table And Copy Data.
Usage: 
declare @s nvarchar(max)
exec [util_CopyTable] 'DataBaseName','schema_source','table_source',1,1,'schema_dest','tab_dest',0,1,@s output
*/

CREATE PROCEDURE [dbo].[util_CopyTable] 
     @DBName SYSNAME
    ,@schema sysname
    ,@TableName SYSNAME
    ,@IncludeConstraints BIT = 1
    ,@IncludeIndexes BIT = 1
    ,@NewTableSchema sysname
    ,@NewTableName SYSNAME = NULL
    ,@UseSystemDataTypes BIT = 0 
	,@CreateTableAndCopyData BIT = 0 
    ,@script nvarchar(max) output
AS 
BEGIN try
    if not exists (select * from sys.types where name = 'TestTableType')
        create type TestTableType as table (ObjectID int)--drop type TestTableType

    declare @sql nvarchar(max)

    DECLARE @MainDefinition TABLE (FieldValue VARCHAR(200))
    --DECLARE @DBName SYSNAME
    DECLARE @ClusteredPK BIT
    DECLARE @TableSchema NVARCHAR(255)

    --SET @DBName = DB_NAME(DB_ID())
    SELECT @TableName = name FROM sysobjects WHERE id = OBJECT_ID(@TableName)

    DECLARE @ShowFields TABLE (FieldID INT IDENTITY(1,1)
                                        ,DatabaseName VARCHAR(100)
                                        ,TableOwner VARCHAR(100)
                                        ,TableName VARCHAR(100)
                                        ,FieldName VARCHAR(100)
                                        ,ColumnPosition INT
                                        ,ColumnDefaultValue VARCHAR(100)
                                        ,ColumnDefaultName VARCHAR(100)
                                        ,IsNullable BIT
                                        ,DataType VARCHAR(100)
                                        ,MaxLength varchar(10)
                                        ,NumericPrecision INT
                                        ,NumericScale INT
                                        ,DomainName VARCHAR(100)
                                        ,FieldListingName VARCHAR(110)
                                        ,FieldDefinition CHAR(1)
                                        ,IdentityColumn BIT
                                        ,IdentitySeed INT
                                        ,IdentityIncrement INT
                                        ,IsCharColumn BIT 
                                        ,IsComputed varchar(255))

    DECLARE @HoldingArea TABLE(FldID SMALLINT IDENTITY(1,1)
                                        ,Flds VARCHAR(4000)
                                        ,FldValue CHAR(1) DEFAULT(0))

    DECLARE @PKObjectID TABLE(ObjectID INT)

    DECLARE @Uniques TABLE(ObjectID INT)

    DECLARE @HoldingAreaValues TABLE(FldID SMALLINT IDENTITY(1,1)
                                                ,Flds VARCHAR(4000)
                                                ,FldValue CHAR(1) DEFAULT(0))

    DECLARE @Definition TABLE(DefinitionID SMALLINT IDENTITY(1,1)
                                        ,FieldValue VARCHAR(200))


  set @sql=
  '
  use '+@DBName+'
  SELECT distinct DB_NAME()
            ,TABLE_SCHEMA
            ,TABLE_NAME
            ,''[''+COLUMN_NAME+'']'' as COLUMN_NAME
            ,CAST(ORDINAL_POSITION AS INT)
            ,COLUMN_DEFAULT
            ,dobj.name AS ColumnDefaultName
            ,CASE WHEN c.IS_NULLABLE = ''YES'' THEN 1 ELSE 0 END
            ,DATA_TYPE
            ,case CHARACTER_MAXIMUM_LENGTH when -1 then ''max'' else CAST(CHARACTER_MAXIMUM_LENGTH AS varchar) end--CAST(CHARACTER_MAXIMUM_LENGTH AS INT)
            ,CAST(NUMERIC_PRECISION AS INT)
            ,CAST(NUMERIC_SCALE AS INT)
            ,DOMAIN_NAME
            ,COLUMN_NAME + '',''
            ,'''' AS FieldDefinition
            ,CASE WHEN ic.object_id IS NULL THEN 0 ELSE 1 END AS IdentityColumn
            ,CAST(ISNULL(ic.seed_value,0) AS INT) AS IdentitySeed
            ,CAST(ISNULL(ic.increment_value,0) AS INT) AS IdentityIncrement
            ,CASE WHEN st.collation_name IS NOT NULL THEN 1 ELSE 0 END AS IsCharColumn 
            ,cc.definition 
            FROM INFORMATION_SCHEMA.COLUMNS c
            JOIN sys.columns sc ON  c.TABLE_NAME = OBJECT_NAME(sc.object_id) AND c.COLUMN_NAME = sc.Name
            LEFT JOIN sys.identity_columns ic ON c.TABLE_NAME = OBJECT_NAME(ic.object_id) AND c.COLUMN_NAME = ic.Name
            JOIN sys.types st ON COALESCE(c.DOMAIN_NAME,c.DATA_TYPE) = st.name
            LEFT OUTER JOIN sys.objects dobj ON dobj.object_id = sc.default_object_id AND dobj.type = ''D''
            left join sys.computed_columns cc on c.TABLE_NAME=OBJECT_NAME(cc.object_id) and sc.column_id=cc.column_id
    WHERE c.TABLE_NAME = @TableName and c.TABLE_SCHEMA=@schema 
    ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION
    '

  print @sql
  INSERT INTO @ShowFields( DatabaseName
                                    ,TableOwner
                                    ,TableName
                                    ,FieldName
                                    ,ColumnPosition
                                    ,ColumnDefaultValue
                                    ,ColumnDefaultName
                                    ,IsNullable
                                    ,DataType
                                    ,MaxLength
                                    ,NumericPrecision
                                    ,NumericScale
                                    ,DomainName
                                    ,FieldListingName
                                    ,FieldDefinition
                                    ,IdentityColumn
                                    ,IdentitySeed
                                    ,IdentityIncrement
                                    ,IsCharColumn
                                    ,IsComputed)

    exec sp_executesql @sql,
                       N'@TableName varchar(50),@schema varchar(50)',
                       @TableName=@TableName,@schema=@schema            
    /*
    SELECT @DBName--DB_NAME()
            ,TABLE_SCHEMA
            ,TABLE_NAME
            ,COLUMN_NAME
            ,CAST(ORDINAL_POSITION AS INT)
            ,COLUMN_DEFAULT
            ,dobj.name AS ColumnDefaultName
            ,CASE WHEN c.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END
            ,DATA_TYPE
            ,CAST(CHARACTER_MAXIMUM_LENGTH AS INT)
            ,CAST(NUMERIC_PRECISION AS INT)
            ,CAST(NUMERIC_SCALE AS INT)
            ,DOMAIN_NAME
            ,COLUMN_NAME + ','
            ,'' AS FieldDefinition
            ,CASE WHEN ic.object_id IS NULL THEN 0 ELSE 1 END AS IdentityColumn
            ,CAST(ISNULL(ic.seed_value,0) AS INT) AS IdentitySeed
            ,CAST(ISNULL(ic.increment_value,0) AS INT) AS IdentityIncrement
            ,CASE WHEN st.collation_name IS NOT NULL THEN 1 ELSE 0 END AS IsCharColumn 
            FROM INFORMATION_SCHEMA.COLUMNS c
            JOIN sys.columns sc ON  c.TABLE_NAME = OBJECT_NAME(sc.object_id) AND c.COLUMN_NAME = sc.Name
            LEFT JOIN sys.identity_columns ic ON c.TABLE_NAME = OBJECT_NAME(ic.object_id) AND c.COLUMN_NAME = ic.Name
            JOIN sys.types st ON COALESCE(c.DOMAIN_NAME,c.DATA_TYPE) = st.name
            LEFT OUTER JOIN sys.objects dobj ON dobj.object_id = sc.default_object_id AND dobj.type = 'D'

    WHERE c.TABLE_NAME = @TableName
    ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION
    */
    SELECT TOP 1 @TableSchema = TableOwner FROM @ShowFields

    INSERT INTO @HoldingArea (Flds) VALUES('(')

    INSERT INTO @Definition(FieldValue)VALUES('CREATE TABLE ' + CASE WHEN @NewTableName IS NOT NULL THEN @DBName + '.' + @NewTableSchema + '.' + @NewTableName ELSE @DBName + '.' + @TableSchema + '.' + @TableName END)
    INSERT INTO @Definition(FieldValue)VALUES('(')
    INSERT INTO @Definition(FieldValue)

    SELECT   CHAR(10) + FieldName + ' ' + 
        --CASE WHEN DomainName IS NOT NULL AND @UseSystemDataTypes = 0 THEN DomainName + CASE WHEN IsNullable = 1 THEN ' NULL ' ELSE ' NOT NULL ' END ELSE UPPER(DataType) +CASE WHEN IsCharColumn = 1 THEN '(' + CAST(MaxLength AS VARCHAR(10)) + ')' ELSE '' END +CASE WHEN IdentityColumn = 1 THEN ' IDENTITY(' + CAST(IdentitySeed AS VARCHAR(5))+ ',' + CAST(IdentityIncrement AS VARCHAR(5)) + ')' ELSE '' END +CASE WHEN IsNullable = 1 THEN ' NULL ' ELSE ' NOT NULL ' END +CASE WHEN ColumnDefaultName IS NOT NULL AND @IncludeConstraints = 1 THEN 'CONSTRAINT [' + ColumnDefaultName + '] DEFAULT' + UPPER(ColumnDefaultValue) ELSE '' END END + CASE WHEN FieldID = (SELECT MAX(FieldID) FROM @ShowFields) THEN '' ELSE ',' END 

        CASE WHEN DomainName IS NOT NULL AND @UseSystemDataTypes = 0 THEN DomainName + 
            CASe WHEN IsNullable = 1 THEN ' NULL ' 
            ELSE ' NOT NULL ' 
            END 
        ELSE 
            case when IsComputed is null then
                UPPER(DataType) +
                CASE WHEN (IsCharColumn = 1 and UPPER(DataType) <> 'TEXT') THEN '(' + CAST(MaxLength AS VARCHAR(10)) + ')' 
                ELSE 
                    CASE WHEN DataType = 'numeric' THEN '(' + CAST(NumericPrecision AS VARCHAR(10))+','+ CAST(NumericScale AS VARCHAR(10)) + ')' 
                    ELSE
                        CASE WHEN DataType = 'decimal' THEN '(' + CAST(NumericPrecision AS VARCHAR(10))+','+ CAST(NumericScale AS VARCHAR(10)) + ')' 
                        ELSE '' 
                        end  
                    end 
                END +
                CASE WHEN IdentityColumn = 1 THEN ' IDENTITY(' + CAST(IdentitySeed AS VARCHAR(5))+ ',' + CAST(IdentityIncrement AS VARCHAR(5)) + ')' 
                ELSE '' 
                END +
                CASE WHEN IsNullable = 1 THEN ' NULL ' 
                ELSE ' NOT NULL ' 
                END +
                CASE WHEN ColumnDefaultName IS NOT NULL AND @IncludeConstraints = 1 THEN 'CONSTRAINT [' + replace(ColumnDefaultName,@TableName,@NewTableName) + '] DEFAULT' + UPPER(ColumnDefaultValue) 
                ELSE '' 
                END 
            else
                ' as '+IsComputed+' '
            end
        END + 
        CASE WHEN FieldID = (SELECT MAX(FieldID) FROM @ShowFields) THEN '' 
        ELSE ',' 
        END 

    FROM    @ShowFields

    IF @IncludeConstraints = 1
        BEGIN    

        set @sql=
        '
        use '+@DBName+'
        SELECT  distinct  '',CONSTRAINT ['' + replace(name,@TableName,@NewTableName) + ''] FOREIGN KEY ('' + ParentColumns + '') REFERENCES ['' + ReferencedObject + '']('' + ReferencedColumns + '')'' 
           FROM ( SELECT   ReferencedObject = OBJECT_NAME(fk.referenced_object_id), ParentObject = OBJECT_NAME(parent_object_id),fk.name
                ,   REVERSE(SUBSTRING(REVERSE((   SELECT cp.name + '',''   
                FROM   sys.foreign_key_columns fkc   
                JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id   
                WHERE fkc.constraint_object_id = fk.object_id   FOR XML PATH('''')   )), 2, 8000)) ParentColumns,   
                REVERSE(SUBSTRING(REVERSE((   SELECT cr.name + '',''   
                FROM   sys.foreign_key_columns fkc  
                JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
                WHERE fkc.constraint_object_id = fk.object_id   FOR XML PATH('''')   )), 2, 8000)) ReferencedColumns   
                FROM sys.foreign_keys fk    
                    inner join sys.schemas s on fk.schema_id=s.schema_id and s.name=@schema) a    
            WHERE ParentObject = @TableName    
        '

        print @sql

        INSERT INTO @Definition(FieldValue)
        exec sp_executesql @sql,
                   N'@TableName varchar(50),@NewTableName varchar(50),@schema varchar(50)',
                       @TableName=@TableName,@NewTableName=@NewTableName,@schema=@schema
            /*
           SELECT    ',CONSTRAINT [' + name + '] FOREIGN KEY (' + ParentColumns + ') REFERENCES [' + ReferencedObject + '](' + ReferencedColumns + ')'  
           FROM ( SELECT   ReferencedObject = OBJECT_NAME(fk.referenced_object_id), ParentObject = OBJECT_NAME(parent_object_id),fk.name
                ,   REVERSE(SUBSTRING(REVERSE((   SELECT cp.name + ','   
                FROM   sys.foreign_key_columns fkc   
                JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id   
                WHERE fkc.constraint_object_id = fk.object_id   FOR XML PATH('')   )), 2, 8000)) ParentColumns,   
                REVERSE(SUBSTRING(REVERSE((   SELECT cr.name + ','   
                FROM   sys.foreign_key_columns fkc  
                JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
                WHERE fkc.constraint_object_id = fk.object_id   FOR XML PATH('')   )), 2, 8000)) ReferencedColumns   
                FROM sys.foreign_keys fk    ) a    
            WHERE ParentObject = @TableName    
            */

            set @sql=
            '
            use '+@DBName+'
            SELECT distinct '',CONSTRAINT ['' + replace(c.name,@TableName,@NewTableName) + ''] CHECK '' + definition 
            FROM sys.check_constraints c join sys.schemas s on c.schema_id=s.schema_id and s.name=@schema    
            WHERE OBJECT_NAME(parent_object_id) = @TableName
            '

            print @sql
            INSERT INTO @Definition(FieldValue) 
            exec sp_executesql @sql,
                               N'@TableName varchar(50),@NewTableName varchar(50),@schema varchar(50)',
                       @TableName=@TableName,@NewTableName=@NewTableName,@schema=@schema
            /*
            SELECT ',CONSTRAINT [' + name + '] CHECK ' + definition FROM sys.check_constraints    
            WHERE OBJECT_NAME(parent_object_id) = @TableName
            */

            set @sql=
            '
            use '+@DBName+'
            SELECT DISTINCT  PKObject = cco.object_id 
            FROM    sys.key_constraints cco    
            JOIN sys.index_columns cc ON cco.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id    
            JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id
            join sys.schemas s on cco.schema_id=s.schema_id and s.name=@schema
            WHERE    OBJECT_NAME(parent_object_id) = @TableName    AND  i.type = 1 AND    is_primary_key = 1
            '
            print @sql
            INSERT INTO @PKObjectID(ObjectID) 
            exec sp_executesql @sql,
                               N'@TableName varchar(50),@schema varchar(50)',
                               @TableName=@TableName,@schema=@schema
            /*
            SELECT DISTINCT  PKObject = cco.object_id 
            FROM    sys.key_constraints cco    
            JOIN sys.index_columns cc ON cco.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id    
            JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id
            WHERE    OBJECT_NAME(parent_object_id) = @TableName    AND  i.type = 1 AND    is_primary_key = 1
            */

            set @sql=
            '
            use '+@DBName+'
            SELECT DISTINCT    PKObject = cco.object_id
            FROM    sys.key_constraints cco   
            JOIN sys.index_columns cc ON cco.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id  
            JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id
            join sys.schemas s on cco.schema_id=s.schema_id and s.name=@schema
            WHERE    OBJECT_NAME(parent_object_id) = @TableName AND  i.type = 2 AND    is_primary_key = 0 AND    is_unique_constraint = 1
            '
            print @sql
            INSERT INTO @Uniques(ObjectID)
            exec sp_executesql @sql,
                               N'@TableName varchar(50),@schema varchar(50)',
                               @TableName=@TableName,@schema=@schema
            /*
            SELECT DISTINCT    PKObject = cco.object_id
            FROM    sys.key_constraints cco   
            JOIN sys.index_columns cc ON cco.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id  
            JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id
            WHERE    OBJECT_NAME(parent_object_id) = @TableName AND  i.type = 2 AND    is_primary_key = 0 AND    is_unique_constraint = 1
            */

            SET @ClusteredPK = CASE WHEN @@ROWCOUNT > 0 THEN 1 ELSE 0 END

            declare @t TestTableType
            insert @t select * from @PKObjectID
            declare @u TestTableType
            insert @u select * from @Uniques

            set @sql=
            '
            use '+@DBName+'
            SELECT distinct '',CONSTRAINT '' + replace(cco.name,@TableName,@NewTableName) + CASE type WHEN ''PK'' THEN '' PRIMARY KEY '' + CASE WHEN pk.ObjectID IS NULL THEN '' NONCLUSTERED '' ELSE '' CLUSTERED '' END  WHEN ''UQ'' THEN '' UNIQUE '' END + CASE WHEN u.ObjectID IS NOT NULL THEN '' NONCLUSTERED '' ELSE '''' END 
            + ''(''+REVERSE(SUBSTRING(REVERSE(( SELECT   c.name +  + CASE WHEN cc.is_descending_key = 1 THEN '' DESC'' ELSE '' ASC'' END + '',''    
            FROM   sys.key_constraints ccok   
            LEFT JOIN sys.index_columns cc ON ccok.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id
            LEFT JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id 
            LEFT JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id  
            WHERE i.object_id = ccok.parent_object_id AND   ccok.object_id = cco.object_id    
            order by key_ordinal FOR XML PATH(''''))), 2, 8000)) + '')''
            FROM sys.key_constraints cco 
            inner join sys.schemas s on cco.schema_id=s.schema_id and s.name=@schema
            LEFT JOIN @U u ON cco.object_id = u.objectID
            LEFT JOIN @t pk ON cco.object_id = pk.ObjectID    
            WHERE    OBJECT_NAME(cco.parent_object_id) = @TableName 

            '

            print @sql
            INSERT INTO @Definition(FieldValue)
            exec sp_executesql @sql,
                               N'@TableName varchar(50),@NewTableName varchar(50),@schema varchar(50),@t TestTableType readonly,@u TestTableType readonly',
                               @TableName=@TableName,@NewTableName=@NewTableName,@schema=@schema,@t=@t,@u=@u

            /*
            SELECT ',CONSTRAINT ' + name + CASE type WHEN 'PK' THEN ' PRIMARY KEY ' + CASE WHEN pk.ObjectID IS NULL THEN ' NONCLUSTERED ' ELSE ' CLUSTERED ' END  WHEN 'UQ' THEN ' UNIQUE ' END + CASE WHEN u.ObjectID IS NOT NULL THEN ' NONCLUSTERED ' ELSE '' END 
            + '(' +REVERSE(SUBSTRING(REVERSE(( SELECT   c.name +  + CASE WHEN cc.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END + ','    
            FROM   sys.key_constraints ccok   
            LEFT JOIN sys.index_columns cc ON ccok.parent_object_id = cc.object_id AND cco.unique_index_id = cc.index_id
           LEFT JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id 
           LEFT JOIN sys.indexes i ON cc.object_id = i.object_id AND cc.index_id = i.index_id  
           WHERE i.object_id = ccok.parent_object_id AND   ccok.object_id = cco.object_id    FOR XML PATH(''))), 2, 8000)) + ')'
           FROM sys.key_constraints cco 
           LEFT JOIN @PKObjectID pk ON cco.object_id = pk.ObjectID    
           LEFT JOIN @Uniques u ON cco.object_id = u.objectID
           WHERE    OBJECT_NAME(cco.parent_object_id) = @TableName 
           */
        END

        INSERT INTO @Definition(FieldValue) VALUES(')')

        set @sql=
        '
        use '+@DBName+'
        select '' on '' + d.name + ''([''+c.name+''])''
        from sys.tables t join sys.indexes i on(i.object_id = t.object_id and i.index_id < 2)
                          join sys.index_columns ic on(ic.partition_ordinal > 0 and ic.index_id = i.index_id and ic.object_id = t.object_id)
                          join sys.columns c on(c.object_id = ic.object_id and c.column_id = ic.column_id)
                          join sys.schemas s on t.schema_id=s.schema_id
                          join sys.data_spaces d on i.data_space_id=d.data_space_id
        where t.name=@TableName and s.name=@schema
        order by key_ordinal
        '

        print 'x'
        print @sql
        INSERT INTO @Definition(FieldValue) 
        exec sp_executesql @sql,
                           N'@TableName varchar(50),@schema varchar(50)',
                           @TableName=@TableName,@schema=@schema

        IF @IncludeIndexes = 1
        BEGIN
            set @sql=
            '
            use '+@DBName+'
            SELECT distinct '' CREATE '' + i.type_desc + '' INDEX ['' + replace(i.name COLLATE SQL_Latin1_General_CP1_CI_AS,@TableName,@NewTableName) + ''] ON '+@DBName+'.'+@NewTableSchema+'.'+@NewTableName+' ('' 
            +   REVERSE(SUBSTRING(REVERSE((   SELECT name + CASE WHEN sc.is_descending_key = 1 THEN '' DESC'' ELSE '' ASC'' END + '',''   
            FROM  sys.index_columns sc  
            JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id   
            WHERE  t.name=@TableName AND  sc.object_id = i.object_id AND  sc.index_id = i.index_id   
                                         and is_included_column=0
            ORDER BY key_ordinal ASC   FOR XML PATH('''')    )), 2, 8000)) + '')''+
            ISNULL( '' include (''+REVERSE(SUBSTRING(REVERSE((   SELECT name + '',''   
            FROM  sys.index_columns sc  
            JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id   
            WHERE  t.name=@TableName AND  sc.object_id = i.object_id AND  sc.index_id = i.index_id   
                                         and is_included_column=1
            ORDER BY key_ordinal ASC   FOR XML PATH('''')    )), 2, 8000))+'')'' ,'''')+''''    
            FROM sys.indexes i join sys.tables t on i.object_id=t.object_id
                               join sys.schemas s on t.schema_id=s.schema_id   
            AND CASE WHEN @ClusteredPK = 1 AND is_primary_key = 1 AND i.type = 1 THEN 0 ELSE 1 END = 1   AND is_unique_constraint = 0   AND is_primary_key = 0 
                where t.name=@TableName and s.name=@schema
            '

            print @sql
            INSERT INTO @Definition(FieldValue)    
            exec sp_executesql @sql,
                               N'@TableName varchar(50),@NewTableName varchar(50),@schema varchar(50), @ClusteredPK bit',
                               @TableName=@TableName,@NewTableName=@NewTableName,@schema=@schema,@ClusteredPK=@ClusteredPK

        END 

            /*

                SELECT   'CREATE ' + type_desc + ' INDEX [' + [name] COLLATE SQL_Latin1_General_CP1_CI_AS + '] ON [' +  OBJECT_NAME(object_id) + '] (' +   REVERSE(SUBSTRING(REVERSE((   SELECT name + CASE WHEN sc.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END + ','   
                FROM  sys.index_columns sc  
                JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id   
                WHERE  OBJECT_NAME(sc.object_id) = @TableName AND  sc.object_id = i.object_id AND  sc.index_id = i.index_id   
                ORDER BY index_column_id ASC   FOR XML PATH('')    )), 2, 8000)) + ')'    
                FROM sys.indexes i    
                WHERE   OBJECT_NAME(object_id) = @TableName
                AND CASE WHEN @ClusteredPK = 1 AND is_primary_key = 1 AND type = 1 THEN 0 ELSE 1 END = 1   AND is_unique_constraint = 0   AND is_primary_key = 0 

            */

            INSERT INTO @MainDefinition(FieldValue)   
            SELECT FieldValue FROM @Definition    
            ORDER BY DefinitionID ASC 

            ----------------------------------

            declare @q  varchar(max)

            set @q=(select replace((SELECT FieldValue FROM @MainDefinition FOR XML PATH('')),'</FieldValue>',''))
  
            set @script=(select REPLACE(@q,'<FieldValue>',''))

if @CreateTableAndCopyData =1
BEGIN
    print  @script
    exec sp_executesql @script

	SELECT Stuff(( SELECT ', '+FieldName FROM @ShowFields FOR XML PATH('') ), 1, 2, '')

	declare @s nvarchar(max)
	set @s= 
	'SET IDENTITY_INSERT ' + @NewTableName + ' ON 
	INSERT ' + @NewTableName + ' ( ' +
	(SELECT Stuff(( SELECT ', '+FieldName FROM @ShowFields FOR XML PATH('') ), 1, 2, '')) --csv columns as from http://stackoverflow.com/a/26987369/52277
	+ ')
	SELECT * from ' + @TableName + '
	SET IDENTITY_INSERT ' + @NewTableName + ' OFF '
	print  @s 
    exec sp_executesql @s
END
END try

-- ##############################################################################################################################################################################
BEGIN CATCH        
    BEGIN
        -- INIZIO  Procedura in errore =========================================================================================================================================================
            PRINT '***********************************************************************************************************************************************************' 
            PRINT 'ErrorNumber               : ' + CAST(ERROR_NUMBER() AS NVARCHAR(MAX))
            PRINT 'ErrorSeverity             : ' + CAST(ERROR_SEVERITY() AS NVARCHAR(MAX)) 
            PRINT 'ErrorState                : ' + CAST(ERROR_STATE() AS NVARCHAR(MAX)) 
            PRINT 'ErrorLine                 : ' + CAST(ERROR_LINE() AS NVARCHAR(MAX)) 
            PRINT 'ErrorMessage              : ' + CAST(ERROR_MESSAGE() AS NVARCHAR(MAX))
            PRINT '***********************************************************************************************************************************************************' 
			
        -- FINE  Procedura in errore =========================================================================================================================================================
    END 
	
        set @script=''
    --return -1
	;THROW --Should call see http://sqlhints.com/2013/06/30/differences-between-raiserror-and-throw-in-sql-server/
END CATCH 
GO  
-- ##############################################################################################################################################################################   
/* Example to exec
declare @s nvarchar(max)
exec [util_CopyTable]   'DataBaseName','schema_source','table_source',1,1,'schema_dest','tab_dest',0,1,@s output
select @s
*/