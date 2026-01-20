About the Author

Doug Ebel has worked in data warehousing and analytical database performance engineering since the 1970s. He built early production data warehouses in the 1970s and 1980s, designed enterprise-scale warehouse architectures for global organizations, and spent decades working directly with customers on benchmark design, workload modeling, and system evaluation.

The original TdBench was created during a period when Doug was working full time on benchmarking engagements and repeatedly observed the same problems:

- inconsistent execution of tests,
- analysts spending excessive time searching through logs to determine what had changed between test runs, and
- additional effort later required to extract and reconstruct data for analysis.

The first implementation was developed on Windows to bring consistency and structure to benchmark execution and result capture. After seeing the tool in use, a DBA at a large corporation asked to use it internally to evaluate DBMS parameter and physical design changes. He later encouraged Doug to make TdBench publicly available and to present it at his organization’s annual user group conference.

Over the past 15+ years, Doug has led workload analysis and benchmark engagements at well over 100 large enterprises worldwide. During that time, TdBench evolved from:

- a single-user Windows-based tool,
- to a Linux and Bash-based implementation supporting team-based execution on shared systems,
- and later to a Java-based version supporting multiple database platforms.

TrueBench is the next evolution of that work. It is a TdBench-compatible workload benchmarking framework implemented in Python, which simplifies installation and lowers the barrier to entry compared to the prior Java-based versions. TrueBench introduces additional usability improvements, including a full-screen interface for designing tests, managing parameters, and browsing documentation, while retaining script-driven automation for large and repeatable test suites.

Earlier TdBench releases were downloaded more than 4,000 times. Doug has delivered multi-week seminars in the United States, India, and the Asia-Pacific region on benchmarking methodology and the use of TdBench to support technology decisions.

A recurring theme in these engagements is that many benchmarks fail to reflect real production workloads. As a result, test outcomes often fail to support multi-million-dollar technology decisions, or benchmarking efforts expand uncontrollably in scope, cost, and duration.

The core of Doug’s approach is careful analysis of existing workloads and disciplined modeling of those workloads using tools such as TrueBench. TrueBench is designed to automatically capture test definitions, execution results, and inputs; organize supporting collateral; and coordinate analysis with host DBMS query logging and resource usage data. This enables repeatable, explainable, and defensible performance evaluations.

Doug is available for short-term advisory and hands-on consulting engagements related to workload modeling, benchmark design, performance regression analysis, and platform evaluation.