# TrueBench Setup — Greenplum (PostgreSQL Protocol)

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Greenplum.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Greenplum workloads without any setup scripts.

For Greenplum connectivity and driver usage, see:
- `MAN greenplum` (or `HELP greenplum`)
- `HELP db`
- `HELP validate`


## Query log data collected by Greenplum
Greenplum is a massively parallel analytic database based on the PostgreSQL protocol. Query
logging and statement history mechanisms vary depending on:
- Greenplum version and deployment
- whether logging is enabled via server configuration
- whether query history is retained in log files, system catalog tables, or monitoring views
- whether optional monitoring tooling is installed

Depending on environment configuration, you may be able to collect:
- statement start/end timestamps and elapsed time
- user/session context and database name
- query text (as submitted/executed)
- statement error codes/messages
- resource usage and execution characteristics (environment dependent)

### How Logging Is Enabled
Greenplum can log statement execution in server logs and may expose monitoring information
through system views.

Exact logging configuration is platform dependent. Your operations team may control:
- which statements are logged
- the verbosity level
- where logs are stored and how long they are retained

### Retention and Availability
Retention is generally controlled by log retention policies and/or monitoring table retention.

If host-side query history is required for benchmark reporting, ensure that query logging is
enabled and retained long enough to cover benchmark analysis cycles.

### Privileges Required
To use the scripts in this directory, you typically need privileges to:
- create objects in the schema/container referenced by `:bench_schema`
- query system monitoring views or query history tables (if enabled)
- optionally create reporting views in `:bench_schema`


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

These statements are significant because they allow TrueBench to integrate benchmark runs with
host-side reporting and external tooling:
- BEFORE_RUN may record system environment and prepare test objects
- AFTER_RUN may capture additional metrics and archive supporting logs
- AFTER_NOTE replicates analyst notes into Greenplum’s TestTracking table as durable history

Greenplum-specific enhancement (optional):
- You may choose to add BEFORE_RUN/AFTER_RUN statements to query Greenplum configuration values
  relevant to performance (resource queues/groups, GP parameters) and store them externally.

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

Greenplum query history availability depends heavily on logging configuration. Many
installations retain query history primarily in server log files rather than in database
tables. This script is intentionally provided as a sample and may require editing based on:
- your DBMS release
- logging configuration and retention
- what monitoring views (if any) are available in your environment

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
   `exec setup\greenplum\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\greenplum\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\greenplum\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## Selecting a Query History Source (View/Table)
If your environment does not provide a database-resident query history source, query history
may only exist in Greenplum server logs. In that case, host-side reporting may require loading
log records into a queryable table.

For documentation, search vendor manuals for:
- "Greenplum Database Administrator Guide"
- "Greenplum Database Reference Guide"
- "Greenplum monitoring views query history"


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Greenplum query history and extracting QueryName in QueryLog_Base.

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
Greenplum. RunId tagging is typically only required for DBMSs that aggregate metrics by
plan/interval rather than query execution.

Recommended Greenplum profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## QueryLog_Base View
The base view is intended to provide statement telemetry joined to benchmark runs (RunId) using
the TestTracking window. It is designed as the stable foundation for benchmark reporting
queries.


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
    count(*) as ExecCnt
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
It summarizes execution counts by TestName and RunId.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    count(*) as ExecCnt
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
- Greenplum query history availability depends on logging configuration and retention.
- In shared environments, other workloads may overlap the same time window.
- To reduce false matches, consider additional filters such as:
  - benchmark username
  - database name
  - session / connection identifier
  - application name (if logged)

You may also want to define a derived column to classify statements executed during the run as:
- benchmark statements (intended workload)
- noise statements (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test, especially when system activity overlaps the benchmark window.

If a benchmark run fails before StopTime is recorded, joins may require logic to treat StopTime
as CURRENT_TIMESTAMP (or another end-time guard).


## Contributing Improvements
You may have deeper knowledge of Greenplum than the authors of TrueBench. If you develop
improvements that may help other members of the Greenplum user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and Greenplum-
specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
