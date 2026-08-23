# visualR Development Plan v0.7.0

> Status: **ACTIVE DRAFT — mainline convergence plan**
> Current implementation layer: **v0.6.2 `reference_experimental`**
> Frozen foundations: v0.5.0 runtime and v0.6.0 A–G discipline
> Scope: converge addressed topology, numerical observations, evidence
> gates, and validation without changing frozen semantics.

## 1. Mainline

The project now has one bounded mainline:

```text
PAL compact state
  -> explicit complete/open address window
  -> TCN-pattern symbolic dilated topology
  -> caller-bound numeric field
  -> lossless Cartesian/polar observations
  -> unitary spectral + address-aware gradient evidence
  -> robust reference review gate
  -> optional future supervised probability gate
  -> existing closure/package/transport lifecycle
```

The TCN repository contributes a compile discipline—fixed ordered
taps, exponential dilation, shape preservation, and same-address
residual identity. It does not contribute trained weights, PyTorch
runtime semantics, causal padding assumptions, or a probability model.

The consciousness-bus terminology remains an architecture and
preprocessing frame. It is not introduced as a hidden runtime, an
unmeasured objective, or a substitute for explicit field contracts.

### 1.1 Method convergence and rejection matrix

| Reference method | Integrated discipline | visualR boundary |
|---|---|---|
| Knuth attribute grammars | addresses, boundary state, hashes, units, and spacing are explicit attributes around syntax | attributes never become PAL tokens or change the frozen grammar |
| Huet zipper | an open PAL window is a focused path plus declared outer context | keep the specialized address window; do not introduce a general tree runtime |
| TCN residual/dilation compiler | fixed ordered taps, `2^level` dilation, two passes, same-address residual | symbolic topology only; no weights, causal-padding inference, or neural probability |
| Base R array/vector semantics | vectorized finite differences, multidimensional FFT, copy-on-write sharing | R is semantic authority; avoid hidden dense persistent fields |
| Registered C99 routine | accelerate the measured integer schedule hotspot after exact matrix equivalence | no C rewrite of PAL, spectrum, gradient, audit, or lifecycle logic |
| R `parallel` portability | deterministic, independently validatable batches; PSOCK-safe cross-platform posture | no nested/fork-only correctness and no scheduling-dependent result order |

This update deliberately does not add FFTW, GPU/CUDA, a new parser, or a
Java computation authority. Such changes require profiling evidence,
measured benefit on representative workloads, exact semantic equivalence,
and a separate compatibility decision.

## 2. Mathematical invariants

### I1. Address before value

Every value has exactly one stable address. PAL global addresses and
matrix row/column addresses cannot be silently reordered. Symbolic
tokens never acquire numerical meaning by position or glyph.

### I2. Boundary before operator

`closed` and `open` remain explicit. An FFT, gradient, convolution, or
future learned operator must declare its boundary interpretation.
Open outer content cannot become zero padding or periodic continuation
by default.

### I3. View does not replace source

Polar and spectral representations are observation views. They retain
a source hash and cannot redefine the authoritative address/value
field. Polar interpolation is forbidden until a sampling/reconstruction
contract exists.

### I4. Normalization is testable

Fourier transforms are unitary, so round-trip reconstruction and
Parseval energy equality are executable acceptance tests. Gradient
stencils and coordinate orientation are similarly declared.

### I5. Evidence is not probability

A robust deviation score is an audit signal. It becomes a probability
only through a separately versioned, target-labelled, leakage-safe and
independently calibrated supervised lifecycle.

## 3. Engineering workstreams

### W1 — Route governance and branch convergence

Goal: integrate without collapsing unrelated experiments.

- Keep the v0.6.1 topology compiler as its own reviewable base.
- Stack v0.6.2 numeric/spectral/bias work on that base.
- Do not merge the reservoir/runtime experiment wholesale; extract
  individual ideas only after contract and test review.
- Rebase after the topology compiler lands, then review the v0.6.2
  delta alone.
- Preserve R as semantic authority and C99 as an optional schedule
  accelerator under exact-equivalence tests.

Exit: clean dependency graph, no accidental frozen-file semantic
change, and one auditable diff per lifecycle decision.

### W2 — Address-bound numeric field

Delivered experimentally in v0.6.2:

- explicit value semantics and units;
- one finite numeric/complex value per address;
- visibility mask and boundary state;
- mapping-pack identity for PAL-backed fields;
- explicit signal provenance/cadence envelope;
- identity hash covering address/value/declarations.

Promotion evidence: property tests for order/round-trip identity,
cross-platform hashing evidence, malformed/stale object rejection, and
performance measurements on representative carrier sizes.

### W3 — Multi-timescale signal scheduling

Delivered experimentally in v0.6.2 as deterministic metadata routing:

- `static`, `fast`, `slow` cadence;
- `dense`, `sparse` route class;
- positive update intervals;
- no payload mixing.

Current M2 evidence includes deterministic scheduling-overhead measurement.
Next: define queue/backpressure behavior. Domain names such as
CNN/metabolic/immune remain caller
provenance, never inferred semantics.

### W4 — Polar and Fourier observation layer

Delivered experimentally:

- exact Cartesian-to-polar coordinates without resampling;
- separate geometric and topology centers;
- unitary path/carrier FFT plans;
- explicit `finite_window` versus `periodic` policy;
- direct weighted angular modes;
- source/address/shape stale-plan rejection.

M2 adds a deterministic property matrix over odd/even, rectangular,
singleton, open-window, periodic, and complex inputs, plus base-R FFT cost
evidence. Any radial transform,
interpolation, padding, or convolution theorem claim requires a new
contract.

### W5 — Gradient evidence

Delivered experimentally:

- central interior and one-sided carrier differences;
- global-address PAL path slopes;
- optional exact radial/tangential projections;
- no hidden extension beyond the observed boundary.

M2 declares positive non-unit coordinate spacing and stores the only current
masked-neighbour policy, `refuse`, in the observation contract and hash.
Do not promote until cross-platform analytic fixtures and benchmark artifacts
are reviewed; missing-region estimation still requires a separate policy.

### W6 — Bias threshold and project audit

Delivered experimentally:

- named structural evidence components;
- robust component-wise reference scaling;
- maximum-deviation aggregation;
- explicit `within_reference`/`review` action;
- feature-schema drift rejection;
- `probability = NULL` by contract.

Next: fit only on a versioned reference cohort, quantify threshold
stability with bootstrap intervals, report subgroup behavior, and
separate the threshold configuration from runtime objects.

### W7 — Supervised probability (blocked)

No probability estimator is in the v0.6.2 API. Work starts only after:

```text
target_definition
  -> labels + provenance
  -> leakage-safe temporal/entity split
  -> frozen feature schema
  -> model fit on training data
  -> independent calibration
  -> held-out discrimination + calibration report
  -> cost-based operating threshold
  -> drift/subgroup/abstention policy
  -> separate promotion review
```

The prediction output, if later approved, must include model/data
versions, horizon, calibrated probability, decision threshold,
abstention status, and component evidence. Gradient magnitudes or robust
scores must never be passed through a sigmoid and called probability.

## 4. Verification matrix

| Layer | Required invariant | Minimum executable evidence |
|---|---|---|
| PAL/window | address and boundary identity | parse/encode/shift tests |
| Dilated compiler | exact R/C tap schedule | equivalence tests by level |
| Numeric field | one value per stable address | order/hash/fail-closed tests |
| Signal routing | cadence without mixing | deterministic tick tests |
| Polar chart | no loss or resampling | address/value/center tests |
| Spectrum | unitary and explicit boundary | round-trip/Parseval/refusal tests |
| Gradient | declared stencil/orientation | constant/affine/path fixtures |
| Bias gate | robust and schema-locked | ordinary/extreme/drift fixtures |
| Probability | calibrated held-out target risk | currently blocked |

Cross-cutting release evidence:

- full `testthat` suite on Linux, Windows, and macOS;
- `R CMD check --as-cran` or documented platform-equivalent checks;
- source-derived test counts, never hand-estimated;
- benchmark record for memory, transform, gradient, and scheduling cost;
- documentation examples executed in a clean session;
- security review of deserialization and provenance strings;
- no lifecycle promotion bundled into an implementation pull request.

## 5. Project-entry audit

| Entry | Decision | Reason / condition |
|---|---|---|
| PAL and mapping-pack semantics | retain frozen | authoritative identity layer |
| v0.6.1 addressed topology compiler | retain experimental base | exact boundaries and residual addresses |
| Numeric field | implement/pilot | required bridge from symbols to math |
| Signal envelope/schedule | implement/pilot | route governance, no semantic inference |
| Polar chart | implement/pilot | exact coordinate view, no interpolation |
| Unitary FFT | implement/pilot | reversible, normalization testable |
| Angular modes | implement/pilot | explicit weights required |
| Address-aware gradient | implement/pilot | analytic fixtures available |
| Robust bias review gate | implement/pilot | evidence only, schema locked |
| Prediction probability | blocked | no target/labels/split/calibration supplied |
| Trainable TCN port | out of scope | reference is structural compiler only |
| Reservoir/runtime wholesale merge | rejected | unrelated semantics and merge conflict risk |
| Frozen promotion | separate review | implementation evidence is not promotion |

## 6. Milestones and gates

### M0 — v0.6.2 implementation candidate

Code, contracts, tests, examples, exports, and metadata complete.
Status stays `reference_experimental`.

### M1 — integration evidence

Topology base merged; v0.6.2 rebased; full cross-platform checks green;
review confirms no frozen semantic drift.

### M2 — numerical evidence hardening

Property tests, benchmark report, masked-gradient policy, non-unit
spacing, and spectral boundary cases complete. Code-level evidence is
implemented; cross-platform CI and generated benchmark artifacts remain the
integration gate before this milestone is accepted.

### M3 — reference cohort audit

Versioned cohort and threshold-stability/subgroup/drift reports complete.
This may promote only the evidence gate, not probability prediction.

### M4 — optional supervised proposal

Begins only when W7 prerequisites exist. It requires its own plan,
model card, pull request, and promotion decision.

## 7. Definition of done for this update

- All v0.6.2 APIs exported and manually documented.
- Numeric, signal, polar, spectral, gradient, and bias contracts covered
  by focused tests.
- Existing frozen semantics unchanged.
- README, DESCRIPTION, changelog, and this plan agree on scope/status.
- Available local/runtime validation is reported truthfully; missing
  toolchains or publication credentials are explicit blockers.
- No predicted probability and no promotion claim appear in code or
  documentation.
