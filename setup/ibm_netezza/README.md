# TrueBench Setup — IBM Netezza Performance Server

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for IBM Netezza Performance Server.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Netezza workloads without any setup scripts.

For Netezza connectivity and driver usage, see:
- `MAN ibm_netezza` (or `HELP ibm_netezza`)
- `HELP db`
- `HELP validate`


## Query log data collected by IBM Netezza
IBM Netezza Performance Server provides system views and historical query information that can
be used to analyze SQL execution activity and performance. Depending on the platform version,
configuration, and installed components, telemetry may include:
- query identifiers and timestamps
- query status and error indicators
- query text
- resource usage measures and execution metrics
- session and user context

Netezza shops often also use platform monitoring tools that capture additional performance
counters outside the database.

### How Logging Is Enabled
Netezza query history and monitoring information is available through system views. The
available data and retention are environment dependent.

### Retention and Availability
Query history retention and historical depth are configuration dependent. Some installations
retain only a limited window of history.

If host-side query history is required for benchmark reporting, run reporting queries soon
after benchmark completion or implement export/retention procedures.

### Privileges Required
To use the scripts in this directory, you typically need privileges to:
- create objects in the schema/container referenced by `:bench_schema`
- query Netezza system views used for monitoring and query history
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

These statements are significant because they allow TrueBench to integrate benchmark runs
with host-side reporting and external tooling:
- BEFORE_RUN may record system environment and prepare test objects
- AFTER_RUN may capture additional metrics and archive supporting logs
- AFTER_NOTE replicates analyst notes into Netezza’s TestTracking table as durable history

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

Multiple versions of query logging sources exist across Netezza releases and deployments.
This script is intentionally provided as a sample and may require editing based on:
- your DBMS release
- query logging configuration and retention
- available system views and privileges

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
   `exec setup\ibm_netezza\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\ibm_netezza\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\ibm_netezza\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## Selecting a Query History Source (View/Table)
Netezza query history objects vary by release and configuration. Common places to look include:
- `_V_*` query history and session views
- `_VT_*` variants (where present)
- `ADMIN.*` views (monitoring and history, where enabled)
- `SYSTEM.*` views (platform-specific monitoring, where enabled)

If you are unsure which objects exist in your environment, use catalog discovery such as:
- list schemas and views
- list objects containing words like: `query`, `hist`, `history`, `session`, `sql`, `text`

Then select the object(s) that provide:
- query start time
- query end time (or elapsed time)
- query id
- query text

If query text is stored in a separate view/table, join on query id.

For documentation, search IBM manuals for:
- "IBM Netezza Performance Server Administrator’s Guide"
- "IBM Netezza Performance Server System Catalog Reference"
- "IBM Netezza Performance Server Monitoring and Troubleshooting"


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Netezza query history and extracting QueryName in QueryLog_Base.

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
Netezza. Most Netezza query logging sources are query-level (not interval/plan aggregated), so
RunId tagging is usually not required.

Recommended Netezza profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## QueryLog_Base View
The base view is intended to provide query history and performance data joined to benchmark
runs (RunId) using the TestTracking window. It is designed as the stable foundation for
benchmark reporting queries.


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
    sum(ElapsedMillisec) as SumElapsedMillisec
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
It summarizes execution counts and timing by TestName and RunId.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    count(*) as ExecCnt,
    sum(ElapsedMillisec) as SumElapsedMillisec
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
- Netezza query history and telemetry retention may be limited by configuration.
- In shared environments, other workloads may overlap the same time window.
- To reduce false matches, consider additional filters such as:
  - benchmark username
  - connection/session identifier
  - database name or schema

You may also want to define a derived column to classify queries executed during the run as:
- benchmark queries (intended workload)
- noise queries (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test, especially when system activity overlaps the benchmark window.

If a benchmark run fails before StopTime is recorded, joins may require logic to treat StopTime
as CURRENT_TIMESTAMP (or another end-time guard).


## Contributing Improvements
You may have deeper knowledge of IBM Netezza Performance Server than the authors of TrueBench.
If you develop improvements that may help other members of the Netezza user community, please
consider submitting enhancements such as query logging guidance, TestTracking join views, and
Netezza-specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
