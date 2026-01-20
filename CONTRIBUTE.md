# CONTRIBUTE.md — Contributing to TrueBench (Python TdBench)

Thank you for your interest in contributing to **TrueBench (Python TdBench / QueryDriver)**.

TrueBench is intended to be a portable, practical workload driver for repeatable SQL and OS
benchmark execution across many DBMS platforms. Contributions are welcome in all areas:
documentation, DBMS setup guidance, new driver support, bug fixes, usability improvements, and
automation/reporting integrations.

This document explains how to contribute via GitHub.

---

## Ways to Contribute

You can help TrueBench in several ways:

### 1) Report Bugs
If something fails, hangs, produces confusing output, or behaves inconsistently across
platforms (Windows/Linux/macOS/WSL), please report it.

Best bug reports include:
- TrueBench version (zip name / tag / commit)
- OS and terminal environment (cmd.exe, PowerShell, Windows Terminal, VS Code terminal, WSL, etc.)
- Python version (in `.venv`)
- exact command(s) used (DB / SQL / RUN script lines)
- relevant log excerpts (sanitized)
- stack trace (if available)

### 2) Suggest Documentation Improvements
Documentation contributions are especially valuable because DB connectivity is often
environment-specific. Improvements may include:

- clearer INSTALL.md instructions
- driver-specific parameter examples
- ODBC driver setup guidance
- “known limitations” and common failure modes
- better help text formatting in CLI/TUI

### 3) Improve DBMS Setup Directories (`setup/<dbms>/`)
TrueBench includes DBMS-specific setup directories to support:

- host-side query log extraction
- correlation of DBMS query history to TrueBench `runid`
- DBMS configuration examples and best practices
- troubleshooting checklists

Contributions to `setup/<dbms>/README.md` are welcome even if you do not write code.

### 4) Add or Improve Drivers
Driver enhancements may include:
- new Python connector support for a DBMS
- improving error messages and diagnostics
- improving connection option support
- better “readiness checks” for missing modules or ODBC drivers

### 5) Provide New Example Scripts / Workloads
Workload definition files are useful to show best practices and help new users get started.
Examples may include:
- single-user baseline tests
- concurrency tests (queue/worker)
- parameter substitution examples
- BEFORE/AFTER automation examples

---

## GitHub Contribution Workflow

### Option A — Quick suggestion (no code)
Use:
- GitHub Issues → “New Issue”

Choose a clear title and include:
- what you expected
- what happened
- how to reproduce
- any proposed wording change (for docs)

### Option B — Contribute code or docs (recommended)
1) Fork the repository
2) Create a branch for your change
3) Make your changes (docs or code)
4) Submit a Pull Request (PR)

---

## Issue Types

When filing issues, consider one of these categories:

- **Bug** — incorrect behavior or crash
- **Documentation** — unclear docs or missing examples
- **Driver Support** — driver/module install issues or DBMS connectivity problems
- **Setup Scripts** — improvements to `setup/<dbms>`
- **Feature Request** — enhancement request (include use case and expected output)

---

## What to Include in DB Connectivity Issues

DB connectivity issues are often caused by environment configuration. If possible, include:

- driver key used (e.g., `teradata`, `odbc`, `pydbapi`)
- DB alias statement (sanitize passwords/tokens)
- OS, Python, terminal
- whether connection works outside TrueBench (vendor tool / python snippet)
- any DBMS error codes

For `odbc` driver issues:
- output of `LIST ODBC`
- ODBC driver name used in the `DB ... driver="..."` parameter

For `pydbapi` driver issues:
- Python module name (e.g., `psycopg2`, `pymysql`, etc.)
- whether module imports successfully inside the venv

---

## Coding Standards

TrueBench prioritizes:
- correctness and deterministic behavior
- maintainability and clear structure
- clear error messages (user actionable)
- portability across Windows/Linux/macOS/WSL

Guidelines:
- keep changes small and reviewable
- preserve backward compatibility where possible
- avoid adding heavy dependencies unless essential
- sanitize sensitive values in logs (passwords, tokens)

### Logging
- errors should be descriptive and include driver key and alias where relevant
- never log raw passwords or access tokens
- prefer actionable errors (“install module X”, “missing parameter Y”)

---

## Documentation Standards

Documentation is stored in:
- root markdown files (`INSTALL.md`, `CONTRIBUTE.md`, etc.)
- help files in the `help/` directory
- DBMS setup readmes in `setup/<dbms>/README.md`

Documentation should:
- prefer examples over long prose
- avoid DBMS marketing terminology
- be explicit about required vs optional parameters
- describe the “why” when it improves user understanding

---

## PR Review Notes

A strong PR includes:
- purpose and scope of the change
- before/after behavior
- test notes

If your change affects driver behavior:
- include an example DB alias
- include example execution with `VALIDATE <alias>`

---

## Security and Credentials

Never commit:
- passwords
- access tokens
- private hostnames or internal URLs
- customer data or query text

If you need to share a failure example, sanitize sensitive fields such as:
- `password=*****`
- `access_token=*****`

---

## Contributor License / Ownership

By submitting a PR, you agree that your contribution may be incorporated into the project and
distributed as part of TrueBench under the repository license.

---

## Thank You

TrueBench benefits directly from real-world usage and DBMS integration experience. If you use
it with a DBMS platform not listed in the standard distribution, contributions to the driver
documentation and setup directories are especially valuable.
