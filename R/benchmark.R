# == benchmark_storage: v0.4.x measurement harness ====================
# Reusable, reproducible measurement of the compact-vs-expanded storage
# trade-off. This is the v0.4.x Efficiency-gate measurement infrastructure
# (DEVELOPMENT_PLAN_v0.5.0.md §10).
#
# Design principles (align with DEVELOPMENT_PLAN_v0.5.0.md):
#   - G1 "store less / move less": PAL serialization is the transport unit.
#   - The matrix is an on-demand working view (materialize), NOT resident.
#   - Reduction RATIOS are the portable claim; absolute byte counts are
#     R-version/platform-specific (serialization header version).
#
# The function returns a reproducible data.frame, one row per measured
# state, with columns:
#   dim          -- state label (S_1 .. S_5)
#   pal_bytes    -- format_pal() serialized content bytes (UTF-8)
#   matrix_bytes -- serialize() of the materialized working matrix
#   cells        -- grid cell count (NULL for non-carrier states)
#   reduction    -- matrix_bytes / pal_bytes (>=1 means PAL is smaller)
#
# NOTE: This measures TRANSPORT/PERSISTENCE bytes (G1), which is the
# documented advantage of PAL. It does NOT claim R object-memory
# advantage -- the S3 pal object carries list+class overhead that makes
# it LARGER in object.size() than the matrix (see pre-freeze report §3).

#' @title Benchmark compact vs expanded storage bytes
#' @description Reproducible measurement of stored/transport bytes for
#'   PAL (compact) vs materialized matrix (expanded) representations
#'   across representative dimensions S_1..S_5.
#' @return data.frame with columns: dim, pal_bytes, matrix_bytes,
#'   cells, reduction. `reduction = matrix_bytes / pal_bytes`; values
#'   >= 1 mean PAL is more compact (smaller) than the matrix.
#' @examples
#' benchmark_storage()
benchmark_storage <- function() {
  # Representative states across dimensions
  defs <- list(
    S1 = list(shells = character(0), core = "A"),
    S2 = list(shells = "A", core = "b"),
    S3 = list(shells = c("A", "B"), core = "c"),
    S4 = list(shells = c("A", "B", "C", "D"), core = "e"),
    S5 = list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )

  measure_matrix <- function(pal) {
    m <- materialize(pal)
    if (!m$ok) {
      return(list(bytes = NA_real_, cells = NA_integer_))
    }
    con <- rawConnection(raw(0), "w")
    serialize(m$grid, con)
    bytes <- length(rawConnectionValue(con))
    cells <- length(m$grid)
    close(con)
    list(bytes = as.numeric(bytes), cells = as.integer(cells))
  }

  rows <- lapply(names(defs), function(nm) {
    d <- defs[[nm]]
    pal <- new_pal_state(d$shells, d$core)
    pal_bytes <- nchar(format_pal(pal), type = "bytes")
    mx <- measure_matrix(pal)
    # High-dim S_5 uses the 11x11 carrier (121 cells) -- the case where
    # PAL's O(n) advantage over the O(n^2) matrix is most pronounced.
    if (nm == "S5") {
      c11 <- carrier_11x11()
      con <- rawConnection(raw(0), "w")
      serialize(c11, con)
      mx$bytes <- as.numeric(length(rawConnectionValue(con)))
      mx$cells <- as.integer(length(c11))
      close(con)
    }
    reduction <- if (is.na(mx$bytes)) NA_real_ else mx$bytes / pal_bytes
    data.frame(
      dim = nm, pal_bytes = pal_bytes,
      matrix_bytes = mx$bytes, cells = mx$cells,
      reduction = reduction,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}