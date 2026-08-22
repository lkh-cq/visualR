# visualR v0.7.0 — Router Contract Base (architecture-language spec)

> Status: **CONTRACT BASE / FROZEN for parallel development**  |  Branch: agent/router-core-v0.7
> Role: This is the **基台 (foundation layer)**. It defines every shared type, its exact
> field schema, ownership, and invariant. Any parallel worker (CC subagent / delegate) MUST
> build only against these frozen contracts — never modify them. Modifying a contract = a
> single review gate, not a per-file change.
> Notation: `field: type`  |  `RO:` read-only  |  `RW:` read-write  |  `FR:` fail-closed rule

---

## 0. Why this is the base for high-parallel development

visualR v0.7 splits into independent phases (packet / router / policy / adjacency / harmony /
round / loop). Multiple workers editing the same repo concurrently would collide on the SHARED
types. The solution is **contract-first**: freeze every shared object's schema + ownership here,
then each phase becomes a self-contained module that consumes/produces only these contracts.
No phase may redefine a shared type; a phase may only add a plugin (policy / harmony operator)
registered through a fixed ABI. This is what makes parallel fan-out safe.

---

## 1. Frozen shared objects (typed schemas)

### 1.1 LocalState  `state:LocalState` (RO for router)
```
fields:  local_id: <nano|character>          — unique id, stable
         address:  <character vector>        — palindrome/global address, position IS state (A6)
         payload:  <opaque>                  — the local's internal state
         boundary: <character>               — open|closed (from topology carrier)
invariants:  local_id + address uniquely identify one local; boundary derived, not stored ambiguous.
ownership:   created by local (Merge), mutated by local only; router treats as RO.
```

### 1.2 Merge  `M: Merge`  (Opaque Payload — router must never read semantics)
```
fields:  merge_id: <character>          — unique
         content:  <opaque>             — semantic content; NOT exposed to router
         origin_local: <local_id>
         logical_time: <integer>        — round it emerged in
invariants:  content is opaque (A2). Two merges equal content, different address = distinct (A6).
ownership:   created by local (Merge). Router: carry-only. Harmony: the only consumer of content.
```
> **Enforcement:** in R, `content` lives behind a closure/private env; router's accessor stack
> returns only `envelope`. See Phase 1 spec for the discipline.

### 1.3 EmergencePacket  `P`  — two layers
```
fields:
  envelope: <RoutingEnvelope>        — router-readable (see 1.4)
  payload:  <Merge>                  — opaque (1.2)
invariants:  layers are strictly separate (A2/P1). Router code path may only touch envelope.
ownership:   built by local (pack_emergence), immutably bound to one Merge.

---

### 1.4 RoutingEnvelope  `envelope`  (public — the ONLY thing router reads)
```
fields:
  packet_id:     <character>            — 1:1 with packet
  source_local:  <local_id>
  source_address:<character>            — address of origin local
  logical_time:  <integer>              — round of emergence
  boundary:      <character>            — open|closed at emit time
  transport:     <list>                 — resource/traffic metadata (capacity used, etc.)
  integrity:     <character>/<hash>     — content integrity hash (tamper-detect)
invariants:  transport and integrity are the ONLY dynamic fields; all others immutable after pack.
ownership:   router reads envelope; local writes it once at pack; harmony never sees it.
```

### 1.5 RouterSnapshot  `S_t`  (immutable per round — A5)
```
fields:
  round:        <integer>
  packets:      <list of envelope>      — ALL packets this round, frozen order-independent
  space:        <placement/coords>      — current addressable space
  resources:    <named numeric>         — per-cell residual capacity
  boundaries:   <named character>       — open/closed per cell
  historical:   <list>                  — allowed structural history (adjacency turnover, etc.)
invariants:  frozen at capture; NOTHING mutates mid-round (A5). Same snapshot => same plan.
ownership:   frozen by step "Freeze Snapshot"; router reads; hub writes only at end-of-round commit.
```

### 1.6 RoutingPlan  `plan`  (router output — NEVER a Merge / never semantics)
```
fields:
  placements:    <list of PlacementPlan>   — where each packet's merge lands
  adjacencies:   <list of proposed edge>   — source packet -> destination
  route_trace:   <character>               — full determinism trace (policy id + inputs)
  collisions:    <list>                    — every collision record (who contended, who won)
  unresolved:    <list of packet_id>       — packets that could not be placed/adjacent this round
  policy_evidence:<list>                   — which policy fired, evidence that justifies choice
invariants:  contains NO semantic score / meaning / prediction / classification / new merge (A4/§8).
ownership:   produced by router; consumed by adjacency materialization; never fed back to router.
```

### 1.7 AdjacencyPair  `pair`  (the ONLY legal harmony input — A3)
```
fields:
  left_merge / right_merge: <merge_id>
  left_address / right_address: <character>
  shared_local_space: <character>     — the space where both are co-resident
  route_trace: <character>
  logical_time: <integer>
invariants:  constructed ONLY via materialize_adjacency (typed). harmony(pair) legal;
             harmony(packet_a, packet_b) ILLEGAL.
ownership:   produced by adjacency materialization; consumed by harmony once.

### 1.8 HarmonyEvent  `h`  (what H emits)
```
fields:  pair: <AdjacencyPair> | operator_id: <character> | result: <Merge> | trace: <character>
invariants: result is a NEW Merge (M_ij') with fresh merge_id + address; never mutates inputs.
ownership: harmony produced it; consumed by round commit.

### 1.9 MergeResult  — result of a full round
```
fields:  new_merges: <list of Merge> | adjacency_used: <list of AdjacencyPair> |
         dropped: <list of merge_id> | resource_left: <named numeric> | trace: <character>
invariants: complete, auditable, deterministic. No hidden aggregation (gate 11).
ownership: produced by run_emergence_round; committed atomically (A5).

### 1.10 ComputationRound  — unit of atomic semantics
```
fields:  S_t (RouterSnapshot) | plan (RoutingPlan) | pairs (list AdjacencyPair) |
         events (list HarmonyEvent) | result (MergeResult)
invariants: all stages share the one S_t; round commits atomically; RFC "round" = one logical time.
ownership: orchestrator (run_emergence_round) builds it; commit is the sole mutation boundary.

---

## 2. Ownership matrix (who may touch what) — the parallel-dev guardrail

| object            | local(Merge) | packer | router | adjacency | harmony | commit |
|-------------------|:---:|:---:|:---:|:---:|:---:|:---:|
| LocalState        | RW  |     | RO   |           |         |       |
| Merge content     | RW  | carry| carry|           | RW      |       |
| EmergencePacket   |     | RW  | read  |           |         |       |
| RoutingEnvelope   |     | W   | read  |           |         |       |
| RouterSnapshot    |     |     | read  | read      |         | write |
| RoutingPlan       |     |     | W     | read      |         | read  |
| AdjacencyPair     |     |     |       | W         | read    | read  |
| HarmonyEvent      |     |     |       |           | W       | read  |
| MergeResult       |     |     |       |           |         | W     |

Rule: **a cell can hold at most one writer.** If two phases claim write on the same object,
split the object or push a phase boundary. This is gate P0's concrete test.

## 3. Interface seams (this is what parallel workers plug into)

Each phase is a module with a fixed ABI; a worker implements the module, not the shared type.

```
Phase 1 packet ABI:     new_emergence_packet / validate_emergence_packet /
                        pack_emergence / unpack_for_local     [consumes Merge -> Packet]
Phase 2 router ABI:     route_emergence / new_router_policy / validate_router_plan
                        [consumes {envelope list, Snapshot, Policy} -> RoutingPlan]
Phase 3 policy plugins: identity_route / nearest_valid_route / phase_route / resource_route /
                        deterministic_shuffle_route / random_reference_route
                        [register via new_router_policy; MANY may live in parallel]
Phase 4 adjacency ABI:  materialize_adjacency / validate_adjacency   [Plan -> AdjacencyPair]
Phase 5 harmony ABI:    register_harmony_operator / harmony_step /
                        validate_harmony_event              [Pair -> HarmonyEvent]
Phase 6 round:          run_emergence_round                 [orchestrates 1-5 + commit]
Phase 7 loop:           run_emergence_system                [rounds x N]
```

> **Parallel rule:** Phase 1, 2+3, 4, 5 are mutually independent given the frozen contracts above.
> They are safe to develop in parallel (separate subagents) because each only reads shared types
> and writes into its own output type. Phase 3 policies are additionally independent of each other.
> Phase 6/7 are integration phases; do them last, alone.

---

## 4. Integration seams discovered during Phase 6 (do NOT re-encounter)

### 4.1 packet_id<->Merge seam (between Phase 4 and Phase 5)
`materialize_adjacency()` (Phase 4) returns `AdjacencyPair` whose `left_merge`/`right_merge`
are the **router-readable packet_id (character)** — because adjacency may only read the
envelope surface (A2). `harmony_step()` (Phase 5) needs the **actual Merge objects** to read
content (`merge_content` requires a `visualr_merge`).
**Resolution:** the round orchestrator (`run_emergence_round`, Phase 6) resolves every pair's
packet_id back to its packet payload Merge via `.packet_merge_map()` *before* calling Harmony.
This is the single place both sides of the contract meet. Do not make adjacency read semantics,
and do not make harmony accept raw packets.

### 4.2 merge_id determinism (concurrency gate 14.4)
`harmony_step()` merge_id is a **pure function** of the pair's structural identity
(left/right id + operator + logical_time + addresses). It must NOT embed a process-global
counter: a counter makes `Result(serial) != Result(PSOCK)` and breaks gate 14.4. Freshness is
still guaranteed because a new `visualr_merge` OBJECT is created on every call (inputs never
mutated). Re-adding a counter would re-break concurrency equivalence.

### 4.3 policy edges must reference packet_id
Baseline routing policies emit edges as `list(source_packet_id=, dest_packet_id=)`, and
`.pair_indices` must be keyed on **packet_id** (not source_address) so `materialize_adjacency`
can resolve them against `snapshot$packets`. Using address as a pairing key produces edges that
fail the packet lookup (Phase 4 fails closed).
