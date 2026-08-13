# Cross-Language Shape Contract v0.6.0

> Status: FROZEN (B-promotion 2026-08-13)
> Extends: inst/PAL_NESTED_CONTRACT.md (frozen, v0.4.0)
> Source of idea: TCN (locuslab/TCN) block composition discipline —
>   blocks compose by shape contract alone.
> Language independence: this contract is R-authored but written so a
>   future Java/JVM or C/C++ reader can verify the same invariants
>   without executing R.

---

## 1. Purpose

The PAL_NESTED_CONTRACT defines the serialized form. This document
defines the **shape layer**: what a compute block may and may not do
to the carrier shape, and how shape changes must be declared.

The frozen rule is:

```text
A shape change without an explicit adaptation declaration is illegal.
```

This is TCN's downsample discipline (explicit 1x1 convolution, never
implicit channel reshaping) mapped onto visualR carrier transfers.

## 2. Legal carrier widths

```text
width  role
3      compute path (canonical Jiugong)
4      registered evidence view (sample analysis)
11     registered S_5 carrier view (carrier_11x11)
```

Any other width is illegal in the adapter layer (fail-closed).

## 3. Legal transfers

```text
from -> to   rule
3  -> 3      identity pass-through
3  -> 4      border pad (zero) — view expansion only
4  -> 3      border crop — view reduction only
3  -> 11     REFUSED: 11x11 must be built by the S_5 carrier rule,
             not by padding (typed view discipline)
any other    REFUSED (fail-closed)
```

## 4. Block ABI invariants

Every composed block declares:

```text
block_name    non-empty string
input_shape   integer vector, non-empty
output_shape  integer vector, non-empty
abi_ok        TRUE iff (input_shape == output_shape)
              OR (adaptation string is present and non-empty)
```

A block with different shapes and no adaptation string is refused.
This is checkable in any language: string equality + presence check.

## 5. Growth-law table invariants

```text
law_id        one of: dilation_power | gradient_batch |
              carrier_width | pal_path
frozen        TRUE means the law is authoritative for its source;
              FALSE means candidate (must NOT be treated as frozen)
depth         integer >= 0
value         integer computed from base/step by the table
```

dilation_power = base^depth (TCN reference: 1, 2, 4, 8, 16, ...).
carrier_width and pal_path remain candidate_not_frozen in the
equation-core sense; the table does NOT freeze them.

## 6. Test vectors (language-independent)

```text
growth_law("dilation_power", 0) = 1
growth_law("dilation_power", 3) = 8
growth_sequence("dilation_power", 4) = [1, 2, 4, 8, 16]
check_shape_preserving([3,3], [3,3]) = true
check_shape_preserving([3,3], [4,4]) = false
block_contract("b", [3,3], [4,4])            -> abi_ok = false
block_contract("b", [3,3], [4,4], "pad")     -> abi_ok = true
carrier_adapter(m, 3, 3).matched              = true
carrier_adapter(m, 3, 11)                    -> error (fail-closed)
emerge_stack([3,3,3]).abi_ok                  = true
emerge_stack([3,4,4]).abi_ok                  = true  (level 2 adapted)
```

## 7. Future readers

A Java/JVM or C/C++ reader implementing these checks must reproduce
the test vectors in section 6 exactly. R remains the semantic
authority; this contract only pins the shape layer so that
cross-language readers fail closed on the same inputs.
