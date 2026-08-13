# visualR Implementation Plan v0.6.0

> Status: **ACTIVE** (2026-08-13)
> Baseline: v0.5.0 (main 6cd29de, 421 tests / 0 failures)
> Source of ideas: TCN (locuslab/TCN) engineering-logic dissection,
>   recomposed for visualR by cross-project analysis.
> Scope: additive files only. No frozen semantics are changed.

---

## 1. Why TCN

locuslab/TCN is a 63-line PyTorch sequence model. Its engineering
logic overlaps visualR's on three disciplines (this is the
"不谋而合" the dissection found):

```text
TCN discipline              visualR discipline
-------------------------   -----------------------------------------
1. invariants as structure  Chomp1d crop makes causality structurally
                            unbreakable            <-> 藏归分离 / frozen
2. shape-preserving blocks  TemporalBlock keeps shape; blocks compose
                            by shape contract only  <-> operator ABI
3. explicit growth law      dilation = 2^i is an explicit constant
                            sequence               <-> L_s/W_d/Q_d
                            candidates + gradient_layers
```

## 2. A-G mapping (what each letter becomes)

```text
A  view typing        -> folded into carrier_adapter(): a non-compute
                        view can never reach a compute path (fail-closed
                        typed dispatch, same discipline as v0.5.0).
B  emerge_stack       -> R/emerge_stack.R : derived stacking API,
                        width list drives ordered composition.
C  carrier_adapter    -> R/carrier_adapter.R : transfer adapter,
                        match = pass-through, mismatch = explicit 1x1
                        adapt or fail-closed stop (TCN downsample).
D  growth-law table   -> R/growth_law.R : frozen constant table for
                        growth laws (dilation 2^i style), query + seq.
E  block ABI          -> R/block_abi.R : shape-preserving block
                        contract checker + unified block ABI record.
F  pack factory       -> folded into emerge_stack() : high-level
                        derived constructors from a mapping pack.
G  cross-lang shape   -> inst/CROSS_LANG_SHAPE_CONTRACT_v060.md :
                        language-independent shape contract doc
                        (extends PAL_NESTED_CONTRACT with shape rules).
```

## 3. Files

```text
New R code:
  R/growth_law.R        D
  R/block_abi.R         E
  R/carrier_adapter.R   C (+A)
  R/emerge_stack.R      B (+F)

New contract doc:
  inst/CROSS_LANG_SHAPE_CONTRACT_v060.md   G

Rd:
  man/growth_law.Rd, man/growth_sequence.Rd
  man/block_contract.Rd, man/carrier_adapter.Rd,
  man/emerge_stack.Rd

NAMESPACE:
  export(growth_law), export(growth_sequence)
  export(block_contract), export(check_shape_preserving)
  export(carrier_adapter), export(emerge_stack)
```

## 4. Acceptance (before commit)

```text
1. package loads in a fresh Rscript session
2. every new function: strict input validation + fail-closed paths
3. existing 421 tests remain green (no frozen file touched)
4. new functions have rd-valid roxygen blocks
5. CHANGELOG entry marks each of A-G with its status
```

## 5. Explicit non-goals

```text
- no change to any FROZEN file (constants.R, carrier.R, mapping_pack.R,
  equation_core.R, topology_carrier.R, orbit_operators.R ...)
- no GPU/native acceleration
- no replacement of R semantic authority
- A-G are additive reference implementations, not frozen semantics
  (they carry status = "reference_additive" until a later B-promotion)
```
