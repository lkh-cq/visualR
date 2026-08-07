# PAL Nested-Logic Contract — Language-Independent Specification

> **Status**: v0.4.x C1 — semantic-alignment reserve (draft for freeze)
> **Date**: 2026-08-07
> **Authority**: R implementation (`R/grammar.R`, `R/format_pal.R`, `R/validate_pal.R`) is the SEMANTIC AUTHORITY. Python (`mapping_pack.py`) is a cross-validation reference. This document is a LANGUAGE-INDEPENDENT porting contract — it does NOT create a new authority.
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §7 (packaging "leave room for future readers"), §8 (Java/JVM reserve), §10 (semantic gate).

---

## 1. Purpose

Any future runtime (Java/JVM, C/C++, other) that reads a visualR package must reproduce the nested palindrome semantics EXACTLY, or it will silently diverge from the R authority. This contract states, in language-independent terms, the semantics a reader MUST implement. It is the portable target for cross-language porting.

## 2. The palindrome grammar (frozen)

```
S_n = {x_0 {x_1 { ... { x_{n-1} { x_n } x_{n-1} } ... } x_1 } x_0 }
```

- `x_0 ... x_n` are **symbols** (tokens).
- A symbol is a non-empty, UTF-8 string that contains NO brace (`{`,`}`) characters.
- `n >= 0` is the nesting depth. `n = 0` is the leaf `{x_0}`.
- Example: `{A{B{C{D{e}D}C}B}A}` → path `[A, B, C, D, e, D, C, B, A]`, depth 4, core `e`.

## 3. Parse contract (text → path)

A conforming parser MUST satisfy:

1. **Outer wrapper**: input must start with `{` and end with `}`.
2. **Recursive descent**: parse a node = consume `{`, read symbol until `{` or `}`, then:
   - if next is `{`: recurse into inner node, then the symbol MUST appear again (the closing symmetric half), then `}`.
   - if next is `}`: this is the leaf (center singularity); consume `}`.
3. **Length-aware symbol comparison**: the closing symbol MUST be compared to the opening symbol as a **full-length token equal**, NOT single-character. This is the multi-character-symbol rule.
4. **Complete consumption**: after the top-level parse, all input MUST be consumed (no trailing characters).
5. **Depth cap**: nesting depth MUST NOT exceed `MAX_SHELLS = 64`.

### 3.1 Multi-character symbol rule (critical)

Symbols are arbitrary-length tokens. A parser MUST compare the complete closing symbol slice against the opening symbol, and advance the cursor by the FULL symbol length. A naive single-character compare is WRONG and will reject valid multi-char inputs (this was a real bug in the Python reference, fixed 2026-08-07).

Valid: `{AB{C}AB}` → path `[AB, C, AB]`, depth 1, core `C`.
INVALID single-char compare: would reject `{AB{C}AB}`.

### 3.2 UTF-8 safety

Symbols may contain multi-byte UTF-8. A parser MUST compare symbols by CODE POINT or by complete byte-slice, not by single byte. C/C++ byte-indexing and Java UTF-16 `char` indexing are hazards (see §5).

## 4. Encode contract (path → text)

A conforming encoder MUST:

1. Require odd-length input (a palindrome path, length `2n+1`).
2. Verify symmetry: `path[k] == path[2n-k]` for all `k`.
3. Build center-outward: start with `{core}`, wrap each shell outward as `{ x_k <inner> x_k }`.
4. Enforce `MAX_SHELLS = 64` depth cap.

## 5. Cross-language hazards (from assessment)

| Language | Hazard | Mitigation |
|---|---|---|
| C/C++ | byte indexing breaks UTF-8; pointer cursor | use code-point iteration; length-aware compare |
| Java | UTF-16 `char` surrogate pairs | use code-point API (`codePointAt`) |
| Python | (fixed) single-char symmetry compare | length-aware slice |
| R | none (authority) | — |

## 6. Invariants a reader must preserve

- `parse(encode(path)) == path` for every legal path.
- `encode(parse(text)) == text` for every canonical text.
- Symmetry is structural: every open `{ symbol` has a matching `} symbol {` ... closing `symbol }`.
- The core is the single center symbol; shells are the symmetric outer symbols.

## 7. Test vectors (for future readers)

| Input | Expected path | Notes |
|---|---|---|
| `{A}` | `[A]` | leaf, depth 0 |
| `{A{B}A}` | `[A, B, A]` | depth 1 |
| `{A{B{C} B}A}` → `{A{B{C}B}A}` | `[A, B, C, B, A]` | depth 2 |
| `{AB{C}AB}` | `[AB, C, AB]` | multi-char symbol |
| `{A{B{C{D{e}D}C}B}A}` | `[A,B,C,D,e,D,C,B,A]` | depth 4, canonical S_4 |

## 8. Relationship to serialization

This contract governs the **palindrome grammar** (interop layer: `pal_parse`/`pal_encode`). The **serialization** format (`format_pal`/`parse_pal`, length-prefixed records, v0.2) is a SEPARATE contract — see the serialization docs. A package reader must support both, but they are distinct:

- palindrome grammar = human-readable canonical form (this doc)
- serialization = length-prefixed transport records (v0.2, RCE-hardened)

## 9. Authority and scope

- **R is authoritative** for PAL semantics. This contract is a precise restatement, not a new authority.
- **No runtime is authoritative over this contract** (§7). This doc exists to make porting correct, not to bless a second implementation.
- This contract is RESERVED for future Java/C++/other readers; it is NOT on the v0.5.0 critical path (§9/non-goals).

---

*Contract baseline: R/grammar.R + R/validate_pal.R (authority) · mapping_pack.py (reference, fixed 2026-08-07) · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · 2026-08-07*