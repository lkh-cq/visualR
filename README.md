# visualR

Distributed Residual Topology Runtime — an R-first exploratory programming
workbench for concurrent local sampling, constrained routing, and topology-
preserving state transitions.

> Intelligence is explored here as local emergence routed toward another
> local process, not as one controller that understands the whole field.

## Current exploration mainline

The new runtime treats a residual field as a positioned reservoir. Multiple
local pipes sample it at the same logical instant while a semantically blind
router enforces two-sided resource constraints:

$$
\sum_j a_{ij}\le b_i,
\qquad
\sum_i a_{ij}\le \min(q_j,c_j)
$$

- each pipe has a draw budget \(b_i\);
- each node owns residual supply \(q_j\) and a per-step draw limit \(c_j\);
- all pipes read one immutable snapshot;
- oversubscribed nodes scale simultaneous requests fairly;
- sampled positions and their relations remain in the output topology;
- supply is deducted once, at an atomic commit boundary.

This is exploratory runtime semantics, not a claim that the structure already
models biological intelligence or outperforms CNNs/attention.

The full direction and its deliberately unresolved questions are documented
in [`EXPLORATION_MAINLINE.md`](EXPLORATION_MAINLINE.md).

## Minimal runnable step

```r
library(visualR)

field <- new_reservoir(
  signal = c(2, -1, 4, 3, 6, 5),
  position = cbind(x = seq(0, 1, length.out = 6)),
  supply = rep(1, 6),
  capacity = rep(0.5, 6)
)

pipes <- list(
  new_reservoir_pipe(
    "local-a", budget = 0.8, phase = 0,
    phase_step = sqrt(2) - 1
  ),
  new_reservoir_pipe(
    "local-b", budget = 0.8, phase = 0.5,
    phase_step = (sqrt(5) - 1) / 2
  )
)

step <- reservoir_step(field, pipes, k = 3)

step$allocation$matrix       # pipe × positioned-node draw rights
step$outputs                 # one boundary output per local pipe
step$topology$nodes          # sampled addresses
step$topology$edges          # distance/direction/co-sampling relations
step$conservation            # input = extracted + remaining (+ tolerance)

# Continue without rebuilding global state.
next_step <- reservoir_step(step$reservoir_out, step$pipes_out, k = 3)
```

The irrational phase steps above are optional scheduling policies. In an
ideal continuous rotation they avoid exact periodic closure; in this R
prototype they are finite floating-point approximations, not proofs or a new
node type.

## Runtime boundary

The implemented router may inspect:

- node address and position;
- residual supply and per-step capacity;
- pipe budget, phase, and bandwidth;
- collisions and commit order.

It does not inspect a local process's private metadata or decide what a signal
means. `outputs + topology` is therefore a boundary packet for the next
exploration — local-to-local coherence — rather than a built-in universal
coherence score.

## Relationship to the PAL runtime

The previous Palindrome-Addressed Topological Runtime remains available and
tested:

```text
PAL compact state
  -> TopologyCarrier / shared snapshot
  -> concurrent orbit operators
  -> reconcile / commit
  -> PAL fold-back and transport
```

Its storage, grammar, mapping-pack, carrier, recursion, concurrency, and
package APIs have not been removed. In the new direction, PAL becomes one
possible topology generator or compact projection instead of the mandatory
shape of every runtime state.

Examples remain valid:

```r
p <- new_pal_state(c("A", "B", "C", "D"), "e")
run_topology_pipeline(p, "rotate")
run_topology_pipeline_parallel(p, "rotate", engine = "psock", ncores = 2)
```

The former frozen v0.5 plan is preserved in
[`DEVELOPMENT_PLAN_v0.5.0.md`](DEVELOPMENT_PLAN_v0.5.0.md) as the PAL-line
baseline. It is no longer presented as the only possible future of visualR.

## New public API

| Function | Role |
|---|---|
| `new_reservoir()` | Create positioned signal, residual supply, and node draw limits |
| `new_reservoir_pipe()` | Declare a local pipe's exposed routing boundary |
| `phase_sequence()` | Inspect a modular scheduling sequence |
| `route_pipes()` | Produce spatial preferences without consuming supply |
| `allocate_pipes()` | Jointly assign pipe budgets under node-side limits |
| `reservoir_topology()` | Recover selected addresses and their relations |
| `reservoir_step()` | Route, allocate, extract, commit, and advance phases atomically |

## Package baseline

- Language: base R reference semantics; `parallel` remains the only import.
- Development package version: 0.4.0.9000 (after the 0.4.0 PAL baseline).
- Existing PAL baseline: serialization hardening, Mapping Pack authority,
  dynamic topology carriers, deterministic CPU lane execution, state store,
  recursion experiments, packaging, and compactness benchmarks.
- New reservoir module: intentionally isolated from PAL storage so both
  computational hypotheses can be compared before an adapter is frozen.

## License

MIT
