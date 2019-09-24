Rem  Copyright (c) 2016 by Oracle Corporation
Rem
Rem  You may not use the identified files except in compliance with The MIT
Rem  License (the "License.")
Rem
Rem  You may obtain a copy of the License at
Rem  https://github.com/oracle/Oracle.NET/blob/master/LICENSE
Rem
Rem  Unless required by applicable law or agreed to in writing, software
Rem  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
Rem  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
Rem
Rem  See the License for the specific language governing permissions and
Rem  limitations under the License.
Rem
Rem  NAME
REM    scott.sql
Rem  
Rem  DESCRIPTION
Rem    SCOTT is a database user whose schema is used for Oracle code demonstrations


SET TERMOUT OFF
SET ECHO OFF

rem CONGDON    Invoked in RDBMS at build time.	 29-DEC-1988
rem OATES:     Created: 16-Feb-83
DROP user SCOTT CASCADE;
CREATE USER SCOTT IDENTIFIED BY TIGER;
GRANT CONNECT,RESOURCE,UNLIMITED TABLESPACE TO SCOTT;
ALTER USER SCOTT DEFAULT TABLESPACE USERS;
ALTER USER SCOTT TEMPORARY TABLESPACE TEMP;
CONNECT SCOTT/TIGER
DROP TABLE DEPT;
CREATE TABLE DEPT
       (DEPTNO NUMBER(2) CONSTRAINT PK_DEPT PRIMARY KEY,
	DNAME VARCHAR2(14) ,
	LOC VARCHAR2(13) ) ;
DROP TABLE EMP;
CREATE TABLE EMP
       (EMPNO NUMBER(4) CONSTRAINT PK_EMP PRIMARY KEY,
	ENAME VARCHAR2(10),
	JOB VARCHAR2(9),
	MGR NUMBER(4),
	HIREDATE DATE,
	SAL NUMBER(7,2),
	COMM NUMBER(7,2),
	DEPTNO NUMBER(2) CONSTRAINT FK_DEPTNO REFERENCES DEPT);
DROP TABLE BONUS;
CREATE TABLE BONUS
	(
	ENAME VARCHAR2(10)	,
	JOB VARCHAR2(9)  ,
	SAL NUMBER,
	COMM NUMBER
	) ;
DROP TABLE SALGRADE;
CREATE TABLE SALGRADE
      ( GRADE NUMBER,
	LOSAL NUMBER,
	HISAL NUMBER );

SET TERMOUT ON
SET ECHO ON