# visualR

`visualR` is an experimental R runtime for topology-first visual and symbolic computation.

Its root contract is:

> Palindromic syntax stores topology; matrices materialize computation.

The project separates four layers:

1. **PAL storage syntax** — stores the independent outer-to-inner chain and one singular center.
2. **Field view** — generates a minimal Manhattan-distance diamond around a singularity.
3. **Jiugong operator view** — materializes local 3 x 3 compute kernels on demand.
4. **Mapping pack** — defines the only authoritative mapping between storage addresses and compute coordinates.

## Status

This repository is an early executable prototype. It does not yet implement a language model, prove acceleration, or claim a biological mechanism.

## Canonical object

```r
x <- pal_state(
  shells = c("A", "B", "C", "D"),
  core = "E"
)
```

Canonical storage form:

```text
{A{B{C{D{E}D}C}B}A}
```

Logical unfolded path:

```text
A B C D E D C B A
```

Jiugong compute view:

```text
A B C
D E D
C B A
```

Minimal diamond field:

```text
        A
      A B A
    A B C B A
  A B C D C B A
A B C D E D C B A
  A B C D C B A
    A B C B A
      A B A
        A
```

## Design constraints

- The palindrome is the canonical storage representation.
- Matrix, field, and tensor forms are derived compute views.
- Return paths are generated and are not duplicated in canonical storage.
- R uses one-based complementary addressing: `mirror(i, L) = L + 1 - i`.
- A Jiugong view is valid only when the unfolded path has length 9.
- All compute views must pass closure checks before folding back to storage.
- Phase and conflict semantics remain versioned experimental mapping rules.
- No global `O(1)` performance claim is made; only fixed local address transforms are constant-cost.

## Initial package layout

```text
visualR/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── pal-core.R
│   ├── field-diamond.R
│   ├── jiugong.R
│   └── constraints.R
├── inst/mapping-packs/
│   └── visualr-profile-v0.1.json
└── tests/testthat/
    └── test-core.R
```

## Quick start

```r
source("R/pal-core.R")
source("R/field-diamond.R")
source("R/jiugong.R")
source("R/constraints.R")

x <- pal_state(c("A", "B", "C", "D"), "E")
encode_pal(x)
unfold_pal(x)
as_jiugong(x)
as_diamond(x)
validate_visualr(x)
```

## Roadmap

The next milestones are a frozen phase schedule, provenance-aware conflict states, multi-singularity routing, `Matrix`/`igraph` integration, and an optional R `torch` backend.
