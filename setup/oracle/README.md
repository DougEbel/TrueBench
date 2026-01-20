# TrueBench Setup — Oracle Database (Python Driver)

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Oracle Database (including Exadata deployments).

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Oracle workloads without any setup scripts.

For connectivity and driver usage, see:
- `MAN oracle` (or `HELP oracle`)
- `HELP db`
- `HELP validate`


## Query log data collected by Oracle
Oracle provides multiple sources of SQL execution history and performance metrics. The data
available to you depends on the Oracle release, platform configuration, licensing options, and
privileges granted to your user.

Oracle environments vary widely. Some platforms provide only basic SQL history, while others
provide detailed execution history and resource usage through performance history views and
diagnostics features.

TrueBench setup scripts in this directory provide a starting point:
- a host-side TestTracking table aligned to the Oracle system clock
- a sample base view (`QueryLog_Base`) joining TestTracking to query history / metrics


## Files Provided

### 1) prompt_for_db.tdb
Prompts for setup variables:
- `:bench_server`  - TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container for TestTracking and reporting views

### 2) testtracking.tdb
Creates the host-side TestTracking table in `:bench_schema`.

This table is populated by TrueBench via BEFORE_RUN / AFTER_RUN / AFTER_NOTE statements and
provides the RunId time window used to join benchmark runs to host-side query history.

### 3) make_links.tdb
Displays BEFORE_RUN, AFTER_RUN, and AFTER_NOTE statements that can be copied into your
`truebench.tdb` startup file.

These statements are significant because they allow TrueBench to integrate benchmark runs with
host-side reporting and external tooling:
- BEFORE_RUN may log system configuration and prepare host-side objects for the test
- AFTER_RUN may capture additional metrics and archive supporting logs to a RunId-tagged file
- AFTER_NOTE replicates analyst notes into the host TestTracking table as durable history

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:

- `:bench_schema.QueryLog_Base`

This script is intentionally provided as a sample. You may need to edit it based on the Oracle
release and options enabled on your platform.

The purpose of the base view is to avoid embedding complex join logic in reporting queries.
Instead, reporting queries can be written against `QueryLog_Base`.

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
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers 
into each SQL statement. These identifiers are extremely useful for linking benchmark queries to 
host-side query history and performance metrics.

### insert_query_name (default: yes)
The profile setting:
- `insert_query_name = yes`

causes TrueBench to embed a query name tag into SQL, using the query filename or queue name as
the base.

Example embedded tag:
- `tdb=query001:001`

This enables filtering host query history to benchmark SQL statements.

### insert_runid (default: no)
The profile setting:
- `insert_runid = yes`

causes TrueBench to also embed the current RunId into SQL.

Example embedded tag:
- `runid=81`

This setting is recommended for platforms where query history and metrics are aggregated into
summary intervals (or where multiple benchmark runs may overlap within the same reporting
window). RunId tagging helps isolate benchmark SQL before and after tuning changes.

Recommended Oracle profile settings (otional):
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## Recommended Setup Sequence
1) Run core setup:
   `exec setup\oracle\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\oracle\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\oracle\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## QueryLog_Base View
The base view is intended to provide one row per logged SQL statement (or nearest equivalent
given platform configuration) with:
- benchmark RunId context from TestTracking
- query identity (QueryText and extracted QueryName)
- basic performance metrics (elapsed time, CPU time, I/O, rows)

The exact columns and accuracy depend on the Oracle query logging source used and how it is
configured on your platform.


## Example 1: Summary by RunId and QueryName (adds execution count)
This query summarizes benchmark queries for multiple runs. It is useful for quickly validating
workload completeness and comparing query performance across runs.

Note: depending on your Oracle logging source, some metrics may be aggregated and/or sampled.
Use execution-weighted averages if your base view contains pre-aggregated metrics.

The source of the data is the example `QueryLog_Base` view created by `querylog_base_view.tdb`,
which you may need to adapt for your DBMS release and platform options.

Example:

```
select
    QueryName,
    RunId,
    count(*) as ExecCnt,
    sum(ElapsedTimeMicrosec) as SumElapsedTimeMicrosec,
    sum(CpuTimeMicrosec) as SumCpuTimeMicrosec,
    sum(BufferGets) as SumBufferGets,
    sum(DiskReads) as SumDiskReads
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
It summarizes execution counts and performance metrics by TestName and RunId.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    count(*) as ExecCnt,
    sum(ElapsedTimeMicrosec) as SumElapsedTimeMicrosec,
    sum(CpuTimeMicrosec) as SumCpuTimeMicrosec,
    sum(BufferGets) as SumBufferGets,
    sum(DiskReads) as SumDiskReads
from
    :bench_schema.QueryLog_Base
where
    QueryName = 'query001:001'
    and RunId in (35, 47)
group by
    TestName, RunId, TestStartTime, QueryName
order by
    TestStartTime, RunId;
```

## Notes and Limitations
- Oracle query logging sources vary by platform options, licensing, and privileges.
- Query history sources may not provide full SQL text, full metrics, or complete retention for
  long-running benchmarks unless configured appropriately.
- In shared environments, other workloads may overlap benchmark windows. Use query tags
  (`tdb=` and `runid=`) to isolate benchmark SQL.
- If a benchmark run fails before StopTime is recorded, the join window may be incomplete.


## Contributing Improvements
You may have deeper knowledge of Oracle Database than the authors of TrueBench. If you develop
improvements that may help other members of the Oracle user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and
Oracle-specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
