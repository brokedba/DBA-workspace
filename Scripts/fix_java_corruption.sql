col  name new_val pdb_name  noprint
select name from v$pdbs;
spool &pdb_name._java_fix.log
set feed on 
alter session set "_ORACLE_SCRIPT"=true;
prompt -- 1. create rootobj view
create or replace view rootobj sharing=object as select obj#,o.name,u.name
uname,o.type#,o.flags from obj$ o,user$ u where owner#=user#;

prompt -- 2. update flags on #obj view where type# in (28,29,30,56)

update obj$ set flags=flags+65536 where type# in (28,29,30,56) and
bitand(flags,65536)=0 and obj# in (select o.obj# from obj$ o,user$ u,rootobj
r where o.name=r.name and o.type#=r.type# and o.owner#=u.user# and
u.name=r.uname and bitand(r.flags,65536)!=0 union select obj# from obj$ where
bitand(flags,4259840)=4194304);

prompt -- 3. update flags on #obj view  where bitand(flags,65600)=64 (not always present)
 
update obj$ set flags=flags+65536
  where bitand(flags,65600)=64 and
        obj# in (select o.obj# from obj$ o,x$joxft x
                               where x.joxftobn=o.obj# and
                                     bitand(o.flags,65600)=64 and
                                     bitand(x.joxftflags,64)=64);
                                    
prompt  -- 4. delete objects from idl_ubl view  
delete from sys.idl_ub1$ where SYS_CONTEXT('USERENV','CON_ID')>1 and
obj# in (select obj# from sys.obj$ where
bitand(flags, 65536)=65536 and type# in (28,29,30,56));

prompt -- commit 
commit;

spool off
