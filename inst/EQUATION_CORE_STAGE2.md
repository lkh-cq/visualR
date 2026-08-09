# Equation Core Stage 2 — Gradient Emergence & Sample Evidence

> Date: 2026-08-09
> Status: stage-2 implements gradient-emergence mechanics and sample
> topology analysis as EVIDENCE; generative equation G_d / L_d still
> not frozen (user is actively deriving it).
> Authority: user original definitions + external review 2026-08-09

## 1. What changed since Stage 1

Stage 1 delivered measurement instruments (candidate series, parity
gradients, residual errors). Stage 2 adds two working structures:

1. `R/gradient_emerge.R` — gradient expansion as LAYERED BATCHES, not
   matrix filling (user direction: "多批次拼接而非一次性算完").
2. `R/sample_analysis.R` — 3x3/4x4 registered as EVIDENCE with full
   structural analysis (symmetry -> orbits -> centers -> label reuse).

## 2. Gradient emergence (multi-batch, not matrix filling)

User correction during derivation: the samples are NOT matrices to be
filled once; they are observation windows of an infinite recursive
gradient expansion. The working structure is the position stream.

```text
gradient_layers(depth)      position stream; layer k>0 has 4k positions
emerge_weight(idx, size)    structural compute/verification weight
                            (位置就是信息), NOT statistical frequency
emerge_by_layers(depth)     incremental batch consumption; deep layers
                            report symbol extension instead of inventing
project_gradient_window()   display-only square window with NA corners
                            (diamond > square)
verify_gradient_emergence() structural invariants:
                            layer sizes 4k, unique center,
                            central inversion, depth == layer index
```

Key verified result: the 5x5 observation window assembled from
center-outward batches (e -> D -> C -> B -> A rings) equals the frozen
5x5 candidate (after transpose). The sample is reproduced by batch
assembly, not by a single Manhattan-distance formula.

Layer sizes: 1, 4, 8, 12, 16, ... (4k for k>0). Diamond total for depth
n is 1 + 2n(n+1) = 41 for the full 5-symbol field; the 5x5 window shows
the 25-cell square observation slice.

## 3. Sample topology analysis (evidence registration)

External review (2026-08-09) redirected the next step: do not generate
5x5/6x6 yet; FIRST register the 3x3/4x4 samples as evidence and extract
their real structure.

```text
detect_symmetries(M)   transpose symmetry + central inversion
orbit_partition(M)     addresses partitioned into orbits under the
                       VERIFIED symmetry group (closure algorithm)
center_analysis(M)     geometric centers (parity) vs semantic centers
                       (singularity token positions)
label_reuse(orbits)    labels appearing in >1 orbit
audit_sample_topology(M, name)  full structural description
```

### Reproduced structural facts

| Sample | Symmetries | Addresses | Orbits | Labels | Reuse | Centers |
|--------|-----------|-----------|--------|--------|-------|---------|
| 3x3    | inversion only | 9 | 5 | 5 | none | geometric == semantic (single e) |
| 4x4    | transpose + inversion | 16 | 6 | 5 | C reused | geometric (2x2 block) != semantic (e pair) |

Key facts:

- 4x4 has NO single center: the central 2x2 block splits into a C pair
  (central main diagonal) and an e pair (central anti-diagonal). The
  center is a relation domain.
- Label C occupies two DIFFERENT orbits (second outer rail + central
  main diagonal). Same letter, different position identity.
- Content value cannot replace address — structural proof that
  position carries information independent of value.

## 4. Sample evidence tables (registered facts)

### 3x3 (S_4 PAL, user-frozen mapping)

```text
A B C
D e D
C B A
```

Orbits (central inversion only):
- A: (1,1),(3,3)
- B: (1,2),(3,2)
- C: (1,3),(3,1)
- D: (2,1),(2,3)
- e: (2,2)

### 4x4 (user-supplied original sample)

```text
A B C D
B C e C
C e C B
D C B A
```

Orbits (transpose + central inversion):
- Orbit 1  A: (1,1),(4,4)
- Orbit 2  B: (1,2),(2,1),(3,4),(4,3)
- Orbit 3  C: (1,3),(3,1),(2,4),(4,2)
- Orbit 4  D: (1,4),(4,1)
- Orbit 5  C: (2,2),(3,3)  <- C reused
- Orbit 6  e: (2,3),(3,2)

## 5. Implication for the future equation

Next-order generation should be formalized as:

```text
X_d = (V_d, S_d, O_d, l_d, eta_d)
  V_d   address set
  S_d   symmetry group
  O_d   orbits under S_d
  l_d   local labels/states
  eta_d newly-added information not derivable from the old slice

X_{d+1} = L_d(X_d, eta_{d+1})
```

NOT `M_{d+1} = M_d + 1`. A single sample cannot uniquely determine
L_d — the user is deriving it; a second consecutive sample or an
explicit local expansion rule is needed.

## 6. Current outputs (Stage 2)

| Output | Status |
|---|---|
| `R/gradient_emerge.R` | implemented (8 tests) |
| `R/sample_analysis.R` | implemented (9 tests) |
| `tests/testthat/test-gradient-emerge.R` | green |
| `tests/testthat/test-sample-analysis.R` | green |
| `man/gradient_emerge.Rd` | documented |
| `man/sample_analysis.Rd` | documented |
| Full suite | 421 tests / 0 failures (local) |
| R CMD check | Status: OK |
| CI | 5/5 platforms |

## 7. Next implementation gate (unchanged)

Do not implement `derive_dimension()` / `L_d` as a guessed generator.
The user is actively deriving the equation. When the derivation lands:

```text
derive_dimension(M_d, eta)   with partitions:
    forced_derivable
    emergent_eta
    unresolved
```

## 8. Open items (not fabricated)

- L_d local expansion rule (user deriving)
- second consecutive sample (needed to pin L_d)
- center-pair semantics beyond the 4x4 evidence
- irrational phase / continuous-position carrier
- residual-pool node capacities and conservation commit
- PAL <-> equation <-> Reservoir unification (Reservoir exists as a
  runnable experiment on a side branch; not yet unified with the
  sample equation — see external review 2026-08-09)
