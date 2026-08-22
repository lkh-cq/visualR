# visualR Implementation Plan v0.7.0 — Central Router & Emergence Computation Loop

> Status: **Architecture Exploration / Research Mainline**
> Semantic authority: **R**  |  Execution: **CPU-native**
> Baseline: main @8e33146 (v0.6.0 frozen, B-promotion)  |  Branch: agent/router-core-v0.7
> Core mission: define the Central Router, NOT migrate any deep-learning architecture.

---

## 0. Definition of computation (one-line thesis)

visualR v0.7 establishes an independent **Topological Emergent Computation** paradigm whose minimal
computation cycle is `M_i -> P_i -> R -> A_{t+1} -> H(M_i, M_j) -> M_ij'`.

A real computation is NOT `Y = F(X)` (matrix multiply / controller-applies-function). It is:

```
[M_i ~ M_j] => H(M_i, M_j) -> M_ij'
```

Two merges that ALREADY established spatial adjacency undergo Resonance/Harmony and produce a new
merge. `M_i !~ M_j` means no computation relation exists.

---

## 1. Three powers (strict separation)

### 1.1 Local
Single power: `Merge`. `M_i = Merge(L_i)`. Never routes, never judges peers, never sorts, never
chooses system goal.

### 1.2 Central Router
Does NOT merge, does NOT harmonize. Sole duty: `Pack -> Transport -> Place -> Re-adjacency`.
Output is not an "answer" but `A_{t+1}` the next adjacency structure:

```
R: (P_t, S_t) -> A_{t+1}
```

`P_t` = all Emergence Packets, `S_t` = current space/resource/boundary/transport state.

### 1.3 Harmony
Belongs to neither Router nor central layer. When `M_i ~ M_j`, local coupling:
`M_i <->H M_j -> M_ij'`. This is the computation.

Frozen identities:
```
Router != Harmony    Routing != Computation    Transport != Emergence
```

---

## 2. Non-negotiable architecture axioms

Every phase's code / branch / migrated algorithm must pass:

- **A1 Emergence Locality** — emergence only at local. Central layer cannot construct/replace Merge.
- **A2 Router Semantic Blindness** — Router may transport Merge but must NOT interpret it. Forbidden:
  `semantic similarity -> routing` as the default routing mechanism.
- **A3 Adjacency Before Computation** — `M_i ~ M_j` must exist before `H(M_i, M_j)`. Adjacency is the
  computational gate.
- **A4 Router Does Not Merge** — Router output only placement / adjacency / transport trace /
  resource state / boundary state. Never a new Merge.
- **A5 Round Atomicity** — Router must see the same logical snapshot `S_t` within one round. Forbidden:
  route A -> mutate world -> route B sees A's result. Snapshot_t -> Route all -> Adjacency_t+1 ->
  Harmony -> Commit.
- **A6 Position Is Computational State** — `M_a = M_b` but `p_a != p_b` still = two distinct entities.
  Position is not annotation.
- **A7 No Accelerator-Driven Densification** — never densify naturally-sparse / address / bounded
  structure merely to be accelerator-friendly. Optimize only profiled local hotspots.

---

## 3. Current baseline (v0.6.0 frozen — do NOT refactor for the Router)

The frozen pipeline is the Router's address/snapshot/concurrency/shape-contract/fail-closed/
transport foundation:

```
PAL storage/serialization -> TopologyCarrier -> Snapshot -> Concurrent Lanes -> Barrier
  -> Reconcile -> Commit -> PAL re-encoding
```

Plus: Equation Core, Gradient Emergence, Growth Law, Block ABI, Carrier Adapter, Emerge Stack,
CPU Concurrent Runtime.

The v0.7 plan MUST NOT modify existing FROZEN semantics to accommodate the new Router.

---

## 4. Repositioning the two experiment branches

- **PR #1 Reservoir Runtime** — NOT evidence the Router is done. Value survives only as three
  experiment modules (resource constraint / collision arbitration / synchronous allocation):
  `sum_j a_ij <= b_i`, `sum_i a_ij <= min(q_j, c_j)`. Those are Router resource-competition references,
  but synchronous water-filling is NOT the Router itself — the Router's core problem is regenerating
  next-round spatial adjacency, not fair resource split.
- **PR #2 Dilated Topology Compiler** — NOT the future compute model. Keep its assets (global address /
  open-closed boundary / outer_reference / boundary_stop / Graph IR / R<->C exact equivalence, and
  `(layer, global address)` as node identity). But `2^level` dilation is a swappable growth policy,
  not a fundamental physical law of visualR.

---

## 5. The five questions v0.7.0 must answer

### Q1. What can the Router see?
Define a strict **Public Routing Envelope** (Router may read these fields). The Merge itself is an
**Opaque Payload** (Router carries it, never interprets it).

### Q2. On what does the Router re-establish adjacency?
Find the minimal rule for `R(P_t, S_t) -> A_{t+1}`. Initially NOT the "smartest" Router. Requirements:
executable / auditable / refutable / does-not-read-payload / does-not-merge / order-independent /
full-trace-giving.

### Q3. How many adjacencies per Merge?
Experiment 1->1, 1->N, N->1, N<->M. But **v0.7.0 first freezes `1<->1`** as the minimal primitive.
Multi-body resonance only after binary Harmony is proven.

### Q4. How long does adjacency live?
`A_t` may be: instantaneous / single-round / memory / decaying / re-activatable. v0.7.0 default:
**adjacency lifetime = one logical round** (no premature long-term memory).

### Q5. How does the Router resolve collisions?
E.g. `M_A -> M_C` and `M_B -> M_C` simultaneously while only `1<->1` is allowed => define conflict
arbitration (address priority / residual capacity / phase / deterministic tie-break / randomized
tie-break). BUT it must be a **routing policy plugin**, never hard-coded into the Router ABI.

---

## 6. Phase 0 — Concept freeze (object boundary)

Goal: freeze object boundaries BEFORE writing any Router algorithm. Gate: no two objects may overlap.

**Architecture-language contract base** (the parallel-dev foundation) lives at:
`inst/ROUTER_CONTRACT_v070.md` — it defines every shared type's exact field schema, ownership,
invariant, the ownership matrix (at most one writer per cell), and the interface seams that make
parallel fan-out safe. Modify it only through a single review gate.

Postulate files:
- `inst/ROUTER_CONTRACT_v070.md`  (the frozen base — authoritative)
- `inst/ROUTER_ARCHITECTURE_AXIOMS_v070.md`  (axioms, derived)
- `inst/ROUTER_TERMINOLOGY_v070.md`  (terms, derived)

Objects that MUST be formally defined (with disjoint responsibilities):
```
LocalState / Merge / EmergencePacket / RoutingEnvelope / RouterSnapshot / PlacementPlan /
AdjacencyPlan / HarmonyEvent / MergeResult / ComputationRound
```

### Acceptance Gate P0
Fail check if any two objects' responsibilities overlap. Specifically verify:
- Router is not secretly merging?
- Harmony is not secretly deciding routing?
- Packet is not leaking semantics the Router must not read?

---

## 7. Phase 1 — Emergence Packet ABI

Build the first version:
```
new_emergence_packet(); validate_emergence_packet(); pack_emergence(); unpack_for_local()
```

Packet has two logical layers:
```
EmergencePacket
|-- Routing Envelope
|     packet_id, source_local, source_address, logical_time, boundary,
|     transport/resource metadata, integrity metadata
|-- Opaque Payload
|     Merge
```

API constraint: `router(packet)` may read `packet$envelope` but MUST NOT call `packet$payload`.

**Enforcement requirement**: stop misreads at the object-system level, not by comment. Use private
environment / closure / accessor discipline / class validator / package internal symbol.

### Acceptance Gate P1
Prove that **swapping the payloads while keeping envelopes identical yields identical Router output**:
`Envelope(P_a) = Envelope(P_b)` => `R(P_a) = R(P_b)` regardless of `Payload(P_a) != Payload(P_b)`.

---

## 8. Phase 2 — Central Router ABI

Build:
```
route_emergence(); new_router_policy(); validate_router_plan()
```

First version:
```
plan <- route_emergence(packets, snapshot, policy)
```

Returns `RoutingPlan`:
```
source packet / destination position / proposed adjacency / route trace / collision record /
unresolved packets / policy evidence
```

Forbidden returns: `semantic score / meaning / prediction / classification / new merge`.

---

## 9. Phase 3 — Router Baseline Policies

Do NOT seek the "final Router" first. Build several toy baselines to confirm the ABI itself holds:
```
identity_route / nearest_valid_route / phase_route / resource_route /
deterministic_shuffle_route / random_reference_route
```

These are NOT intelligent algorithms. Their purpose: answer "when the Router policy is swapped, does
the rest of the system keep the same semantic contract?" Therefore `Router ABI` is ABOVE
`Routing Policy`.

---

## 10. Phase 4 — Adjacency Materialization

Router plan != computation. Add a separate stage:
```
materialize_adjacency(); validate_adjacency()
```

`RoutingPlan -> A_{t+1}` and formally produce `AdjacencyPair`:
```
left_merge / right_merge / left_address / right_address / shared_local_space / route_trace / logical_time
```

Only `AdjacencyPair` may enter Harmony. Enforce by type:
```
harmony(packet_a, packet_b)      # ILLEGAL
harmony(adjacency_pair)          # LEGAL
```

The type system expresses: **No adjacency, no computation.**

---

## 11. Phase 5 — Harmony ABI (not Harmony theory)

This phase builds only the `H` interface, not an explanation of resonance:
```
register_harmony_operator(); harmony_step(); validate_harmony_event()
```

First stage uses hand-built baselines (identity / swap / pairwise deterministic composition /
reversible toy operator). Purpose is NOT to prove intelligence, but to verify `M_i ~ M_j` can fully
enter `H` and produce `M_ij'` without Router intervention.

**Boundary**: Router lifecycle ends at "Adjacency created". Harmony must NOT call Router internal
state as semantic input.

---

## 12. Phase 6 — First complete Computation Round

Unified entry:
```
run_emergence_round()
```

Full process:
```
LocalState_t -> Local Merge -> Emergence Packet -> Freeze Snapshot -> Central Router
  -> Routing Plan -> Adjacency Materialization -> Harmony -> New Merge -> Atomic Commit -> State_t+1
```

Math:
```
M_t --Pack--> P_t            A_{t+1} = R(P_t, S_t)            M_{t+1} = H(M_t, A_{t+1})
Commit(M_{t+1})
```

---

## 13. Phase 7 — Multi-round emergence loop

Only after single-round holds, build:
```
run_emergence_system(initial_state, rounds)
```

Producing `M_0 -> A_1 -> M_1 -> A_2 -> M_2 -> ...`. First time we may study whether computational
topology evolves on its own. Observation metrics:
```
adjacency turnover / route length / collision rate / merge survival / merge diversity /
local recurrence / topological cycle / boundary utilization / resource consumption / emergence depth
```

Forbidden in this phase: intelligence score / reasoning score / AGI score. Describe structural facts
only.

---

## 14. Test system (six classes — not just function outputs)

1. **Semantic Isolation** — Router cannot access Merge payload.
2. **Adjacency Gate** — Harmony fails closed without a legal adjacency object.
3. **Snapshot Equivalence** — different execution order => same routing plan.
4. **CPU Concurrency Equivalence** — `Result_serial == Result_PSOCK == Result_multicore` (perf may differ).
5. **Trace Completeness** — every new Merge traces to: source locals / packet / router policy /
   destination position / adjacency / harmony operator / logical round.
6. **Mutation Boundary** — Router must not modify payload; Harmony must not modify Router snapshot;
   prior-round state not modified before Commit.

---

## 15. Performance route (frozen order)

```
R reference semantics -> correctness -> profiling -> identify hotspot -> native local accelerator
```
NOT `GPU -> redesign the data structure`. Priority: `Base R -> vectorized R -> parallel R ->
C99/C++ local kernel -> SIMD`. GPU only as an optional kernel if profiling proves a hotspot is
naturally GPU-suited; GPU is NEVER semantic authority.

---

## 16. Branch plan

```
main  = v0.6.0 frozen baseline
agent/router-core-v0.7          = new research branch (this work)
agent/topology-dilated-compiler = independent experiment source
agent/reservoir-topology-runtime = independent experiment source
```
Stage 1 forbids merging PR #1 / PR #2 into main. First: Architecture Audit, THEN decide which
mechanisms migrate / which stay experiments / which are deprecated.

---

## 17. Suggested file layout

```
R/      emergence_packet.R, router_contract.R, router_policy.R, adjacency.R,
        harmony_contract.R, emergence_round.R
inst/   ROUTER_ARCHITECTURE_AXIOMS_v070.md, ROUTER_PACKET_CONTRACT_v070.md,
        ROUTER_ADJACENCY_CONTRACT_v070.md, HARMONY_ABI_v070.md,
        COMPUTATION_ROUND_CONTRACT_v070.md
tests/  test-emergence-packet.R, test-router-blindness.R, test-router-order-invariance.R,
        test-adjacency-gate.R, test-harmony-boundary.R, test-emergence-round.R,
        test-round-concurrency.R, test-emergence-trace.R
```

---

## 18. Promotion gate (architecture correctness BEFORE intelligence claims)

Before freeze, prove all 15:
1. Merge/Packet/Router/Adjacency/Harmony five layers fully separated.
2. Router cannot read Merge internal semantics.
3. Router produces no Merge.
4. Harmony accepts only legal adjacency objects.
5. Each round uses one immutable snapshot.
6. serial/parallel semantics identical.
7. any new Merge fully tracable to source.
8. address is always computational state, never downgraded to annotation.
9. no silent fallback.  10. no silent padding.  11. no hidden semantic aggregation.
12. all error paths fail closed.  13. R is semantic authority.
14. native accelerator does not change semantics.
15. >= 2 Router policies plug in without modifying Harmony.
16. >= 2 Harmony baselines plug in without modifying Router.

All pass => `reference_experimental -> B-promotion -> FROZEN`.

---

## 19. Core research question of the next stage

Find `R(P_t, S_t) -> A_{t+1}` and answer: *how can a Central Router that understands NO Merge
semantics, using only position/time/boundary/resource/historical topology and other allowed
structural variables, let different local emergences keep re-forming meaningful spatial adjacency?*

If it holds, Central Router is not "an intelligent central controller" but an **Emergence Transport
Topology Generator** — and real computation still only occurs at `Adjacency + Resonance -> New
Emergence`.

---

## 20. Project overview

```
                    visualR
                  Local State -> MERGE -> Emergence Packet
              [ CENTRAL ROUTER Pack/Transport/Place/Re-adjoin ]
                    -> Adjacency Plan -> Spatial Neighbor
                 Merge A <-> RESONANCE/HARMONY <-> Merge B
                    -> New Merge -> Packet -> ...
```

The question is no longer "make the central model compute smarter" but:
> **How to let the central layer only transport, while local emergences keep gaining the spatial
> conditions to compute next?**

---

## 21. Per-step execution & audit gates (this is how each step is worked)

For EVERY phase step, work in this order before committing:

1. **写代码 / write R** (additive files only; never touch a FROZEN file).
2. **优先编译 / compile-first** — after each step run the compile+test gate before proceeding:
   ```
   R CMD INSTALL --no-multiarch --with-keep.source .   # or devtools::install
   Rscript -e 'devtools::test()'                        # testthat, fail-closed
   ```
   A step is not "done" until `R CMD check` is green on this branch.
3. **CC 审查 / claude-code review** — per step, review (4dim, via claude -p read-only):
   - 代码依赖性 / dependency: new function's import/export graph, no cross-FROZEN coupling.
   - 系统兼容性 / compat: R version, package lifecycle, Windows/macOS/Linux CI silence vs fail.
   - 稳定性 / stability: fail-closed paths, snapshot/commit atomicity, concurrency determinism.
   - 端口对接性 / port: R<->C exact-equivalence and ABI stringency — R stays semantic authority.

### Acceptance Gate P-V (version-level, before promotion)
All of 14/18 hold AND every step's CC review 4-dim findings are resolved.

---

## 22. Boundary note (author / provenance)

- Source of concept: user's architecture exploration text (this document is the decomposed,
  executable sub-plan deriving from it).
- Semantic authority: R. GPU never defines semantics (A7, §15).
- Work area: this plan lives in the **visualR work tree** (branch agent/router-core-v0.7).
  The knowledge base (hermes_memory) holds only a routing pointer to it, not a copy.

---


