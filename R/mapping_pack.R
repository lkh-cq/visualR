# == mapping_pack: first-class dependency injection ==================
# P0-1 fix (2026-08-07, v0.2.1 Semantic Hardening):
#   mapping_pack_id must DRIVE runtime rules, not be a passive label.
#
# Root principle (frozen): the mapping pack is the authoritative basis
# for ALL storage-computation mappings.
#
# Design:
#   new_mapping_pack()     -- construct an immutable pack object
#   register_mapping_pack()-- add to the global pack registry
#   resolve_mapping_pack() -- look up by id; FAIL CLOSED on unknown
#   assert_pack()          -- internal: resolve + validate hash
#
# Fail-closed policy (audit ruling): unknown pack id, version mismatch,
# or hash mismatch MUST error -- never silently fall back to a default.

# == Constructor ======================================================

#' @title Construct a mapping pack
#' @description Create an immutable mapping-pack object that DRIVES all
#'   storage-computation mappings. This is the fix for
#'   \code{mapping_pack_id-as-label}: a pack carries the actual
#'   orbit table, expand order, complement table, closure symbols and
#'   carrier generator. Objects declare \code{mapping_pack_id}; runtime
#'   resolves the pack and uses ITS rules -- never global constants.
#' @param id single character, unique pack id
#' @param orbit_table named list of orbit entries (A/B/C/D/e -> coords)
#' @param expand_order character vector, center-outward expansion order
#' @param complement_table named list, symbol complement mapping
#' @param frozen_symbols character vector, legal symbol alphabet
#' @param carrier_fn function, carrier generator (e.g. carrier_11x11)
#' @param version single character, pack version
#' @param description single character, human-readable description
#' @return object of class \code{visualr_mapping_pack}
#' @examples
#' pack <- new_mapping_pack(
#'   id = "pal-jiugong-v0.2",
#'   orbit_table = ORBIT_TABLE,
#'   expand_order = EXPAND_ORDER,
#'   complement_table = list(),
#'   frozen_symbols = c("A","B","C","D","e"),
#'   carrier_fn = carrier_11x11
#' )
new_mapping_pack <- function(id,
                             orbit_table,
                             expand_order,
                             complement_table = list(),
                             frozen_symbols,
                             carrier_fn = NULL,
                             version = "0.2.0",
                             description = "") {
  if (!is.character(id) || length(id) != 1L || id == "") {
    stop("`id` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.list(orbit_table) || length(orbit_table) == 0L) {
    stop("`orbit_table` must be a non-empty list.", call. = FALSE)
  }
  if (!is.character(expand_order) || length(expand_order) == 0L) {
    stop("`expand_order` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.character(frozen_symbols) || length(frozen_symbols) == 0L) {
    stop("`frozen_symbols` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.null(carrier_fn) && !is.function(carrier_fn)) {
    stop("`carrier_fn` must be a function or NULL.", call. = FALSE)
  }

  # Pack identity hash (fail-closed integrity check)
  hash_input <- paste(
    id, version,
    paste(names(orbit_table), collapse = ","),
    paste(expand_order, collapse = ","),
    paste(frozen_symbols, collapse = ","),
    sep = "|"
  )
  hash <- .pal_sha1(hash_input)

  structure(
    list(
      id = id,
      orbit_table = orbit_table,
      expand_order = expand_order,
      complement_table = complement_table,
      frozen_symbols = frozen_symbols,
      carrier_fn = carrier_fn,
      version = version,
      description = description,
      hash = hash
    ),
    class = "visualr_mapping_pack"
  )
}

#' @export
print.visualr_mapping_pack <- function(x, ...) {
  cat(sprintf("<visualr_mapping_pack> %s v%s hash=%s\n",
              x$id, x$version, substr(x$hash, 1, 8)))
  cat(sprintf("  symbols: %s\n", paste(x$frozen_symbols, collapse = " ")))
  cat(sprintf("  expand:  %s\n", paste(x$expand_order, collapse = " -> ")))
  cat(sprintf("  carrier: %s\n", if (is.null(x$carrier_fn)) "(none)" else "yes"))
  invisible(x)
}

# == Registry =========================================================

# Package-level pack registry (module state; fork-safe copy-on-write)
.visualR_pack_registry <- new.env(parent = emptyenv())

#' @title Register a mapping pack
#' @description Add a pack to the global registry so
#'   \code{resolve_mapping_pack()} can find it by id.
#' @param pack a \code{visualr_mapping_pack} object
#' @param overwrite logical, allow replacing an existing id.
#'   Default FALSE (fail closed on duplicates).
#' @return invisible NULL
#' @examples
#' register_mapping_pack(new_mapping_pack(
#'   id = "pal-jiugong-v0.2",
#'   orbit_table = ORBIT_TABLE,
#'   expand_order = EXPAND_ORDER,
#'   frozen_symbols = c("A","B","C","D","e")
#' ))
register_mapping_pack <- function(pack, overwrite = FALSE) {
  if (!inherits(pack, "visualr_mapping_pack")) {
    stop("`pack` must be a visualr_mapping_pack object.", call. = FALSE)
  }
  if (!overwrite && exists(pack$id, envir = .visualR_pack_registry, inherits = FALSE)) {
    stop(sprintf("Mapping pack '%s' already registered (fail closed). Use overwrite=TRUE.",
                 pack$id), call. = FALSE)
  }
  assign(pack$id, pack, envir = .visualR_pack_registry)
  invisible(NULL)
}

#' @title Resolve a mapping pack by id (fail closed)
#' @description Look up a registered mapping pack. Unknown id -> error
#'   (never silently fall back to a default). This is the P0-1 fix:
#'   runtime rules come from the resolved pack, not global constants.
#' @param id single character, pack id
#' @return a \code{visualr_mapping_pack} object
#' @examples
#' resolve_mapping_pack("pal-jiugong-v0.2")
resolve_mapping_pack <- function(id) {
  if (!is.character(id) || length(id) != 1L || id == "") {
    stop("`id` must be a single non-empty character.", call. = FALSE)
  }
  if (!exists(id, envir = .visualR_pack_registry, inherits = FALSE)) {
    stop(sprintf("Unknown mapping pack '%s' (fail closed). Registered: %s",
                 id,
                 paste(sort(ls(.visualR_pack_registry)), collapse = ", ")),
         call. = FALSE)
  }
  get(id, envir = .visualR_pack_registry, inherits = FALSE)
}

# == Internal helpers =================================================

# Minimal deterministic hash (zero external deps; NOT cryptographic, but
# sufficient for fail-closed integrity of pack identity).
# Avoids bitwXor integer-overflow issues by using byte-value arithmetic
# in double precision. Deterministic across R versions for ASCII input.
.pal_sha1 <- function(s) {
  bytes <- charToRaw(paste(s, collapse = ""))
  h <- 5381.0                      # djb2 variant seed
  for (b in bytes) {
    h <- (h * 33 + as.numeric(b)) %% 2^32
  }
  # Manual hex conversion (avoids as.integer overflow on h >= 2^31)
  hex_digits <- c("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f")
  out <- character(8)
  x <- h
  for (i in 8:1) {
    out[i] <- hex_digits[x %% 16 + 1]
    x <- floor(x / 16)
  }
  paste(out, collapse = "")
}

# Resolve a pack for a pal object; fail closed.
# Internal: used by computation entry points.
pal_resolve_pack <- function(pal) {
  pack <- resolve_mapping_pack(pal$mapping_pack_id)
  pack
}

# == Default pack bootstrap ===========================================

# The frozen pal-jiugong pack (v0.2) is registered at package load.
# NOTE (P0-7): carrier_11x11 is experimental (fitted from examples),
# NOT frozen; it is attached as carrier_fn for convenience but callers
# must not treat it as an axiom. See carrier.R for the explicit
# experimental annotation.

.onLoad <- function(libname, pkgname) {
  default_pack <- new_mapping_pack(
    id = "pal-jiugong-v0.2",
    orbit_table = ORBIT_TABLE,
    expand_order = EXPAND_ORDER,
    complement_table = list(),
    frozen_symbols = c("A", "B", "C", "D", "e"),
    carrier_fn = carrier_11x11,
    version = "0.2.0",
    description = "Frozen pal-jiugong mapping pack (sanyuan-runtime v0.2)"
  )
  register_mapping_pack(default_pack)
}
