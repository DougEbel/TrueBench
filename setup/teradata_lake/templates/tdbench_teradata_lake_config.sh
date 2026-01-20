# TdBench 8.0 Copyright (c) 2024 Teradata Corporation

# ------------------------------------------------------------------------
# The following parameters can be edited to affect the generation of views.
#
# TdBenchServer is the server where tests are run and reporting against
# DBQL and Resusage in TD_METRIC_SVC database is performed
#
# TdBenchDb is the logon/database where test metadata, views, and macros will
# be saved. You must have read/write/create function rights to this user.
#
# The TdBenchPrefix is the username prefix of the worker logons, used to
# distinguish tdbench workload from competing workload in reporting views.
# For example, the benchmark user might be test_benchmark and the tactical
# workers might be test_tac_user01, test_tac_user02, ... and the reporting
# workers might be test_rpt_user01, test_rpt_user02, ... In the reporting
# views, any usage by logon IDs beginning with 'test%' would be labeled
# benchmark usage and the rest considered "noise".
#
# Simply: We will run tests on TdBenchServer and report results in TdBenchDB
# of work done by logons with a prefix of TdBenchPrefix.
#
# ------------------------------------------------------------------------

export TdBenchServer=not_set    
export TdBenchDb=not_set
export TdBenchPrefix=not_set

