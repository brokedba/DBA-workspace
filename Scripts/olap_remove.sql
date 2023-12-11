col  name new_val pdb_name  noprint
select name from v$pdbs;
spool &pdb_name..log
set feed on 
prompt  ----> Remove OLAP Catalog
@?/olap/admin/catnoamd.sql
prompt  ----> Remove OLAP API 
@?/olap/admin/olapidrp.plb
@?/olap/admin/catnoxoq.sql
prompt  ----> Deinstall APS - OLAP AW component
@?/olap/admin/catnoaps.sql
@?/olap/admin/cwm2drop.sql
ptompt  ----> cleanup leftovers and Recompile invalids 
@remove_olap_leftovers.sql
@?/rdbms/admin/utlrp.sql
spool off
