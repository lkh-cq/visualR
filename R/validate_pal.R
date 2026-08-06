# ── validate_pal: Layer 1 invariant verification ────────────────────
# Checks structure and types of visualr_pal.
# Audit ruling R5: does NOT check active_singularities or phase.
# Audit ruling R6: does NOT check rho+theta consistency.

validate_pal <- function(pal) {
  # V1: Class attribute
  if (!inherits(pal, CLASS_PAL)) {
    stop("`pal` must be a visualr_pal object.", call. = FALSE)
  }

  # V2: Field completeness
  required_fields <- c("shells", "core", "mapping_pack_id", "provenance")
  missing <- setdiff(required_fields, names(pal))
  if (length(missing) > 0) {
    stop(sprintf("Missing required fields: %s",
                 paste(missing, collapse = ", ")),
         call. = FALSE)
  }

  # V3: shells — character, no NA
  if (!is.character(pal$shells) || anyNA(pal$shells)) {
    stop("`shells` must be a character vector without NA.", call. = FALSE)
  }

  # V4: core — character scalar, no NA
  if (!is.character(pal$core) || length(pal$core) != 1 || is.na(pal$core)) {
    stop("`core` must be a single non-NA character value.", call. = FALSE)
  }

  # V5: mapping_pack_id — character scalar, no NA
  if (!is.character(pal$mapping_pack_id) ||
      length(pal$mapping_pack_id) != 1 ||
      is.na(pal$mapping_pack_id)) {
    stop("`mapping_pack_id` must be a single non-NA character value.",
         call. = FALSE)
  }

  # V6: provenance — list
  if (!is.list(pal$provenance)) {
    stop("`provenance` must be a list.", call. = FALSE)
  }

  # NOT checked (deferred to v0.2):
  # - active_singularities (R5: field does not exist in v0.1)
  # - phase (R5: field does not exist in v0.1)
  # - rho+theta=1 consistency (R6: not hard-verified in v0.1)

  invisible(TRUE)
}
