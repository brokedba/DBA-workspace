SELECT p.name AS [loginname] , 
p.type , p.type_desc , 
p.is_disabled, 
CONVERT(VARCHAR(10),p.create_date ,101) AS [created], 
CONVERT(VARCHAR(10),p.modify_date , 101) AS [update]
FROM sys.server_principals p 
JOIN sys.syslogins s ON p.sid = s.sid
--WHERE p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP') 
-- Logins that are not process logins 
AND p.name NOT LIKE '##%' -- Logins that are sysadmins 
AND s.sysadmin = 1
go
 SELECT      dp1.name AS DatabaseRoleName,
            COALESCE(DP2.name, 'No members') AS DatabaseUserName
FROM        sys.database_principals AS dp1
LEFT  JOIN  sys.database_role_members AS drm
      ON    drm.role_principal_id = dp1.principal_id
LEFT  JOIN  sys.database_principals AS dp2
      ON    dp2.principal_id = drm.member_principal_id
WHERE       dp1.type = 'R'
ORDER BY    dp1.name;
go 

SELECT p.NAME
,m.NAME
FROM sys.database_role_members rm
JOIN sys.database_principals p
ON rm.role_principal_id = p.principal_id
JOIN sys.database_principals m
ON rm.member_principal_id = m.principal_id;
go

select name,iif(is_fixed_role=1,'YES','NO') 'fixed',type_desc,default_schema_name,user_name(owning_principal_id)'owner' from  sys.database_principals order by 2;
go

SELECT p.name AS [loginname] , 
p.type , p.type_desc , 
p.is_disabled, 
CONVERT(VARCHAR(10),p.create_date ,101) AS [created], 
CONVERT(VARCHAR(10),p.modify_date , 101) AS [update]
FROM sys.server_principals p 
JOIN sys.syslogins s ON p.sid = s.sid
--WHERE p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP') 
-- Logins that are not process logins 
AND p.name NOT LIKE '##%' -- Logins that are sysadmins 
AND s.sysadmin = 1