PRINT impersonate utest user - or open new window and log on as test login
execute as user='utest'
go
PRINT 'check security context'
print user_name()
PRINT 'check your view ability to select'
select * from msdb.dbo.all_mailitems
PRINT 'revert to original scope/superuser'
revert


/*  create role and grant it to user
USE msdb;
GO
CREATE ROLE MailReview
GRANT SELECT ON dbo.sysmail_sentitems    TO MailReview;
GRANT SELECT ON dbo.sysmail_unsentitems  TO MailReview;
GRANT SELECT ON dbo.sysmail_faileditems  TO MailReview;

--a Windows Group login example
CREATE USER [mydomain\Developers] FOR LOGIN [mydomain\Developers];
EXEC sp_addrolemember 'MailReview','mydomain\Developers';

--a SQL login example
CREATE USER LOWELL FOR LOGIN LOWELL;
EXEC sp_addrolemember 'MailReview','LOWELL';
*/