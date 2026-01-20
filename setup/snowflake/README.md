# TrueBench Setup — Snowflake

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Snowflake.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS
was doing that resulted in that response time, including resource usage and opportunities to
tune SQL plans for better performance.

This setup is optional. TrueBench can run Snowflake workloads without any setup scripts.

For Snowflake connectivity and driver usage, see:
- `MAN snowflake` (or `HELP snowflake`)
- `HELP db`
- `HELP validate`


## Query log data collected by Snowflake
Snowflake collects detailed query history and execution telemetry in system views. Depending
on your Snowflake edition, configuration, and privileges, these views may include:
- query identifiers and timestamps (start/end)
- query text and compilation/execution statistics
- session and user context
- warehouse name and execution context
- rows produced, bytes scanned, bytes written (varies by query type)

Snowflake also supports query result caching which can cause repeated queries to return quickly
without full execution. This must be considered when interpreting benchmark results.


## Files Provided

### 1) prompt_for_db.tdb
Prompts for common setup variables:
- `:bench_server`  - the TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container where TestTracking and reporting objects will be created

Note: these values are normally prompted once per TrueBench execution. To change them you may
need to restart TrueBench (or clear the variables).

Snowflake-specific enhancement (optional):
- If you want to enforce a database, warehouse, or role for setup execution, extend this
  script to prompt for those values and issue DBMS-specific session configuration SQL.

### 2) testtracking.tdb
Creates the TestTracking table in `:bench_schema`.

This table is populated by TrueBench via:
- BEFORE_RUN  - insert the run start row
- AFTER_RUN   - update stop timestamp and counters
- AFTER_NOTE  - store analyst notes about run quality or anomalies

Snowflake-specific enhancement (optional):
- Some environments prefer separate schemas for setup objects vs query history views.

### 3) make_links.tdb
Displays example BEFORE_RUN, AFTER_RUN, and AFTER_NOTE statements that can be copied into your
`truebench.tdb` startup file.

These statements are significant because they allow TrueBench to integrate benchmark runs
with host-side reporting and external tooling:

- BEFORE_RUN may also be used to:
  - record system environment to a file (including RunId in the filename)
  - create or reset OS directories used for this run
  - prepare database tables used by the test

- AFTER_RUN may also be used to:
  - capture non-standard benchmark metrics (for example batches processed)
  - capture end-of-run environment details
  - zip a temp/log directory into a file named with TestName and RunId

- AFTER_NOTE replicates analyst notes written to the local TrueBench metadata into Snowflake’s
  TestTracking table as a durable historical record for reporting and analysis.

Snowflake-specific enhancement (optional):
- You may choose to set a Snowflake QUERY_TAG in BEFORE_RUN using the runid/testname. This can
  greatly improve the ability to filter Snowflake query history to only benchmark queries.

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

This script is intentionally provided as a sample. You may need to edit it based on the DBMS
release and platform options selected, and/or the query history source available in your
environment.

The purpose of the base view is to avoid embedding complex join logic in README.md examples.
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


## Recommended Setup Sequence
1) Run core setup:
   `exec setup\snowflake\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\snowflake\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\snowflake\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Snowflake query history and extracting QueryName in QueryLog_Base.

### insert_query_name (default: yes)
The profile setting:
- `insert_query_name = yes`

causes TrueBench to embed a query name tag into SQL.

Example SQL before tagging:
- `select invoice_dt, invoice_no, ...`

Example SQL after tagging (insert_query_name=yes):
- `select /* tdb=query001:001 */ invoice_dt, invoice_no, ...`

### insert_runid (default: no)
The profile setting:
- `insert_runid = yes`

causes TrueBench to also embed the current RunId into SQL.

Example embedded tag:
- `runid=81`

Note: the default TrueBench profile sets `insert_runid=no`, and this is recommended for
Snowflake. Snowflake query history is query-level (not interval/plan aggregated), so RunId
tagging is usually not required.

Recommended Snowflake profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## QueryLog_Base View
The base view is intended to provide one row per logged query with:
- benchmark RunId context from TestTracking
- query identity (QueryText and extracted QueryName)
- performance and resource usage columns relevant to Snowflake analysis

The exact columns depend on the query history source used and the configuration of your
Snowflake environment.


## Example 1: Summary by RunId and QueryName (adds execution count)
This query summarizes benchmark queries for multiple runs. It is useful for quickly validating
workload completeness and comparing query performance across runs.

The source of the data is the example `QueryLog_Base` view created by `querylog_base_view.tdb`,
which you may need to adapt for your DBMS release and platform options.

Example:

```
select
    QueryName,
    RunId,
    count(*) as ExecCnt,
    sum(ExecutionTimeMillisec) as SumExecTimeMillisec,
    sum(BytesScanned) as SumBytesScanned,
    sum(BytesWritten) as SumBytesWritten
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
    sum(ExecutionTimeMillisec) as SumExecTimeMillisec,
    sum(BytesScanned) as SumBytesScanned,
    sum(BytesWritten) as SumBytesWritten
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
- In shared Snowflake environments, other workloads may overlap the same time window. This may
  cause unrelated queries to join to your benchmark RunId.
- To reduce false matches, consider additional filters such as:
  - benchmark username
  - warehouse_name
  - query_tag (recommended for benchmarks)

You may also want to define a derived column to classify queries executed during the run as:
- benchmark queries (intended workload)
- noise queries (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test. In particular, noise queries can contribute to warehouse contention and resource
availability changes during the run window.

If a benchmark run fails before StopTime is recorded, joins may require logic to treat StopTime
as CURRENT_TIMESTAMP (or another end-time guard).

Snowflake benchmark note:
- query result caching may cause repeated queries to return quickly without DBMS execution.
  If you want to measure execution capability, ensure caching behavior is considered in your
  benchmark design and interpretation.


## Contributing Improvements
You may have deeper knowledge of Snowflake than the authors of TrueBench. If you develop
improvements that may help other members of the Snowflake user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and
Snowflake-specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
