# Topology Dilated Compiler Contract v0.6.1

> - Status: `reference_experimental`
> - Semantic authority: R
> - Native role: C99 integer-address schedule acceleration only
> - Extends, does not modify: `PAL_NESTED_CONTRACT.md` and
>   `CROSS_LANG_SHAPE_CONTRACT_v060.md`
> - Engineering reference: `locuslab/TCN`, commit
>   `2f8c2b817050206397458dfd1f5a25ce8a32fe65`, `TCN/tcn.py`

## 1. Scope and evidence boundary

The compiler migrates four structural ideas from the TCN reference:

1. one fixed ordered kernel per stack;
2. dilation `2^(level-1)`;
3. two ordered tap passes per residual block by default;
4. a same-address residual identity from block input to block output.

It does **not** migrate PyTorch, learned weights, activation functions,
dropout, causal padding, or neural-network meaning. The similarity is an
engineering reference, not evidence that TCN and PAL are mathematically
equivalent. visualR correctness is established only by the PAL invariants
and the tests in this repository.

The upstream repository is MIT licensed. This implementation is an
independent address-plan compiler; no upstream Python source is embedded.

## 2. Complete solution and open window

The frozen complete-solution grammar is unchanged:

```text
{A{B{C{D}C}B}A}
```

An open visible window adds one boundary marker on each side:

```text
}{B{C{D}C}B}{
^             ^
omitted outer solution exists; it is not serialized here
```

Normative parsing rule:

```text
open_text = "}" + pal_encode(visible_pal) + "{"
```

The first `}` and last `{` are boundary syntax, never PAL tokens. Removing
them must leave a string accepted by the frozen `pal_parse()` function.

Every window carries:

```text
boundary       closed | open
origin         global integer address of the visible core
radius         number of shells
width          2*radius + 1
local_offset   [-radius, ..., 0, ..., +radius]
global_address origin + local_offset
outer_ref      opaque {left, right} references or explicit unbound values
```

An unbound outer reference is not zero, null topology, or permission to
guess. It remains an unresolved frontier edge.

## 3. State transitions

### 3.1 Deepen a complete solution

```text
input shells = [x0, ..., xn-1], core = xn
explicit next_core = y
output shells = [x0, ..., xn-1, xn], core = y
```

Test vectors:

```text
{A{B}A}                 + c -> {A{B{c}B}A}
{A{B{C}B}A}             + d -> {A{B{C{d}C}B}A}
{A{B{C{D}C}B}A}         + e -> {A{B{C{D{e}D}C}B}A}
```

### 3.2 Shift a fixed-radius open window

```text
new_shells = old_shells without first element, followed by old_core
new_core   = explicit next_core
new_origin = old_origin + 1
outer_ref  = preserved, never dereferenced or fabricated
```

The trace contains one row per new visible address. Each row is marked
`retained` (same global address from the previous left/core chain),
`introduced` (the explicit new core), or `mirrored` (right-side PAL role
derived from the new window's left counterpart). Thus a shift never hides
which address relationship produced a visible token.

Test vectors:

```text
}{B{C{D}C}B}{ + E -> }{C{D{E}D}C}{
}{C{D{E}D}C}{ + F -> }{D{E{F}E}D}{
```

## 4. Tap schedule

For visible width `W`, levels `L`, ordered offsets `K`, and passes per
level `C`, the schedule contains exactly:

```text
W * L * C * length(K)
```

rows. For each row:

```text
dilation       = 2^(level-1)
source_layer    = (level-1)*C + convolution - 1
target_layer    = source_layer + 1
source_position = target_position + kernel_offset*dilation
scope           = -1 if source_position < 1
                   0 if 1 <= source_position <= W
                  +1 if source_position > W
```

The ordered integer columns are normative:

```text
level, convolution, source_layer, target_layer, dilation,
target_position, kernel_offset, source_position, scope
```

## 5. Graph IR

Every visible node is identified by `(layer, global_address)`. Equal token
labels at different addresses are different nodes. Every tap and residual
is a declared edge; all edge endpoints must occur in the node table.

Outside tap handling is normative:

| Window boundary | Source node kind | Resolution state |
|---|---|---|
| `open` | `outer_reference` | unresolved frontier; may carry opaque ref |
| `closed` | `boundary_stop` | unresolved frontier; no implicit value |

`zero_padding` is not a legal implicit source kind.

Each level adds exactly `W` `residual_identity` edges:

```text
from layer = (level-1)*C
to layer   = level*C
source_global == target_global
```

The declared receptive span includes that identity path:

```text
dilation_sum = sum(2^(level-1), level=1..L)
tap_min      = C * dilation_sum * min(K)
tap_max      = C * dilation_sum * max(K)
min_offset   = min(0, tap_min)
max_offset   = max(0, tap_max)
span_width   = max_offset - min_offset + 1
```

The compiler declares visible input and output widths equal. It does not
perform numeric addition, convolution, activation, or residual fusion.

## 6. R/C authority contract

R generates the normative schedule and enriches it with PAL tokens,
boundaries, references, nodes, edges, and validation. C99 accepts only:

```text
width, levels, kernel_offsets, convolutions_per_level
```

and returns only the nine-column integer schedule from section 4.

For every accepted input in the shared domain:

```text
identical(schedule_C, schedule_R) == TRUE
identical(graph_C, graph_R)       == TRUE
```

C must independently reject invalid scalar types, even widths, invalid
limits, duplicate offsets, integer overflow, and excessive schedule size.
It may not define token, boundary, transition, or numeric semantics.

## 7. Limits and failure behavior

```text
PAL width                  1..129, odd
levels                     1..30
convolutions_per_level     1..16
kernel offset count        1..31, unique
kernel offset value        -32768..32767
compiled tap rows          <= 1,000,000
address arithmetic         signed R integer range used by visualR
```

All violations fail closed. No engine fallback is silent: requesting the
C engine without a loaded native routine is an error.

## 8. Promotion gate

This contract and its implementation remain experimental. Promotion needs
all of the following in a separate decision:

1. Linux, Windows, and macOS package checks;
2. exact R/C schedule and graph equivalence evidence;
3. complete/open round-trip and transition coverage;
4. no change to frozen v0.6.0 A–G behavior;
5. an explicit lifecycle update from `reference_experimental`.
