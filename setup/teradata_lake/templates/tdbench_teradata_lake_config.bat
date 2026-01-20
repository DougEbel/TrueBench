@echo off
rem TdBench 8.0 Copyright (c) 2024 Teradata Corporation

rem ------------------------------------------------------------------------
rem The following parameters can be edited to affect the generation of views.
rem
rem TdBenchServer is the server where tests are run and reporting against
rem DBQL and Resusage in TD_METRIC_SVC database is performed 
rem 
rem TdBenchDb is the logon/database where test metadata, views, and macros will
rem be saved. You must have read/write/create function rights to this user.
rem 
rem The TdBenchPrefix is the username prefix of the worker logons, used to 
rem distinguish tdbench workload from competing workload in reporting views.
rem For example, the benchmark user might be test_benchmark and the tactical
rem workers might be test_tac_user01, test_tac_user02, ... and the reporting
rem workers might be test_rpt_user01, test_rpt_user02, ... In the reporting
rem views, any usage by logon IDs beginning with 'test%' would be labeled
rem benchmark usage and the rest considered "noise".
rem
rem Simply: We will run tests on TdBenchServer and report results in TdBenchDB
rem of work done by logons with a prefix of TdBenchPrefix. 
rem
rem ------------------------------------------------------------------------

set TdBenchServer=not_set
set TdBenchDb=not_set
set TdBenchPrefix=not_set
