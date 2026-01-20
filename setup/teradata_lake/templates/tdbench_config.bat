@echo off 
:: This file is always run before starting the TdBench JAVA program by tdbench.sh or tdbench.bat.
:: It specifies which version of the JAVA program to run and which DBMS configuration file to run.
:: The setting of TdBench_DBMS may be overridden on the command line of tdbench.sh with the -d parameter.

set "TdBench_jar_version=tdbench-8.01.04" 
  
set TdBench_DBMS=teradata_lake
if not "%~1" == "" set TdBench_DBMS=%~1

:: You may put common statements across all DBMSs in this file such as prompting for passwords or cleaning up files.



:: ---------- run the platform specific file specified by TdBench_DBMS or -d parameter ---------- 
if exist "tdbench_%TdBench_DBMS%_config.bat" ( 
   call "tdbench_%TdBench_DBMS%_config.bat" 
   if not errorlevel 0 (  
       echo tdbench_%TdBench_DBMS%_config.bat ended with return code %errorlevel% 
   ) 
) else (
   echo.
   echo ERROR: The file tdbench_%TdBench_DBMS%_config.bat does not exist. Use SETUP to fix tdbench_config.bat
   echo.
)
