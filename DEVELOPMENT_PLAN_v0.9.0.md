# visualR Development Plan v0.9.0 — Mainline Convergence

> Status: **DRAFT for review** | Author: Hermes (geometry line) + numeric-spectral-bias plan (W1 lineage)
> Date: 2026-08-25
> Predecessors: DEVELOPMENT_PLAN_v0.7.0.md (numeric-spectral-bias branch),
> GEOMETRY_TRANSPORT_CONTRACT_v080.md (geometry-transport-v0.8 branch),
> ROUTER_CONTRACT_v070.md (frozen)

---

## 0. Why converge now

Three parallel lines exist in the repository, all additive over the same
frozen v0.6.x base:

| Line | Branch | Adds | Frozen-semantics touched? |
|------|--------|------|---------------------------|
| Router/Emergence loop | agent/router-core-v0.7 (= local mainline of 5639f3b) | Central Router, EmergencePacket, AdjacencyPair gate, Harmony ABI, promotion-gate suite | No (contract-first) |
| Numeric/spectral evidence | agent/numeric-spectral-bias (v0.6.2, c0e97fd) | numeric_field, signal_envelope, polar_chart, spectral_plan, field_gradient, bias_audit + M0-M4 milestones | No (additive; PAL_NESTED_CONTRACT gains §6.1 attribute discipline only) |
| Geometric transmission | agent/geometry-transport-v0.8 (1783f97) | PositionState, TransmissionPath, Metric/Transport registries, geometric adjacency, arbitration-only router, R CMD check OK | No (v0.7 untouched; report migration steps 1-7 done) |

All three lines are individually green. The cost of NOT converging is now
higher than the merge risk: three NAMESPACEs, three DESCRIPTIONs, and two
competing "adjacency" concepts (router-proposed vs geometric predicate)
that must be reconciled before any further feature work.

## 1. Convergence order (dependency-driven)

```text
Step A  merge agent/router-core-v0.7 -> main          (v0.7.0 release base)
Step B  rebase/merge geometry-transport-v0.8 onto A   (v0.8 layer lands on v0.7 loop)
Step C  rebase/merge numeric-spectral-bias onto B     (v0.6.2 evidence layer)
Step D  semantic reconciliation pass                   (the real work, §3)
Step E  version unification: 0.9.0000 dev numbering
```

Rationale: geometry depends on the v0.7 loop types (AdjacencyPair,
harmony_step); numeric/spectral depends on neither but shares
NAMESPACE/DESCRIPTION seams with both. A before B before C minimizes
conflict surface to metadata files only.

Conflict forecast (from diff inspection):
- DESCRIPTION: Version/Date/Description — trivial, resolved by hand.
- NAMESPACE: pure additions on all three branches — concatenation.
- inst/PAL_NESTED_CONTRACT.md: numeric adds §6.1; no other line touches it.
- R/visualR-package.R: doc-comment only on numeric; none elsewhere.

### 1.1 Merge-time known hazards (pre-flight audit 2026-08-25, 12 dimensions)

Verified by direct branch diffs before any merge executes:

1. **Version drift across lines.** main=0.6.1 / router-core-v0.7=**0.6.0
   (never bumped through all 8 commits)** / numeric-spectral-bias=0.6.2 /
   geometry-transport-v0.8=0.7.9001. At Step A the DESCRIPTION version MUST
   be hand-set to 0.7.0; never trust the router branch's own value.
2. **Two unrelated "v0.7 plan" documents.** numeric carries
   DEVELOPMENT_PLAN_v0.7.0.md (numeric M0-M4 milestones); the router line
   carries IMPLEMENTATION_PLAN_v0.7.0.md (router phases). Both must be kept,
   each with a header note pointing to the other, or future archaeology will
   misattribute them (S1-21 same-family risk).
3. **CHANGELOG: all three lines edit the head.** Entries must be re-ordered
   by timeline across three lineages at merge time; take-one-side is wrong.

Non-conflicts verified (safe to merge mechanically):
- NAMESPACE export clash: ZERO — numeric adds 15 exports, router line 41,
  geometry line 21; pairwise intersections of the add-sets are empty.
- Reverse dependency: numeric's four core modules reference zero v0.7
  functions (route_emergence/harmony_step/materialize_adjacency/new_merge/
  AdjacencyPair all count = 0), so Step C is safe after B.
- Test helpers: numeric appends to helper-pal.R; geometry adds its own
  helper-geometry.R — different files.
- CI workflow: numeric appends two CPU-evidence steps; router line does not
  touch .github/.
- src/ C code: untouched by all three lines.


## 2. What each line contributes to the converged mainline

```text
PAL compact state (v0.5 frozen)
  -> addressed window / dilated topology compiler (v0.6.1, already main)
  -> numeric field + polar/FFT observation views (v0.6.2 evidence layer)
  -> geometric transmission: PositionState + Path + Metric/Transport (v0.8)
  -> adjacency by geometric predicate; Router = arbitration plugin only
  -> Harmony ABI creates fresh merges (v0.7, unchanged)
  -> bias/evidence review gates (v0.6.2), probability still BLOCKED
```

## 3. Semantic reconciliation decisions required at Step D

These are the two-line collisions that must be DECIDED, not merged around:

D1. **Two adjacency producers.** v0.7 `materialize_adjacency()` derives
pairs from Router plans; v0.8 `detect_adjacency()` derives pairs from a
geometric predicate over positions.
Resolution direction: geometric predicate becomes the ONLY source of
computation eligibility ("no adjacency, no computation" now means "no
GEOMETRIC adjacency"); `materialize_adjacency()` survives one release as a
deprecated adapter whose Router plans are filtered through the predicate.
Retirement completes in v0.10.

D2. **Round orchestration.** v0.7 `run_emergence_round()`
(Router->Plan->Adjacency->Harmony) vs v0.8 `run_transmission_round()`
(Snapshot->Transmission->Adjacency->Harmony->Commit).
Resolution direction: v0.8 runtime becomes canonical for new work;
v0.7 round stays exported and tested through v0.9 deprecation window,
marked deprecated in Rd, removed in v0.10 after benchmark equivalence
evidence (same inputs => same Harmony events where predicates agree).

D3. **Position semantics for surviving merges.** v0.7
`.prepare_next_state()` round-robins survivors across space; v0.8 keeps
survivor position+path untouched (report: "position is state").
Resolution: v0.8 behavior is normative from v0.9. Round-robin is retired
with the v0.7 runtime path (D2). This is the deep-research-report's
central demand and the reason convergence cannot wait.

D4. **Address vs coordinate.** numeric_field binds values to addresses;
PositionState carries address+coordinate+chart. Reconciliation: address
remains THE identity (I1 unchanged); coordinate/chart are PositionState
attributes for geometry only, never parsed from PAL text (numeric §6.1
attribute discipline applies verbatim).

D5. **Evidence vocabulary.** bias_audit produces robust deviation scores;
geometry produces transmission signatures. Both are audit signals, not
probabilities (I5). W7 supervised-probability remains BLOCKED unchanged.

## 4. Verification matrix additions for convergence

| Gate | Requirement |
|------|-------------|
| Cross-line regression | full testthat green on Linux/Windows/macOS after each merge step |
| R CMD check | Status: OK locally per step (S1-29 rule), CI as second gate |
| Predicate-filtered legacy | every Router-plan pair must pass geometric predicate in adapter mode, else fail closed |
| Determinism | serial == repeated runs on converged runtime |
| Promotion separation | no lifecycle promotion rides the implementation PRs |

## 5. Non-goals for v0.9

- Chart transition maps / coordinate-invariance experiment (deferred gate
  in GEOMETRY_TRANSPORT_CONTRACT_v080 §6).
- Holonomy experiments with non-identity edge transports (roadmap month 2).
- Supervised probability (W7 prerequisites still absent).
- Reservoir runtime wholesale merge (still rejected).

## 6. Definition of done for v0.9.0

- Steps A-C merged; conflict surface limited to §1 forecast; zero frozen
  file semantic changes outside PAL_NESTED_CONTRACT §6.1 addition.
- D1/D2/D3 implemented as deprecation adapters with tests; D4/D5 recorded
  as contract notes in both contracts.
- Single VERSION = 0.9.0, single NAMESPACE, cross-platform checks green.
- CHANGELOG documents all three lineages honestly, including what was
  rejected and why.
