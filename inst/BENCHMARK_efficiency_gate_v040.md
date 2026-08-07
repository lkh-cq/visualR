# visualR — Efficiency Gate Remaining Measurements (D1)

> **Status**: v0.4.x D1 — complete
> **Date**: 2026-08-07
> **Package baseline**: v0.3.0
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §10 (Efficiency gate)
> **Scope**: Complete the remaining five Efficiency-gate measurements.
>   Stored bytes (benchmark_storage) and concurrent throughput
>   (concurrency_report) were already measured; this report covers
>   working-set, peak RAM, transfer, encoding/fold overhead, serial
>   latency.

---

## 1. Efficiency gate completeness map

| Measurement | Method | Status |
|---|---|---|
| compact stored size | `benchmark_storage()` | ✅ (earlier) |
| concurrent throughput | `concurrency_report()` | ✅ (earlier) |
| expanded working-set size | this report | ✅ |
| peak RAM | this report | ✅ |
| transfer size | this report | ✅ |
| encoding/fold overhead | this report | ✅ |
| serial execution latency | this report | ✅ |

**All seven Efficiency-gate measurements are now complete.**

## 2. Results (R 4.5.2, Linux)

### 2.1 Expanded working-set size (single S_4 state)

| Representation | Bytes |
|---|---|
| PAL compact string (`pal_compact`) | 87 B |
| Materialized 3x3 matrix | 624 B |
| S3 pal object | 1344 B |

Working-set ordering: compact string < matrix < S3 object. The S3 object
is the largest (list + class overhead); the compact string is smallest.

### 2.2 Peak RAM (1000 S_4 states)

| Workflow | Peak | vs full-materialize |
|---|---|---|
| Full materialize (all matrices resident) | 609.4 KB | 1.0× |
| Compact (all `pal_compact` strings resident) | 226.6 KB | **2.7× smaller** |

The compact resident workflow saves 2.7× peak RAM — consistent with the
A1 finding. This is the actionable memory optimization.

### 2.3 Transfer size (S_4 state, gzip)

| Form | Raw bytes | gzip bytes |
|---|---|---|
| Matrix serialize | 151 B | 82 B |
| PAL compact string | 87 B | 90 B |

Raw: PAL string (87 B) beats serialized matrix (151 B) by 1.7×.
gzip: matrix compresses to 82 B, PAL to 90 B — gzip nearly equalizes
them (PAL is already near-compact). For uncompressed transport, PAL wins
1.7×; for gzip transport, ~parity.

### 2.4 Encoding/fold overhead (10k operations)

| Operation | Total | Per-op |
|---|---|---|
| `pal_encode` | 2.140 s | 214 µs |
| `pal_parse` | 2.557 s | 256 µs |

Encoding is ~214-256 µs per op. Parse is slightly slower than encode
(recursive-descent + symmetry check).

### 2.5 Serial execution latency (10k operations)

| Operation | Total | Per-op |
|---|---|---|
| `compute_jiugong` (orbit_rotate, 3x3) | 6.210 s | 621 µs |

Serial compute latency is ~621 µs per 3x3 operator application. This is
the dominant single-op cost (string-matrix operations in R).

## 3. Interpretation

- **Memory**: compact resident form (A1) is the clear win — 2.7× peak-RAM
  savings. This is the recommended production pattern.
- **Transfer**: PAL wins uncompressed (1.7×); gzip parity. PAL's value is
  "no compression needed to be compact."
- **Latency**: `compute_jiugong` at 621 µs is the single largest per-op
  cost. Per plan §5, native acceleration is ALLOWED only after profiling
  identifies this as a real hotspot — this measurement is that evidence,
  but acceleration is deferred (not on v0.5.0 critical path unless it
  blocks the loop).

## 4. Reproduction

All values are reproducible via the R commands in this session's
transcript (system.time microbenchmarks, object.size, memCompress).

---

*Report baseline: visualR v0.3.0 · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · R 4.5.2 · 2026-08-07 · D1 complete — all 7 Efficiency-gate measurements done*