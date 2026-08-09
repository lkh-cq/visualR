# Equation Core Stage 1 — Audit and Implementation Record

> Date: 2026-08-09
> Status: stage-1 probe implemented; generative equation G_d not frozen
> Authority: user original definitions + sanyuan-runtime source documents

## 1. Global purpose

visualR's next phase is not another state-container extension. The target is an equation core that can distinguish:

```text
PAL storage index s
carrier/expansion index d
recursive re-type layer r
runtime operator step t
```

The development order is:

```text
source samples → separate series → gradient structure → derivation/error
→ language/backend boundaries → concurrency feasibility
→ topology-complete equation kernel
```

## 2. Source and constraints

Verified source anchors:

- `/mnt/d/sanyuan-runtime/README.md`: PAL length `|U(S_n)| = 2n+1`, S4/3x3 mapping, Φ/Γ separation, peel-chain completeness.
- `/mnt/d/hermes_memory/archive/visualR_next_phase_equation_core_outline_20260809.md`: user-defined stage outline and candidate sequences.
- Existing visualR R code: PAL parser/formatter, Φ/Γ-related operators, recursive containers, lane execution.

No complete original 4x4/5x5 source file was found in the audited sanyuan-runtime README or visualR package tree during this pass. The 4x4 sample supplied in the discussion remains an evidence anchor, not an invented generated result.

Hard constraints:

- Letters are display symbols, not the ontology.
- 3x3 is a local operator observation/projection, not the whole topology.
- Higher-dimensional and irrational information must not be forced into A-Z token labels.
- Odd/even carrier geometry must be represented separately.
- Unknown dimensions must not be filled with guessed ground truth.
- Structural invariants are preferred over copied precedent-value assertions.

## 3. Candidate series implemented

`R/equation_core.R::dimension_series()` exposes, but does not freeze:

```text
L_s = 2s + 1
W_d = d + 2
Q_d = W_d + d = 2d + 2
```

It reports PAL length, carrier width, step count, area, and adjacent differences as separate tables. The old-draft continuation `6+4=10` is explicitly recorded as non-frozen.

## 4. Gradient and parity implementation

`gradient_lattice(width)` generates coordinate metadata only:

- row/column coordinates;
- Manhattan gradient to the nearest geometric center set;
- odd single-center mode;
- even center-set mode;
- parity and width metadata.

It does not assign symbolic values. It therefore cannot be mistaken for a generated 5x5/6x6 answer.

`audit_dimension_sample()` records shape/parity/gradient facts while preserving `values_uninterpreted = TRUE`.

## 5. Error and residual calculation

`gradient_residual(observed, predicted, weights = NULL)` reports:

- element-wise residual;
- maximum absolute error;
- mean absolute error;
- L1 and L2 error;
- optional weighted L1;
- exact input dimensions.

This is an error instrument for a future candidate `G_d`, not a replacement for the missing equation.

## 6. Language, authority, and responsibility

- R remains the semantic/reference language.
- C is a future execution-fabric backend and must not redefine the equation.
- Java is the later formal runtime/service implementation, sharing the same frozen contracts.
- User original definitions outrank existing code and GPT/Agent extrapolations.
- Existing topology containers serve the equation; they do not define the equation.

## 7. Dependencies and compatibility

Verified package state:

- `parallel` is the only required imported runtime dependency.
- `testthat`, `pkgload`, `openssl`, `RSQLite`, `DBI`, `knitr`, and `rmarkdown` remain optional suggestions.
- Equation-core probes use base R/data.frame/matrix operations only.
- No I/O, shell, OS-specific path, GPU, C, or Java dependency was introduced.
- The implementation is portable at the R semantic layer.

## 8. Concurrency feasibility

Measured contracts:

```text
S4: serial lane result == PSOCK lane result
S5: serial lane result == PSOCK lane result
```

Observed worker counts:

```text
S4: 5 lanes (four orbit lanes + singularity lane)
S5: 6 lanes (five orbit lanes + singularity lane)
```

The concurrent layer uses one snapshot, independent lane reads, a barrier, then reconciliation/commit. The current equation-core stage does not yet implement node-capacity allocation or residual conservation; those belong after `G_d`/`D_d` semantics are grounded.

## 9. Topology completeness audit

Already represented in source/runtime:

- PAL storage versus matrix/projection separation;
- Φ versus Γ projection separation;
- odd/even geometry probe;
- S1-S5 dynamic orbit preservation in the current branch;
- serial/PSOCK semantic equivalence;
- explicit residual/error instrumentation.

Still incomplete and deliberately not fabricated:

- original 4x4/5x5 evidence files and provenance;
- a general `G_d` generation equation;
- a general `D_(d+1)` inverse/decomposition equation;
- explicit `η_(d+1)` emergence representation;
- center-pair semantics for the supplied even 4x4 sample;
- irrational phase/continuous-position carrier;
- residual-pool node capacities and conservation commit;
- proof that a candidate equation generalizes beyond supplied samples.

## 10. Current outputs

| Output | Status |
|---|---|
| `R/equation_core.R` | implemented |
| `tests/testthat/test-equation-core.R` | 10 tests, passed locally |
| `man/equation_core.Rd` | documented |
| `inst/EQUATION_CORE_STAGE1.md` | this record |

## 11. Next implementation gate

Do not implement `derive_dimension()` as a guessed matrix generator yet. First recover or receive the original 3x3/4x4/5x5 sample provenance, then implement:

```text
derive_dimension(M_d, eta)
project_dimension(M_(d+1))
```

with output partitions:

```text
forced_derivable
emergent_eta
unresolved
```

Only after that gate may a candidate 6x6 be generated.
