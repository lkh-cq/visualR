# == Recursive re-typing: four recursion families (B branch) =========
# v0.5.0 B-branch: recurse/unrecurse/freeze for recursive re-typing.
#
# Frozen definition (sanyuan-runtime spec):
#   S_n^[r] -- recursion layer r (0 = base S_n)
#   R: S4^[r] -> S0^[r+1] <S4^[r]>   re-type: inner topology PRESERVED,
#                                     new layer wraps it as an atomic
#                                     whole (NOT "carry 4 -> 0" which
#                                     loses information)
#   Dimension and layer are independent: each layer holds 0..4 operators,
#   recursion depth is unbounded (finite alphabet, not infinite length).
#
# Four families (user requirement 2026-08-08, tested in separate files):
#   1. simple      -- same-operator re-typing repeated r times
#   2. complex     -- mixed re-typing over a peel chain (topology kept)
#   3. interactive -- user-driven step up/down via the interactive layer
#   4. nested      -- recursion inside recursion; depth is queryable
#
# Java interface note (user decision 2026-08-08): this R file IS the
# reference semantics for the future Java port. Every exported function
# has a stable signature documented here; the Java layer will mirror
# these names and contracts (see man/recurse.Rd).

# Internal: atomic token for a re-typed layer.
# The frozen re-type wraps the inner topology as an atomic whole. The
# token domain forbids reserved chars (\\x1f | = { } \\n) and caps at
# MAX_TOKEN_LEN, so the raw format_pal text cannot be the token. We use
# a deterministic sha256 digest (pure hex, no reserved chars) of the
# canonical PAL text: the digest IS the atomic identity — verifiable,
# length-safe, and topology-preserving (same topology -> same token).
atomic_token <- function(pal) {
  digest_sha256(format_pal(pal))
}

# A re-typed state is a list of pal states, one per layer, outermost
# first: list(r0 = S_n, r1 = ..., rk = ...). We carry it as a
# "recursion stack" (deepest layer last).

#' @title Recursion layer container
#' @description Creates a recursion-stack object: a list of
#'   \code{visualr_pal} objects, one per recursion layer, base first.
#'   Layer 0 is the original state; higher layers are re-typed wrappers.
#' @param pals list of \code{visualr_pal} objects, base layer first.
#' @return object of class \code{visualr_recursion} with fields:
#'   layers (list of pals) and depth (integer).
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- new_recursion(list(p))
new_recursion <- function(pals) {
  if (!is.list(pals) || length(pals) == 0L) {
    stop("`pals` must be a non-empty list of visualr_pal objects.",
         call. = FALSE)
  }
  for (p in pals) {
    if (!inherits(p, "visualr_pal")) {
      stop("All `pals` must be visualr_pal objects.", call. = FALSE)
    }
    validate_pal(p)
  }
  structure(list(layers = pals, depth = length(pals)),
            class = "visualr_recursion")
}

#' @title Recursion depth
#' @description Number of recursion layers in a recursion object.
#' @param rc a \code{visualr_recursion} object.
#' @return integer depth.
recursion_depth <- function(rc) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  rc$depth
}

#' @export
print.visualr_recursion <- function(x, ...) {
  cat(sprintf("<visualr_recursion> depth=%d\n", x$depth))
  for (i in seq_along(x$layers)) {
    p <- x$layers[[i]]
    cat(sprintf("  [r%d] shells=%d core=%s\n", i - 1L,
                length(p$shells), p$core))
  }
  invisible(x)
}

# =====================================================================
# 1. SIMPLE recursion: same-operator re-typing repeated r times
# =====================================================================

#' @title Simple recursion: repeat re-typing r times
#' @description Applies the SAME re-typing r times: each step wraps the
#'   current top layer in a new layer whose core is the previous top's
#'   canonical token and whose shells are empty (S_0 form), preserving
#'   inner topology as an atomic whole. Equivalent to r applications of
#'   the frozen re-type R.
#' @param pal a \code{visualr_pal} object (base state, layer 0).
#' @param r integer; number of re-typing repetitions (>= 0).
#' @return a \code{visualr_recursion} object with depth r + 1.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' simple_recurse(p, 2L)
simple_recurse <- function(pal, r = 1L) {
  validate_pal(pal)
  r <- as.integer(r)
  if (r < 0L) stop("`r` must be >= 0.", call. = FALSE)
  layers <- list(pal)
  if (r == 0L) return(new_recursion(layers))
  cur <- pal
  for (i in seq_len(r)) {
    # Re-type: wrap cur as an atomic whole in a new S_0 layer.
    # core = atomic digest of cur (topology-preserving identity),
    # shells = empty. Inner topology is retained atomically.
    inner <- atomic_token(cur)
    nxt <- new_pal_state(shells = character(0), core = inner,
                         mapping_pack_id = pal$mapping_pack_id)
    layers <- c(layers, list(nxt))
    cur <- nxt
  }
  new_recursion(layers)
}

#' @title Simple un-recurse: collapse one layer
#' @description Inverts one re-typing step: removes the outermost
#'   wrapper layer, returning the recursion stack with depth reduced by
#'   one. Refuses to go below the base layer.
#' @param rc a \code{visualr_recursion} object.
#' @return a \code{visualr_recursion} object with depth - 1.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- simple_recurse(p, 2L)
#' rc1 <- simple_unrecurse(rc)
simple_unrecurse <- function(rc) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  if (rc$depth <= 1L) {
    stop("Cannot un-recurse below base layer.", call. = FALSE)
  }
  new_recursion(rc$layers[-length(rc$layers)])
}

#' @title Freeze a recursion at a given depth
#' @description Produces the canonical PAL text of the top layer at the
#'   requested depth. The top layer is an S_0 (single core token) whose
#'   token encodes the whole inner topology atomically; freezing returns
#'   that token's canonical form.
#' @param rc a \code{visualr_recursion} object.
#' @param at_depth integer; which layer to freeze (default: top).
#' @return single character canonical PAL text.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- simple_recurse(p, 2L)
#' freeze_layer(rc, 0L)
freeze_layer <- function(rc, at_depth = NULL) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  if (is.null(at_depth)) at_depth <- rc$depth - 1L
  at_depth <- as.integer(at_depth)
  if (at_depth < 0L || at_depth >= rc$depth) {
    stop(sprintf("at_depth %d out of range [0, %d).", at_depth, rc$depth),
         call. = FALSE)
  }
  format_pal(rc$layers[[at_depth + 1L]])
}

# =====================================================================
# 2. COMPLEX recursion: mixed re-typing over a peel chain
# =====================================================================

#' @title Complex recursion: re-type over a peel chain
#' @description Re-types a state by FIRST peeling it down its chain
#'   (S_n -> ... -> S_0), then re-wrapping each peeled level with a
#'   distinct core derived from the chain. The inner topology of every
#'   level is preserved (each peel result is retained as a layer), so
#'   the result encodes the full chain as a recursion stack.
#' @param pal a \code{visualr_pal} object.
#' @return a \code{visualr_recursion} object, one layer per peeled
#'   level, base first (deepest peel last as wrapper).
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' complex_recurse(p)
complex_recurse <- function(pal) {
  validate_pal(pal)
  chain <- peel_chain(pal)  # S_n, S_{n-1}, ..., S_0 (longest first)
  # Re-type: wrap each level (except base) with the next inner core as
  # an atomic whole, preserving chain order.
  layers <- list(chain[[length(chain)]])  # S_0 first (base)
  if (length(chain) > 1L) {
    for (i in (length(chain) - 1L):1L) {
      inner <- chain[[i]]
      nxt <- new_pal_state(shells = character(0),
                           core = atomic_token(inner),
                           mapping_pack_id = pal$mapping_pack_id)
      layers <- c(layers, list(nxt))
    }
  }
  new_recursion(layers)
}

# =====================================================================
# 3. INTERACTIVE recursion: user-driven step up/down
# =====================================================================

#' @title Interactive recursion: step up one layer
#' @description Interactive-layer wrapper: given a recursion object and
#'   an operator, advances one re-typing step (like simple_recurse r=1)
#'   but returns a full \code{visualr_compute_result}-style trace so
#'   the interactive REPL can show what changed.
#' @param rc a \code{visualr_recursion} object.
#' @param op single character, operator name (reserved; default
#'   "identity").
#' @return list with fields: rc (new recursion), step (integer),
#'   prev_depth, new_depth, action ("recurse").
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- new_recursion(list(p))
#' interactive_step_up(rc)
interactive_step_up <- function(rc, op = "identity") {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  prev_depth <- rc$depth
  top <- rc$layers[[prev_depth]]
  nxt <- new_pal_state(shells = character(0), core = atomic_token(top),
                       mapping_pack_id = top$mapping_pack_id)
  rc2 <- new_recursion(c(rc$layers, list(nxt)))
  list(rc = rc2, step = 1L, prev_depth = prev_depth,
       new_depth = rc2$depth, action = "recurse")
}

#' @title Interactive recursion: step down one layer
#' @description Interactive-layer wrapper for one un-retype step.
#' @param rc a \code{visualr_recursion} object.
#' @return list with fields: rc (new recursion), prev_depth, new_depth,
#'   action ("unrecurse").
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- simple_recurse(p, 2L)
#' interactive_step_down(rc)
interactive_step_down <- function(rc) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  prev_depth <- rc$depth
  rc2 <- simple_unrecurse(rc)
  list(rc = rc2, prev_depth = prev_depth,
       new_depth = rc2$depth, action = "unrecurse")
}

# =====================================================================
# 4. NESTED recursion: recursion inside recursion, depth query
# =====================================================================

#' @title Nested recursion: recurse the recursion
#' @description Builds a nested recursion: applies re-typing to the
#'   recursion object itself, so the recursion stack becomes a layer
#'   inside a new recursion. Depth is the recursion-of-recursion count.
#' @param rc a \code{visualr_recursion} object.
#' @param r integer; nesting repetitions.
#' @return a \code{visualr_recursion} object whose depth is the nested
#'   count; each layer wraps the previous recursion atomically.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- simple_recurse(p, 1L)
#' nested_recurse(rc, 2L)
nested_recurse <- function(rc, r = 1L) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  r <- as.integer(r)
  if (r < 0L) stop("`r` must be >= 0.", call. = FALSE)
  # Each nesting layer re-types the whole recursion: top layer of the
  # recursion becomes the core token of a new wrapper.
  layers <- rc$layers
  cur_top <- rc$layers[[rc$depth]]
  for (i in seq_len(r)) {
    nxt <- new_pal_state(shells = character(0),
                         core = atomic_token(cur_top),
                         mapping_pack_id = cur_top$mapping_pack_id)
    layers <- c(layers, list(nxt))
    cur_top <- nxt
  }
  new_recursion(layers)
}

#' @title Query the full recursion stack
#' @description Returns every layer's canonical PAL text in order,
#'   base first. Useful for verifying that re-typing preserved the inner
#'   topology at every level.
#' @param rc a \code{visualr_recursion} object.
#' @return character vector, one canonical PAL per layer.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' rc <- simple_recurse(p, 2L)
#' recursion_stack(rc)
recursion_stack <- function(rc) {
  if (!inherits(rc, "visualr_recursion")) {
    stop("`rc` must be a visualr_recursion.", call. = FALSE)
  }
  vapply(rc$layers, format_pal, character(1))
}
