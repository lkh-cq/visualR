# == validate_pal: Layer 1 invariant verification ====================
# v0.2.1 Semantic Hardening (P0-3/P0-4):
#   Token domain is now CLOSED: a legal token is a non-empty,
#   newline-free, separator-free UTF-8 string that cannot collide with
#   serialization framing. This guarantees parse_pal(format_pal(S)) == S
#   for EVERY legal state, not just the tested subset.
#
# Audit rulings:
#   R5: does NOT check active_singularities or phase.
#   R6: does NOT check rho+theta consistency.

# Serialization-reserved characters (must never appear in tokens):
#   \n  -- line framing in format_pal (line-based protocol)
#   \x1f -- unit separator (record-internal framing)
#   |   -- provenance record separator
#   =   -- provenance key/value separator
#   { } -- palindrome grammar delimiters (P0-3: grammar is token syntax)
RESERVED_CHARS <- c("\n", "\r", "\x1f", "|", "=", "{", "}")

# Hard limits (P1: parser depth/length protection)
MAX_SHELLS <- 64L        # S_64 max depth
MAX_TOKEN_LEN <- 256L    # per-token character length
MAX_PROVENANCE <- 32L    # provenance record count

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

  # V3: shells -- character, no NA, closed token domain
  if (!is.character(pal$shells) || anyNA(pal$shells)) {
    stop("`shells` must be a character vector without NA.", call. = FALSE)
  }
  if (length(pal$shells) > MAX_SHELLS) {
    stop(sprintf("`shells` exceeds MAX_SHELLS=%d (depth limit).",
                 MAX_SHELLS), call. = FALSE)
  }
  for (s in pal$shells) {
    if (nchar(s) == 0L) {
      stop("`shells` entries must be non-empty (closed token domain).",
           call. = FALSE)
    }
    if (nchar(s) > MAX_TOKEN_LEN) {
      stop(sprintf("`shells` token exceeds MAX_TOKEN_LEN=%d.",
                   MAX_TOKEN_LEN), call. = FALSE)
    }
    bad <- RESERVED_CHARS[sapply(RESERVED_CHARS,
                                 function(rc) grepl(rc, s, fixed = TRUE))]
    if (length(bad) > 0) {
      stop(sprintf("`shells` token contains reserved character(s): %s",
                   paste(sprintf("'%s'", bad), collapse = " ")),
           call. = FALSE)
    }
  }

  # V4: core -- character scalar, no NA, closed token domain
  if (!is.character(pal$core) || length(pal$core) != 1 || is.na(pal$core)) {
    stop("`core` must be a single non-NA character value.", call. = FALSE)
  }
  if (nchar(pal$core) == 0L) {
    stop("`core` must be non-empty (closed token domain).", call. = FALSE)
  }
  if (nchar(pal$core) > MAX_TOKEN_LEN) {
    stop(sprintf("`core` token exceeds MAX_TOKEN_LEN=%d.", MAX_TOKEN_LEN),
         call. = FALSE)
  }
  bad_core <- RESERVED_CHARS[sapply(RESERVED_CHARS,
                                    function(rc) grepl(rc, pal$core, fixed = TRUE))]
  if (length(bad_core) > 0) {
    stop(sprintf("`core` token contains reserved character(s): %s",
                 paste(sprintf("'%s'", bad_core), collapse = " ")),
         call. = FALSE)
  }

  # V5: mapping_pack_id -- character scalar, no NA, token-safe
  if (!is.character(pal$mapping_pack_id) ||
      length(pal$mapping_pack_id) != 1 ||
      is.na(pal$mapping_pack_id)) {
    stop("`mapping_pack_id` must be a single non-NA character value.",
         call. = FALSE)
  }
  if (nchar(pal$mapping_pack_id) == 0L) {
    stop("`mapping_pack_id` must be non-empty.", call. = FALSE)
  }
  bad_id <- RESERVED_CHARS[sapply(RESERVED_CHARS,
                                  function(rc) grepl(rc, pal$mapping_pack_id, fixed = TRUE))]
  if (length(bad_id) > 0) {
    stop(sprintf("`mapping_pack_id` contains reserved character(s): %s",
                 paste(sprintf("'%s'", bad_id), collapse = " ")),
         call. = FALSE)
  }

  # V6: provenance -- list with scalar values only (P0-4)
  if (!is.list(pal$provenance)) {
    stop("`provenance` must be a list.", call. = FALSE)
  }
  if (length(pal$provenance) > MAX_PROVENANCE) {
    stop(sprintf("`provenance` exceeds MAX_PROVENANCE=%d records.",
                 MAX_PROVENANCE), call. = FALSE)
  }
  for (nm in names(pal$provenance)) {
    v <- pal$provenance[[nm]]
    if (is.null(v) || length(v) != 1L || is.na(v)) {
      stop(sprintf("`provenance$%s` must be a scalar non-NA value.",
                   nm), call. = FALSE)
    }
    if (!(is.character(v) || is.numeric(v) || is.logical(v))) {
      stop(sprintf("`provenance$%s` must be character/numeric/logical.",
                   nm), call. = FALSE)
    }
    if (is.character(v)) {
      bad_v <- RESERVED_CHARS[sapply(RESERVED_CHARS,
                                     function(rc) grepl(rc, v, fixed = TRUE))]
      if (length(bad_v) > 0) {
        stop(sprintf("`provenance$%s` contains reserved character(s): %s",
                     nm, paste(sprintf("'%s'", bad_v), collapse = " ")),
             call. = FALSE)
      }
    }
  }

  # NOT checked (deferred to v0.2):
  # - active_singularities (R5: field does not exist in v0.1)
  # - phase (R5: field does not exist in v0.1)
  # - rho+theta=1 consistency (R6: not hard-verified in v0.1)

  invisible(TRUE)
}
