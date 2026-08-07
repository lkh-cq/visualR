# visualR v0.4.x — Stored Bytes Measurement Report

> **Status**: v0.4.x measurement baseline (draft)
> **Date**: 2026-08-07
> **Package baseline**: v0.3.0
> **Plan reference**: DEVELOPMENT_PLAN_v0.5.0.md §4 (v0.4.x) + §10 (Efficiency gate: "compact stored size")
> **Scope**: This report covers ONE of the seven Efficiency-gate measurements — **stored/transport bytes**. The remaining six (expanded working-set, transfer size, peak RAM, encoding/fold overhead, serial latency, concurrent throughput) are future v0.4.x work.

---

## 1. Purpose

Development plan G1 (Minimal authoritative storage) asserts that canonical information is stored compactly in PAL/palindromic form rather than as a permanently materialized matrix. This report measures whether that claim holds **quantitatively** for stored/transport bytes.

The central question:

> How many bytes does it take to persist/transport a visualR state, in compact PAL form vs materialized matrix form?

## 2. Method

### 2.1 Definition of "stored bytes"

Two representations of the same semantic state are compared:

| Representation | What is measured | Why it matters |
|---|---|---|
| **Compact PAL** | `nchar(format_pal(pal), type="bytes")` — the UTF-8 byte length of the length-prefixed v0.2 serialization string | This is what crosses the wire / hits disk when a visualR state is transported or persisted |
| **Expanded matrix** | `serialize(grid, con)` byte length of the materialized working matrix | This is the expanded working view that `materialize()` produces on demand |

### 2.2 Why not `object.size`?

`object.size()` on an R string measures the **string header + CHARSXP overhead** (a fixed ~232 bytes independent of content), NOT the content length. It is the wrong tool for transport-byte accounting. Content bytes are measured with `nchar(s, type="bytes")`.

### 2.3 Platform note

Serialized byte counts are R-version- and platform-version-specific (serialization format version embedded in header). The *reduction ratios* are the stable, comparable quantity; absolute byte counts may shift across R versions. All measurements below were taken on R 4.5.2 (2025-10-31), Linux.

## 3. Results

### 3.1 Low-dimension carriers (3×3, 9 cells)

| Dim | PAL serialized (bytes) | Matrix serialize (bytes) | Cells | Reduction (mat/pal) |
|---|---|---|---|---|
| S_1 | 79 | n/a (not a 3×3 carrier) | 0 | — |
| S_2 | 81 | 151 | 9 | 1.86× |
| S_3 | 83 | 151 | 9 | 1.82× |
| S_4 | 87 | 151 | 9 | 1.74× |

### 3.2 High-dimension carrier (11×11, 121 cells)

| Dim | PAL serialized (bytes) | Matrix serialize (bytes) | Cells | Reduction (mat/pal) |
|---|---|---|---|---|
| S_5 | 89 | 1038 | 121 | **11.66×** |

### 3.3 Dimension scaling of the PAL advantage

| Transition | PAL growth | Matrix cell growth |
|---|---|---|
| S_4 → S_5 | +2 bytes (87 → 89) | +112 cells (9 → 121) |

## 4. Conclusions

1. **G1 claim quantified**: For 3×3 carriers, PAL serialization is 1.7–1.9× more compact than the materialized matrix. For the 11×11 carrier, **PAL is 11.7× more compact**.

2. **PAL advantage scales with dimension**: PAL is O(n) in the number of shells (each shell adds one token), while the matrix is O(n²) in grid cells. The gap widens superlinearly. S_4→S_5 costs PAL only +2 bytes but adds 112 matrix cells.

3. **This is "store less / expand less / move less" evidence**: The compact PAL form is the right transport unit; the matrix is correctly relegated to an on-demand working view (`materialize`), exactly as DEVELOPMENT_PLAN G2 prescribes.

## 5. Limitations

- **Absolute byte counts are R-version-specific** (serialization header version). Reduction ratios are the portable claim.
- **Only transport bytes measured here.** The other six Efficiency-gate metrics (working set, peak RAM, latency, throughput, encoding/fold overhead) are NOT yet measured — they are the remaining v0.4.x scope.
- **S_1 is not a 3×3 carrier** in this package's semantics (needs `project_matrix` display projection, not `materialize`), so no matrix comparison exists for it.
- **No latency data**: this report measures bytes, not time. The Python-vs-R speed gap observed separately (Python ≈3× faster than base R `uniroot`) is a *runtime latency* question and belongs to the latency/throughput measurement, not this stored-bytes report.

## 6. Reproduction

```r
library(visualR)

# definitions
pals <- list(
  S1 = new_pal_state(character(0), "A"),
  S2 = new_pal_state("A", "b"),
  S3 = new_pal_state(c("A","B"), "c"),
  S4 = new_pal_state(c("A","B","C","D"), "e")
)
# S5: 11x11 carrier
p5 <- new_pal_state(c("A","B","C","D","E"), "f")

# compact PAL bytes
for (nm in names(pals)) {
  cat(nm, "PAL:", nchar(format_pal(pals[[nm]]), type="bytes"), "bytes\n")
}
cat("S5 PAL:", nchar(format_pal(p5), type="bytes"), "bytes\n")

# matrix serialize bytes
for (nm in names(pals)) {
  m <- materialize(pals[[nm]])
  if (m$ok) {
    con <- rawConnection(raw(0), "w")
    serialize(m$grid, con)
    cat(nm, "matrix:", length(rawConnectionValue(con)), "bytes\n")
    close(con)
  }
}
c11 <- carrier_11x11()
con <- rawConnection(raw(0), "w"); serialize(c11, con)
cat("S5 matrix:", length(rawConnectionValue(con)), "bytes (121 cells)\n"); close(con)
```

Expected output (R 4.5.2, Linux):

```
S1 PAL: 79 bytes
S2 PAL: 81 bytes
S3 PAL: 83 bytes
S4 PAL: 87 bytes
S5 PAL: 89 bytes
S2 matrix: 151 bytes
S3 matrix: 151 bytes
S4 matrix: 151 bytes
S5 matrix: 1038 bytes (121 cells)
```

## 7. Next steps (v0.4.x)

1. Formalize this as an in-package `benchmark_storage()` function (returns reproducible data.frame) — currently deferred per user decision.
2. Extend to the remaining six Efficiency-gate metrics: expanded working-set size, transfer size (compressed), peak RAM, encoding/fold overhead, serial latency, concurrent throughput.
3. Benchmark compact-state vs expanded-state workflows (plan §4 v0.4.x exit condition).
4. Use latency measurements to identify whether a native hotspot (plan §5) exists in the R compute path.

---

*Report baseline: visualR v0.3.0 · DEVELOPMENT_PLAN_v0.5.0.md (frozen) · R 4.5.2 · 2026-08-07*