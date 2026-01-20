# TrueBench Setup — Google BigQuery

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Google BigQuery.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what BigQuery was
doing that resulted in that response time, including resource usage and opportunities to tune
SQL for better performance.

This setup is optional. TrueBench can run BigQuery workloads without any setup scripts.

For connectivity and driver usage, see:
- `MAN bigquery` (or `HELP bigquery`)
- `HELP db`
- `HELP validate`


## Query log data collected by BigQuery
BigQuery provides query/job history and resource usage metrics through metadata views. Most
benchmark reporting workflows use:
- `INFORMATION_SCHEMA` job history views (queries/jobs by project)

These views capture query text and useful resource metrics such as:
- bytes processed/billed
- total slot milliseconds
- cache hit indicator

Important note: BigQuery has query caching behavior that can cause a query to return results
without performing full execution. This is useful for analytics workloads, but it can produce
misleading benchmark results if not controlled (see Query Cache guidance below).


## Files Provided

### 1) prompt_for_db.tdb
Prompts for setup variables:
- `:bench_server`  - TrueBench DB alias used to run setup SQL
- `:bench_schema`  - schema/container for TestTracking and reporting views

### 2) testtracking.tdb
Creates the host-side TestTracking table in `:bench_schema`.

This table is populated by TrueBench via BEFORE_RUN / AFTER_RUN / AFTER_NOTE statements and
provides the RunId time window used to join benchmark runs to BigQuery query history.

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

This script is intentionally provided as a sample. You may need to edit it based on:
- your BigQuery region / multi-region location
- your project and dataset conventions
- the metadata view(s) you have access to

The purpose of the base view is to avoid embedding complex query log logic in reporting queries.
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


## BigQuery Region / Multi-Region Notes
BigQuery job metadata views are commonly accessed using a location qualifier such as:
- `region-us`
- `region-eu`

Your environment may use a different region or a multi-region configuration. You must edit
`querylog_base_view.tdb` to reference the correct region for your project.

If your jobs are executed in multiple locations, you may need multiple base views or a UNION
view.

Recommended approach:
- start by locating the correct INFORMATION_SCHEMA view for your project/location
- validate that it returns rows for your benchmark jobs
- then adapt the join predicate to TestTracking (RunId window)


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement. These identifiers are extremely useful for linking benchmark queries
to BigQuery job history.

### insert_query_name (default: yes)
The profile setting:
- `insert_query_name = yes`

causes TrueBench to embed a query name tag into SQL, using the query filename or queue name as
the base.

Example SQL before tagging:
- `select invoice_dt, invoice_no, ...`

Example SQL after tagging (insert_query_name=yes):
- `select /* tdb=query001:001 */ invoice_dt, invoice_no, ...`

This enables filtering query history to benchmark SQL statements.

### insert_runid (default: no)
The profile setting:
- `insert_runid = yes`

causes TrueBench to also embed the current RunId into SQL.

Example embedded tag:
- `runid=81`

Note: the default TrueBench profile sets `insert_runid=no`. This is recommended to enable only
when you need to isolate runs in host-side query logging.

Example changing BigQuery profile settings (optional):
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid yes`


## Query Cache (Benchmark Correctness)
BigQuery can return cached results for repeated queries. When benchmarking DBMS execution and
resource usage, query caching can bypass the actual DBMS execution path and produce misleading
results.

Recommendations:
- disable query cache when benchmarking (driver option)
- monitor the `CacheHit` field in `QueryLog_Base`

If `CacheHit` is true for benchmark statements, performance results are not representative of
full query execution.

This setup directory provides `CacheHit` as part of `QueryLog_Base` so cached executions can be
identified and filtered.


## Recommended Setup Sequence
1) Run core setup:
   `exec setup\bigquery\initial_setup.tdb`

2) (Optional) Review and edit the sample query log view script as needed:
   `setup\bigquery\querylog_base_view.tdb`

3) (Optional) Create the base query log view:
   `exec setup\bigquery\querylog_base_view.tdb`

4) Run reporting queries against:
   `:bench_schema.QueryLog_Base`


## QueryLog_Base View
The base view is intended to provide one row per logged BigQuery query job with:
- benchmark RunId context from TestTracking
- query identity (QueryText and extracted QueryName)
- resource usage columns relevant to BigQuery analysis

Typical BigQuery resource usage columns include:
- TotalBytesProcessed
- TotalBytesBilled
- TotalSlotMs
- CacheHit


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
    sum(TotalSlotMs) as SumSlotMs,
    sum(TotalBytesProcessed) as SumBytesProcessed,
    sum(TotalBytesBilled) as SumBytesBilled
from
    :bench_schema.QueryLog_Base
where
    RunId in (81, 92)
    and QueryName is not null
    and CacheHit = false
group by
    QueryName, RunId
order by
    QueryName, RunId;
```

## Example 2: Tuning analysis for one query across tests / runs
This query supports tuning workflows by tracking a specific benchmark query across test runs.
It summarizes execution counts and resource usage metrics by TestName and RunId.

Example:

```
select
    TestName,
    RunId,
    TestStartTime,
    QueryName,
    count(*) as ExecCnt,
    sum(TotalSlotMs) as SumSlotMs,
    sum(TotalBytesProcessed) as SumBytesProcessed,
    sum(TotalBytesBilled) as SumBytesBilled
from
    :bench_schema.QueryLog_Base
where
    QueryName = 'query001:001'
    and RunId in (35, 47)
    and CacheHit = false
group by
    TestName, RunId, TestStartTime, QueryName
order by
    TestStartTime, RunId;
```

## Notes and Limitations
- BigQuery query/job history sources and retention may vary by platform configuration.
- Region / multi-region settings affect which INFORMATION_SCHEMA views contain your job history.
- In shared environments, other workloads may overlap benchmark windows. Use query tags
  (`tdb=` and `runid=`) to isolate benchmark SQL.
- Query caching can invalidate benchmark results. Use the CacheHit column to detect and filter
  cached statements.


## Contributing Improvements
You may have deeper knowledge of BigQuery than the authors of TrueBench. If you develop
improvements that may help other members of the BigQuery user community, please consider
submitting enhancements such as query logging guidance, TestTracking join views, and
BigQuery-specific TrueBench benchmarking recommendations.

See `CONTRIBUTE.md` in the TrueBench root directory.
