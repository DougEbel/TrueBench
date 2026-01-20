# INSTALL.md — TdBench / TrueBench Installation & Driver Setup

## Overview

**TrueBench (Python TdBench / QueryDriver)** is a lightweight CLI + scripting workload driver for executing repeatable SQL and OS workloads, with:

- queues, workers, pacing
- run metadata capture of all tests and their query/os executions
- BEFORE/AFTER hooks for automation and reporting
- variable substitution (`:runid`, `:testname`, `:cd`, etc.)
- help topics via `HELP` and `MAN`
- driver abstraction for multiple DBMS platforms

This document covers:

1) installing TrueBench  
2) virtual environment setup  
3) DBMS driver installation (Python + ODBC)  
4) `truebench.tdb` startup configuration

See the README.md for quick start instructions for using TrueBench.

---

## Directory Layout (Root)

Typical structure:

```
truebench/
  truebench.bat
  truebench.sh
  truebench.tdb
  INSTALL.md
  setup/
  scripts/
  metadata/
  logs/
  temp/
  truebench_01_00/         (code)
  .venv/                   (virtual environment)
```

---

## Virtual Environment Notes 

To avoid issues with system adminitrators or other users, TrueBench automaticall sets up
a virtual environment to install functions and drivers needed by TrueBench. 

The `.venv` directory is **OS-specific**. A virtual environment created on Windows cannot 
be used on Linux/macOS (and vice versa).  TrueBench protects against cross-OS corruption using:

```
.venv/truebench_env_os
```

If the venv OS does not match the current OS, the launcher stops and instructs you to delete and recreate `.venv`.

---

## Startup Configuration: `truebench.tdb`

On startup, TrueBench **auto-includes**:

```
truebench.tdb
```

This file is intended for common startup commands such as:

- default DB connection setup (`DB ...`)
- initial configuration / environment settings
- default variables (e.g., setting `:testname` conventions)

### Example `truebench.tdb`

```text
@ECHO OFF
DB vantage teradatasql url=myvantage.company.com user=dadmin password=SuperSecret
```

## The `DB` and `VALIDATE` commands

The `DB` command defines a DB alias (named connection configuration) by selecting a driver and
recording connection parameters (url/user/password and driver-specific options).

When `DB` is executed, TrueBench performs a *driver readiness check* for supported drivers:

- For known Python drivers: verifies the required Python module is importable
  (and may offer to install it into the TrueBench `.venv` when running interactively)
- For ODBC-style drivers: verifies `pyodbc` is installed and (where applicable) that a matching
  OS-level ODBC driver is detectable

TrueBench does not fully validate URL, credentials, or driver-specific parameters at DB
definition time. Full validation occurs on first use of the alias.

After defining an alias, the recommended next step is:

`VALIDATE <alias>`

The `VALIDATE` command:
- confirms the alias is usable (driver + connection parameters + credentials)
- connects and executes trivial test SQL repeatedly for ~5 seconds
- measures baseline latency from this TrueBench client platform to the DBMS

This latency baseline is extremely useful for diagnosing performance variability and
separating DBMS execution time from client/network overhead.


---

## Automatic Driver Installation (Known Python Drivers)

TrueBench includes a list of “known” Python driver modules for common DBMS platforms.  
If a known driver is missing, TrueBench can offer to install it automatically (via `pip`) 
**when prompting is allowed** (interactive terminal session).

Examples of Python driver modules:

- Teradata: `teradatasql`
- PostgreSQL: `psycopg2` or `psycopg`
- MySQL/MariaDB: `mysql-connector-python` or `pymysql`
- Snowflake: `snowflake-connector-python`
- SQL Server: `pyodbc` (often ODBC-based)

If you are running in non-interactive mode (redirected stdin/out, cron, CI), TrueBench will 
refuse to prompt and will instead display an error telling you to install the module manually.

### Manual install example

Inside the TrueBench root directory:

Windows:
```bat
.venv\Scripts\pip.exe install teradatasql
```

Linux/macOS:
```bash
. .venv/bin/activate
pip install teradatasql
```

---

## Generic Python DB-API Drivers (pydbapi)

If your DBMS platform is not supported as a built-in “known driver”, you may still be able to
connect using a generic Python DB-API 2.0 driver module.

TrueBench supports this using the `pydbapi` driver key.

### Requirements

1) **Install the DBMS-specific Python module into the TrueBench `.venv`** (manual install)
2) Define a DB alias using:
   - `driver=pydbapi`
   - `module=<python module name>`

TrueBench does **not** automatically install Python modules for the generic driver. This is
intentional because the module name is user-supplied and may represent any third-party DB-API
implementation.

### Example

PostgreSQL using psycopg2:

```text
DB pg pydbapi url=localhost user=myuser password=? module=psycopg2 database=mydb port=5432
SQL pg "select 1"
```

Teradata using teradatasql (generic driver form):

```text
DB td pydbapi url=myvantage.company.com user=demo_user password=? module=teradatasql encryptdata=true
SQL td "select current_date"
```

### Installation

Windows:

```bat
.venv\Scripts\pip.exe install <module>
```

Linux/macOS:

```bash
. .venv/bin/activate
pip install <module>
```

### Notes

- The module must expose a `connect()` function and behave as a Python DB-API compatible driver.
- The `PREPARE` command is not supported for generic DB-API drivers. TrueBench performs variable
  substitution before execution, so normal `SQL` and benchmark runs are not impacted.
- If connection parameters do not match the DBMS module requirements, the first attempt to use
  the alias (e.g., `SQL <alias> ...` or `VALIDATE <alias>`) will fail with a connection error.

---

## ODBC Drivers (System-Level Installation)

ODBC drivers are not pure Python dependencies; they require:

- OS-level driver installation
- ODBC driver manager configuration
- DSN configuration (optional but common)

### Windows
- Install DBMS vendor ODBC driver
- Confirm it appears in **ODBC Data Sources (64-bit)**

### Linux
Usually requires:
- unixODBC
- vendor ODBC package
- `/etc/odbcinst.ini` and optionally `/etc/odbc.ini`

Example packages (Linux):

```bash
sudo apt-get install unixodbc unixodbc-dev
```

TrueBench may use `pyodbc` as the Python bridge, but the real ODBC driver must be installed at the OS level.

---

## Setup Directory and DBMS Templates

The `setup/` directory contains DBMS-specific startup helpers, templates, and scripts.

This often includes:

- example `DB ...` statements
- ODBC DSN templates
- connection parameter examples
- reporting or “query log” setup helpers

When configuring a new DBMS platform, start with:

```
setup/<dbms>/
```

---

## BEFORE/AFTER Hooks (Reporting and Query Log Integration)

TrueBench supports pre/post automation hooks such as:

- `BEFORE_RUN`
- `AFTER_RUN`
- `AFTER_NOTE`

These are intended to support integrations such as:

- setup of defaults for all runs like workload parameters or default databases
- clearing or pre-populating directories with OS commands
- host query log / DB query history reporting
- DBQL / query log extracts
- workload metadata extraction
- environment snapshots (OS + DB configuration capture)
- collection of all files generated in the temp directory to
  a logs directory named by runid

### Practical usage

You can use:

- `BEFORE_RUN` to begin query log capture / enable tracing
- `AFTER_RUN` to extract query logs / explain plans / stats
- `AFTER_NOTE` to attach supporting artifacts to the run output (notes, filenames, reports)

See the `setup/` directory for DBMS-specific implementation guidance.

---

## Recommended First Validation Test

1) Start TrueBench
2) Confirm help system runs:

```text
HELP
HELP db
HELP echo
```

3) Run a minimal DB connection test (your DBMS will vary):

```text
DB td ...
validate td
```

---

## Troubleshooting

### “requires Python module … but it is not installed”
Install the missing module into the venv.

Windows:
```bat
.venv\Scripts\pip.exe install <module>
```

Linux/macOS:
```bash
. .venv/bin/activate
pip install <module>
```

### “prompting is not allowed in non-interactive mode”
You are running in a mode where TrueBench cannot prompt (CI, redirected IO, etc.).

Fix:
- install modules manually via pip (above), then retry.

### VS Code hangs after switching OS
Delete and recreate `.venv` using the proper OS launcher.

---

## Next Steps

- Review the driver help topics:
  - `HELP drivers`
  - `HELP db`
  - `HELP <driver>`
- Explore DBMS setup examples under:
  - `setup/`
