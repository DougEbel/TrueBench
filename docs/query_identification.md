# Correlating Client-Side Workload Execution with Server-Side Database Telemetry  
## A Practical Pattern Supporting Quality Assurance and Performance Regression Analysis

**Author:** Doug Ebel  
**Date:** February 6, 2026  
**Context:** TrueBench  
**Publication Type:** Defensive Technical Disclosure

---

## Abstract

Understanding database performance behavior increasingly requires correlating client-side workload
execution with server-side database telemetry. In modern environments, application code, workload
drivers, database platforms, and infrastructure are often owned and evolved independently, making
such correlation difficult without intrusive instrumentation or vendor-specific features.

This paper describes a practical pattern used in workload-driven testing and analysis in which a
workload driver parses submitted SQL statements and transparently augments them with execution
identifiers. These identifiers allow standard DBMS query logging to be correlated with client-side
execution records and test metadata across repeated executions, without requiring changes to
application code or database management system (DBMS) internals.

---

## 1. Context and Motivation

Performance regressions in contemporary information systems are increasingly emergent rather than
attributable to a single, well-defined change. Workload behavior may shift due to factors such as:

- application code evolution
- open-source library updates
- changes in DBMS optimizer or runtime behavior
- infrastructure and platform updates
- AI-assisted code or query generation

While DBMS platforms commonly provide detailed query logging, those logs often lack reliable context
linking individual server-side executions to the originating client-side workload definition, test
instance, or parameter set. Conversely, workload drivers may record execution intent without direct
visibility into server-side behavior.

---

## 2. Common Approaches and Limitations

Existing correlation techniques are typically based on one or more of the following:

- application-level instrumentation or tracing identifiers
- DBMS-specific features such as query banding or session attributes
- custom logging embedded in workload drivers
- timestamp-based correlation heuristics

In practice, these approaches may be unsuitable in scenarios where application code cannot be
modified, DBMS-specific features are unavailable or undesirable, or workloads must remain portable
across heterogeneous platforms. Inserting statements to set query bands for subsequent queries
**doubles the impact of latency** on workoad measurements. This is especially concerning for
tests involving high volumne tactical queries.  

---

## 3. Problem Framing

In workload-driven testing and analysis, a recurring practical question arises:

> How can server-side database executions be associated with the originating client-side workload
> definition and execution context, without modifying application code or DBMS behavior?

A related concern is how such associations can be preserved across time to support regression
analysis between executions.

---

## 4. Descriptive Pattern Overview

The pattern described here operates entirely at the workload driver level and is based on the
following practices:

1. Identifying individual SQL statements within workload files queued for execution.
2. Assigning execution identifiers derived from workload structure and statement position.
3. Transparently augmenting submitted SQL statements with those identifiers in a semantically
   neutral manner.
4. Recording client-side execution metadata in a persistent store.
5. Using standard DBMS query logging to capture the identifiers for later correlation.

These practices are applied without requiring changes to application code, database schemas, or
DBMS internals.

---

## 5. Identifying SQL Statements Within Workload Files

In workload-driven testing, SQL statements are commonly stored in files that may contain multiple
statements. Prior to execution, the workload driver examines each file and identifies executable
SQL statements using a lightweight syntactic filter.

For example, statements may be recognized based on leading SQL verbs such as:

- SELECT, INSERT, UPDATE, DELETE, MERGE
- CREATE, DROP, ALTER, REPLACE
- WITH, CALL, EXEC, EXECUTE

This identification step allows the workload driver to treat each statement as a distinct workload
item for execution and measurement purposes.

---

## 6. Execution Identifier Construction and Augmentation

Once individual SQL statements are identified, the workload driver assigns execution identifiers
based on stable attributes such as:

- the workload file name
- the ordinal position of the statement within the file

For example, a statement identified as the first executable statement in a file named
`query021.sql` may be associated with an identifier such as:

`query021.001`

Prior to submission to the DBMS, the workload driver transparently augments the SQL statement by
inserting the identifier into a non-executing metadata location, such as a SQL comment, immediately
following the SQL verb. For example:

```
SELECT /* tdb=query021.001 */ invoice_dt, invoice_no, cust_no, product_id, ...
```

This augmentation preserves semantic equivalence while allowing the identifier to be captured by
standard DBMS query logging facilities.

---

## 7. Client-Side Execution Tracking

In addition to augmenting submitted SQL, the workload driver maintains local execution metadata
that records, for each workload execution:

- workload and test identifiers
- execution timestamps
- statement identifiers
- parameter sets used
- client-side execution metrics

This metadata is stored in a persistent local repository to support historical comparison and
regression analysis.

---

## 8. Host-Side Test Tracking and Telemetry Correlation

Where permitted, the workload driver may also maintain a simple test tracking table on the host
DBMS. This table records the start and stop timestamps for each workload execution.

By joining the host-side test tracking table with native DBMS query logs, it becomes possible to:

- select only those server-side executions that occurred within a given test window
- associate each execution with its embedded identifier
- retrieve detailed execution metrics for each statement within each test

This correlation is achieved using standard DBMS logging and query facilities.
Since comment strings are universally ignored by the DBMS, the only impact to the execution measurement is
less than 20 characters added to the SQL text being transmitted from the 
client running TrueBench to the host DBMS. 

---

## 9. Longitudinal Regression Analysis

Because execution identifiers are derived from stable workload definitions, they can be preserved
across repeated executions of the same workload.

This enables:

- comparison of identical statements across test runs
- identification of performance regressions or improvements
- isolation of changes to specific workload components
- analysis of behavior across different DBMS platforms or environments

The pattern supports serial as well as mixed workloads and does not depend on concurrent execution
to generate meaningful results.

---

## 10. Applicability Across Platforms

The practices described rely solely on workload-driver behavior and standard DBMS query logging.
They are therefore applicable across heterogeneous database platforms, including environments
where:

- application instrumentation is not feasible
- DBMS-specific tracing features are unavailable
- workloads are executed via scripts or batch processes

---

## 11. Representative Use Contexts

This pattern has been applied in contexts such as:

- workload-driven performance testing
- regression analysis following platform or version upgrades
- consulting and benchmarking engagements
- investigation of dynamically generated or AI-influenced workloads
- performance analysis in environments with limited system ownership

---

## 12. Summary

Correlating client-side workload execution with server-side database telemetry is an ongoing
practical challenge in modern information systems. The pattern described in this paper illustrates
how practitioners have addressed this challenge by combining lightweight SQL statement
identification, transparent query augmentation, and standard database logging facilities.

This document is published as a defensive technical disclosure to describe existing practices and
establish prior art.

---

## References

None.

