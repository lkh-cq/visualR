# == Address-bound numeric field ====================================
# STATUS: reference_experimental (v0.6.2)
#
# Numeric values are attached to declared addresses.  PAL token order
# is never converted into numbers implicitly.  Matrix, path and signal
# metadata remain explicit and independently auditable.

.field_character_scalar <- function(x, name, allow_null = FALSE) {
  if (allow_null && is.null(x)) return(NULL)
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x) ||
      grepl("\n|\r", x)) {
    stop(sprintf("`%s` must be one non-empty, single-line character value.",
                 name), call. = FALSE)
  }
  x
}

.field_is_numeric <- function(x) {
  is.numeric(x) || is.complex(x)
}

.field_encode_values <- function(x) {
  encode_one <- function(z) {
    if (is.complex(z)) {
      paste0(
        format(Re(z), digits = 17L, scientific = TRUE, trim = TRUE),
        "+",
        format(Im(z), digits = 17L, scientific = TRUE, trim = TRUE),
        "i"
      )
    } else {
      format(z, digits = 17L, scientific = TRUE, trim = TRUE)
    }
  }
  vapply(as.list(x), encode_one, character(1))
}

.field_length_prefix <- function(x) {
  x <- enc2utf8(as.character(x))
  paste0(nchar(x, type = "bytes"), ":", x)
}

.numeric_field_source_hash <- function(field) {
  signal <- field$signal
  .validate_signal_envelope(signal)
  parts <- c(
    "visualr_numeric_field_v1",
    paste(field$address$address_id, collapse = ","),
    paste(.field_encode_values(field$address$global_address), collapse = ","),
    paste(.field_encode_values(field$address$row), collapse = ","),
    paste(.field_encode_values(field$address$col), collapse = ","),
    paste(.field_encode_values(field$value), collapse = ","),
    paste(as.integer(field$mask), collapse = ","),
    field$value_semantics,
    field$unit,
    field$domain,
    paste(field$shape, collapse = "x"),
    field$boundary_state,
    if (is.na(field$mapping_pack$id)) "NA" else field$mapping_pack$id,
    if (is.na(field$mapping_pack$version)) "NA" else field$mapping_pack$version,
    if (is.na(field$mapping_pack$hash)) "NA" else field$mapping_pack$hash,
    signal$source_kind,
    signal$timescale,
    signal$density,
    signal$update_interval,
    signal$spatial_scope,
    signal$persistence,
    signal$provenance,
    format(signal$uncertainty, digits = 17L, scientific = TRUE),
    signal$declared,
    field$topology_source
  )
  canonical <- paste(.field_length_prefix(parts), collapse = "|")
  digest_sha256(canonical)
}

.field_mapping_identity <- function(pal) {
  pack <- resolve_mapping_pack(pal$mapping_pack_id)
  list(id = pack$id, version = pack$version, hash = pack$hash)
}

.matrix_field_addresses <- function(x) {
  nr <- nrow(x)
  nc <- ncol(x)
  rows <- as.integer(as.vector(row(x)))
  cols <- as.integer(as.vector(col(x)))
  data.frame(
    address_id = sprintf("R%05d:C%05d", rows, cols),
    global_address = rep.int(NA_integer_, length(rows)),
    row = rows,
    col = cols,
    stringsAsFactors = FALSE
  )
}

.path_field_addresses <- function(window) {
  data.frame(
    address_id = sprintf("G%+011d", window$addresses$global_address),
    global_address = window$addresses$global_address,
    row = rep.int(NA_integer_, window$width),
    col = rep.int(NA_integer_, window$width),
    stringsAsFactors = FALSE
  )
}

#' @title Construct an address-bound numeric field
#' @description Attaches finite numeric or complex values to a PAL path or a
#'   numeric matrix without assigning numerical meaning to symbolic tokens.
#'   Address identity, value semantics, units, mask, boundary state, mapping
#'   pack identity, signal envelope and source hash are stored explicitly.
#' @param x a \code{visualr_pal}, \code{visualr_pal_window},
#'   \code{visualr_dilated_plan}, or numeric/complex matrix
#' @param values values to bind for PAL/path inputs; matrix inputs bind their
#'   own values and require this to remain \code{NULL}
#' @param value_semantics non-empty caller-declared numerical meaning
#' @param unit optional unit string; defaults to \code{"unspecified"}
#' @param mask optional logical visibility vector, one per address
#' @param boundary_state explicit matrix boundary state; PAL inputs inherit
#'   their declared window state and reject a conflicting override
#' @param signal optional \code{visualr_signal_envelope}
#' @return a \code{visualr_numeric_field}
new_numeric_field <- function(x,
                              values = NULL,
                              value_semantics,
                              unit = NULL,
                              mask = NULL,
                              boundary_state = NULL,
                              signal = NULL) {
  value_semantics <- .field_character_scalar(
    value_semantics, "value_semantics"
  )
  unit <- if (is.null(unit)) {
    "unspecified"
  } else {
    .field_character_scalar(unit, "unit")
  }
  signal <- if (is.null(signal)) .default_signal_envelope() else signal
  .validate_signal_envelope(signal)

  if (inherits(x, "visualr_dilated_plan")) {
    validate_dilated_plan(x)
    x <- x$window
  }
  if (inherits(x, "visualr_pal")) {
    x <- new_pal_window(x, boundary = "closed")
  }

  if (inherits(x, "visualr_pal_window")) {
    .validate_pal_window(x)
    if (is.null(values)) {
      stop("PAL/path fields require one value per address.", call. = FALSE)
    }
    expected_boundary <- x$boundary
    if (!is.null(boundary_state) &&
        !identical(boundary_state, expected_boundary)) {
      stop("`boundary_state` conflicts with the PAL window boundary.",
           call. = FALSE)
    }
    boundary_state <- expected_boundary
    address <- .path_field_addresses(x)
    shape <- as.integer(x$width)
    domain <- "path"
    mapping_pack <- .field_mapping_identity(x$pal)
    topology_source <- "pal_window"
  } else if (is.matrix(x)) {
    if (!.field_is_numeric(x)) {
      stop("Matrix `x` must contain numeric or complex values.",
           call. = FALSE)
    }
    if (nrow(x) < 1L || ncol(x) < 1L) {
      stop("Matrix fields require positive row and column dimensions.",
           call. = FALSE)
    }
    if (!is.null(values)) {
      stop("Matrix fields bind the values already present in `x`.",
           call. = FALSE)
    }
    values <- as.vector(x)
    if (is.null(boundary_state)) {
      stop("Matrix fields require an explicit `boundary_state`.",
           call. = FALSE)
    }
    if (!is.character(boundary_state) || length(boundary_state) != 1L ||
        is.na(boundary_state) ||
        !boundary_state %in% c("closed", "open")) {
      stop("`boundary_state` must be 'closed' or 'open'.", call. = FALSE)
    }
    address <- .matrix_field_addresses(x)
    shape <- as.integer(dim(x))
    domain <- "carrier"
    mapping_pack <- list(
      id = NA_character_, version = NA_character_, hash = NA_character_
    )
    topology_source <- "matrix"
  } else {
    stop(paste0(
      "`x` must be a visualr_pal, visualr_pal_window, ",
      "visualr_dilated_plan, or numeric/complex matrix."
    ), call. = FALSE)
  }

  if (!.field_is_numeric(values)) {
    stop("`values` must be numeric or complex.", call. = FALSE)
  }
  if (length(values) != nrow(address)) {
    stop("Numeric fields require one value per address.", call. = FALSE)
  }
  if (any(!is.finite(values))) {
    stop("`values` must contain only finite values.", call. = FALSE)
  }
  if (is.null(mask)) mask <- rep.int(TRUE, length(values))
  if (!is.logical(mask) || length(mask) != length(values) || anyNA(mask)) {
    stop("`mask` must be a non-NA logical value per address.",
         call. = FALSE)
  }
  if (anyDuplicated(address$address_id)) {
    stop("Numeric field addresses must be unique.", call. = FALSE)
  }

  field <- structure(
    list(
      address = address,
      value = as.vector(values),
      value_semantics = value_semantics,
      unit = unit,
      mask = mask,
      boundary_state = boundary_state,
      domain = domain,
      shape = shape,
      mapping_pack = mapping_pack,
      signal = signal,
      topology_source = topology_source,
      source_hash = NA_character_,
      status = "reference_experimental"
    ),
    class = "visualr_numeric_field"
  )
  field$source_hash <- .numeric_field_source_hash(field)
  validate_numeric_field(field)
  field
}

#' @title Validate an address-bound numeric field
#' @param field a \code{visualr_numeric_field}
#' @return invisible \code{TRUE}; errors on any stale or ambiguous field
validate_numeric_field <- function(field) {
  if (!inherits(field, "visualr_numeric_field")) {
    stop("`field` must be a visualr_numeric_field.", call. = FALSE)
  }
  required <- c(
    "address", "value", "value_semantics", "unit", "mask",
    "boundary_state", "domain", "shape", "mapping_pack", "signal",
    "topology_source", "source_hash", "status"
  )
  if (!identical(names(field), required)) {
    stop("Numeric field schema is invalid.", call. = FALSE)
  }
  if (!is.data.frame(field$address) ||
      !identical(names(field$address),
                 c("address_id", "global_address", "row", "col")) ||
      anyDuplicated(field$address$address_id)) {
    stop("Numeric field address table is invalid.", call. = FALSE)
  }
  if (nrow(field$address) == 0L ||
      !is.character(field$address$address_id) ||
      anyNA(field$address$address_id) ||
      any(!nzchar(field$address$address_id)) ||
      !is.integer(field$address$global_address) ||
      !is.integer(field$address$row) || !is.integer(field$address$col)) {
    stop("Numeric field requires non-empty character address identities.",
         call. = FALSE)
  }
  if (!.field_is_numeric(field$value) ||
      length(field$value) != nrow(field$address) ||
      any(!is.finite(field$value))) {
    stop("Numeric field values are invalid.", call. = FALSE)
  }
  .field_character_scalar(field$value_semantics, "field$value_semantics")
  .field_character_scalar(field$unit, "field$unit")
  if (!is.logical(field$mask) || length(field$mask) != length(field$value) ||
      anyNA(field$mask)) {
    stop("Numeric field mask is invalid.", call. = FALSE)
  }
  if (!is.character(field$boundary_state) ||
      length(field$boundary_state) != 1L || is.na(field$boundary_state) ||
      !is.character(field$domain) || length(field$domain) != 1L ||
      is.na(field$domain) ||
      !field$boundary_state %in% c("closed", "open") ||
      !field$domain %in% c("path", "carrier")) {
    stop("Numeric field domain/boundary is invalid.", call. = FALSE)
  }
  if (!is.integer(field$shape) || length(field$shape) == 0L ||
      anyNA(field$shape) || any(field$shape < 1L) ||
      prod(field$shape) != length(field$value)) {
    stop("Numeric field shape is invalid.", call. = FALSE)
  }
  if (!is.list(field$mapping_pack) ||
      !identical(names(field$mapping_pack), c("id", "version", "hash"))) {
    stop("Numeric field mapping-pack identity is invalid.", call. = FALSE)
  }
  valid_pack_value <- vapply(field$mapping_pack, function(value) {
    is.character(value) && length(value) == 1L &&
      (is.na(value) || nzchar(value))
  }, logical(1))
  if (!all(valid_pack_value) ||
      !is.character(field$topology_source) ||
      length(field$topology_source) != 1L ||
      is.na(field$topology_source) ||
      !field$topology_source %in% c("pal_window", "matrix") ||
      !is.character(field$source_hash) || length(field$source_hash) != 1L ||
      is.na(field$source_hash) || !nzchar(field$source_hash) ||
      !identical(field$status, "reference_experimental")) {
    stop("Numeric field identity metadata is invalid.", call. = FALSE)
  }
  if (is.na(field$mapping_pack$id) &&
      (!is.na(field$mapping_pack$version) ||
       !is.na(field$mapping_pack$hash))) {
    stop("Numeric field mapping-pack identity is incomplete.", call. = FALSE)
  }
  if (!is.na(field$mapping_pack$id)) {
    pack <- resolve_mapping_pack(field$mapping_pack$id)
    if (!identical(pack$version, field$mapping_pack$version) ||
        !identical(pack$hash, field$mapping_pack$hash)) {
      stop("Numeric field mapping-pack identity is stale.", call. = FALSE)
    }
  }
  if (identical(field$domain, "path")) {
    if (length(field$shape) != 1L ||
        anyNA(field$address$global_address) ||
        anyDuplicated(field$address$global_address) ||
        is.unsorted(field$address$global_address, strictly = TRUE) ||
        any(!is.na(field$address$row)) || any(!is.na(field$address$col)) ||
        !identical(field$address$address_id,
                   sprintf("G%+011d", field$address$global_address)) ||
        is.na(field$mapping_pack$id) ||
        !identical(field$topology_source, "pal_window")) {
      stop("Path field address coordinates are invalid.", call. = FALSE)
    }
  } else {
    expected <- .matrix_field_addresses(
      matrix(0, nrow = field$shape[[1L]], ncol = field$shape[[2L]])
    )
    if (length(field$shape) != 2L ||
        !all(is.na(unlist(field$mapping_pack, use.names = FALSE))) ||
        !identical(field$topology_source, "matrix") ||
        !identical(field$address, expected)) {
      stop("Carrier field address coordinates/order are invalid.",
           call. = FALSE)
    }
  }
  .validate_signal_envelope(field$signal)
  expected <- .numeric_field_source_hash(field)
  if (!identical(expected, field$source_hash)) {
    stop("Numeric field source hash mismatch (fail closed).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
print.visualr_numeric_field <- function(x, ...) {
  validate_numeric_field(x)
  cat(sprintf(
    "<visualr_numeric_field> domain=%s addresses=%d semantics=%s boundary=%s\n",
    x$domain, length(x$value), x$value_semantics, x$boundary_state
  ))
  cat(sprintf("  source_hash=%s signal=%s_%s\n",
              substr(x$source_hash, 1L, 12L),
              x$signal$timescale, x$signal$density))
  invisible(x)
}
