# CC Review Task — visualR v0.7.0 Central Router code

> Work dir: /mnt/d/visualR/visualR
> You are the independent code reviewer. Read ONLY the files listed below.
> DO NOT read any other directory. DO NOT write/modify any file. DO NOT git.
> DO NOT network. Report findings to stdout only (this is a read-only review).

## Scope — v0.7.0 files to review (all in this repo)

Read these 6 R files + 2 contract docs:

- R/router_contract.R          (shared object constructors + validators + semantic-blindness seam)
- R/emergence_packet.R         (Phase 1: pack_emergence / unpack_for_local)
- R/router_abi.R               (Phase 2: route_emergence / new_router_policy / get_router_policy)
- R/router_policy.R            (Phase 3: 6 baseline routing policies)
- R/adjacency.R                (Phase 4: materialize_adjacency / validate_adjacency)
- R/harmony_contract.R         (Phase 5: register_harmony_operator / harmony_step)
- R/emergence_round.R          (Phase 6/7: run_emergence_round / run_emergence_system)
- inst/ROUTER_CONTRACT_v070.md (the frozen contract base — the spec being enforced)

## Review context

This is v0.7.0 "Central Router & Emergence Computation Loop". Semantic
authority is R; execution is CPU-native. The architecture forbids any DL
migration. The seven axioms (A1-A7) and the frozen shared types in
inst/ROUTER_CONTRACT_v070.md are the contract. The ownership matrix (one writer
per object/cell) is the parallel-dev guardrail.

## Four review dimensions (report per-dimension)

1. **Code dependency / 代码依赖性** — does any v0.7 file illegally depend on
   another phase's private internals instead of the frozen contract? Does a
   phase redefine a shared type? Any hidden cross-FROZEN coupling (touching
   constants.R / mapping_pack.R / closure.R / topology_carrier.R etc.)?
2. **System compatibility / 系统兼容性** — base-R only? Any non-base
   dependency (rlang/dplyr/data.table/etc.) that would break on a minimal R
   install? Any use of `%||%` or other tidyverse operators? Does it run on R
   >= 4.x cleanly? PSOCK cluster usage correct?
3. **Stability / fail-closed / 稳定性** — every error path fail-closed?
   Semaphore/atomicity of the round (A5)? Snapshot immutability? No silent
   fallback/padding/hidden aggregation? Determinism of randomized policies
   (seed purity)?
4. **Port / R<->C exact-equivalence intent / 端口对接性** — R stays semantic
   authority (A7 §15). No GPU/accelerator assumption. Any place that would
   leak Merge semantics to the Router (A2 violation)?

## Output format

Per finding, one line: `[severity P0|P1|P2] <file>:<line> <problem> | <evidence> | <suggestion>`
Then a summary count by severity. If you find nothing in a dimension, say so
explicitly for that dimension (do not pad).

## Hard constraints

- This is a SEMANTIC-MODEL review; you are NOT implementing anything.
- Identify the packet_id<->Merge seam (Phase4 pair vs Phase5 harmony) and
  whether the Phase 6 resolution (.packet_merge_map) is correct and airtight.
- Identify whether merge_id determinism (no process counter) actually holds
  so serial == PSOCK (contract 14.4).
