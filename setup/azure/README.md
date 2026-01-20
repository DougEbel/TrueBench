# TrueBench Setup — Azure SQL Database / SQL Server (ODBC)

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Azure SQL Database and Microsoft SQL Server (including Azure SQL Managed Instance).

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Azure SQL / SQL Server workloads without any setup
scripts.

For connectivity and driver usage, see:
- `MAN azure` (or `HELP azure`)
- `HELP db`
- `HELP validate`


## Query log data collected by Azure SQL / SQL Server
Azure SQL Database and SQL Server provide extensive query performance telemetry, commonly
through Query Store. Query Store collects query text, plans, and performance statistics.

Important note: Query Store is not a row-by-row query execution log like Teradata DBQL. Query
Store records aggregated statistics by query plan and time interval. This affects how benchmark
runs should be tagged for tuning comparisons (see insert_runid below).


## Files Provided

### 1) prompt_for_db.tdb
Prompts for setup variables:
- `:bench_server`  - TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container for TestTracking and reporting views

### 2) testtracking.tdb
Creates the host-side TestTracking table in `:bench_schema`.

This table is populated by TrueBench via BEFORE_RUN / AFTER_RUN / AFTER_NOTE statements and
provides the RunId time window used to join benchmark runs to Query Store telemetry.

### 3) querylog_base_view.tdb
Provides a sample script that creates the base query log view:

- `:bench_schema.QueryLog_Base`

This script is intentionally separated from the core setup process because query logging
objects and permissions can vary across Azure SQL / SQL Server versions and environments.
You may need to edit this script to match your platform configuration.

### 4) make_links.tdb
Displays BEFORE_RUN, AFTER_RUN, and AFTER_NOTE statements that can be copied into your
`truebench.tdb` startup file.

These statements are significant because they allow TrueBench to integrate benchmark runs with
host-side reporting and external tooling:
- BEFORE_RUN may log system configuration and prepare host-side objects for the test
- AFTER_RUN may capture additional metrics and archive supporting logs to a RunId-tagged file
- AFTER_NOTE replicates analyst notes into the host TestTracking table as durable history

### 5) initial_setup.tdb
Runs the core setup scripts in the correct order:
- prompt_for_db.tdb
- testtracking.tdb
- make_links.tdb

Note: `querylog_base_view.tdb` is NOT executed automatically by initial_setup.tdb. It is a
sample that you may optionally edit and execute to create host-side query log reporting views.

### 6) README.md
This file.


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings that inject identifiers into each SQL statement. These
identifiers are extremely useful for linking benchmark queries to host query logs.

### insert_query_name (default: yes)
The profile setting:
- `insert_query_name = yes`

causes TrueBench to embed a tag into each SQL statement containing the query name based on the
query filename or queue name.

Example embedded tag:
- `tdb=query001:001`

This enables Query Store text filtering to isolate benchmark SQL.

### insert_runid (default: no)
The profile setting:
- `insert_runid = yes`

causes TrueBench to also embed the current RunId into SQL.

Example embedded tag:
- `runid=81`

This is strongly recommended for Azure SQL / SQL Server Query Store analysis because Query Store
aggregates statistics over time intervals. If two benchmark runs occur inside the same Query
Store time interval, Query Store may aggregate their performance statistics together. Injecting
RunId tags allows you to isolate the benchmark SQL for a specific RunId even when tuning changes
are made and tests are re-run within the same Query Store interval.

Recommended Azure profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid yes`


## Recommended Setup Sequence
1) Run core setup:
   `exec setup\azure\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\azure\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\azure\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## QueryLog_Base View Columns
The base view provides the following key columns:

- Benchmark context:
  - RunId, TestName, Description, TestStartTime, TestStopTime
- Query identity:
  - QueryText, QueryName
- Query Store identifiers:
  - QueryId, PlanId
  - IntervalStartTime, IntervalEndTime
- Query Store metrics (aggregated):
  - ExecCnt
  - AvgDurationMicrosec
  - AvgCpuMicrosec
  - AvgLogicalReads
  - AvgPhysicalReads
  - AvgLogicalWrites


## Example 1: Summary by RunId and QueryName (adds execution count)
This query summarizes benchmark queries for multiple runs. It is useful for quickly validating
workload completeness and comparing query performance across runs.

Note: Query Store metrics are interval/plan aggregates. Reporting queries should use
execution-weighted averages for accurate results.

The source of the data is the example `QueryLog_Base` view created by `querylog_base_view.tdb`,
which you may need to adapt for your DBMS release and platform options.

Example:

```
select
    QueryName,
    RunId,
    sum(ExecCnt) as ExecCnt,
    sum(AvgDurationMicrosec * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgDurationMicrosec,
    sum(AvgCpuMicrosec * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgCpuMicrosec,
    sum(AvgLogicalReads * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgLogicalReads,
    sum(AvgPhysicalReads * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgPhysicalReads
from
    :bench_schema.QueryLog_Base
where
    RunId in (81, 92)
    and QueryName is not null
group by
    QueryName, RunId
order by
    QueryName, RunId;
```

## Example 2: Tuning analysis for one query across tests / runs
This query supports tuning workflows by tracking a specific benchmark query across test runs.
It summarizes execution counts and Query Store performance metrics by TestName and RunId.

Note: This example uses execution-weighted averages.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    sum(ExecCnt) as ExecCnt,
    sum(AvgDurationMicrosec * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgDurationMicrosec,
    sum(AvgCpuMicrosec * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgCpuMicrosec,
    sum(AvgLogicalReads * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgLogicalReads,
    sum(AvgPhysicalReads * ExecCnt) / nullif(sum(ExecCnt), 0) as AvgPhysicalReads
from
    :bench_schema.QueryLog_Base
where
    QueryName = 'query001:001'
group by
    TestName, RunId, TestStartTime, QueryName
order by
    TestStartTime, RunId;
```

## Notes and Limitations
- Query Store stores aggregated statistics by query plan and time interval. It is excellent for
  trending and regression detection, but it is not a row-by-row execution log.
- In shared environments, other workloads may overlap benchmark windows. Use QueryName tags to
  isolate benchmark SQL.
- For Azure Query Store, enabling `insert_runid=yes` is recommended for tuning workflows so
  benchmark runs within the same logging interval can be isolated by RunId.
- If `querylog_base_view.tdb` fails, you can still use TrueBench normally; only host-side query
  log reporting will be unavailable until the script is adapted to your environment.


## Contributing Improvements
You may have deeper knowledge of Azure SQL Database / SQL Server than the authors of TrueBench.
If you develop improvements that may help other members of the SQL Server user community,
please consider submitting enhancements such as query logging guidance, TestTracking join views,
and Azure/SQL Server-specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
