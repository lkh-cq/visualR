# == new_pal_state: Layer 1 constructor ==============================
# Creates a visualr_pal S3 object with 4 fields.
# Audit ruling R1: shells is character vector, any non-negative length.
# Audit ruling R2: core is single character scalar.
# Audit ruling R5: no active_singularities or phase in v0.1.
# Audit ruling R7: mapping_pack_id is versioned string.

new_pal_state <- function(shells, core,
                          mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
                          provenance = list()) {
  # v0.2.1: constructor delegates ALL invariant checks to validate_pal
  # (single source of truth). This closes the token domain at
  # construction time — newline/separator/empty tokens are rejected
  # here, before they can ever enter serialization or grammar.
  obj <- structure(
    list(
      shells = shells,
      core = core,
      mapping_pack_id = mapping_pack_id,
      provenance = provenance
    ),
    class = CLASS_PAL
  )
  validate_pal(obj)
  obj
}

# == print method ====================================================

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
