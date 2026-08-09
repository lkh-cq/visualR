# visualR Development Plan v0.5.0

> Historical PAL-line baseline. The branch-level exploration mainline was
> superseded on 2026-08-09 by
> [`EXPLORATION_MAINLINE.md`](EXPLORATION_MAINLINE.md). This document remains
> authoritative only for reproducing and evaluating the earlier PAL milestone;
> it no longer excludes parallel computational hypotheses.
>
> Status: **FROZEN DEVELOPMENT PLAN**  
> Target milestone: **visualR v0.5.0**  
> Current package baseline when this plan was frozen: **v0.3.0**  
> Scope: core project direction, milestone boundaries, acceptance conditions, and deferred work.

---

## 1. Project mission

visualR exists to make computation possible under constrained memory, context, and transport conditions by reducing what must be stored, expanded, moved, and recomputed.

The frozen mainline is:

```text
Palindrome storage
    -> Jiugong expansion / operator state
    -> R-based CPU concurrent computation
    -> closure / fold-back
    -> complete package storage and transport
```

In Chinese:

```text
回文数据储存
    -> 九宫展开 / 算子状态
    -> R 语言基座 CPU 快速并发计算
    -> 闭合回收
    -> 完整打包储存 / 传输
```

The purpose is not to maximize model or hardware scale. The purpose is to reduce unnecessary materialization and data movement so that visualR can operate efficiently in limited RAM and limited context, while **avoiding VRAM/GPU dependency as a core requirement**.

---

## 2. Frozen project goals

visualR v0.5.0 has four primary goals.

### G1. Minimal authoritative storage

Canonical information is stored in PAL/palindromic form rather than as a permanently materialized matrix or field.

The storage layer should preserve only the independent information necessary to reconstruct the supported compute view.

### G2. On-demand compute expansion

Jiugong and other approved compute carriers are materialized only when computation requires them.

Matrices are compute states, not the default storage form.

### G3. CPU-first R runtime

R remains the authoritative semantic/reference implementation and the first complete runtime.

The runtime should exploit CPU concurrency where it is safe and deterministic, while keeping single-core behavior authoritative.

### G4. Closed-loop packaging and transport

After computation, legal results must be able to close, fold back into compact storage, and be packaged for persistence or transport without requiring the expanded working representation to remain resident.

The complete v0.5.0 value proposition is therefore:

```text
store less
-> expand less
-> move less
-> compute only what is active
-> fold back
-> transmit/store the compact result
```

---

## 3. Core architecture to v0.5.0

The project is organized around one closed pipeline rather than a collection of independent experimental features.

```text
[PAL compact state]
        |
        v
[Mapping Pack]
        |
        v
[Typed Jiugong / operator state]
        |
        v
[R CPU runtime]
        |
        v
[Closure + transition]
        |
        v
[Fold-back PAL]
        |
        v
[visualR package / transport unit]
```

Every major feature before v0.5.0 must strengthen this pipeline directly.

A feature that does not improve storage compactness, legal expansion, deterministic CPU computation, closure, packaging, transport, measurement, or verification is not part of the v0.5.0 critical path.

---

## 4. Milestone plan

### v0.3.x — semantic and lifecycle stabilization

Purpose: establish a trustworthy R package baseline before performance work.

Focus:

- PAL storage and grammar stability;
- strict Jiugong/type boundaries;
- mapping-pack authority and integrity;
- operator/closure/transition contracts;
- standard R package lifecycle;
- Linux / Windows / macOS CI diagnosis and stabilization;
- audit protocol and reproducible evidence.

Exit condition: the package has one unambiguous semantic path and one reproducible package/runtime lifecycle.

### v0.4.x — compact-runtime and concurrency proof

Purpose: prove that the architecture saves work before adding broader features.

Focus:

- reduce unnecessary materialization;
- prefer lazy/local access where possible;
- establish serial reference behavior;
- establish deterministic CPU concurrency;
- quantify memory, transport, and runtime costs;
- define a stable compact package/transport representation;
- benchmark compact-state workflows against expanded-state workflows.

Exit condition: visualR can demonstrate measurable benefit in at least the following dimensions:

```text
stored bytes
transferred bytes
peak RAM
materialized working set
single-core latency
CPU concurrent throughput
```

The benchmark must show where visualR wins, where it does not, and the cost of encoding/decoding/folding.

### v0.5.0 — closed packaged CPU runtime

Purpose: deliver the first complete end-to-end visualR runtime.

Required end-to-end path:

```text
PAL input
-> validate
-> resolve mapping pack
-> materialize approved Jiugong/operator state
-> execute on CPU
-> closure / transition decision
-> fold-back when legal
-> package
-> reload
-> reproduce the same canonical state
```

v0.5.0 is reached only when this full loop is stable, measured, auditable, and packageable.

---

## 5. R is the authoritative first implementation

Before v0.5.0, R has four roles:

1. authoritative PAL and mapping semantics;
2. reference implementation of compute operators;
3. CPU execution and concurrency benchmark;
4. package validation, testing, and reproducibility environment.

Native code is allowed only after profiling identifies a real CPU hotspot.

C/C++ may later accelerate isolated kernels, but it must not redefine visualR semantics.

The rule is:

```text
R defines correctness
-> benchmark identifies bottleneck
-> native code accelerates the proven bottleneck
```

Not:

```text
rewrite first
-> decide semantics later
```

---

## 6. Concurrency contract

Concurrency is an execution optimization, not a semantic fork.

The authoritative rule is:

```text
Result(single-core) == Result(supported multi-core mode)
```

where the platform actually supports the selected execution mode.

A platform-specific serial fallback must be reported as a fallback, not as proof that a true multi-core path was exercised.

Before v0.5.0, concurrency work must prioritize:

- deterministic results;
- stable ordering;
- explicit worker/fallback reporting;
- no hidden shared-state mutation;
- reproducible fresh-process runtime behavior.

---

## 7. Packaging and transport direction

The final compact storage/transport unit should not be permanently tied to an R-only serialization format.

The v0.5.0 target is a visualR-owned package contract containing, at minimum, the information required to reconstruct and verify the canonical state.

Conceptually:

```text
visualR package
├── format/version header
├── PAL canonical state
├── mapping-pack identity/version/integrity
├── operator or compute-state metadata when required
├── payload or payload references
├── provenance
└── integrity/checksum data
```

R is the first implementation of this contract.

The package format should leave room for future readers in Java/JVM, C/C++, or other runtimes without making those runtimes authoritative over PAL semantics.

---

## 8. Java/JVM reserve plan

Java/JVM is a **post-core runtime reserve**, not part of the v0.5.0 semantic critical path.

Its intended future role is orchestration around visualR rather than replacement of R.

Possible responsibilities:

```text
Java/JVM
├── long-lived service runtime
├── task scheduling
├── worker/process orchestration
├── network transport
├── cache management
└── package routing

R workers
├── PAL semantics
├── Jiugong/operator materialization
├── CPU computation
├── closure
└── fold-back
```

The intended interaction model is:

```text
Java/JVM scheduler
        |
        +--> R worker
        +--> R worker
        +--> R worker
```

rather than uncontrolled concurrent Java threads entering one shared R interpreter.

A future Java layer is valuable only if the R-based compact compute loop is already proven.

---

## 9. Explicit non-goals before v0.5.0

The following are deferred unless they become necessary to complete the frozen mainline:

- GPU/CUDA/VRAM-backed core execution;
- distributed-cluster runtime;
- Java replacing the R semantic core;
- broad domain semantics such as sanyuan-specific ontology;
- full UI/Unity/desktop shell;
- generalized global field materialization;
- full phase/temporal theory;
- large multi-singularity routing system;
- speculative complex carriers that do not improve the core loop;
- performance rewrites without benchmark evidence.

These may become later modules, but they must not delay the v0.5.0 closed runtime.

---

## 10. v0.5.0 acceptance gates

A release candidate for v0.5.0 must pass all of the following gates.

### Semantic gate

- PAL remains canonical storage;
- supported expansion/fold-back is reversible;
- mapping-pack authority is enforced;
- Jiugong/operator types are explicit;
- illegal/non-closed states cannot silently become canonical storage.

### Runtime gate

- CPU-only execution is sufficient for the normative implementation;
- single-core reference execution is deterministic;
- supported concurrent execution is deterministic relative to the reference;
- fresh installed-package runtime works outside the source/check environment.

### Efficiency gate

The project must publish reproducible measurements for:

- compact stored size;
- expanded working-set size;
- transfer size;
- peak RAM;
- encoding/expansion/fold overhead;
- serial execution latency;
- concurrent throughput.

No optimization claim is accepted without measurement.

### Packaging gate

- canonical state can be packaged;
- package integrity/version can be checked;
- package can be reloaded into a fresh process;
- reloaded canonical state is equivalent to the original legal state;
- the package contract does not require GPU state or GPU memory.

### Engineering gate

- R package metadata is aligned;
- tests use the standard package lifecycle;
- CI evidence distinguishes Windows/macOS/Linux behavior correctly;
- failures are diagnosed by lifecycle boundary rather than hidden by broad skips;
- AUDIT.md red-line checks are satisfied for the release candidate.

---

## 11. Success criterion

visualR v0.5.0 is successful if it demonstrates this complete behavior:

```text
A compact PAL state can be stored and transmitted cheaply,
expanded only when an operator needs a compute view,
computed deterministically on CPU through the R runtime,
closed and folded back into compact canonical storage,
packaged and reloaded without preserving the expanded working state.
```

The project does not need GPU memory to satisfy this criterion.

The central engineering question for every pre-v0.5.0 change is therefore:

> Does this change make the compact-storage -> local-compute -> CPU-runtime -> compact-package loop more correct, smaller, faster, more deterministic, or more transferable?

If not, it is not on the critical path.

---

## 12. Frozen one-line roadmap

```text
v0.3.x  stabilize semantics + package lifecycle
   ->
v0.4.x  prove compactness + CPU deterministic concurrency + transport efficiency
   ->
v0.5.0  deliver the closed, packaged, CPU-native visualR runtime
   ->
post-0.5  JVM orchestration / native hotspots / broader topology systems
```

This document is the authoritative development-plan baseline for the v0.5.0 milestone until explicitly superseded by a later versioned plan.
