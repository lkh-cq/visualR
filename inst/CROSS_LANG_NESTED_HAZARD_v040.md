# visualR — Cross-Language Nested-Logic Hazard & Feasibility Assessment

> **Status**: v0.4.x semantic-alignment reserve (draft)
> **Date**: 2026-08-07
> **Package baseline**: v0.3.0
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §7 (packaging/transport), §8 (Java/JVM reserve), §9 (non-goals), §10 (semantic gate)
> **Scope**: Evaluate the hazard and feasibility of porting visualR's nested palindrome logic to other languages (C/C++, Java/JVM, Python), to reserve space for future cross-language semantic alignment WITHOUT making any runtime authoritative over PAL semantics.

---

## 1. Why this assessment exists

The packaging contract (§7) must "leave room for future readers in Java/JVM, C/C++, or other runtimes without making those runtimes authoritative over PAL semantics." Before any future runtime can read a visualR package, the **nested-logic semantics** it must reproduce must be understood well enough to port safely — or the port will silently diverge from the R semantic core.

This document is the hazard/feasibility analysis for that port. It does NOT author a Java/C++ implementation; it precedes one.

## 2. The nested-logic core being assessed

The palindrome grammar (frozen, `R/grammar.R` = `mapping_pack.py`):

```
S_n = {x_0{x_1{...{x_{n-1}{x_n}x_{n-1}}...}x_1}x_0}
example: {A{B{C{D{e}D}C}B}A}  -> path ['A','B','C','D','e','D','C','B','A']
```

Two operations carry the nesting:
- **Parse** (`pal_parse` / `parse_palindrome`): recursive-descent parser with a mutable position cursor, symmetry check after each inner node.
- **Encode** (`pal_encode` / `encode_palindrome`): center-outward recursive wrapping.

## 3. Hazard assessment by language

### 3.1 Mutable position cursor (the #1 hazard)

The parser shares a single mutable position across recursion levels.

| Language | Mechanism | Hazard |
|---|---|---|
| R | lexical closure + `pos <<-` superassign | ✔ safe (interpreter-managed); but `<<-` is subtle, easy to shadow |
| Python | `nonlocal pos` in nested `parse_node` | ✔ safe; `nonlocal` explicit |
| **C** | `int *pos` or `size_t *pos` passed by pointer | ⚠ pointer aliasing; must manually restore on error; no stack unwind cleanup |
| **C++** | reference `size_t &pos` or parser `struct` with member | ⚠ mutable-ref aliasing; exception safety requires RAII; easy to forget to increment |
| **Java** | `int[] pos = {0}` or mutable `Position` holder | ⚠ legal but awkward; invisible mutation; reader must know pos is by-reference semantics |

**Feasibility**: all languages CAN express it, but C/C++/Java make the cursor mutation an *implicit contract* that is easy to violate. The R/Python versions are the semantic authority and are correct.

### 3.2 Recursion depth

`parse_node` recurses once per shell layer. `validate_pal` caps at `MAX_SHELLS = 64`.

| Language | Stack depth capacity | Risk |
|---|---|---|
| R | interpreter stack, 64 layers trivial | none |
| Python | interpreter stack, 64 layers trivial | none |
| C/C++ | native stack; 64 frames trivial (default 1MB) | none at 64, but NO hard guard if a future S_256 is allowed |
| Java | JVM stack, thread-stack default 512KB-1MB | none at 64 |

**Risk**: none at the frozen S_64 cap. The danger is a **future dimension increase without re-auditing stack depth** — a native port has no interpreter safety net. Mitigation: keep the depth cap in the shared semantic contract.

### 3.3 Multi-character symbols (UTF-8 safety)

Symbols are arbitrary non-empty token strings (e.g. multi-char domain symbols), not single chars.

| Language | Mechanism | Hazard |
|---|---|---|
| R | `strsplit(text,"")` then `paste(chars[start:end])` | ✔ UTF-8 safe (R strings are code points) |
| Python | `text[start:pos]` on str | ✔ UTF-8 safe (Python str is code points) |
| **C** | `char` array, byte indexing | ⚠🚩 **BREAKS UTF-8 / multi-byte**. Must use wide chars or a UTF-8 library; byte-offset symmetry check is wrong |
| **C++** | `std::string` with `operator[]` (byte) | ⚠🚩 same byte-indexing hazard; must use code-point iteration |
| **Java** | `String` + `charAt` | ⚠ `char` is UTF-16 code unit; surrogate pairs break multi-byte; use code-point API |

**This is the highest-severity hazard.** A na$ive C/C++ port that treats symbols as single bytes will silently corrupt multi-char symbols and break the symmetry check. The R/Python authority handles this correctly.

### 3.4 Symmetry check

After each inner node, the parser verifies the closing symbol matches the opening symbol.

| Language | Mechanism | Hazard |
|---|---|---|
| R | `paste(chars[pos:pos+len-1]) != sym` | ✔ correct multi-char compare |
| Python | `text[pos] != sym` then `pos += 1` | ⚠ **BUG if sym is multi-char** — `text[pos]` is ONE char, `pos += 1` advances one unit. Python reference has a latent multi-char-symbol bug (see §4) |
| C/C++ | `strncmp` / `substr(pos, len) != sym` | ⚠ must compare full length, not one unit |
| Java | `regionMatches(pos, sym, 0, len)` | ✔ correct if length-aware |

## 4. Latent divergence found: Python multi-char symmetry bug

The Python reference `parse_palindrome` (mapping_pack.py lines 119-125):

```python
if text[pos] != sym:      # single-char compare
    raise ...
pos += 1                    # single-char advance
```

For a **multi-character symbol**, `text[pos]` is only the FIRST char of `sym`, and `pos += 1` advances only one unit — so `{AB{C}AB}` (multi-char sym "AB") would be **mis-parsed**: after inner `C`, `text[pos]` is `'A'` (first char of "AB"), `!= "AB"` → raises a spurious error, OR with luck might pass incorrectly. The R version compares the full `sym_len` slice and is correct.

**This is a real cross-language semantic divergence** the R authority does NOT have. It confirms the R implementation is the correct reference, and it must be documented so a future Java/C++ reader does not copy the Python bug.

### 4.1 Empirical confirmation + fix (2026-08-07)

**Confirmed by execution** (R 4.5.2 vs mapping_pack.py):

| Input `{AB{C}AB}` | R `pal_parse` | Python `parse_palindrome` (pre-fix) |
|---|---|---|
| Result | shells=`AB`, core=`C`, roundtrip OK | **ERROR** "位置 6: 期望对称符号 AB，收到 A" |

**Fix applied to `mapping_pack.py`** (2026-08-07): the symmetry check now compares the full-length slice `text[pos:pos+sym_len]` and advances `pos += sym_len`, aligning with the R authority. Verified:
- `{AB{C}AB}` → `['AB','C','AB']`, roundtrip `{AB{C}AB}` ✓
- single-char `{A{B{C{D{e}D}C}B}A}` → S_4 path unchanged ✓
- full Python test suite: **69 pass / 0 fail** ✓

The R implementation remains the correct semantic authority; the Python reference is now aligned with it.

## 5. Feasibility summary

| Language | Feasible? | Key hazard | Verdict |
|---|---|---|---|
| Python | ✔ (already exists) | multi-char symmetry bug (§4) | Fix or document; NOT authority |
| C | ✔ but unsafe without care | UTF-8 byte indexing, pointer cursor | Feasible post-core, high care |
| C++ | ✔ but unsafe | UTF-8 byte indexing, mutable ref | Feasible post-core, RAII required |
| Java | ✔ | UTF-16 surrogate pairs | Feasible post-core, code-point API required |

All are feasible; none is safe as a naive byte-level port. The R authority is correct and must remain the semantic reference.

## 6. Semantic-alignment reserve actions (what this unlocks)

To reserve space for future cross-language readers WITHOUT making them authoritative:

1. **Document the frozen nested-logic contract** (this document) — what a reader MUST reproduce: length-aware multi-char symbol compare, symmetry check, depth cap, incremental cursor.
2. **Fix or annotate the Python multi-char symmetry bug** in mapping_pack.py (§4) so it cannot be copied as authority.
3. **Keep `MAX_SHELLS` depth cap in the shared contract** (already in `validate_pal`).
4. **No C/C++/Java implementation in v0.5.0 critical path** (§9: Java is post-core reserve; native only after profiling shows a hotspot, §5).
5. **The R implementation remains authoritative** — this document is a porting guide, not a new authority.

## 7. Relationship to v0.4.x current work

This assessment is the "reserve space" prerequisite for the packaging contract (§7: "leave room for future readers"). It does not change current R code. It feeds:
- The concurrency/benchmark harness (already in progress) — stays R-first.
- Future packaging work — the package contract must carry the nesting contract so a Java/C++ reader can validate its port.

---

*Assessment baseline: visualR v0.3.0 · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · R 4.5.2 & mapping_pack.py (Python reference) · 2026-08-07*