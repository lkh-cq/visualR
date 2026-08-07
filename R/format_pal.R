# == format_pal / parse_pal: Layer 1 serialization ==================-
# format_pal: visualr_pal -> single character string
# parse_pal:  single character string -> visualr_pal
# Invariant 1: parse_pal(format_pal(S)) == S
#
# SECURITY (2026-08-06): v0.1.1 hardened against RCE.
#   Old v0.1.0 used eval(parse(text=...)) for shells/provenance fields,
#   which executed arbitrary code embedded in the serialized string
#   (demonstrated: system("echo FULL_PWN") ran during parse_pal).
#   New format uses length-prefixed records with unit-separator (\x1f)
#   delimiters: no eval, no parse(text=), no code path.
#   Format version bumped to v0.2.

# Serialization format (one record per line):
#   visualr_pal/v0.2
#   shells:4\x1fA\x1fB\x1fC\x1fD       (count \x1f v1 \x1f ... \x1f vN)
#   core:E
#   mapping_pack_id:pal-jiugong-v0.1
#   provenance:0|                       (empty)
#   provenance:1|clock=i:42             (idx | key = TYPE:value)
#   (empty shells -> "shells:0")

format_pal <- function(pal) {
  validate_pal(pal)

  n_shells <- length(pal$shells)
  pal_assert_no_sep(pal$shells, "shells")
  shells_rec <- if (n_shells == 0L) {
    "shells:0"
  } else {
    paste0("shells:", n_shells, PAL_SEP, pal_join(pal$shells))
  }

  prov_lines <- character(0)
  if (length(pal$provenance) == 0L) {
    prov_lines <- "provenance:0|"
  } else {
    prov_keys <- names(pal$provenance)
    if (is.null(prov_keys) || any(prov_keys == "")) {
      stop("`provenance` must be a named list for serialization.",
           call. = FALSE)
    }
    for (i in seq_along(pal$provenance)) {
      v <- pal$provenance[[i]]
      # Encode type prefix for lossless round-trip (42L != "42")
      if (is.integer(v)) {
        v_enc <- paste0("i:", v)
      } else if (is.numeric(v)) {
        v_enc <- paste0("d:", v)
      } else if (is.logical(v)) {
        v_enc <- paste0("l:", v)
      } else if (is.character(v)) {
        v_enc <- paste0("c:", v)
      } else {
        stop("`provenance` values must be atomic (integer/numeric/logical/character).",
             call. = FALSE)
      }
      if (grepl("|", v_enc, fixed = TRUE) || grepl("|", prov_keys[i], fixed = TRUE)) {
        stop("`provenance` keys/values must not contain '|'.", call. = FALSE)
      }
      prov_lines <- c(prov_lines,
        sprintf("provenance:%d|%s=%s",
                i - 1L, prov_keys[i], v_enc))
    }
  }

  lines <- c(
    FORMAT_HEADER,
    shells_rec,
    paste0("core:", pal$core),
    paste0("mapping_pack_id:", pal$mapping_pack_id),
    prov_lines
  )

  paste(lines, collapse = "\n")
}

#' @title Resident compact representation of a pal state
#' @description Returns the compact serialized string for a
#'   \code{visualr_pal} — the recommended RESIDENT form for memory /
#'   transport efficiency (v0.4.x A1). The S3 pal object carries
#'   list+class overhead (~1344 B) that makes it LARGER than the
#'   materialized matrix; the compact string stays small (~87 B) and
#'   can be restored on demand with \code{parse_pal}.
#' @details
#'   Measure baseline (v0.4.x, R 4.5.2, 1000 states):
#'   - resident S3 pal objects: ~1312.5 KB (0.46x vs matrix)
#'   - resident compact strings: ~226.6 KB (2.7x smaller than matrix)
#'   - resident matrices: ~609.4 KB
#'
#'   Recommended resident workflow: keep \code{pal_compact()} strings
#'   in memory / transit; materialize to pal state (\code{parse_pal})
#'   or matrix (\code{materialize}) only when an operator needs a
#'   compute view. This is the "store less / expand less / move less"
#'   pattern (DEVELOPMENT_PLAN_v0.5.0.md G1/G2).
#' @param pal a \code{visualr_pal} object
#' @return single character, the compact serialized form
#' @examples
#' pal_compact(new_pal_state(c("A","B","C","D"), "e"))
pal_compact <- function(pal) {
  format_pal(pal)
}

parse_pal <- function(string) {
  if (!is.character(string) || length(string) != 1) {
    stop("`string` must be a single character value.", call. = FALSE)
  }

  lines <- strsplit(string, "\n", fixed = TRUE)[[1]]

  # Check format header
  if (length(lines) < 1 || lines[1] != FORMAT_HEADER) {
    stop(sprintf("Invalid format header: expected '%s'", FORMAT_HEADER),
         call. = FALSE)
  }

  # == Pure string parser: NO eval, NO parse(text=), NO code execution ==
  parse_shells <- function(line) {
    body <- sub("^shells:", "", line)
    parts <- pal_split_fixed(body, PAL_SEP)
    n <- suppressWarnings(as.integer(parts[1]))
    if (is.na(n) || n < 0) {
      stop("Malformed shells record: bad count.", call. = FALSE)
    }
    if (n == 0L) {
      if (length(parts) != 1L) {
        stop("Malformed shells record: count mismatch.", call. = FALSE)
      }
      return(character(0))
    }
    if (length(parts) != n + 1L) {
      stop("Malformed shells record: count mismatch.", call. = FALSE)
    }
    parts[-1]
  }

  parse_provenance <- function(prov_lines) {
    if (length(prov_lines) == 0L) {
      stop("Missing field: provenance", call. = FALSE)
    }
    if (identical(prov_lines, "provenance:0|")) {
      return(list())
    }
    n <- length(prov_lines)
    out <- vector("list", n)
    nms <- character(n)
    for (i in seq_along(prov_lines)) {
      line <- prov_lines[i]
      if (!startsWith(line, "provenance:")) {
        stop("Malformed provenance record.", call. = FALSE)
      }
      body <- sub("^provenance:", "", line)
      idx_val <- strsplit(body, "|", fixed = TRUE)[[1]]
      if (length(idx_val) != 2L) {
        stop("Malformed provenance record: expected idx|key=value.",
             call. = FALSE)
      }
      kv <- strsplit(idx_val[2], "=", fixed = TRUE)[[1]]
      if (length(kv) != 2L) {
        stop("Malformed provenance record: expected key=value.",
             call. = FALSE)
      }
      # Decode type prefix: i:integer, d:double, l:logical, c:character
      raw_val <- kv[2]
      type_pref <- substr(raw_val, 1, 2)
      val <- substring(raw_val, 3)
      out[[i]] <- switch(type_pref,
        "i:" = as.integer(val),
        "d:" = as.numeric(val),
        "l:" = as.logical(val),
        "c:" = val,
        stop("Malformed provenance value: unknown type prefix.", call. = FALSE)
      )
      nms[i] <- kv[1]
    }
    names(out) <- nms
    out
  }

  shells_line <- lines[startsWith(lines, "shells:")]
  core_line <- lines[startsWith(lines, "core:")]
  mid_line <- lines[startsWith(lines, "mapping_pack_id:")]
  prov_lines <- lines[startsWith(lines, "provenance:")]

  if (length(shells_line) != 1L) stop("Missing field: shells", call. = FALSE)
  if (length(core_line) != 1L) stop("Missing field: core", call. = FALSE)
  if (length(mid_line) != 1L) stop("Missing field: mapping_pack_id", call. = FALSE)
  if (length(prov_lines) == 0L) stop("Missing field: provenance", call. = FALSE)

  shells <- parse_shells(shells_line)
  core <- sub("^core:", "", core_line)
  mapping_pack_id <- sub("^mapping_pack_id:", "", mid_line)
  provenance <- parse_provenance(prov_lines)

  new_pal_state(
    shells = shells,
    core = core,
    mapping_pack_id = mapping_pack_id,
    provenance = provenance
  )
}
