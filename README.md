# visualR

Palindrome-Addressed Topological Runtime — an R-first, CPU-native
runtime for the consciousness-bus mapping layer.

> Palindromic syntax stores topology; matrices materialize computation.

## Development baseline and current layer

The frozen development baseline is **visualR v0.5.0**:

**Palindrome storage -> Jiugong/operator state -> R/CPU concurrent compute -> closure/fold-back -> compact package storage and transport.**

See [`DEVELOPMENT_PLAN_v0.5.0.md`](DEVELOPMENT_PLAN_v0.5.0.md) for the authoritative development-plan baseline.

The current additive layer is **v0.6.1 `reference_experimental`**:
complete/open PAL windows plus a TCN-pattern dilated address compiler.
It does not alter the frozen v0.6.0 A–G reference functions.

## Root contract

- **PAL storage** stores the independent outer-to-inner chain and one
  singular center as palindrome grammar: `{A{B{C{D{e}D}C}B}A}`.
- **Matrices are equations, not pictures**: a working matrix is a 2D
  slice of a dimension expansion, storing computation-state information.
- **Mapping pack** is the authoritative basis for ALL
  storage-computation mappings (mapping-pack dependency injection,
  fail closed).
- **R interactive + concurrent computation is the BENCHMARK**; Python
  `mapping_pack.py` is glue/cross-validation only.
- **Open boundaries stay explicit**: `}{...}{` means an enclosing
  solution exists but is not listed. It is never interpreted as zero
  padding or admitted into the frozen token grammar.
- **Language roles stay separated**: R defines semantics, C99 may
  accelerate integer address schedules under exact equivalence tests,
  and Java remains an orchestration/service target.

## Three-layer architecture (藏归分离)

1. **Storage layer** — palindrome state (`new_pal_state`),
   serialization (`format_pal`/`parse_pal`, v0.2 length-prefixed,
   RCE-safe), validation (closed token domain).
2. **Grammar layer** — palindrome grammar interop
   (`pal_parse`/`pal_encode`), bijective with Python reference.
3. **Compute layer** — unfold/fold, jiugong mapping, closure fact /
   transition policy, emergence operators, Gamma generator, peel
   chain, 11x11 carrier, unified carrier dispatch
   (`materialize`).

## Address-window and dilated compile reference

```r
# Complete solution: deepen only with an explicit next core
p <- pal_parse("{A{B}A}")
pal_encode(deepen_solution(p, "c"))
#> "{A{B{c}B}A}"

# Open fixed-radius window: shift focus without fabricating outer content
w <- open_window_parse("}{B{C{D}C}B}{", origin = 10L)
w2 <- shift_open_window(w, "E")
open_window_encode(w2)
#> "}{C{D{E}D}C}{"

# Compile fixed taps + 2^level dilation + explicit residual/frontier edges
plan <- compile_dilated_topology(w2, levels = 3L, engine = "r")
validate_dilated_plan(plan)
```

The compiler migrates a structural pattern from
[`locuslab/TCN`](https://github.com/locuslab/TCN), not neural weights or
PyTorch semantics. See
[`inst/TOPOLOGY_DILATED_COMPILER_CONTRACT_v061.md`](inst/TOPOLOGY_DILATED_COMPILER_CONTRACT_v061.md).

## Interactive + concurrent entry points

```r
pal_pipe("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")  # storage->compute->fold-back
batch_compute(pals, "identity", ncores = 12)      # parallel bulk (R benchmark)
interact("{A{B{C{D{e}D}C}B}A}", "orbit_rotate")   # full loop -> compute result
```

## Status

- v0.1.1: RCE-hardened serialization, frozen symmetry operators
- v0.2.0: grammar layer, compute layer, Gamma, carrier, R
  interactive+concurrent layer
- **v0.2.1: Semantic Hardening** — mapping-pack DI (fail closed),
  unified carrier dispatch, closed token domain, closure fact /
  transition policy separation, compute result with trace;
  experimental markers on fitted carrier/Gamma rules
- **v0.3.0: B-Promotion** — 3 experimental markers promoted to
  FROZEN (carrier_11x11, Gamma lowercasing, closure recurse), backed
  by added coverage; version/metadata/lifecycle aligned
- **v0.4.0: Compactness + Deterministic Concurrency Proof** — frozen
  baseline with reproducible measurement infrastructure:
  `benchmark_storage()` (stored bytes), `concurrency_report()`
  (throughput), `concurrency_health()` (fork/effective-mode),
  `pal_compact()` (resident compact form). All 7 Efficiency-gate
  measurements published. Cross-language nested-logic contract
  (`inst/PAL_NESTED_CONTRACT.md`) reserved for future readers.
- **v0.5.0: Topology Operator ABI** — topology carrier, concurrent
  lanes, barrier/reconcile/commit, and equation-core stages.
- **v0.6.0: TCN-inspired engineering discipline** — frozen growth-law,
  shape ABI, carrier adapter, and derived emergence-stack references.
- **v0.6.1: Addressed window + dilated topology compiler** —
  `reference_experimental`; explicit frontier nodes and registered C99
  tap-schedule acceleration with R/C equality tests.

R package checks run on Linux, Windows, and macOS across release,
oldrel, and devel. Runtime semantics use base R + `parallel`; optional
storage/benchmark packages remain in `Suggests`, and v0.6.1 adds one
registered C99 address kernel.

## License

MIT

## 基准原型 (Benchmark Prototype, 2026-08-08)

Two one-command entry points prove the complete closed loop is usable
and reproducible — the reference baseline for all later work
(R remains semantic authority; C is an acceleration fabric; Java is the
orchestration/service target. Python `mapping_pack.py` is historical
cross-validation only):

```r
# 1. Full closed loop: PAL -> expand -> compute -> closure -> fold-back
#    -> package -> fresh-process reload (same canonical state)
demo_full_loop()

# 2. All 7 Efficiency-gate measurements in one call
benchmark_all()
```

Expected `demo_full_loop()` output ends with:

```
7. 重载复现: OK (同一canonical state)
```

Acceptance: full test suite green (302 tests / 1229 assertions), and
`demo_full_loop()` returns `reload_ok = TRUE`.
