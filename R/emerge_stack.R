# == Derived emergence stack (TCN reference, B + F) ==================
# STATUS: FROZEN (B-promotion 2026-08-13)
#   Promoted from reference_additive after three prerequisites:
#   - testthat coverage: tests/testthat/*.R, suite total 449 / 0 failures
#   - benchmark: inst/BENCHMARK_shape_contract_v060.md (sub-8 us/op)
#   - cross-lang contract: inst/CROSS_LANG_SHAPE_CONTRACT_v060.md
#   Semantic changes after freeze go through the bug-fix channel only.
#   TCN's TemporalConvNet is built from a minimal interface: a channel
#   list num_channels defines the whole stack, and each level derives
#   its dilation as 2^i automatically. The stack composition contract
#   is: levels are shape-preserving blocks applied in order.
#
#   visualR analogue: emerge_stack() derives an ordered stack of
#   emergence levels from a width list. Each level records its ABI
#   (block_contract) and its growth law value (growth_law), so the
#   stack is auditable without executing anything. This is the
#   high-level derived constructor (F) folded into the stack API (B).

#' @title Derive an emergence stack from a width list
#' @description Builds an ordered emergence stack from a carrier width
#'   list, mirroring TCN's num_channels interface: the caller supplies
#'   the widths, the stack derives per-level growth-law values and
#'   block ABI records automatically.
#'
#'   Level k (k = 1 .. length(widths)) receives:
#'   \itemize{
#'     \item width = widths[k];
#'     \item dilation = growth_law("dilation_power", k - 1L)$value;
#'     \item abi = block_contract(level, previous_width, current_width)
#'       with explicit adaptation when widths differ (carrier_adapter
#'       discipline), so a width change is never implicit.
#'   }
#' @param widths integer vector of carrier widths, length >= 1, all
#'   positive. The first width is the input width.
#' @return A list of class \code{visualr_emerge_stack} with levels
#'   (one data frame row per level) and abi_ok (all levels legal).
#' @examples
#' emerge_stack(c(3L, 3L, 3L))     # 3 shape-preserving levels
#' emerge_stack(c(3L, 4L, 4L))     # level 2 adapts 3x3 -> 4x4
emerge_stack <- function(widths) {
  widths <- as.integer(widths)
  if (length(widths) < 1L || anyNA(widths) || any(widths < 1L)) {
    stop("`widths` must be a non-empty integer vector of positive widths.",
         call. = FALSE)
  }

  n <- length(widths)
  levels <- vector("list", n)
  for (k in seq_len(n)) {
    prev_width <- if (k == 1L) widths[1L] else widths[k - 1L]
    cur_width  <- widths[k]
    adapt_note <- if (prev_width == cur_width) NULL
                  else sprintf("carrier_adapter %dx%d -> %dx%d",
                               prev_width, prev_width, cur_width, cur_width)
    abi <- block_contract(
      block_name = sprintf("emerge_level_%d", k),
      input_shape = c(prev_width, prev_width),
      output_shape = c(cur_width, cur_width),
      adaptation = adapt_note
    )
    levels[[k]] <- data.frame(
      level = k,
      width = cur_width,
      dilation = growth_law("dilation_power", k - 1L)$value,
      shape_preserving = abi$shape_preserving,
      adaptation = if (is.null(abi$adaptation)) "" else abi$adaptation,
      abi_ok = abi$abi_ok,
      stringsAsFactors = FALSE
    )
  }

  stack <- do.call(rbind, levels)
  structure(
    list(
      levels = stack,
      n_levels = n,
      widths = widths,
      abi_ok = all(stack$abi_ok)
    ),
    class = "visualr_emerge_stack"
  )
}

#' @export
print.visualr_emerge_stack <- function(x, ...) {
  cat(sprintf("<visualr_emerge_stack> %d levels abi_ok=%s\n",
              x$n_levels, x$abi_ok))
  print(x$levels, row.names = FALSE)
  invisible(x)
}
