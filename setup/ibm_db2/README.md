# TrueBench Setup — IBM Db2 / Db2 Warehouse

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for IBM Db2 and Db2 Warehouse (including appliance and integrated deployments such as
IIAS).

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what the DBMS was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL plans for better performance.

This setup is optional. TrueBench can run Db2 workloads without any setup scripts.

For Db2 connectivity and driver usage, see:
- `MAN ibm_db2` (or `HELP ibm_db2`)
- `HELP db`
- `HELP validate`


## Query log data collected by IBM Db2 / Db2 Warehouse
IBM Db2 provides multiple sources of query execution and performance telemetry. Which objects
are available depends on platform edition (Db2 LUW vs Db2 Warehouse), configuration, and
enabled monitoring features.

Common sources include:
- Db2 monitoring table functions
  - execution information and activity metrics
  - often used as the primary interface for performance monitoring
- system catalog and administrative views
  - session context, package/cache details, and other metadata
- optional event monitoring (event monitors)
  - configurable logging and persistence of activity metrics

The collected data may include:
- statement start/end times and elapsed time
- statement text
- user/session context
- rows returned and related counters
- sort / temporary usage indicators (depending on monitoring configuration)
- CPU / execution counters available through monitoring functions

### How Logging Is Enabled
Db2 monitoring telemetry is controlled by configuration. Some views and monitoring functions
provide immediate insight without additional setup, while durable statement history may require:
- enabling specific monitoring switches
- configuring an event monitor to persist activity data to tables

In managed deployments (including appliances), access and configuration may be governed by the
operations team.

### Retention and Availability
Retention varies by telemetry source:
- cached / in-memory monitoring may only cover a recent window
- persisted event monitor tables can support long retention, depending on cleanup policies

If host-side query history is required for benchmark reporting, ensure monitoring retention is
sufficient for your benchmark cycle.

### Privileges Required
To use the scripts in this directory, you typically need privileges to:
- create objects in the schema/container referenced by `:bench_schema`
- access Db2 monitoring functions and administrative views used for reporting
- optionally create reporting views in `:bench_schema`
- optionally configure or query event monitor output tables (if used)


## Files Provided

### 1) prompt_for_db.tdb
Prompts for common setup variables:
- `:bench_server`  - the TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container where TestTracking and reporting objects will be created

Note: these values are normally prompted once per TrueBench execution. To change them you may
need to restart TrueBench (or clear the variables).

Db2-specific enhancement (optional):
- You may choose to extend prompting to capture additional identifiers required for your
  environment, such as a specific database name, schema, or monitoring object locations.

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
- AFTER_NOTE replicates analyst notes into Db2’s TestTracking table as durable history

Db2-specific enhancement (optional):
- You may choose to add BEFORE_RUN/AFTER_RUN statements to query and persist configuration
  details (bufferpool sizes, workload settings, package cache state) to assist analysis.

### 4) querylog_base_view.tdb
Provides a sample script that creates the base query log view:
- `:bench_schema.QueryLog_Base`

This script is intentionally provided as a sample. You may need to edit it based on the DBMS
release and platform options selected, and/or your chosen monitoring approach.

Important note:
- Many Db2 monitoring sources are current-only unless an event monitor is enabled. If you
  require durable history for benchmark reporting, consider activity event monitors that write
  activity rows into tables.

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
   `exec setup\ibm_db2\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\ibm_db2\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\ibm_db2\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## Selecting a Query History Source (View/Table)
Db2 statement history and performance telemetry vary by edition and configuration. Common
places to look include:
- monitoring table functions that expose statement/activity metrics
- administrative views (prefixed with `SYS*` or `ADMIN*` in many environments)
- event monitor output tables (persisted statement/activity history)

If you are unsure which objects exist in your environment, consult documentation and search for
objects containing words such as:
- `activity`, `stmt`, `statement`, `history`, `mon`, `event`

Then select the object(s) that provide:
- statement start time
- statement end time (or elapsed time)
- statement identifier (if any)
- statement text

If statement text is stored separately from timing information, join using the statement id or
activity id provided by the monitoring source.

For documentation, search IBM manuals for:
- "IBM Db2 Monitoring and Tuning Guide"
- "IBM Db2 Performance Monitoring"
- "IBM Db2 Warehouse Administration Guide"
- "IBM Db2 System Catalog Reference"


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to Db2 statement telemetry and extracting QueryName in QueryLog_Base.

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

Note: the default TrueBench profile sets `insert_runid=no`, and this is recommended for Db2.
Db2 telemetry is generally query/activity level. RunId tagging is typically only required for
DBMSs that aggregate metrics by plan/interval rather than query execution.

Recommended Db2 profile settings:
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
    count(*) as ExecCnt,
    avg(CpuTimeMicrosec) as AvgCpuTimeMicrosec,
    sum(RowsReturned) as SumRowsReturned
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
It summarizes execution counts and average telemetry by TestName and RunId.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    count(*) as ExecCnt,
    avg(CpuTimeMicrosec) as AvgCpuTimeMicrosec,
    avg(RowsReturned) as AvgRowsReturned
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
- Db2 telemetry depth and retention depend heavily on monitoring configuration.
- In shared environments, other workloads may overlap the same time window.
- To reduce false matches, consider additional filters such as:
  - benchmark username
  - application name / client identifier (if available)
  - session / connection id

You may also want to define a derived column to classify statements executed during the run as:
- benchmark statements (intended workload)
- noise statements (other workloads overlapping the run window)

This classification can help explain benchmark variability across repeated executions of the
same test, especially when system activity overlaps the benchmark window.

If a benchmark run fails before StopTime is recorded, joins may require logic to treat StopTime
as CURRENT_TIMESTAMP (or another end-time guard).


## Contributing Improvements
You may have deeper knowledge of IBM Db2 / Db2 Warehouse than the authors of TrueBench. If you
develop improvements that may help other members of the Db2 user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and Db2-
specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
