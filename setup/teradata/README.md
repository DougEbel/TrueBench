# TrueBench Setup — Teradata Vantage (Enterprise)

## Scope of This Directory
This directory contains optional scripts and documentation to support host-side benchmark
reporting for Teradata Vantage Enterprise.

TrueBench stores benchmark results in its local SQLite metadata database (TestTracking and
TestResults). Analysis of the metadata TestResults using SQLite shows response time and
throughput as observed from the client machine running TrueBench.

Host-side reporting complements metadata analysis by allowing you to analyze what Teradata was
doing that resulted in that response time, including:
- the SQL text executed (after parameter substitution)
- explain plans and step-level execution details
- object usage (tables, indexes, views)
- system resource usage (ResUsage / RSS)

This setup is optional. TrueBench can run Teradata workloads without any setup scripts.

For Teradata connectivity and driver usage, see:
- `MAN teradata` (or `HELP teradata`)
- `HELP db`
- `HELP validate`


## Query log data collected by Teradata (DBQL + ResUsage)
Teradata provides rich host-side logging sources. The scripts in this directory are designed
to integrate benchmark executions with Teradata query logging and resource usage telemetry.

### DBQL (Query logging)
DBQL tables (in DBC) can provide:
- query identifiers and timestamps
- SQL text (via dbqlsqltbl)
- object usage (via dbqlobjtbl)
- explain text (via dbqlexplaintbl)
- step details (via dbqlsteptbl)
- workload management fields (WDID, FinalWDID, DelayTime, etc.)
- resource usage per query (CPU, IO, spool, skew measures, etc.)

### ResUsage / RSS
ResUsage tables provide periodic system activity measurements, including:
- CPU busy / idle / IO wait
- disk activity / device counters
- AMP Worker Task activity (AWT)
- node-level health and workload information

### How Logging Is Enabled
Teradata Vantage query logging and ResUsage availability depend on system configuration.
Production systems often use PDCR to prevent the DBC user's perm space from being exhausted
and to apply partitioning to historical data for improved analysis performance. 
Typically, all DBQL data is moved to PDCR tables every 8 hours.  Resusage data is typically
retained in DBC for several months. 

#### Enabling DBQL logging
DBQL logging is enabled through the `REPLACE QUERY LOGGING ...` statement. 
That statement requires EXECUTE privilege on the macro DBC.DBQLAccessMacro. 
For a Testing/Development platform, there is little issue with issuing:
- `replace query logging with all on all;`

However you should monitor perm space on DBC because recording objects, especially
columns can chew up a lot of space with a lot of executions.  In a production
environment, you might need to limit your request to the DBA to:
- `replace query logging with sql, stepinfo, explain, no column objects on account = 'benchmark';`

DBQL buffers are retained in memory and flushed to disk, typically every 10 minutes or when
the buffers are full, when a `replace query logging ...` statement is issued, or can be 
flushed immediately to disk so you can analyze the test that just completed with:
- `flush query logging with all;`

#### Enabling ResUsage logging
This requires someone with DBA responsibilities to logon to one of the nodes and use the
`ctl` utility to indicate which of the logging types should be enabled and the interval 
for capturing the data. Some of the logging types can generate lots of records per interval
by AMP or PDISK. The ResusageSPMA table is a good selection to get a summary of CPU, I/O, 
statements executed, etc by node.  ResUsageSPS can be valuable if you are tuning TASM
workload rules. 

The most important change in addition to enable ResusageSPMA is to set a collection interval
that will produce useful information for a benchmark. The default is 600 seconds or 10 minutes. 
That means in a 15 minute "Fixed Time" test, there would be only 1 set of rows by node that 
are purely within the test and in a 5 minute test, there may be no rows at all. 

For benchmarks, setting the logging interval for the system to 30 or 60 seconds will provide
multiple snapshots of system utilization within the duration of the test. With ResusageSPMA
enabled, on a 16 node platform with 60 second interval, there would be 240 ResusageSPMA rows
logged in a 15 minute test.

### Privileges Required
To use the scripts in this directory, you typically need privileges to:
- create the database or user `:bench_schema` from a parent database or user
- create objects in the database/user referenced by `:bench_schema`
- create views and functions in `:bench_schema`
- query DBC DBQL tables and ResUsage tables
- optionally create a database/user for benchmark reporting objects (initial_setup.tdb)


## Files Provided

### 1) initial_setup.tdb
This is the primary setup entry point for Teradata.

Unlike most other DBMS setup directories, the Teradata setup supports additional automation:
- offers to create the target database or user, then prompts for needed information
- then executes the remaining setup scripts in sequence

### 2) prompt_for_db.tdb
Prompts for common setup variables:
- `:bench_server`  - the TrueBench DB alias used to run setup SQL
- `:bench_schema`  - database/user where objects will be created

Note: these values are normally prompted once per TrueBench execution. To change them you may
need to restart TrueBench (or clear the variables).

### 3) testtracking.tdb
Creates the host-side TestTracking table in `:bench_schema`.

This table is populated by TrueBench via:
- BEFORE_RUN  - insert the run start row
- AFTER_RUN   - update stop timestamp and counters
- AFTER_NOTE  - store analyst notes about run quality or anomalies

### 4) querylog_base_view.tdb
Creates the base query logging views. This script:
- creates the main DBQL join view `dbqlogtbl`
- then executes additional DBQL/ResUsage view scripts:
  - querylog_base_view_dbql.tdb
  - querylog_base_view_resusage.tdb

### 5) querylog_base_view_dbql.tdb
Creates additional DBQL base views joining:
- TestTracking
- dbqlogtbl
- and one other DBQL table

These views provide explain text, SQL text, object usage, and step details.

### 6) querylog_base_view_resusage.tdb
Creates ResUsage base views joining:
- TestTracking
- one ResUsage table

These views allow system activity reporting aligned to benchmark RunId windows.

### 7) reporting_functions.tdb
Creates utility functions used by reporting views:
- ExtractBenchQname
- TimestampSubtract

### 8) reporting_views.tdb
Creates reporting views built on top of DBQL and ResUsage base views.

Reporting views select a useful subset of columns and add value such as:
- query name extraction
- runtime interval calculations
- skew measures
- summaries by query and run

### 9) make_links.tdb
Displays example BEFORE_RUN, AFTER_RUN, and AFTER_NOTE statements that can be copied into your
`truebench.tdb` startup file.

These statements are significant because they allow TrueBench to integrate benchmark runs with
host-side query logging analysis and external tooling:
- BEFORE_RUN may record environment, prepare data, and reset run-specific objects
- AFTER_RUN may capture non-standard metrics and archive supporting logs
- AFTER_NOTE replicates analyst notes into host TestTracking as durable history


## Recommended Setup Sequence
1) Run Teradata setup:
   `exec setup\teradata\initial_setup.tdb`

2) Copy BEFORE_RUN / AFTER_RUN / AFTER_NOTE statements into your `truebench.tdb` startup file.

3) Ensure DBQL is configured to collect required information.

4) Run one short benchmark test, then query reporting views under `:bench_schema`.


## SQL Tagging Settings (insert_query_name and insert_runid)
TrueBench supports profile settings (via the TrueBench PROFILE command) that inject identifiers
into each SQL statement.

These identifiers are critical for host-side logging correlation.

### insert_query_name (default: yes)
When enabled:
- TrueBench embeds: `/* tdb=<qname> */` into SQL text

Example SQL before tagging:
- `select col1, col2 from t where ...`

Example SQL after tagging:
- `select /* tdb=query001:001 */ col1, col2 from t where ...`

This makes it easy to:
- locate benchmark SQL in DBQL query text
- summarize by query name across runs
- analyze tuning changes by query

### insert_runid (default: no)
Teradata DBQL logs individual query executions; metrics are not aggregated by query plan/interval
in the same way as some other DBMSs.

Recommended Teradata profile settings:
- `PROFILE insert_query_name yes`
- `PROFILE insert_runid no`


## Objects Created (Functions / Tables / Views)
The Teradata setup creates the following objects under `:bench_schema`.

```
TableKind | TableName        | CommentString
F         | ExtractBenchQname| Extracts query name from ExtractBenchInfo function
F         | TimestampSubtract| Time#1 - Time#2 in seconds
T         | TestTracking     | Table to save start and stop timestamps for each run

V         | dbqlogtbl        | One row for every query within a RunId from dbc.dbqlogtbl
V         | dbqlsqltbl       | SQL statements for every query within a RunId from dbc.dbqlsqltbl
V         | dbqlobjtbl       | Tables, views, columns for every query within a RunId from dbc.dbqlobjtbl
V         | dbqlexplaintbl   | Explain plan for every query within a RunId from dbc.dbqlexplaintbl
V         | dbqlsteptbl      | Every step executed for every query within a RunId from dbc.dbqlsteptbl

V         | ResUsageIpma     | RSS data related to performance of an entire node
V         | ResUsageSawt     | RSS data collected for AMP Worker Tasks (AWT)
V         | ResUsageScpu     | RSS data collected on a per CPU basis
V         | ResUsageSldv     | RSS data collected for logical (disk) devices
V         | ResUsageSmhm     | RSS data collected for MHM (Multiple Hash Maps)
V         | ResUsageSpdsk    | RSS data collected for PDISK devices
V         | ResUsageSpma     | Tracks performance of an entire node independent of applications
V         | ResUsageSps      | RSS data collected for the Priority Scheduler and other areas
V         | ResUsageSvdsk    | RSS data collected for VDISK devices
V         | ResUsageSvpr     | RSS data collected for each virtual processor on the node

V         | RptSumErrors     | Summary by run of executions and errors (constrain on RunId)
V         | RptSumQueries    | Summary of query executions (constrain on RunId)
V         | RptSumRuns       | Summary of benchmark queries vs other queries across RunIds
V         | RptSystemCpu     | CPU / IO wait / idle for each ResUsage interval within RunId
V         | RptTestExplain   | Explain text by RunId and/or QueryName
V         | RptTestSQL       | Extracts complete SQL by RunId or query across RunIds
V         | RptTestSteps     | Step detail by RunId and/or QueryName
```

## Example Queries (Reporting Views)

### Example 1: Summary by RunId and QueryName (adds execution count)
This query summarizes benchmark queries for multiple runs. It is useful for quickly validating
workload completeness and comparing query performance across runs.

Example:

```
select
    RunId,
    QueryName,
    ExecCnt,
    AveRunSecs,
    MaxRunSecs,
    SumCpuTime
from
    :bench_schema.RptSumQueries
where
    RunId in (81, 92)
order by
    QueryName, RunId;
```

### Example 2: Extract SQL for one query script before a set of modifications
This query is useful during tuning: it extracts the SQL for all queries in a
script file as executed before a set of changes were made to the SQL. 
Notes:
- This query would work best against a serial or fixed work test where there 
  is only one execution of the query
- The SQL will be after any parameter substitution, which is useful if the 
  parameters generated any errors or created no output from the query.

Example:

```
select
    RunId,
    QueryName,
    QueryText
from
    :bench_schema.RptTestSQL
where
    QueryName like 'query045%'
    and RunID = 15
order by
    RunId;
```

### Example 3: Explain plan for one benchmark query between two runs
Example:

```
select
    RunId,
    QueryName,
    ExplainText
from
    :bench_schema.RptTestExplain
where
    QueryName = 'query001:001'
    and RunId in (35, 47)
order by
    RunId;
```

## Notes and Limitations

### Shared system noise
In shared Teradata environments, other workloads may overlap the benchmark time window. Some
reporting views include logic to separate benchmark-tagged queries from other queries, but you
may still need additional constraints:
- username
- account string
- QueryBand patterns

You may want to define a derived classification:
- benchmark queries
- noise queries

This classification can help explain benchmark variability across repeated executions.

### PDCR (not yet implemented)
Many production Teradata Vantage Enterprise sites deploy PDCR (Database Query Capture and
Replay / performance repositories) which copy DBQL and ResUsage to PDCR tables. Supporting
transparent DBQL+PDCR union views requires additional work and testing.

### VantageLake (not yet implemented)
VantageLake query logging and telemetry sources may require special handling and aggregation.
This setup currently targets traditional Vantage Enterprise DBQL/ResUsage logging.


## Contributing Improvements
You may have deeper knowledge of Teradata Vantage than the authors of TrueBench. If you develop
improvements that may help other members of the Teradata user community, please consider
submitting enhancements such as query logging guidance, reporting enhancements, PDCR support,
and additional ResUsage/reporting views.

See `CONTRIBUTE.md` in the TrueBench root directory.
