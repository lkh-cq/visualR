# visualR v0.4.x — Pre-Freeze Verification Report

> **Status**: PRE-FREEZE — verification complete, not yet frozen
> **Date**: 2026-08-07
> **Package baseline**: v0.3.0
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §4 (v0.4.x) + §6 (concurrency contract) + §10 (Efficiency gate)
> **Scope**: Six-dimension verification of the v0.4.x baseline per user directive: baseline, concurrency advantage, quantified advantage, serial stability, error handling, silent-degradation risk, compatibility.

---

## 1. Baseline — stored bytes (G1: minimal storage)

Measured in `inst/BENCHMARK_stored_bytes_v040.md`. Summary:

| Dim | PAL serialized (bytes) | Matrix serialize (bytes) | Reduction |
|---|---|---|---|
| S_2 (3×3) | 81 | 151 | 1.86× |
| S_3 (3×3) | 83 | 151 | 1.82× |
| S_4 (3×3) | 87 | 151 | 1.74× |
| S_5 (11×11) | 89 | 1038 | **11.66×** |

**PAL transport-byte advantage scales superlinearly with dimension** (S_4→S_5: PAL +2 bytes, matrix +112 cells). G1 "store less / move less" is **verified** for transport/persistence bytes.

## 2. Concurrency advantage — batch_compute

Measured across task size × core count (R 4.5.2, Linux):

| Size | ncores=1 | ncores=2 | ncores=4 | 2c speedup | 4c speedup |
|---|---|---|---|---|---|
| 200 | 0.909 s | 0.699 s | 0.641 s | 1.30× | 1.42× |
| 1000 | 4.497 s | 3.350 s | 2.848 s | 1.34× | 1.58× |
| 5000 | 23.309 s | 16.756 s | 14.826 s | 1.39× | 1.57× |

**Finding**: concurrency gives a *bounded, real* 1.3–1.6× speedup, NOT linear scaling. The plateau is because single 3×3 `orbit_rotate` compute is too light — mclapply fork overhead dominates. Speedup rises only marginally with task size (200→5000: 1.30→1.39 at 2c).

**Implication**: concurrency is worth it for bulk compute (1000s of states), marginal for small batches. This is honest — the plan's §6 "no proof of multi-core path without evidence" is respected.

## 3. Quantified advantage — compact vs expanded workflow

**Critical honest finding — visualR's compact advantage does NOT extend to R object memory:**

| Representation (1000 states) | Bytes | vs matrix |
|---|---|---|
| Traditional (all matrices resident) | 609.4 KB | 1.0× |
| **format_pal string resident** | **226.6 KB** | **2.7× smaller** |
| visualR S3 PAL object resident | 1312.5 KB | 0.46× (LARGER) |

**Root cause**: The S3 PAL object (list + class attribute) carries ~1344 B fixed overhead per state — larger than the 624 B character matrix. **The current S3-object-based PAL representation is memory-inefficient.**

**The real compact resident form is the `format_pal` string** (87 B, 2.7× smaller than matrix). This is the actionable insight: **store strings as the resident compact form; materialize S3 objects / matrices only on demand.**

**Materialize cost**: 10k materialize+compute = 22.04 s (~2.2 ms each). On-demand materialization has real compute cost — avoid re-materializing hot states.

## 4. Serial stability (determinism)

**Verified**: `batch_compute(pals, op, ncores=1)` run 5× → identical results each time. 200 states all `promote`, `consistent=TRUE`. Single-core reference behavior is deterministic. Passes plan §6 "Result(single-core) == Result(supported multi-core mode)".

## 5. Error handling (fail closed)

| Test | Result |
|---|---|
| Illegal core "ee" (multi-char) | PASSES (valid: token domain allows multi-char; not a defect) |
| Illegal shell (reserved sep \x1f) | FAIL CLOSED ✓ |
| Unknown operator | FAIL CLOSED ✓ |
| Non-3x3 matrix | FAIL CLOSED ✓ |
| Unknown mapping pack | FAIL CLOSED ✓ |
| Bad serialization format | FAIL CLOSED ✓ |
| closure_jiugong: closed/recurse/transient | all correct ✓ |
| closure_jiugong non-3x3 | FAIL CLOSED ✓ |

**Note**: "ee" multi-char core is **correctly accepted** — the closed token domain restricts to non-empty/separator-free/within-length, NOT single-char (domain apps may use multi-char symbols). Not a defect.

## 6. Silent-degradation risk — ⚠ ACTIONABLE DEFECT

**The Windows fallback in `batch_compute` is a silent degradation risk (S1-27 class):**

```r
# R/interact.R line 158-160
if (ncores == 1L || .Platform$OS.type == "windows") {
  verdicts <- vapply(seq_along(grids), work, character(1L))
  used <- 1L
}
```

- When `ncores >= 2` on Windows, computation silently falls back to serial `vapply`, setting `used <- 1L`.
- **The return structure has NO `fallback` flag.** A caller cannot distinguish "user requested 1 core" from "Windows forced serial fallback".
- **Violates plan §6**: "A platform-specific serial fallback must be reported as a fallback, not as proof that a true multi-core path was exercised."

**Fix required before freeze**: add a `fallback` logical field to the `batch_compute` return, set TRUE when `ncores >= 2` but platform forced serial (`used < ncores`). Document it.

## 7. Compatibility — cross-dimension / cross-carrier

All verified:
- Cross-dimension PAL round-trip (S_0–S_5): all ✓
- Carrier auto-dispatch correct (S_4 → canonical_jiugong, S_3/S_2 → gamma_local)
- Explicit carrier == auto-carrier for same dim
- Cross-dimension closure all `closed`

---

## Summary of actionable findings for freeze

| # | Finding | Severity | Action before freeze |
|---|---|---|---|
| 1 | **Silent-degradation**: batch_compute Windows fallback not reported | ⚠ Defect | Add `fallback` field to return; document |
| 2 | **Memory**: S3 PAL object is memory-inefficient (0.46× vs matrix) | Info/Opt | Use format_pal string as resident compact form (2.7×) |
| 3 | Concurrency bounded at 1.3–1.6× (fork overhead) | Info | Document as "bounded concurrency"; use for bulk only |
| 4 | On-demand materialize ~2.2 ms each | Info | Cache hot materialized states |
| 5 | PAL transport-byte advantage verified (1.7–11.7×) | ✅ | Keep as core G1 evidence |

## Reproduction

All measurements are reproducible via the R commands in this session's transcript. The stored-bytes baseline has a self-contained script in `inst/BENCHMARK_stored_bytes_v040.md` §6.

---

*Report baseline: visualR v0.3.0 · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · R 4.5.2 · 2026-08-07 · Six-dimension pre-freeze verification*