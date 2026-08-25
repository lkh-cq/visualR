# visualR CPU Evidence Contract v0.6.2

> Status: `reference_experimental`
>
> Scope: M2 numerical and native-boundary measurements
>
> Semantic authority: R

## Purpose

The project optimizes only after semantics, equivalence, workload, and
measurement are explicit. This contract prevents a fast result on one runner
from becoming a hidden semantic promise.

## Evidence outputs

`benchmark_numeric_observers()` emits one row per field size and operation:

- deterministic numeric-field construction;
- lossless polar metadata;
- unitary spectral execution and inversion;
- address-aware gradient;
- bias evidence extraction;
- deterministic signal scheduling.

Each row records field cells, repetitions, batches, median elapsed
milliseconds, static result-object bytes, semantic authority, and lifecycle
status. `object.size()` is not peak RSS; timing is not a cross-machine SLA.

`benchmark_tap_compiler()` emits R and C99 rows for bounded odd widths. Before
timing C99 it compares the complete native schedule matrix, including column
names, with R. A mismatch stops the run. The measurement excludes graph
materialization so it isolates the only native hotspot currently authorized.

## CI artifact

The Linux/R-release job runs `.github/scripts/ci-v062-benchmark.R` after
package installation and writes:

```text
benchmark-evidence/numeric-observers.csv
benchmark-evidence/tap-compiler.csv
benchmark-evidence/report.md
```

GitHub Actions uploads the directory as `v062-cpu-evidence`. The report records
R/platform identity and session information. Other CI jobs still execute the
full package checks, so Windows/macOS compatibility is not inferred from the
Linux timing artifact.

## Optimization gate

A new native dependency or native code surface is admissible only when all are
present:

1. representative workload and reproducible benchmark;
2. profiler or allocation evidence identifying the hotspot;
3. exact R/native equivalence tests, including failures and boundaries;
4. Linux, Windows, and macOS package checks;
5. measured benefit large enough to justify build and maintenance cost;
6. separate lifecycle review with R still authoritative.

Therefore FFTW, GPU/CUDA, general C rewrites, and fork-only algorithms are not
part of v0.6.2.
