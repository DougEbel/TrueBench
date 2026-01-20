# TrueBench Setup — Amazon Redshift

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Amazon Redshift.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what Redshift was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Redshift workloads without any setup scripts.

For Redshift connectivity and driver usage, see:
- `MAN redshift` (or `HELP redshift`)
- `HELP db`
- `HELP validate`


## Query log data collected by Amazon Redshift
Amazon Redshift records query execution information in system tables and views. Depending on
cluster type, Redshift version, and your privileges, useful sources include:
- `STL_QUERY` and related `STL_*` tables
  - detailed execution data for SQL queries
  - query text may be split across rows in `STL_QUERYTEXT`
- `SVL_QLOG`
  - readable subset of recent query execution information
- `SVL_QUERY_SUMMARY`
  - aggregated query information across nodes and steps
- `SYS_QUERY_HISTORY` (unified SYS monitoring views)
  - provides query start/end, queue time, elapsed time, and related metrics

These sources generally include:
- query identifiers, start/end timestamps, and elapsed times
- database and user context
- query status indicators (aborted, errors)
- workload queue placement / WLM data (via related tables/views)


## Files Provided

### 1) prompt_for_db.tdb
Prompts for common setup variables:
- `:bench_server`  - the TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container where TestTracking and reporting objects will be created

Note: these values are normally prompted once per TrueBench execution. To change them you may
need to restart TrueBench (or clear the variables).

### 2) testtracking.tdb
Creates the TestTracking table in `:bench_schema`.

This table is populated by TrueBench via:
- BEFORE_RUN  - insert the run start row
- AFTER_RUN   - update stop timestamp and counters
- AFTER_NOTE  - store analyst notes about run quality or anomalies

### 3) make_links.tdb
Displays example BEFORE_RUN, AFTER_RUN, and AFTER_NOTE statements that can be copied into your
`truebench.tdb` startup file.

These statements are significant because they allow TrueBench to integrate benchmark runs
with host-side reporting and external tooling:
- BEFORE_RUN may record system environment and prepare test objects
- AFTER_RUN may capture additional metrics and archive supporting logs
- AFTER_NOTE replicates analyst notes into Redshift’s TestTracking table as durable history

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

This script is intentionally provided as a sample. You may need to edit it based on the DBMS
release and platform options selected, and/or the Redshift query history source preferred in
your environment.

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
   `exec setup\redshift\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\redshift\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\redshift\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Redshift query history and extracting QueryName in QueryLog_Base.

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
Redshift. Redshift query history is query-level (not interval/plan aggregated), so RunId
tagging is usually not required.

Recommended Redshift profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## QueryLog_Base View
The base view is intended to provide query history and performance data joined to benchmark
runs (RunId) using the TestTracking window. It is designed as the stable foundation for
benchmark reporting queries.

Redshift note:
- Some query text sources store SQL across multiple rows (for example STL_QUERYTEXT). Your
  QueryLog_Base view may expose rows per text segment, or may reconstruct full SQL text
  depending on your environment and preferences.


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
    sum(TotalExecTimeMicrosec) as SumExecTimeMicrosec,
    sum(TotalQueueTimeMicrosec) as SumQueueTimeMicrosec
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
    sum(TotalExecTimeMicrosec) as SumExecTimeMicrosec,
    sum(TotalQueueTimeMicrosec) as SumQueueTimeMicrosec
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
- In shared Redshift environments, other workloads may overlap the same time window. This may
  cause unrelated queries to join to your benchmark RunId.
- To reduce false matches, consider additional filters such as:
  - benchmark username/userid
  - database name
  - query labels or WLM queue (if used)

You may also want to define a derived column to classify queries executed during the run as:
- benchmark queries (intended workload)
- noise queries (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test. In particular, noise queries can contribute to queueing delays and resource
contention during the run window.

If a benchmark run fails before StopTime is recorded, joins may require logic to treat StopTime
as CURRENT_TIMESTAMP (or another end-time guard).

Redshift benchmark note:
- Some telemetry tables are short-retention. If you rely on query history for reporting, run
  reporting queries soon after benchmark completion or export the required history externally.


## Contributing Improvements
You may have deeper knowledge of Amazon Redshift than the authors of TrueBench. If you develop
improvements that may help other members of the Amazon Redshift user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and Redshift-
specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
