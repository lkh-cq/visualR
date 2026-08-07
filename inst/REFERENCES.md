# visualR consciousness-bus mapping

## Benchmark positioning (frozen 2026-08-07)

**R interactive + concurrent computation is the BENCHMARK.**
visualR is the first-class implementation of the consciousness-bus
core. R's REPL interactivity and parallel computation carry the
"storage → compute → fold-back" loop. Python (mapping_pack.py) is a
GLUE/CROSS-VALIDATION implementation only — it exists to cross-check
semantics, NOT to define the interface. The frozen spec (2026-08-05)
is the authority; R and Python are both its implementations, with R
interactive-concurrent as the reference.

## Three-layer architecture (藏归分离)

### Layer 1: Palindrome Storage (藏 — compressed storage)
- `new_pal_state()` constructs 4-field compressed state
- `format_pal()` serializes to string (v0.2 length-prefixed, RCE-hardened)
- `parse_pal()` deserializes (pure string parser, NO eval)
- `validate_pal()` invariant verification

### Layer 2: Matrix Computation Emergence (归 — on-demand expansion)
- `unfold_pal()` palindrome expansion: c(shells, core, rev(shells))
- `fold_pal()` palindrome folding [reads only expanded path, 藏归分离]
- `pal_to_jiugong()` palindrome → k×k matrix mapping
- `jiugong_to_pal()` k×k matrix → palindrome inverse mapping
- `complement_pal()` complement operator C (C² = I, frozen)
- `mirror_addr()` central inversion Σ (Σ² = I, frozen)
- `locate()` O(1) fourth-dimension mapping table lookup

### Layer 3: Projection View (projection — one-way derivation)
- `diamond_field()` order field λ = n - |p-c|₁ [one-way, no inverse]

## 藏归分离 (Storage-Return Separation)

fold_pal only reads the character vector produced by unfold_pal (the expanded path).
It cannot access the hidden original pal_state object.
This ensures true separation between storage (Layer 1) and read (Layer 2).

## Frozen operators (sanyuan-runtime v0.2, ported from mapping_pack.py)

- Complement C: default self-complement C(x)=x (palindrome head==tail);
  custom involution tables allowed, verified C²=I at call time.
- Central inversion Σ: (r,c) -> (4-r, 4-c) in 1-indexed 3x3 jiugong;
  Σ²=I, center (2,2) is fixed point.
- Fourth-dimension mapping table (ORBIT_TABLE): A/B/C/D/e ↔ head/tail
  indices ↔ jiugong coordinate pairs (user-frozen 2026-08-05).
- Expand order: center-outward palindrome depth order (e→D→C→B→A),
  NOT geometric distance order.

## Security hardening (2026-08-06)

v0.1.0 `format_pal`/`parse_pal` used eval(parse(text=...)) for shells and
provenance fields — arbitrary code execution (RCE) was demonstrated
(system() payload ran during parse_pal). Fixed in v0.1.1:
- Serialization format bumped to v0.2 (visualr_pal/v0.2)
- Length-prefixed records with unit-separator (\x1f) delimiters
- Pure string parser: no eval, no parse(text=), no code path
- Regression tests in test-security.R cover injection payloads

## Scope annotations (NOT frozen)

- S_12 → 5×5 jiugong: implemented for generality (2*12+1=25=5²) but is an
  UNFROZEN extension. Frozen spec covers S_4→3×3 and S_5→11×11 carrier
  (11 is not a perfect square, so S_5 cannot use pal_to_jiugong).
- diamond_field: order field only. No diamond_to_pal() inverse (one-way).

## ρ+θ=1 Dual-Engine (Architecture note only — NOT v0.1 hard verification)

The consciousness-bus ρ+θ=1 dual-engine maps to runtime states:
- active → ρ convergence (attention focus)
- idle → θ switching (local dissipation)
- dormant → θ' advance (stale clock progression)

This mapping is deferred to v0.2 `visualr_runtime_state`.
v0.1 does NOT implement numerical ρ/θ conservation checks.

## v0.2.1 Semantic Hardening (2026-08-07)

Six-role specialist audit (B- rating) found 7 P0 blockers before merge.
All P0 fixed in v0.2.1:

- P0-1 mapping_pack_id now DRIVES runtime rules via new_mapping_pack /
  register_mapping_pack / resolve_mapping_pack; unknown id, duplicate
  registration, and hash mismatch all FAIL CLOSED. Root principle: the
  mapping pack is the authoritative basis for all storage-computation
  mappings.
- P0-2 unified carrier dispatch: materialize(pal, carrier) is the ONLY
  entry; pal_pipe / batch_compute / interact share it (no semantic
  fork between entry points).
- P0-3 closed token domain: validate_pal rejects empty tokens, newline,
  and reserved separators (\x1f | = { }); constructor delegates to
  validate_pal (single source of truth). Multi-char role tokens are
  legal and round-trip through the grammar.
- P0-4 serialization round-trip hardened: parse_pal(format_pal(S)) == S
  holds for every legal state (token domain closure).
- P0-5 closure FACT (closure_check -> logical) separated from
  transition POLICY (transition_policy -> promote/transient/recurse/
  reject). recurse-on-asymmetry is a FROZEN scheduling policy
  (B-promotion 2026-08-07, fully tested).
- P0-6 interact returns visualr_compute_result (input, carrier,
  computed, closed, action, fold_back, trace); never silently restores
  the original state — "not closed" != "nothing happened".
- P0-7 carrier_11x11 and gamma_field lowercasing promoted to FROZEN
  (B-promotion 2026-08-07: 282 new tests covering determinism, symmetry,
  custom pack local_center_transform/gamma_rule overrides, and four-state
  transition_policy gate).

P1 items (parallel in Imports, operator ABI overwrite guard, ncores NA
guard, ASCII-only source, Rd sync) also landed. Remaining P1: lazy
diamond, NAMESPACE roxygen unification, CI matrix, release isolation.

## v0.2.2 P0 completion (2026-08-07)

Second six-role audit: B+ / Experimental Runtime Candidate. Three new
P0 blockers fixed:

- P0-1 FULL pack hash: pack_hash() now digests the complete rule
  surface — id, version, orbit_table (full content incl. coordinates),
  expand_order, complement_table (content), frozen_symbols, carrier_fn
  (deparsed), gamma_rule (deparsed), local_center_transform
  (deparsed), closure_policy (content). assert_pack() recomputes the
  canonical hash on EVERY resolve_mapping_pack() and FAILS CLOSED on
  mismatch (implemented, not doc-only).
- P0-2 pack drives ALL mappings: materialize("carrier_11x11") calls
  pack$carrier_fn; gamma_field honors pack$gamma_rule and
  pack$local_center_transform (pal-jiugong pack chooses tolower;
  custom packs may choose identity); pal_resolve_pack() is the single
  authority at every computation entry.
- P0-3 typed carrier dispatch: operators are defined per carrier
  SHAPE. Non-3x3 carriers (11x11) are materializable VIEWS only;
  compute entry points fail with a clear typed error instead of a
  confusing "grid must be 3x3" downstream.

P1 landed: operator ABI enforced at registration (probe) and call
time (return validated: matrix, 3x3, character); diamond_at offset
domain validation; pal_to_jiugong STRICTLY S_4 -> 3x3 (new
pal_to_square_view for general perfect-square projections); GitHub
Actions CI matrix (Linux/Windows/macOS x release/oldrel/devel) with
1-core == N-core invariant check.
