# visualR Changelog

Version log for the visualR package. Format: `Keep a Changelog`-style,
most recent first. Statuses: `[Added]`, `[Changed]`, `[Fixed]`,
`[Known]`, `[Planned]`.

---

## [v0.5.0] — 2026-08-09 (Topology Operator ABI + equation-core stage 1-2)

Per DEVELOPMENT_PLAN_v0.5.0.md: high-dimensional operator concurrency
(Topology Operator ABI v0.1) replaced the serial-primitive C plan.
**421 tests / 0 failures, R CMD check OK, CI 5/5 platforms.**

### [Added] — Topology Operator ABI v0.1 (R implementation)
- `R/topology_carrier.R` — full pipeline: PAL -> TopologyCarrier ->
  Snapshot -> Concurrent Lanes -> Barrier -> Reconcile -> Commit ->
  PAL re-encoding (cell_to_pal). TopologyCell holds singularity + N
  orbits (dynamic labels A..Z, O##), 3x3 is a projection not the
  object.
- `R/orbit_operators.R` — 5 lane kernels: identity / complement
  (C^2=I) / mirror / rotate / gamma. Register/get/list, fail-closed,
  .onLoad idempotent registration.
- `R/lane_concurrency.R` — `execute_lanes_parallel()` /
  `run_topology_pipeline_parallel()`: serial/PSOCK/multicore engines,
  semantic-equivalence contract (differences are performance only).
- `R/recurse.R` — recursive re-type four families (simple / complex /
  interactive / nested), atomic sha256 token design.
- `R/state_store.R` — SQLite versioned StateStore + event log
  (optional RSQLite/DBI, fail-closed).

### [Added] — equation-core stage 1-2
- `R/equation_core.R` — `dimension_series()` (separate candidate
  L_s/W_d/Q_d, candidate_not_frozen), `gradient_lattice()`
  (parity-aware), `gradient_residual()`, `audit_dimension_sample()`.
- `R/gradient_emerge.R` — gradient expansion as layered batches
  (multi-batch, not matrix filling): gradient_layers / emerge_weight /
  emerge_by_layers / project_gradient_window /
  verify_gradient_emergence.
- `R/sample_analysis.R` — 3x3/4x4 registered as EVIDENCE:
  detect_symmetries / orbit_partition / center_analysis / label_reuse /
  audit_sample_topology. Reproduces 4x4 = 6 orbits / 5 labels with
  label C reused; geometric center != semantic center.
- `inst/EQUATION_CORE_STAGE1.md`, `inst/EQUATION_CORE_STAGE2.md`.

### [Changed]
- Branch-1: dynamic orbit labels across S_1..S_5+ (was hardcoded A-D);
  lane/barrier/reconcile/topology_map fully dynamic.
- Baseline: R = operator language; C/Java = execution fabric.

---

## [v0.4.0] — released (2026-08-07)

v0.4.0 proves compactness + CPU deterministic concurrency + transport
efficiency (per DEVELOPMENT_PLAN_v0.5.0.md §4). Package version 0.4.0.
**Frozen baseline.**

### [Added] — measurement infrastructure
- `benchmark_storage()` — reproducible stored/transport-bytes harness
  (PAL vs materialized matrix across S_1..S_5). Exported.
- `concurrency_report()` — reproducible concurrent-throughput harness
  (speedup table across task sizes × core counts). Exported.
- `inst/BENCHMARK_stored_bytes_v040.md` — stored-bytes baseline report.
- `inst/BENCHMARK_prefreeze_verification_v040.md` — six-dimension
  pre-freeze verification (baseline / concurrency / quantified /
  serial stability / error handling / silent-degradation / compatibility).
- `inst/BENCHMARK_concurrency_contract_v040.md` — concurrency contract
  verification (5/5 requirements met).
- `inst/CROSS_LANG_NESTED_HAZARD_v040.md` — cross-language nested-logic
  hazard & feasibility assessment (semantic-alignment reserve).

### [Changed] — concurrency reporting
- `batch_compute()` return now includes `requested_cores`, `fallback`,
  `execution` fields. Windows-forced serial fallback is explicit
  (was silent — S1-27 class defect).

### [Fixed]
- Python reference `mapping_pack.py` multi-character symmetry bug:
  `{AB{C}AB}` now parses correctly (was raising a spurious error).
  Aligned with the R authority. 69/69 Python tests pass.

### [Known] — active issues
- **S3 PAL object memory is NOT smaller than the matrix** (0.46×), due
  to list+S3 class overhead. The truly compact resident form is the
  `format_pal` string (~2.7× smaller). Open branch: A.
- **Concurrency speedup is bounded at 1.3–1.6×** (fork overhead limits
  linear scaling). Honest, quantified. Open branch: B.
- **Cross-language nesting hazards** (C/C++ UTF-8 byte indexing, Java
  UTF-16 surrogates) documented but not yet encoded as a portable
  contract file. Open branch: C.
- **ubuntu CI occasionally stalls** in `setup-r-dependencies`
  (environmental, not code).

### [Planned] — open branches
- **A1** ✅ DONE (2026-08-07): `pal_compact()` added — format_pal
  semantic alias as the recommended resident compact form. Resolves
  the S3-object memory disadvantage (2.7x smaller than matrix). 1133
  assertions, 0 fail.
- **C1** ✅ DONE (2026-08-07): `inst/PAL_NESTED_CONTRACT.md` — frozen
  language-independent nested-logic contract (grammar / parse / encode
  / multi-char rule / UTF-8 hazards / test vectors, verified against R
  authority). Semantic-alignment reserve for future Java/C++ readers.
- **B** ✅ DONE (2026-08-08): `concurrency_health()` fork/effective-mode
  report (plan §6) + **PSOCK engine** (`engine` param on batch_compute)
  for true Windows parallelism. PSOCK measured 1.6-3.85× speedup on
  PAL tasks (beats mclapply 0.85-2.07×). `execution` reports actual
  path, `engine` reports requested (never silent). `on.exit(stopCluster)`
  guards leak; R CMD check clean.
- **D1** ✅ DONE (2026-08-07):
  `inst/BENCHMARK_efficiency_gate_v040.md` — all 7 Efficiency-gate
  measurements complete (working-set / peak RAM 2.7× / transfer / encode
  fold ~214-256µs / serial latency 621µs). compute_jiugong 621µs is the
  hotspot candidate (native acceleration deferred, plan §5).

---

## [v0.3.0] — 2026-08-07 (semantic + lifecycle stabilization)

Per DEVELOPMENT_PLAN_v0.5.0.md §3: establish a trustworthy R package
baseline before performance work. **1093 assertions, 0 fail**, CI green
on 5 platforms.

### [Changed]
- 3 experimental markers promoted to FROZEN: `carrier_11x11`,
  `gamma_lowercasing`, `closure_recurse`.
- README + DESCRIPTION synchronized to v0.3.0 (test count 783 → 1093,
  source-derived).

### [Added]
- Frozen v0.5.0 development plan (`DEVELOPMENT_PLAN_v0.5.0.md`).

---

## [v0.2.x] — 2026-08-06 (semantic hardening)

### [Added]
- Mapping-pack DI (fail closed), unified carrier dispatch, closed token
  domain, closure fact / transition policy separation, compute result
  with trace.
- Serialization v0.2 (length-prefixed records, RCE-hardened — removed
  `eval(parse())`).

### [Fixed]
- RCE vulnerability in serialization (v0.1.0 → v0.2).

---

## [v0.1.x] — 2026-08-06 (initial layers)

### [Added]
- Layer 1 palindrome storage (`new_pal_state`, `format_pal`,
  `parse_pal`, `validate_pal`).
- Layer 2 matrix computation emergence (`unfold_pal`, `fold_pal`,
  `pal_to_jiugong`, `jiugong_to_pal`, `complement_pal`,
  `mirror_addr`, `locate`).
- Layer 3 projection view (`diamond_field`).
- Python cross-validation reference (`mapping_pack.py`).

---

*Changelog maintained alongside DEVELOPMENT_PLAN_v0.5.0.md. The plan is
the authoritative roadmap; this log records what changed.*