# visualR v0.8 — Geometry Transmission Contract (architecture-language spec)

> Status: **DRAFT for review** | Branch: agent/geometry-transport-v0.8
> Base: ROUTER_CONTRACT_v070.md (frozen, untouched)
> Math source: "visualR 的数学地基" deep-research-report (2026-08-25 采纳)
> Notation: `field: type` | RO: read-only | FR: fail-closed rule

---

## 0. Scope and authority

This contract freezes the **geometric transmission layer** added in v0.8
(batches 1-7). It is strictly additive over the frozen v0.7 router
contracts: every v0.7 type (`Merge`, `EmergencePacket`, `RoutingEnvelope`,
`RouterSnapshot`, `AdjacencyPair`, `HarmonyEvent`) keeps its schema,
ownership, and invariants. Nothing in v0.7 is redefined here.

Mathematical anchor sentence (from the report, normative):

> 向量只是局部表示；位置决定它属于哪里；度量决定怎样比较长度；
> 连接决定怎样跨位置比较；路径保存传播历史；调控改变传播条件；
> 邻接赋予计算资格；Harmony 才产生新的 Merge。

## 1. Frozen shared objects (typed schemas)

### 1.1 PositionState  `ps: visualr_position_state`
```
fields:  address:    <non-empty character vector>
         coordinate: <numeric, one per address element>
         cell:       <single non-empty character>
         layer:      <single non-negative integer> = 0L default
         chart:      <single non-empty character> = "grid" default
invariants:  address+chart identify one position; coordinate interpretation
             is chart-relative (cross-chart comparison requires an explicit
             transition contract — NOT in v0.8).
ownership:   created by callers; treated RO by runtime.
FR:          any field violation stops (fail closed).
```

### 1.2 TransmissionPath  `path: visualr_transmission_path`
```
fields:  merge_id:  <character>            — owning merge identity
         positions: <list of PositionState>  — p_0..p_k
         steps:     <list of step records>   — k records
step record: from / to (PositionState) + grade (T1|T2|T3|T4) +
             logical_time (non-negative integer) +
             boundary_event / regulation_event (nullable annotations)
invariants:  APPEND-ONLY. No mutation API exists. positions[k+1] is reached
             by steps[k]. Step `from` must equal current path head.
ownership:   rebuilt (never mutated) on append; prefix rebuild allowed only
             inside arbitration deferral (§5).
```

### 1.3 MetricLaw registry entry
```
signature: distance_fn(a: PositionState, b: PositionState) -> numeric(1) >= 0
defaults:  manhattan, euclidean
FR:        unknown name lookup stops; negative/NA distance stops consumers.
```

### 1.4 TransportLaw registry entry
```
signature: step_fn(state, from, to, regulation) -> list with $position
defaults:  grid_identity (P_ij = I; flat baseline => trivial holonomy)
semantics: applies to the STATE wrapper, never to Merge payload content.
FR:        missing $position in result stops (fail closed).
```

### 1.5 TransportedState  `ts: visualr_transported_state`
```
fields:  merge_id:         <character> — SAME identity as the carried Merge
         merge:            visualr_merge (payload opaque, A2 holds)
         position:         PositionState (current p)
         path:             TransmissionPath (full history)
         signature:        lossy audit digest (transmission_signature)
         regulation_trace: <list> annotation only
invariants:  transport NEVER creates a new Merge identity. Only Harmony
             creates fresh Merges. Signature equality does NOT imply
             transport-result equality (holonomy warning, normative).
```

## 2. Adjacency predicate (A3 refinement)

`default_adjacency_predicate(max_distance, metric_name, same_layer_only)`
returns a semantic-blind predicate over two PositionStates:

```
A_t(i,j) = C_distinct AND C_layer AND C_space AND C_distance
  C_distinct: address(i) != address(j)
  C_layer:    layer(i) == layer(j)              (if same_layer_only)
  C_space:    chart(i) == chart(j)              (no transition contract yet)
  C_distance: d_metric(p_i, p_j) <= max_distance
```

`detect_adjacency(states, predicate, logical_time)` scans all unordered
pairs; only predicate-passing pairs gain computation eligibility.
Semantic blindness: predicate reads positions ONLY — never Merge content.

## 3. Runtime round (v0.8 semantics)

```
run_transmission_round:
  Snapshot -> Transmission(per-state, no central repositioner)
           -> Adjacency(geometric predicate)
           -> Harmony(existing ABI, unchanged)
           -> Commit(fresh merges from Harmony only)
```

- Surviving states keep their own position and path. There is NO analogue
  of v0.7's round-robin `.prepare_next_state()` repositioning; that
  function remains v0.7-only legacy and its retirement is a v0.9 decision.
- Determinism: same input => same pairs/events/new_merges (serial ==
  "parallel" trivially; no scheduling-dependent order).

## 4. Emergence position rule (explicit unresolved interface)

New-Merge birth position is NOT silently decided. `emergence_position_rule()`
exposes reference policies: `left_origin`, `right_origin`, `shared_boundary`.
Unknown policy names stop (fail closed). Experiments decide later which
policy matches topological semantics; adding policies is additive.

## 5. Arbitration plugin (Router's only remaining role)

Shared-resource conflicts are detected geometrically
(`detect_cell_collisions`: >= 2 TransportedStates declaring the same
(cell, chart, layer)). Resolution is deterministic and semantic-blind:

```
tie-break chain:  1) fewer accumulated path steps wins
                  2) lexicographically smaller merge_id wins
loser outcome:    DEFERRAL, not deletion — rewound to previous path
                  position via immutable prefix rebuild; n==1 losers
                  defer in place; payload never touched.
invocation point: run_transmission_round_arbitrated() deconflicts BEFORE
                  adjacency/harmony.
```

This is the report's "arbitration plugin" landing: the Router has no
general transmission role, no meaning-choosing role, no smart policy role.

## 6. Property gates (normative tests)

Implemented in tests/testthat/test-geometry-*.R:

```
no_adjacency_no_harmony                       PASS
adjacent_pair_produces_one_event              PASS
serial determinism                            PASS
survivor_not_repositioned                     PASS
distance_accumulates_stepwise                 PASS
same_endpoint_different_path_is_not_same_state  PASS (promotion gate)
flat_transport_has_trivial_holonomy           PASS (grid_identity)
regulation_cannot_mutate_payload              PASS (transport touches state only)
router_cannot_bypass_transport                structural (Router absent by default)
coordinate_change_preserves_invariant         DEFERRED (needs chart transition contract)
```

Current evidence: geometry suite 189 assertions, 0 failures, under
`pkgload::load_all(export_all = FALSE)` (R CMD check-equivalent path).

## 7. Out of scope for v0.8

- Chart transition maps (ABC/CBA gluing) — needs its own contract.
- Non-identity edge transports with curvature/holonomy experiments —
  second-month roadmap item; registries already accept them additively.
- Regulation-dependent metrics (Finsler-like) — third-priority experiment.
- Retirement of v0.7 `.prepare_next_state()` — v0.9 mainline convergence.
