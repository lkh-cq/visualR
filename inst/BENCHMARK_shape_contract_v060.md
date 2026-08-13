# BENCHMARK — A-G reference additive per-op cost v0.6.0

> Status: FROZEN (B-promotion 2026-08-13)
> Companion to: IMPLEMENTATION_PLAN_v0.6.0.md,
>   inst/CROSS_LANG_SHAPE_CONTRACT_v060.md
> Method: R 4.5.2, system.time elapsed, per-op mean over n iterations,
>   fresh pkgload::load_all session.

---

## 1. Per-op cost (reproducible)

```text
operation                              n        ms/op
--------------------------------------------------------------
growth_law(dilation, depth=3)          20000    <0.001
growth_sequence(dilation, depth=8)      5000     0.002
check_shape_preserving(3x3, 3x3)       20000    <0.001
block_contract(identity)               20000    <0.001
carrier_adapter 3x3 -> 3x3 (identity)  20000    <0.001
carrier_adapter 3x3 -> 4x4 (pad)       20000     0.002
carrier_adapter 4x4 -> 3x3 (crop)      20000    <0.001
emerge_stack(3,3,3)                     5000     0.003
emerge_stack(3,4,4,11)                  2000     0.008
```

## 2. Storage sanity

```text
3x3 -> 4x4 pad:  9 -> 16 cells (+7, one zero row + one zero col)
4x4 -> 3x3 crop: 16 -> 9 cells (-7, last row + last col removed)
identity:        0 cell delta (pass-through, no copy semantics)
```

## 3. Conclusion (honest)

```text
A-G are discipline-layer primitives (table lookups, shape checks,
adapter rules), not compute kernels. Their per-op cost is
sub-microsecond to ~8 microseconds -- 2-3 orders of magnitude below
the current compute hotspot (compute_jiugong 621 us, v0.4.0 D1).

No optimization claim is made here; per DEVELOPMENT_PLAN discipline,
no optimization is accepted without measurement, and this measurement
shows there is nothing to optimize in this layer.
```

## 4. Reproduction

```text
pkgload::load_all("/mnt/d/visualR/visualR")
run the benchmark loop above with n as listed;
results are expected stable within one order of magnitude on any
contemporary x86_64 CPU (they are dominated by R interpreter call
overhead, not by the functions' own work).
```

## 5. Freeze-decision input

This benchmark is one of the two prerequisites for a future
B-promotion of A-G from reference_additive to FROZEN (the other
prerequisite, testthat coverage, was added 2026-08-13: 4 files,
28 assertions, suite total 449 / 0 failures). The promotion decision
itself is NOT made by this document.
