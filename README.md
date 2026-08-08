# visualR

Palindrome-Addressed Topological Runtime — an R-first, CPU-native
runtime for the consciousness-bus mapping layer.

> Palindromic syntax stores topology; matrices materialize computation.

## Development target

The frozen development target is **visualR v0.5.0**:

**Palindrome storage -> Jiugong/operator state -> R/CPU concurrent compute -> closure/fold-back -> compact package storage and transport.**

See [`DEVELOPMENT_PLAN_v0.5.0.md`](DEVELOPMENT_PLAN_v0.5.0.md) for the authoritative development-plan baseline.

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

1137 test expectations, `R CMD check` clean (0 errors / 0 warnings /
0 notes). Pure base R + `parallel`; zero external dependencies.

## License

MIT
