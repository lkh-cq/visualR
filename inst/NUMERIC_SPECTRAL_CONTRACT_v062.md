# visualR Numeric / Polar / Spectral Contract v0.6.2

Status: `reference_experimental`
Authority: R implementation
Scope: numeric observations bound to the existing PAL/carrier address
model. This contract does not change frozen PAL, mapping-pack, carrier,
closure, residual, or TCN-pattern topology semantics.

## 1. Numeric field identity

A numeric field is the tuple

```text
F = (A, V, M, S_v, U, B, D, shape, P, E)
```

where:

- `A` is an ordered table of unique addresses;
- `V` is one finite real or complex value per address;
- `M` is one non-missing visibility flag per address;
- `S_v` is a non-empty caller-declared value meaning;
- `U` is its declared unit;
- `B` is the explicit `closed` or `open` boundary state;
- `D` is `path` or `carrier`;
- `P` is the mapping-pack identity when the source is PAL-backed;
- `E` is a signal-routing envelope.

`source_hash(F)` covers every item above that can affect identity. A
symbolic PAL token is never cast to a number. For matrices, address and
value order is R column-major order. For PAL windows, each value binds
to the existing `global_address`.

## 2. Signal envelope

The envelope contains routing metadata only:

```text
(source_kind, timescale, density, update_interval,
 spatial_scope, persistence, provenance, uncertainty)
```

`compile_signal_schedule()` selects a named field at tick `t` exactly
when

```text
t mod update_interval = 0.
```

It never averages, concatenates, reduces, or otherwise mixes payloads.
`fast/slow` and `dense/sparse` are declarations, not inferred domain
semantics. `uncertainty` is an observation attribute, not a prediction
probability.

## 3. Polar observation chart

For a carrier of `nr x nc`, the geometric center is

```text
c_r = (nr + 1) / 2
c_c = (nc + 1) / 2
x   = col - c_c
y   = c_r - row
r   = sqrt(x^2 + y^2)
theta = atan2(y, x) mod 2*pi.
```

At `r = 0`, `theta` is undefined. The chart preserves every original
address/value pair and performs no interpolation. For even dimensions,
the half-cell geometric center is distinct from the two/four central
topology addresses.

## 4. Unitary Fourier observation

For `N` observed values, the supported normalization is

```text
X_k = (1 / sqrt(N)) * sum_n x_n exp(-i 2*pi*k*n/N)
x_n = (1 / sqrt(N)) * sum_k X_k exp(+i 2*pi*k*n/N).
```

The same product normalization applies to a two-dimensional carrier.
Therefore, up to floating-point tolerance,

```text
sum |x|^2 = sum |X|^2.
```

The plan requires a fully observed mask until a masked-sample policy is
separately defined. It records source hash, address-order hash, shape, transform
domain, normalization, center shift, boundary state, and boundary
policy. Execution refuses a stale field. `finite_window` means only the
supplied samples are observed. It does not imply padding. `periodic`
must be requested explicitly and is refused for an open field.

## 5. Direct angular modes

No Cartesian-to-polar resampling is performed. With explicitly supplied
non-negative sampling weights `w_j`, angular mode `m` is

```text
a_m = sum_j w_j v_j exp(-i m theta_j) / sum_j w_j.
```

Samples with undefined `theta` must have zero weight. This is a direct
weighted observation, not a claim that the grid is uniformly sampled in
angle.

## 6. Gradients

Carrier gradients use positive caller-declared row/column spacing, with
unit spacing as the backward-compatible default:

- central differences at interior addresses;
- one-sided differences at observed boundaries;
- zero derivative along a singleton dimension;
- no padding, wraparound, or extrapolation.

Carrier and path gradients require a fully observed mask under the stored
`masked_policy = "refuse"`. Masked-neighbour behavior is deliberately
unavailable rather than silently imputed. Other policy strings fail closed.

With the geometric y-axis pointing upward, `g_x = g_col` and
`g_y = -g_row`. Optional radial/tangential components are exact vector
projections at existing addresses. PAL path gradients use forward slopes
over strictly increasing `global_address` values. Their coordinate
delta is `address_delta * spacing["address"]`; both deltas are retained in
the edge table and covered by the gradient hash.

Spacing names, values, the mask policy, difference policy, source/chart
identity, and every output value are hash-bound. Changing any of these
invalidates the observation.

## 7. CPU evidence boundary

`benchmark_numeric_observers()` reports platform-dependent median wall time
and static result-object size for each observation stage. It does not claim
peak process memory or a universal performance threshold.

`benchmark_tap_compiler()` measures only the integer tap-schedule boundary.
It computes the R schedule first and refuses to report C99 timing unless the
complete native matrix is identical. Graph construction, PAL semantics,
spectral execution, gradients, and bias evidence remain R-authoritative.

CI emits versioned CSV and Markdown artifacts for review; timing values do
not enter hashes or lifecycle semantics.

## 8. Non-claims

This layer does not claim:

- trainable TCN behavior or migrated neural weights;
- frequency-domain convolution equivalence for arbitrary operators;
- semantic meaning inferred from tokens, cadence, density, or source
  names;
- probability prediction, calibration, or causal inference;
- polar interpolation accuracy.

Every such extension requires a separate contract, tests, evidence,
and lifecycle decision.
