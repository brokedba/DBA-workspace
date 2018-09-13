USE [master]
GO 
CREATE LOGIN [kh85124] WITH PASSWORD = 0x02001C8D2260C2A69E9DA944461D5919C0F87B88F373FE030C4551CDDACFE168DB72FF465B5764F317177E7ECC9A6C872B50DC6D0888ACE48FBE2E5C2F947B6ED2FE3CDAF5F8 HASHED, SID = 0x6C3D6E7F61753349A1463A7BA0E79F01, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
ALTER SERVER ROLE [sysadmin] ADD MEMBER [sa]
GO


/*
A. Changing the owner of a database
ALTER AUTHORIZATION ON database::testdb TO KH85124;   -------transfer ownership to user 

B. Transfer ownership of a table                                                                                                                    ALTER AUTHORIZATION ON OBJECT::Sprockets TO MichikoOsada; 
                                                                                                                                                    ALTER AUTHORIZATION ON Sprockets TO MichikoOsada;            
 ALTER AUTHORIZATION ON OBJECT::schema.table TO USER;                                                                                               ALTER AUTHORIZATION ON dbo.Sprockets TO MichikoOsada;        
 ALTER AUTHORIZATION ON OBJECT::HumanRessources.employees TO KH85124;   -- transfer ownership of table to user                                      ALTER AUTHORIZATION ON OBJECT::dbo.Sprockets TO MichikoOsada; 
 ALTER AUTHORIZATION ON Sprockets TO MichikoOsada; ------- look in users default schema (I.E dbo)                                                   

C. Transfer ownership of a view to the schema owner
ALTER AUTHORIZATION ON OBJECT::Production.ProductionView06 TO SCHEMA OWNER;    ---to the owner of the schema that contains it

D. Transfer ownership of a schema to a user
ALTER AUTHORIZATION ON SCHEMA::SeattleProduction11 TO kh85124;    

*/
/*
ALTER LOGIN [kh85124] WITH PASSWORD=N'SQL_new_PWD' , CHECK_POLICY = OFF
GO
USE [AdventureWorks2012]
GO
ALTER USER [kh85124] WITH DEFAULT_SCHEMA=[INFORMATION_SCHEMA]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_accessadmin] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_backupoperator] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_ddladmin] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_denydatareader] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_denydatawriter] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[db_securityadmin] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[HumanResources] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[Person] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[Production] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[Purchasing] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER AUTHORIZATION ON SCHEMA::[Sales] TO [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_datareader] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_denydatareader] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_owner] ADD MEMBER [kh85124]
GO
USE [AdventureWorks2012]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [kh85124]
GO
*/