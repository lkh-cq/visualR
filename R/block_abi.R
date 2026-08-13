# == Shape-preserving block ABI (TCN reference, E) ===================
# STATUS: FROZEN (B-promotion 2026-08-13)
#   Promoted from reference_additive after three prerequisites:
#   - testthat coverage: tests/testthat/*.R, suite total 449 / 0 failures
#   - benchmark: inst/BENCHMARK_shape_contract_v060.md (sub-8 us/op)
#   - cross-lang contract: inst/CROSS_LANG_SHAPE_CONTRACT_v060.md
#   Semantic changes after freeze go through the bug-fix channel only.
#   TCN's TemporalBlock is shape-preserving: a block may transform the
#   channel (carrier) dimension but must not silently change the
#   spatial/temporal shape, so blocks compose by shape contract alone.
#   This file exposes that discipline as an auditable checker for
#   visualR compute blocks (lane kernels, carrier steps, emergence
#   layers): a block either declares itself shape-preserving, or it
#   declares an explicit adaptation -- anything else fails closed.

#' @title Check whether a block transformation is shape-preserving
#' @description Compares input and output shapes of a compute block.
#'   Shape-preserving means the two shapes are identical. The checker
#'   does not inspect values; it is the block-composition contract
#'   only (TCN TemporalBlock discipline).
#' @param input_shape integer vector, input dimensions (e.g. \code{c(3L, 3L)}).
#' @param output_shape integer vector, output dimensions.
#' @return logical(1), TRUE when identical.
#' @examples
#' check_shape_preserving(c(3L, 3L), c(3L, 3L))   # TRUE
#' check_shape_preserving(c(3L, 3L), c(11L, 11L)) # FALSE
check_shape_preserving <- function(input_shape, output_shape) {
  if (!is.numeric(input_shape) || !is.numeric(output_shape)) {
    stop("`input_shape` and `output_shape` must be numeric.",
         call. = FALSE)
  }
  identical(as.integer(input_shape), as.integer(output_shape))
}

#' @title Build a block ABI record (unified block contract)
#' @description Constructs a block ABI record that a compute block
#'   declares before it may be composed into a stack. The record
#'   captures the block name, declared input/output shapes, whether
#'   it is shape-preserving, and an optional adaptation note.
#'
#'   Fail-closed: a block that changes shape without an explicit
#'   \code{adaptation} string is refused (\code{abi_ok = FALSE});
#'   this mirrors TCN's rule that a shape change requires an explicit
#'   downsample layer, never an implicit one.
#' @param block_name character(1), block identifier.
#' @param input_shape integer vector, declared input dimensions.
#' @param output_shape integer vector, declared output dimensions.
#' @param adaptation character(1) or NULL. Required when shapes differ.
#'   Describes the explicit adaptation (e.g. \code{"1x1 downsample"}).
#' @return A list of class \code{visualr_block_abi} with fields
#'   block_name, input_shape, output_shape, shape_preserving,
#'   adaptation, abi_ok.
#' @examples
#' block_contract("identity_lane", c(3L, 3L), c(3L, 3L))
#' block_contract("carrier_jump", c(3L, 3L), c(11L, 11L),
#'                adaptation = "11x11 carrier view")
block_contract <- function(block_name, input_shape, output_shape,
                           adaptation = NULL) {
  if (!is.character(block_name) || length(block_name) != 1L ||
      is.na(block_name) || !nzchar(block_name)) {
    stop("`block_name` must be one non-empty character.", call. = FALSE)
  }
  if (!is.numeric(input_shape) || !is.numeric(output_shape) ||
      length(input_shape) == 0L || length(output_shape) == 0L) {
    stop("`input_shape` and `output_shape` must be non-empty numeric.",
         call. = FALSE)
  }
  if (!is.null(adaptation) &&
      (!is.character(adaptation) || length(adaptation) != 1L ||
       is.na(adaptation) || !nzchar(adaptation))) {
    stop("`adaptation` must be NULL or one non-empty character.",
         call. = FALSE)
  }

  in_sh  <- as.integer(input_shape)
  out_sh <- as.integer(output_shape)
  same   <- identical(in_sh, out_sh)
  abi_ok <- same || !is.null(adaptation)

  structure(
    list(
      block_name = block_name,
      input_shape = in_sh,
      output_shape = out_sh,
      shape_preserving = same,
      adaptation = adaptation,
      abi_ok = abi_ok
    ),
    class = "visualr_block_abi"
  )
}

#' @export
print.visualr_block_abi <- function(x, ...) {
  cat(sprintf("<visualr_block_abi> %s in=%s out=%s ok=%s\n",
              x$block_name,
              paste(x$input_shape, collapse = "x"),
              paste(x$output_shape, collapse = "x"),
              x$abi_ok))
  if (!x$shape_preserving) {
    cat(sprintf("  adaptation: %s\n",
                if (is.null(x$adaptation)) "(MISSING -> abi NOT ok)"
                else x$adaptation))
  }
  invisible(x)
}
