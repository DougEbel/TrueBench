# TrueBench

## Modern systems don’t fail—they drift.

Performance changes.  
Costs increase.  
Behavior shifts across components you don’t control.

Some changes are planned:
- database migrations  
- cloud platform changes  
- architectural decisions  

These happen infrequently—and are usually tested.

But most changes are not planned.

Your information system is the unique integration of components from multiple vendors:
- open-source libraries  
- cloud services  
- database releases  
- network layers  
- supporting services  

These evolve independently and continuously—often every week.

Each change is small. The accumulation is not.

The result is rarely immediate failure. It is often **drift**:

- slower response times  
- increasing capacity costs  
- inconsistent user experience  
- issues that surface too late  

Traditional monitoring tools focus on components:
CPU, memory, I/O, query metrics, service health.

They show whether parts of the system are operating.

They don’t show how the system behaves as a whole—
from the perspective of your users.

**TrueBench detects that drift**—  
using realistic workloads based on how your system is actually used.

---

## What TrueBench does

TrueBench validates **system behavior**, not just components.

It:
- Executes realistic workloads based on actual usage patterns  
- Preserves session behavior and query relationships  
- Runs repeatedly to detect changes over time  
- Captures results for comparison and analysis  
- Links test results to database query logs for root-cause insight  

This is not synthetic load testing.  
It is **repeatable validation of real system behavior**.

---

## Download

**Get started with TrueBench:**

→ [truebench_01-01-004.zip](https://github.com/DougEbel/TrueBench/releases/download/01_01_004/truebench_01_01_004.zip)

---

## How it works (in practice)

A TrueBench test suite:
- selects representative workload patterns  
- executes them as structured work units  
- runs under controlled conditions (serial and concurrent)  
- compares results over time  

This makes it possible to detect:
- subtle performance regressions  
- cost-impacting changes  
- behavioral drift across system components  

before they become user-visible issues.

---

## The key concept: sufficient scope

The objective is not to test everything.

It is to define **sufficient scope**:
- enough to reflect real system behavior  
- without creating unnecessary effort  

This is the difference between:
- impractical testing  
- and effective validation  

---

## Methodology

TrueBench is built around a structured methodology for validating system behavior.

Start with the overview:

→ [TBM-01_TrueBench_Methodology_Overview.pdf](https://dougebel.github.io/TrueBench/Methodology/TBM-01_TrueBench_Methodology_Overview.pdf)

Additional documents:

→ [https://dougebel.github.io/TrueBench/Methodology/index.md](https://dougebel.github.io/TrueBench/Methodology/index.md)

The methodology progresses from:
- understanding production workload behavior  
- selecting representative activity  
- converting that activity into executable tests  
- and analyzing results to detect drift over time  

---

## Learn more

### Video walkthrough

→ [TrueBench Playlist on YouTube](https://www.youtube.com/playlist?list=PLH_YijAOG5xHtI0ap7LHjmnxRCteRJtd1)

---

## Positioning

Benchmarks answer:

> “Will this change work?”

TrueBench answers:

> “Is the system still working as expected over time?”

---

## Summary

If your system depends on multiple components that change independently,  
you need a way to continuously validate how they behave together.

TrueBench provides that capability.

---