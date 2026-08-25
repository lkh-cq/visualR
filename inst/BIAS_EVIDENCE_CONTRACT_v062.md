# visualR Structural Bias Evidence Contract v0.6.2

Status: `reference_experimental`
Decision output: `within_reference` or `review`
Probability output: unavailable by contract

## 1. Purpose

The bias layer exposes observable reasons to review a field. It does
not turn structural irregularity into a probability. Each component is
kept named so an audit can identify the source of a gate decision.

The v0.6.2 component family includes:

```text
B_boundary     open-window incompleteness indicator
B_coverage     fraction of masked addresses
B_uncertainty  caller-declared source uncertainty
B_center       center-versus-field magnitude contrast (carrier only)
B_polar        first angular resultant magnitude (optional chart)
B_spectral     largest share of observed spectral energy (optional FFT)
B_gradient     root-mean-square gradient magnitude (optional gradient)
```

These are descriptive evidence features. They are neither learned
coefficients nor causal effects.

## 2. Reference normalization

For feature `j`, the reference center is its median. The scale is tried
in this fail-safe order:

1. scaled median absolute deviation;
2. `IQR / 1.349`;
3. maximum absolute deviation from the median;
4. `1` for a completely constant reference feature.

For observation `i`:

```text
z_ij = |(B_ij - median_j) / scale_j|
S_i  = max_j z_ij.
```

The gate is the type-8 empirical quantile

```text
tau = Q_(1-alpha)({S_i}).
```

An observation is `review` only when `S > tau`; otherwise it is
`within_reference`. Exact feature names and order must match the fitted
reference. Feature drift fails closed.

## 3. Why this is not probability

`S` is a robust distance from an empirical reference envelope. It has
no target event, likelihood, posterior interpretation, calibration
guarantee, or class-conditional meaning. Consequently the audit object
contains `probability = NULL` and an explicit unavailable status.

## 4. Probability promotion gate

A future probability API may be proposed only after all of the
following are versioned and independently auditable:

1. a precise target event and prediction horizon;
2. labelled outcomes with provenance and missingness policy;
3. entity/group isolation and temporal train/validation/test splits;
4. a feature schema frozen before the held-out evaluation;
5. a fitted probabilistic model with reproducible seed/configuration;
6. an independent calibration set;
7. calibration evidence (reliability curve plus Brier/log loss and a
   declared calibration-error measure);
8. discrimination evidence appropriate to prevalence;
9. operating thresholds tied to explicit loss/cost assumptions;
10. subgroup, drift, abstention, and out-of-distribution review;
11. a model card, versioned dataset identity, and rollback path;
12. a separate lifecycle/promotion decision.

Until all twelve conditions pass, visualR may report evidence and a
review action but must not label either as a predicted probability.

## 5. Audit checklist

Every proposed feature or threshold change must answer:

- Which address/value contract produces it?
- Does it change under masking, boundary state, or resampling?
- Is the source hash still aligned?
- Can leakage enter through time, identity, mapping-pack revision, or
  preprocessing fit?
- Is its scale learned from reference data only?
- Does feature-name drift fail closed?
- Is the result being described only at its supported evidence level?

Failure to answer any item blocks promotion.
