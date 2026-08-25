# == Harmony ABI (Phase 5 — the H interface, NOT Harmony theory) ========
# STATUS: new module for v0.7.0. Builds ONLY the interface:
#   register_harmony_operator / harmony_step / (validate_harmony_event is
#   inherited from router_contract.R and deliberately NOT redefined here).
#
# Purpose is NOT to prove intelligence; it is to verify that a pair of
# merges (M_i, M_j) can fully enter H (via an AdjacencyPair) and produce a
# NEW Merge M_ij' without any Router intervention.
#
# Boundary (A3 / A2 / A6 governance):
#   - AdjacencyPair is the ONLY legal Harmony input: harmony_step() type-checks
#     class == "visualr_adjacency_pair" and fails closed against raw packets.
#   - Harmony NEVER reads Router internal state (snapshot / envelope) as a
#     semantic input. Router lifecycle ends at "Adjacency created".
#   - An operator only ever transforms CONTENT (the opaque Merge payload);
#     it never sees an envelope / snapshot. harmony_step extracts content via
#     merge_content() and hands the operator (content_a, content_b, pair).
#
# Ordering note: this file sorts alphabetically BEFORE router_contract.R
# ("harmony_" < "router_"), so at source time the router registry
# (.visualR_harmony_op_env) and the shared constructors do not yet exist.
# Therefore every reference to them is made lazily, inside function bodies,
# where lexical scoping resolves them from the fully-assembled package
# namespace at call time.

# == Module state (this file owns it; independent of Router) ==============
# NOTE: no merge_id counter here. merge_id is a PURE function of the pair's
# structural identity (contract 4.2) so serial == PSOCK (gate 14.4). A
# process-global counter was deliberately removed — re-adding one would break
# determinism.

# == Built-in baseline operators (toy baselines; not a theory) ============
# Each obeys the operator ABI: fn(merge_a_content, merge_b_content, pair)
# -> new content. They only transform content; they never touch envelope /
# snapshot / merge object internals.
.harmony_builtins <- function() {
  list(
    # identity: pass the left content through unchanged.
    identity = function(a, b, pair) a,
    # swap: pass the right content through as the combined content.
    swap = function(a, b, pair) b,
    # pair_comp: deterministic combination of the two contents into one value.
    pair_comp = function(a, b, pair) paste(a, b),
    # reversible_toy: a reversible toy — result = c(a, b); both inputs remain
    # recoverable (v[1] -> a, v[2] -> b), which is what makes it reversible.
    reversible_toy = function(a, b, pair) c(a, b)
  )
}

# Names of built-ins; used to enforce the fail-closed overwrite rule.
harmony_builtin_names <- function() names(.harmony_builtins())

# Seed whatever built-ins are not yet present into the registry. Called
# lazily so the ordering problem above never matters. `overwrite=TRUE` lets
# a caller explicitly replace a previous registration (needed to re-register
# a built-in). Built-in NAMES are still protected in register_harmony_operator
# unless the caller passes overwrite=TRUE there.
harmony_seed_builtins <- function(overwrite = FALSE) {
  .e <- .visualR_harmony_op_env            # resolved at call time
  bf <- .harmony_builtins()
  for (nm in names(bf)) {
    if (is.null(.e[[nm]]) || isTRUE(overwrite)) {
      .e[[nm]] <- bf[[nm]]
    }
  }
  invisible(NULL)
}

# == Public ABI ============================================================
# Register a harmony operator into .visualR_harmony_op_env.
# ABI: fn(merge_a_content, merge_b_content, pair) -> new content (non-NULL).
# Built-in names cannot be overwritten unless overwrite=TRUE (fail closed).
register_harmony_operator <- function(name, fn, overwrite = FALSE) {
  if (!is.character(name) || length(name) != 1L || is.na(name) || !nzchar(name)) {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(fn)) {
    stop("`fn` must be a function.", call. = FALSE)
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  # ABI arity check: operator must be able to take (merge_a_content,
  # merge_b_content, pair).
  fmls <- names(formals(fn))
  if (length(fmls) < 3L && !("..." %in% fmls)) {
    stop("Harmony operator ABI: fn must accept (merge_a_content, merge_b_content, pair).",
         call. = FALSE)
  }

  # Ensure built-ins are present/known, then protect their names.
  harmony_seed_builtins()
  builtins <- harmony_builtin_names()
  if (name %in% builtins && !overwrite) {
    stop(sprintf("'%s' is a built-in harmony operator (fail closed). Use overwrite=TRUE.",
                 name), call. = FALSE)
  }

  # Runtime probe: run the operator once on a real pair and require non-NULL
  # content. This catches contract violations at registration time.
  probe_ok <- tryCatch({
    ma <- new_merge("A", "probe_a", "space", 1L)
    mb <- new_merge("B", "probe_b", "space", 1L)
    pr <- new_adjacency_pair(ma, mb, "aa", "bb", "space",
                             character(0L), 1L)
    out <- fn(merge_content(ma), merge_content(mb), pr)
    !is.null(out)
  }, error = function(e) {
    stop(sprintf("Harmony operator '%s' probe failed: %s",
                 name, conditionMessage(e)), call. = FALSE)
  })
  if (!probe_ok) {
    stop(sprintf("Harmony operator '%s' returned NULL content (contract violated).",
                 name), call. = FALSE)
  }

  .visualR_harmony_op_env[[name]] <- fn
  invisible(NULL)
}

# Normalize a left/right side to a single merge_id, accepting either the
# merge OBJECT (the natural payload carrier) or a bare merge_id string.
merge_id_of <- function(x) {
  if (inherits(x, "visualr_merge")) return(x$merge_id)
  if (is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)) return(x)
  NULL
}

# (merge_id is deterministic, contract 4.2 — no per-session counter.)

# Execute one Harmony step: AdjacencyPair -> HarmonyEvent (a NEW Merge).
# Accepts ONLY a visualr_adjacency_pair (fails closed on raw packets, A3).
harmony_step <- function(pair, operator = "identity") {
  # Fail-closed: this is the A3 seam. Non-AdjacencyPair input is refused.
  validate_adjacency_pair(pair)
  if (!is.character(operator) || length(operator) != 1L ||
      is.na(operator) || !nzchar(operator)) {
    stop("`operator` must be a single non-empty character.", call. = FALSE)
  }

  harmony_seed_builtins()
  fn <- .visualR_harmony_op_env[[operator]]
  if (is.null(fn)) {
    stop(sprintf("Unknown harmony operator: '%s'. Registered: %s",
                 operator,
                 paste(sort(ls(.visualR_harmony_op_env)), collapse = ", ")),
         call. = FALSE)
  }

  # Semantic input is CONTENT only (A2/A3): Harmony never reads router state.
  a <- merge_content(pair$left_merge)
  b <- merge_content(pair$right_merge)
  left_id  <- merge_id_of(pair$left_merge)
  right_id <- merge_id_of(pair$right_merge)
  if (is.null(left_id) || is.null(right_id)) {
    stop("AdjacencyPair sides are not resolvable to a merge_id (fail closed).",
         call. = FALSE)
  }
  new_content <- tryCatch(fn(a, b, pair), error = function(e) {
    stop(sprintf("Harmony operator '%s' failed: %s",
                 operator, conditionMessage(e)), call. = FALSE)
  })
  if (is.null(new_content)) {
    stop(sprintf("Harmony operator '%s' produced NULL content (contract violated).",
                 operator), call. = FALSE)
  }

  # Fresh merge_id (contract 1.8). DETERMINISTIC: derived purely from the
  # pair's structural identity (left/right ids + operator + round + addresses),
  # NOT a process-global counter — a global counter would make serial vs PSOCK
  # produce different ids and break the concurrency-equivalence gate (14.4).
  # A new_merge OBJECT is still created fresh on every call (never mutates inputs).
  addr_key <- if (!is.null(pair$left_address) && !is.null(pair$right_address)) {
    paste0(as.character(pair$left_address), "~", as.character(pair$right_address))
  } else {
    left_id
  }
  mid <- paste0(left_id, "~", right_id, "#", operator,
                "@", pair$logical_time, "@", addr_key)

  # New Merge born in the shared space; position is state (A6) via address.
  origin <- if (!is.null(pair$shared_local_space) &&
                is.character(pair$shared_local_space) &&
                length(pair$shared_local_space) == 1L) {
    pair$shared_local_space
  } else {
    paste0(left_id, "~", right_id)
  }
  result <- new_merge(new_content, mid,
                      origin_local = origin,
                      logical_time = pair$logical_time)

  # New Merge lives in the shared space where both inputs co-reside.
  result$address <- pair$shared_local_space

  # Trace records the producing operator + logical round AND the source merges
  # + addresses, so a new Merge is FULLY traceable from its trace alone (gate 7:
  # source locals / packet / router policy / destination position / adjacency /
  # harmony operator / logical round).
  trace <- c(pair$route_trace,
             sprintf("harmony:%s@t=%s", operator, pair$logical_time),
             sprintf("src=%s@%s~%s@%s", left_id, pair$left_address,
                     right_id, pair$right_address),
             sprintf("op=%s", operator))
  trace <- trace[!is.na(trace) & nzchar(trace)]
  if (is.null(trace)) trace <- character(0L)

  ev <- new_harmony_event(pair, operator, result, trace = trace)

  # Validate the produced event (must carry a valid Merge result).
  validate_harmony_event(ev)
  ev
}
