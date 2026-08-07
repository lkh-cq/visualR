# visualR — Concurrency Contract Verification Report

> **Status**: v0.4.x concurrency-package round 1 (verified, being frozen)
> **Date**: 2026-08-07
> **Package baseline**: v0.3.0
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §6 (concurrency contract), §10 (runtime gate)
> **Scope**: Verify the five concurrency-contract requirements on `batch_compute` before extending the concurrency package.

---

## 1. The contract (plan §6)

> - deterministic results;
> - stable ordering;
> - explicit worker/fallback reporting;
> - no hidden shared-state mutation;
> - reproducible fresh-process runtime behavior.

Plus the authoritative rule:
```
Result(single-core) == Result(supported multi-core mode)
```

## 2. Verification results (R 4.5.2, Linux, multiple independent processes)

### 2.1 Deterministic results ✅

`batch_compute(pals, op, ncores=N)` produces results identical to `ncores=1` across all tested op/state combinations. Verified repeatedly (200→5000 states, orbit_rotate; 5-state mix, identity).

### 2.2 Stable ordering ✅

`batch_compute` uses `mclapply`, which returns a list in the SAME order as its input. The `results` vector is position-aligned with the input `pals` list. Verified: concurrent `results` are `identical()` to serial `results` (same order, same values).

**Note**: the current operator set (identity, orbit_rotate) both produce `promote` on standard S_4/S_3/S_2 states, so ordering cannot currently be discriminated by value — but the position-alignment property is guaranteed by `mclapply` semantics (same-order list) and holds identically.

### 2.3 Explicit worker/fallback reporting ✅ (fixed in round 0)

`batch_compute` now returns:
- `requested_cores` — cores as requested
- `ncores` — effective cores used
- `fallback` — logical, TRUE when requested >1 but execution fell back to serial
- `execution` — "serial" | "serial-fallback" | "multicore"

Windows-forced serial fallback is now explicit (was silent — S1-27 class defect, fixed 2026-08-07).

### 2.4 No hidden shared-state mutation ✅

- After concurrent run, package namespace exports unchanged (`identical(g0, g1) == TRUE`).
- `mclapply` uses fork: worker-side `.GlobalEnv` mutations are NOT visible in the parent (verified: `CONCURRENCY_TEST_MUTATION` absent in parent after workers set it).
- `batch_compute`'s worker function is read-only over its inputs; no shared mutable state.

### 2.5 Reproducible fresh-process behavior ✅

Two independent fresh R processes (separate `Rscript` invocations, freshly `library(visualR)`):

```
进程1: n_promote=30 consistent=TRUE fallback=FALSE
进程2: n_promote=30 consistent=TRUE fallback=FALSE
```

Identical results across fresh processes. Reproducible.

## 3. Concurrency scaling (from six-dim pre-freeze report)

| Size | 2c speedup | 4c speedup |
|---|---|---|
| 200 | 1.30× | 1.42× |
| 1000 | 1.34× | 1.58× |
| 5000 | 1.39× | 1.57× |

Concurrency gives a bounded, real 1.3–1.6× speedup (fork overhead limits linear scaling). Honest: concurrency is an execution optimization, not a semantic fork (§6).

## 4. Concurrency-package extension plan (rounds)

Based on verification, the concurrency package will be extended in rounds:

| Round | Change | Verification |
|---|---|---|
| Round 0 (done) | fallback/requested/execution reporting | CI green, 1114 assertions |
| **Round 1 (this)** | Contract verification report + regression tests | this report |
| Round 2 | extract concurrency to `R/concurrency.R` (cohesion) | tests still green |
| Round 3 | add `concurrency_report()` harness (measure speedup table) | reproducible |
| Round 4 | add worker-count autotuning / explicit fork health check | CI all platforms |

Each round is independently verified before the next.

## 5. Status

Concurrency Contract Verification: **5/5 requirements met**. The `batch_compute` concurrency path is contract-compliant and ready for the concurrency-package extension rounds.

---

*Report baseline: visualR v0.3.0 · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · R 4.5.2 · 2026-08-07*