# ── new_pal_state: Layer 1 constructor ──────────────────────────────
# Creates a visualr_pal S3 object with 4 fields.
# Audit ruling R1: shells is character vector, any non-negative length.
# Audit ruling R2: core is single character scalar.
# Audit ruling R5: no active_singularities or phase in v0.1.
# Audit ruling R7: mapping_pack_id is versioned string.

new_pal_state <- function(shells, core,
                          mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
                          provenance = list()) {
  # Validate shells (R1: character vector, any length, no NA)
  if (!is.character(shells)) {
    stop("`shells` must be a character vector.", call. = FALSE)
  }
  if (anyNA(shells)) {
    stop("`shells` must not contain NA values.", call. = FALSE)
  }

  # Validate core (R2: single character scalar, no NA)
  if (!is.character(core) || length(core) != 1 || is.na(core)) {
    stop("`core` must be a single non-NA character value.", call. = FALSE)
  }

  # Validate mapping_pack_id (R7: versioned string)
  if (!is.character(mapping_pack_id) || length(mapping_pack_id) != 1 || is.na(mapping_pack_id)) {
    stop("`mapping_pack_id` must be a single non-NA character value.", call. = FALSE)
  }

  # Validate provenance
  if (!is.list(provenance)) {
    stop("`provenance` must be a list.", call. = FALSE)
  }

  structure(
    list(
      shells = shells,
      core = core,
      mapping_pack_id = mapping_pack_id,
      provenance = provenance
    ),
    class = CLASS_PAL
  )
}

# ── print method ────────────────────────────────────────────────────

print.visualr_pal <- function(x, ...) {
  n <- length(x$shells)
  cat(sprintf("<visualr_pal> shells=%d core=%s mapping_pack=%s\n",
              n, x$core, x$mapping_pack_id))
  if (n > 0) {
    cat("  shells:", paste(x$shells, collapse = ", "), "\n")
  } else {
    cat("  shells: (empty)\n")
  }
  invisible(x)
}
