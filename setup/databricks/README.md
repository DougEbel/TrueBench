# TrueBench Setup — Databricks SQL

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Databricks SQL.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Databricks SQL workloads without any setup scripts.

For Databricks connectivity and driver usage, see:
- `MAN databricks` (or `HELP databricks`)
- `HELP db`
- `HELP validate`


## Query log data collected by Databricks
Databricks SQL provides multiple sources of query execution telemetry. Depending on your
Databricks workspace configuration, SQL warehouse type, and permissions, useful sources may
include:
- SQL query history and execution metadata
- query text and execution status
- timing metrics (start/end times, duration)
- user/session context
- resource usage and execution statistics (varies by environment)

Databricks environments often support additional governance tooling, including audit logs and
workspace-level event telemetry.

### How Logging Is Enabled
Query history is generally available in Databricks SQL, but the ability to view detailed
telemetry depends on workspace permissions.

Some environments rely on centralized logging and export of telemetry to external systems.

### Retention and Availability
Retention varies by telemetry type. Some query history is retained for a limited window, while
audit/event logs may be retained externally based on enterprise governance policies.

If host-side query history is required for benchmark reporting, ensure retention is sufficient
for your benchmark analysis cycle.

### Privileges Required
To use the scripts in this directory, you typically need privileges to:
- create objects in the schema/container referenced by `:bench_schema`
- query Databricks query history and/or monitoring tables/views
- optionally create reporting views in `:bench_schema`


## Files Provided

### 1) prompt_for_db.tdb
Prompts for common setup variables:
- `:bench_server`  - the TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container where TestTracking and reporting objects will be created

Note: these values are normally prompted once per TrueBench execution. To change them you may
need to restart TrueBench (or clear the variables).

Databricks-specific enhancement (optional):
- Some environments may require additional context such as catalog/schema selection or session
  properties. You may extend prompt_for_db.tdb to capture those values.

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
- AFTER_NOTE replicates analyst notes into Databricks TestTracking as durable history

Databricks-specific enhancement (optional):
- If you want to classify benchmark SQL vs noise SQL, consider using SQL tagging patterns
  (embedded identifiers such as `/*tdb=query001*/`) and filtering query history accordingly.

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

Databricks query history sources vary across environments. This script is intentionally
provided as a sample and may require editing based on:
- workspace configuration
- SQL warehouse type
- telemetry source availability and retention
- permissions and governance controls

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
   `exec setup\databricks\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\databricks\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\databricks\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## Selecting a Query History Source (View/Table)
Databricks query telemetry sources vary depending on whether you are using:
- Databricks SQL warehouses
- governance tools and audit log export
- Unity Catalog and workspace-level monitoring capabilities

For documentation, search vendor manuals for:
- "Databricks SQL query history"
- "Databricks system tables query history"
- "Databricks audit logs"
- "Unity Catalog system tables query history"


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Databricks query history and extracting QueryName in QueryLog_Base.

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
Databricks. RunId tagging is typically only required for DBMSs that aggregate metrics by
plan/interval rather than query execution.

Recommended Databricks profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## QueryLog_Base View
The base view is intended to provide query telemetry joined to benchmark runs (RunId) using
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
- Databricks query history availability depends on workspace configuration and permissions.
- In shared environments, other workloads may overlap the same time window.
- To reduce false matches, consider additional filters such as:
  - benchmark username
  - warehouse name / warehouse id
  - workspace id / catalog / schema (as appropriate)

You may also want to define a derived column to classify queries executed during the run as:
- benchmark queries (intended workload)
- noise queries (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test, especially when concurrent workloads overlap the benchmark window.

Databricks-specific benchmark note:
- Some environments provide result caching and acceleration features. Benchmark results should
  be interpreted in the context of cache state and repeated-query behavior.


## Contributing Improvements
You may have deeper knowledge of Databricks SQL than the authors of TrueBench. If you develop
improvements that may help other members of the Databricks user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and Databricks-
specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
