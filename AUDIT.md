# visualR Project Audit Protocol

> **Purpose**: project-specific audit logic for `visualR`.
>
> This document is not a generic R-package checklist. It audits whether the implementation still obeys visualR's own topology-storage, mapping-pack, compute-emergence, closure, carrier, concurrency, and lifecycle contracts.
>
> Initial calibration baseline: `main@296f5478bf89ffea8879919dcc0fc93d34dc0032`, package version `0.2.2`, 2026-08-07.

---

## 0. Core audit model

Every audit item MUST be split into five independent parts:

```text
Boundary -> Contract -> Implementation -> Evidence -> Ruling
   B          C              I            E          R
```

The auditor MUST NOT collapse these parts into one statement.

- **Boundary**: what part of visualR is being audited, and what is explicitly outside scope.
- **Contract**: the frozen or declared rule that the code is expected to obey.
- **Implementation**: the actual path in code, including all adapters, registries, fallbacks, and runtime lifecycle steps.
- **Evidence**: source code, tests, CI logs, runtime probes, package metadata, or reproducible outputs.
- **Ruling**: pass / conditional pass / unverified / fail, with severity and required action.

A claim without evidence is **UNVERIFIED**, not PASS.

A commit message, README sentence, test count, benchmark claim, or prior chat conclusion is evidence of intent only; it is never sufficient proof of runtime correctness by itself.

---

## 1. visualR root contracts that auditing must protect

### 1.1 PAL storage is authoritative

The canonical topology is the palindrome-addressed storage object, not a matrix rendering.

For an order-`n` state:

```text
S_n = {x0{x1{...{x(n-1){xn}x(n-1)}...}x1}x0}
```

Its unfolded path is:

```text
U(S_n) = (x0, x1, ..., xn, ..., x1, x0)
```

Audit consequence:

- matrices are compute/materialized views;
- a matrix MUST NOT silently become the source of truth;
- storage write-back is only legal after the compute state satisfies the relevant closure/foldability contract;
- the independent state is the outer-to-inner chain plus one singular center; the reflected half is derived, not independently authoritative.

Minimum invariants to preserve where applicable:

```text
fold(unfold(x)) = x
parse(format(x)) = x
C(C(x)) = x
mirror(mirror(addr)) = addr
```

If a new representation cannot demonstrate a reversible mapping to authoritative storage, it must be classified as a transient/projection view rather than canonical state.

### 1.2 Mapping pack is the mapping authority

The mapping pack is not metadata. It is dependency-injected runtime authority for the storage <-> computation bridge.

Audit rules:

- unknown mapping-pack IDs must fail closed;
- tampered or hash-mismatched packs must fail closed;
- any rule surface declared to belong to a pack must be read from the resolved pack, not duplicated in hidden globals;
- a silent fallback to a default pack is a root-contract violation;
- a custom pack must change behavior only through its declared rule surface;
- pack identity/version/hash must be part of provenance when a result depends on pack semantics.

Operator-local algorithms are allowed only when they are explicitly part of the operator specification. Addressing, complement, carrier, Gamma, transform, or closure semantics must not be re-invented inside an operator if the mapping pack claims authority over them.

### 1.3 Jiugong is a typed compute carrier, not a synonym for any square matrix

Current frozen meaning:

```text
S_4 -> unfold length 9 -> 3 x 3 Jiugong
```

General perfect-square projections belong to a general square-view API, not to `pal_to_jiugong()`.

Audit consequence:

- `pal_to_jiugong()` must remain strict about the S_4/3x3 contract;
- a 1x1, 5x5, 11x11, or arbitrary square view must not be relabeled as Jiugong merely because it is square;
- non-3x3 carriers must not enter a 3x3 operator ABI unless a distinct typed operator contract is implemented.

### 1.4 Compute and storage commit are separated by closure

The compute path is conceptually:

```text
PAL storage
   -> resolve mapping pack
   -> materialize typed compute carrier
   -> apply operator from a stable snapshot
   -> closure_check()
   -> transition_policy()
   -> fold/promote only if legal
```

`closure_check()` answers a structural fact. `transition_policy()` answers a scheduling/action decision. Auditing must keep these two meanings separate.

A structurally non-closed state is not allowed to be written back merely because a policy chooses to continue computing it.

### 1.5 Snapshot-commit semantics are part of operator correctness

A 3x3 emergence operator reads one stable input snapshot and commits one complete output. Mutation order must not affect the result.

Required audit question:

```text
Would a different cell traversal order change the result?
```

If yes, the implementation is not snapshot-commit and must be treated as a semantic defect unless the operator specification explicitly defines ordered mutation.

### 1.6 Experimental rules must remain visibly experimental

Current visualR development contains fitted/candidate semantics, including carrier/Gamma/transition behaviors and future phase/temporal rules.

Audit rule:

- do not promote an experimental rule to a frozen axiom through comments, naming, tests, or README wording alone;
- tests for an experimental rule prove implementation stability, not theoretical truth;
- a frozen contract change requires an explicit versioned specification change and migration impact review.

---

## 2. Project-specific audit order

A visualR audit SHOULD run in the following order. Do not start from line-by-line style review.

### A0. Freeze the audit baseline

Record:

```text
repository
base commit
head commit
package version
mapping-pack version/id if relevant
R version + OS
CI run or local check evidence
changed files
```

Never audit a moving branch without recording the exact commit being ruled on.

### A1. Audit the authority path before implementation details

For every changed feature, identify:

```text
canonical input
-> authoritative storage object
-> mapping pack resolution
-> compute view/carrier
-> operator or field rule
-> closure / transition
-> canonical output or transient result
```

A new shortcut is suspicious if it skips an authority boundary.

Typical red flags:

```text
matrix -> direct persistence
unknown pack -> default pack
compute result -> PAL without closure
11x11 view -> 3x3 operator
projection metadata -> treated as canonical state
```

### A2. Audit storage and grammar invariants

Check at minimum:

- constructor and validator agree on the legal token/state domain;
- format/parse round-trips are deterministic;
- parsing never evaluates user-provided R code;
- unfold/fold is reversible for supported states;
- center singularity is singular and not duplicated as independent state;
- complement/mirror is derived consistently;
- invalid input fails before entering compute logic.

Security note: parser convenience MUST NOT reintroduce `eval(parse(...))`, unsafe deserialization, or equivalent arbitrary-code execution paths.

### A3. Audit mapping-pack integrity and dependency injection

Trace every semantic mapping used by the changed path.

For each mapping, answer:

```text
Where is the rule defined?
Which pack field owns it?
Is the pack resolved before use?
Is integrity asserted at resolve/use time?
Can a global/default constant override the pack?
Can a mutated pack preserve the same identity/hash?
```

Fail closed is mandatory at pack-boundary uncertainty.

### A4. Audit typed carrier boundaries

Classify each materialized object as one of:

```text
canonical storage
3x3 compute carrier
non-3x3 view/carrier
field lookup
transient compute state
```

Then verify that the consumer accepts that type/shape intentionally.

Specific checks:

- S_4 Jiugong remains 3x3;
- general square view remains distinct from Jiugong;
- `carrier_11x11` remains a view unless/until an explicit 11x11 operator ABI exists;
- `diamond_at()` style lazy access must not require full field materialization merely to answer one coordinate;
- coordinate domains must reject NA, non-finite, non-scalar, and non-integer-like offsets when integer topology is required.

### A5. Audit compute operator ABI

For every registered operator:

```text
input shape/type
accepted arguments
mapping-pack access
snapshot behavior
output shape/type
failure behavior
```

The registration-time probe and call-time validation are complementary; neither replaces the other.

New code must not rely on a custom operator merely having the right function name or argument count.

### A6. Audit closure fact separately from transition policy

This is a visualR-specific semantic checkpoint.

Required questions:

```text
Is the grid symbolically legal?
Is the symmetry/complement relation satisfied?
Can it fold and re-expand identically?
What action does policy choose for a non-closed state?
Does that action preserve the fact that the state is non-closed?
```

Important compatibility hazard:

`closure_jiugong()` is a legacy three-way adapter. In the current implementation, `transition_policy() == "reject"` is mapped back to legacy `"transient"`. Therefore **new scheduling code should not use `closure_jiugong()` when it needs to distinguish illegal/rejected states**. Audit all new uses of this compatibility function carefully.

### A7. Audit field/Gamma/peel semantics without conflating levels

visualR uses several centers/levels that must remain distinct:

```text
PAL storage center singularity
local 3x3 compute center
global field center
local operator order
recursive/emergent level
```

Do not infer that equal symbols at different positions or levels are the same state.

For diamond/minimal-information fields:

```text
order = n - (|x| + |y|)
```

where valid. The field is a path/order carrier; it must not be mistaken for the full atlas of all local Jiugong operators.

Peel/Gamma rules should be auditable as generators rather than requiring every derived matrix to be stored independently.

### A8. Audit concurrency as semantics, not only speed

The core invariant is deterministic equivalence of supported execution modes:

```text
Result(serial) = Result(parallel)
```

But result equality alone is insufficient evidence that a parallel path was actually exercised.

A concurrency audit must also verify:

```text
requested execution mode
actual execution mode / worker count
OS-specific fallback behavior
result ordering
provenance ordering
error propagation
shared mutable state / registry interaction
```

On platforms that intentionally fall back to serial execution, test the fallback contract explicitly; do not report it as proof of true N-core execution.

For stress tests, vary input order and worker count. A stable result that changes only when scheduling changes indicates hidden state or non-snapshot behavior.

### A9. Audit the R package lifecycle and CI lifecycle

For package-level evidence, the canonical lifecycle is:

```text
checkout source
-> install dependencies
-> R CMD build
-> R CMD check built tarball
-> R CMD INSTALL built tarball
-> start a fresh R process
-> library(visualR)
-> runtime/concurrency invariant probes
```

The audit must distinguish:

```text
source tree exists
package namespace is loadable
package is installed in current .libPaths()
package is installed only in an R CMD check temporary library
```

Do not classify a downstream CI step as failed if it was skipped because an earlier step failed.

Cross-platform shell rules are part of lifecycle correctness. A command that works under Bash but is parsed differently by PowerShell is a CI-interface defect, not an R-runtime defect.

The standard `tests/testthat.R` entry and `R CMD check` should remain the primary package test path. Avoid inventing a second, semantically different test lifecycle unless it is intentionally testing a different environment.

### A10. Audit release/documentation evidence

Check consistency among:

```text
DESCRIPTION version
README status/version text
NAMESPACE exports
man/ documentation
mapping-pack version/id
CI claims
release/tag claims
reported test counts
```

A documentation drift does not necessarily break runtime behavior, but it weakens auditability and can create false evidence. Treat stale counts/version statements as an audit issue rather than using them as proof.

---

## 3. Evidence grading

Use the strongest applicable evidence level; do not average weak evidence into a strong conclusion.

| Grade | Evidence | Meaning |
|---|---|---|
| **E4** | reproducible runtime + relevant tests + CI/platform evidence | strong operational evidence |
| **E3** | executable tests + inspected implementation | strong implementation evidence, environment not fully proven |
| **E2** | inspected implementation only | static evidence |
| **E1** | README, comments, commit messages, design notes | intent/documentation evidence |
| **E0** | unsupported claim | no audit evidence |

If the contract itself is not frozen or is ambiguous, the maximum ruling is **CONDITIONAL / UNVERIFIED**, regardless of test count.

---

## 4. Severity scale

This audit uses `S0-S3` to avoid confusion with implementation priority labels such as P0/P1.

| Severity | Meaning | Typical visualR example |
|---|---|---|
| **S0 Critical** | root-contract, security, or canonical-state corruption | unsafe parser execution; silent pack fallback; non-closed state written as canonical PAL |
| **S1 Major** | public ABI, determinism, lifecycle, or reproducibility defect | wrong carrier enters operator; concurrency order dependence; CI proves fallback but claims parallel execution |
| **S2 Moderate** | auditability, provenance, or documentation drift | README version/test count disagrees with package metadata |
| **S3 Note** | maintainability/performance/style concern without semantic break | duplicated helper, avoidable materialization, naming cleanup |

A clean `R CMD check` does not automatically downgrade an S0/S1 semantic defect.

---

## 5. Required red-line checks

Before a change is accepted, explicitly rule on these red lines:

1. **Authority inversion** — did any matrix/view become canonical state without reversible PAL mapping?
2. **Mapping-pack bypass** — did a pack-governed rule move into a hidden/global fallback?
3. **Silent fallback** — can unknown/tampered pack, carrier, operator, or invalid state continue silently?
4. **Illegal write-back** — can a transient/rejected/non-closed compute state be folded into canonical storage?
5. **Type/shape confusion** — is Jiugong generalized beyond S_4/3x3, or is a view passed into the wrong ABI?
6. **Experimental laundering** — is a fitted/candidate rule being presented as frozen theory?
7. **Unsafe parsing/state admission** — can untrusted text execute code or bypass the token/state validator?
8. **Concurrency non-determinism** — can scheduling, worker count, traversal order, or mutable registry state change results?
9. **Lifecycle misdiagnosis** — is a package-install/shell/CI-step problem being reported as a runtime algorithm defect?
10. **Evidence drift** — do version, test-count, export, mapping-pack, and README claims agree with the audited commit?

Any unresolved red line prevents an unconditional PASS.

---

## 6. Audit report format

Every project audit should use this table or an equivalent machine-readable structure:

| ID | Layer | Contract | Observed implementation | Evidence | Severity | Ruling | Required action |
|---|---|---|---|---|---|---|---|
| A-001 | mapping pack | unknown pack fails closed | ... | file/test/CI | S0-S3 | PASS/FAIL/UNVERIFIED | ... |

Rules for writing findings:

- state what was actually observed before interpreting it;
- cite exact file/function/test/run/commit where possible;
- separate "not implemented" from "implemented incorrectly";
- separate "not proven" from "failed";
- do not fill missing evidence with an expected answer;
- one finding should describe one violated or unproven contract.

---

## 7. Current baseline calibration notes (2026-08-07)

These notes are snapshot-specific and should not be treated as permanent facts after `main` changes.

### 7.1 Confirmed from current files

- `DESCRIPTION` declares package version `0.2.2` and describes mapping-pack fail-closed behavior, typed carrier dispatch, strict S_4 Jiugong, operator ABI checks, and CI coverage.
- `tests/testthat.R` uses the standard package lifecycle: `library(testthat)`, `library(visualR)`, `test_check("visualR")`.
- `.github/workflows/ci.yml` currently builds and checks the package, installs the built tarball, then starts a fresh `Rscript` process for the concurrency invariant.
- `R/closure.R` separates `closure_check()` from `transition_policy()` and validates operator shape/type at registration/call boundaries.

### 7.2 Audit drift already visible

At this baseline, README status text still presents `v0.2.1` as the latest named status item and reports `783 tests`, while `DESCRIPTION` is `0.2.2`; a v0.2.2 implementation commit message reports `811 tests`.

Ruling:

```text
Severity: S2
Reason: documentation/evidence drift
Action: do not use the README test count as acceptance evidence; update documentation from an executable/source-derived count when the next release documentation pass is performed.
```

This mismatch is intentionally recorded here as an example of the audit rule: **claims, implementation, and evidence must remain separate**.

### 7.3 Compatibility hazard to keep under audit

`closure_jiugong()` preserves a legacy three-state interface and maps a modern `reject` policy result to legacy `transient`. This is acceptable only as compatibility behavior. New scheduling logic that needs to distinguish illegal state must call the separated fact/policy APIs instead.

### 7.4 Concurrency evidence must prove execution mode

The current CI compares serial and requested-N-core results. Future hardening should also assert/record the actual execution mode or worker count so that Windows/other fallback behavior cannot be misreported as true multicore execution.

---

## 8. Reserved audit guards for planned visualR layers

The following are **pre-implementation guards**, not claims that these features are already frozen or complete.

### 8.1 Rotation measure / phase schedule

Until a six-stage geometric rotation group is formally proven/frozen, code may expose `rotation_measure` while internal semantics remain a phase/schedule concept.

Audit guard:

- do not encode geometric claims stronger than the specification;
- phase/address assignment must be deterministic and versioned;
- a phase change that affects equality must appear in provenance.

### 8.2 Equal-value / unequal-position conflict

Equal symbols do not imply equal state when position, phase, role, time, or source operator differs.

Future state comparisons should be prepared to distinguish at least:

```text
symbol
shell/order
phase or rotation_measure
Jiugong role/address
time phase
source operator
provenance
```

Audit guard: never deduplicate solely by symbol value if the specification defines positional/temporal identity.

### 8.3 Temporal emergence step

A conflict-triggered time step must be audited as a state transition, not as duplicate deletion or string cleanup.

Required future properties:

```text
snapshot order independence
deterministic conflict resolution
provenance preservation
explicit old -> new phase relation
```

### 8.4 Multi-singularity common-optimum routing

For the planned shortest-path reverse-set method:

- shortest-path tables may be built offline/deep-sleep;
- invocation-time routing should use precomputed indices rather than silently rerun Dijkstra;
- candidate coverage, compatibility, and closure constraints must be explicit;
- tie-breaking must be deterministic;
- routing chooses where active singularities converge; it must not decide which singularities are semantically active.

Suggested audit objective for a common optimum `v`:

```text
minimize lexicographically:
(max_i d(s_i, v), sum_i d(s_i, v), topology_loss(v))
```

The exact objective remains versioned specification material until frozen.

### 8.5 Domain analogies

DNA/base/docking analogies are explanatory mappings, not core visualR type definitions unless a separate versioned domain mapping pack formalizes them.

Audit guard: analogy must never silently redefine PAL order, singularity, corner, Jiugong role, or carrier semantics.

---

## 9. Minimal acceptance gate for future changes

A change is ready for acceptance only when all applicable statements below are true:

```text
[ ] Baseline commit and scope are recorded.
[ ] Root contract affected by the change is identified.
[ ] Canonical storage authority is preserved.
[ ] Mapping-pack authority is preserved or explicitly version-changed.
[ ] Input/state domains fail closed.
[ ] Carrier/operator types and shapes are explicit.
[ ] Compute result cannot bypass closure before canonical write-back.
[ ] Snapshot/determinism properties are tested where applicable.
[ ] Serial/parallel/fallback execution semantics are distinguished.
[ ] R CMD build/check/install/runtime lifecycle is valid on relevant platforms.
[ ] Experimental semantics are labeled as experimental.
[ ] Documentation/version/export/test claims match the audited evidence.
[ ] Every remaining uncertainty is recorded as UNVERIFIED rather than silently passed.
```

---

## 10. One-sentence audit principle

> **visualR auditing does not ask only whether the code runs; it asks whether every runtime result can be traced from canonical PAL storage through the declared mapping authority and typed compute path, closed or rejected explicitly, and supported by reproducible evidence without semantic or lifecycle substitution.**
