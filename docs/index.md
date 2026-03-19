# TrueBench

#### Performance Invariance in a World of Continuous Change

TrueBench is a lightweight framework for validating database workloads under continuous system change.

It allows teams to run **repeatable query and workload tests** and detect performance drift caused by application, infrastructure, or platform evolution.

---

## Quick Start — Download TrueBench

**Download the latest release:** - Runs with Python on Windows, Linux, and macOS 

➡ **[Download TrueBench](https://github.com/DougEbel/TrueBench/releases/download/01_01_004/truebench_01_01_004.zip)**

1. Download the `.zip` package  
2. Extract it to a directory  
3. Follow the setup instructions in `INSTALL.md`

No Git installation is required.

---

## Watch the Introduction (2 minutes)

If you want to understand the problem TrueBench solves, the first video in the following playlist describes that, 
and is followed by tutorials on using TrueBench's capabilities:

<a href="https://www.youtube.com/playlist?list=PLH_YijAOG5xHtI0ap7LHjmnxRCteRJtd1" target="_blank" rel="noopener">
TrueBench — A Structured Approach to System Validation (YouTube Playlist)
</a>

---

## The Problem TrueBench Addresses

Modern information systems no longer change in discrete, controlled releases.

They evolve continuously — driven by:

- AI-generated code and query patterns
- open-source library updates
- cloud platform evolution
- optimizer and runtime behavior shifts
- cross-team integration across teams that do not share ownership

Most changes are correct.  
Version-compatible.  
Well-intentioned.

Yet behavior still shifts.

Often subtly.  
Often without attribution.  
Often detected only after service levels degrade.

---

## When No One Owns the Change

In modern systems, no single team owns all change. Products are integrated from multiple vendors. 

- Applications evolve.
- Infrastructure shifts.
- AI accelerates iteration.
- Dependencies drift indirectly.

Performance degradation is rarely caused by a single decision.  
It is emergent behavior.

Traditional approaches struggle here:

- Monitoring shows symptoms, not causes.
- Functional testing validates correctness, not invariance.
- Benchmarks measure capacity, not stability under change.

---

## A Structured Validation Workflow

TrueBench introduces a disciplined, repeatable workflow for validating system behavior:

1. **Define database tests** using real queries and parameters  
2. **Model realistic workloads** that reflect production behavior  
3. **Execute repeatable validation runs**  
4. **Analyze execution history for root cause evidence**

This is not instrumentation.  
Not embedded agents.  
Not synthetic benchmarking.

TrueBench operates externally — observing the system as a black box and preserving historical evidence of its behavior.

---

## A Distinct Category

TrueBench is not an AI tool.

It is a validation discipline for systems whose behavior is shaped by AI, open source, and continuous integration.

More precisely:

**TrueBench provides regression observability for complex systems under continuous change.**

This is:

- not monitoring  
- not functional testing  
- not benchmarking  

It is structured system validation.

---

## What This Enables

With minimal setup, TrueBench allows teams to:

- Preserve historical execution baselines  
- Detect behavioral drift after any modification  
- Quantify performance change  
- Isolate affected queries  
- Correlate execution windows with platform telemetry  
- Explain why behavior shifted  

The goal is not prediction.

The goal is evidence.

---

## Documentation and Methodology

TrueBench is supported by a series of short technical papers that explain the validation methodology in more depth.

These documents describe how to:

- profile production workloads
- select representative queries
- prepare parameters and test data
- model realistic workloads
- execute repeatable validation tests
- analyze performance changes

📄 **TrueBench Methodology Series**

- TBM-01 — Methodology Overview  
- TBM-02 — Profiling Production Workloads  
- TBM-03 — Selecting Representative Queries  
- TBM-04 — Preparing Queries and Parameters  
- TBM-05 — Handling Writable Data  
- TBM-06 — Privacy and Data Protection  
- TBM-07 — Modeling Workloads  
- TBM-08 — Repeatable Test Design  
- TBM-09 — Analyzing Results  

➡ **View the documentation**

<a href="https://github.com/DougEbel/TrueBench/tree/main/docs" target="_blank" rel="noopener">
TrueBench Documents
</a>
---

### Details of the methodology (in order)

1. <a href="https://youtu.be/vPIqj_dh93o" target="_blank" rel="noopener">
   L3-1 — Define Database Tests — Simple Query & Parameter Design
   </a>

2. <a href="https://youtu.be/CYZpTOhWtAg" target="_blank" rel="noopener">
   L3-2 — Realistic Workloads — Modeling Query Mix for Accurate Results
   </a>

3. <a href="https://youtu.be/B841A7Rs7ZI" target="_blank" rel="noopener">
   L3-3 — Quick Install & Setup — Run Your First Test Fast
   </a>

4. <a href="https://youtu.be/3SI5NUFmLko" target="_blank" rel="noopener">
   L3-4 — Building Test Suites — Repeatable Validation Under Real Workloads
   </a>

5. <a href="https://youtu.be/teehUHxy40w" target="_blank" rel="noopener">
   L3-5 — Performance Analysis — From Query Logs to Root Cause Evidence
   </a>

---

### Full Playlist

<a href="https://www.youtube.com/playlist?list=PLH_YijAOG5xHtI0ap7LHjmnxRCteRJtd1" target="_blank" rel="noopener">
TrueBench — A Structured Approach to System Validation (YouTube Playlist)
</a>

Opening the playlist preserves the curated order and allows you to select the next video.


*Performance no longer fails loudly.  
TrueBench exists to make behavioral change observable.*