SET NOCOUNT ON;
print 'remove user'
EXEC sp_droprolemember '$(rolename)', '$(membername)'
EXEC sp_revokedbaccess '$(membername)'