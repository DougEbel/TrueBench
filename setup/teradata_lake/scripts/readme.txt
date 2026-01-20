This is support documentation describing the setup files for Teradata Lake and how they are called.

The file setup.menu may allow editing of config and TdBench startup scripts, or execute various TdBench scripts.
Note: The TdBench setup function determines the OS and if Windows, edits/executes .bat files, else uses .sh files. 
The descriptions below with reference to .sh files applies to .bat files.  

The Menu options and what they do:

0  Provides starter set of config files or just setup a DB for logon
- executes copy_templates.tdb to copy/replace config and TdBench startup scripts
   
              ------------ editing section ---------------

1  OPTIONAL - Customize execution for you to choose jar file version and default DBMS
- editing of tdbench_config.sh which sets jar version and default database, then calls DBMS specific config

2  Customize environment variables such as passwords and directories
- editing of DBMS specific config, in this case tdbench_teradata_lake_config.sh

3  OPTIONAL - Initial command file executed by jar file to customize session settings
- editing of tdbench.tdb, used to set global session preferences then calls DBMS specific startup script

4  Command file to define class and db connections for Teradata servers
- editing of the DBMS specific startup script used to define CLASS and DB plus BEFORE/AFTER run handling
   
5   IF NEEDED - Restart tdbench to reload the settings from above 4 config & .tdb files
- Just an exit with a distinctive 123 exit code causing tdbench.sh/tdbench.bat to re-execute the jar file

           ------------ Creating benchmark user section ------------
   
6  Run simple select to validate your logon ID on host DBMS
- Executes test_connect.tdb to prompt for user's logon/password and then validate it can get current timestamp

7  Edit the script with create user and grant statements for host DBMS TdBench user
- Editing create_tdbench.sql for create user/grants/query logging.  Note: this is making changes to original file in scripts.

8  Define the user/database on target Teradata DBMS
- Runs the test_connect.tdb to validate user can logon, then runs create_tdbench.sql

9  Validate setup of user/database on target Teradata DBMS
- Executes valiate_tdbench_host.tdb to ensure all rights granted. This is important if a DBA is setting up the 
  benchmark user for the benchmark analyst. It also helps when user has almost all the rights to create/grant
  but is missing something like grant function requiring DBC logon or having DBC grant to benchmark analyst so
  they can grant to the benchmark user. 

          ------------ Setup reporting views/functions and utility macro section ------------
   
10 Create the TestTracking table, TestStart and TestStop macros and basic views
- Executes setup_tdbench.tdb which defines the base level test tracking and dbql/resusage views
  - testtracking.tdb to define/upgrade the test tracking table and the new testtrackingv view for Teradata Lake
  - teststart.tdb to adapt the teststart macro to the privledges that have been granted for execution BEFORE_RUN
  - teststop.tdb to adapt the teststop macro to the privledges that have been granted for execution AFTER_RUN
  - dbqlogv_sum.sql to create the view for lake that collapses multiple dbqlog rows from different clusters
  - dbql_nopdcr.tdb which creates the join views of testtracking to TD_METRIC_SVC.dbqlogv
  - dbql_nopdcr_other.tdb executed multiple times for different DBQL tables joined to TestTracking and dbqlogv
  - findtable.tdb determine if optional DBQL tables have been enabled, currently only dbqlParamV 
  - dbql_nopdcr_util.tdb HAS NOT BEEN CONVERTED FOR LAKE
  - resusage_nopdcr.tdb executed multiple times for diffoerent ResUsage tables joined to TestTracking

11 Build the views and macros used for host DBMS reporting
- executes setup_host_reporting.tdb for rpt* views and macros

12 OPTIONAL - Useful macros to assist in benchmark preparation and execution
- executes setup_host_utilities.tdb with macros to help prepare and monitor benchmark 


Other:

validate_variables.tdb - checks that TdBench_DBMS, TdBenchServer, and TdBenchDB have been set
- used by create_tdbench.tdb and test_connect.tdb

