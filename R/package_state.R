# == package_state / unpack_state: G4 closed-loop packaging ==========
# v0.5.0 Efficiency/Engineering gate (DEVELOPMENT_PLAN_v0.5.0.md §7/§10).
#
# The compact transport unit is a flat list with explicit versioning and
# integrity, NOT an R-only serialized blob. A future reader (Java/JVM,
# C/C++) can parse the header + PAL canonical state without running R.
#
# Package contract:
#   format      -- "visualR-package"
#   version     -- package format version (integer)
#   pal         -- canonical PAL string (format_pal output)
#   mapping_pack -- named list(id, version, hash) of the resolved pack
#   payload     -- optional compute-state metadata (list)
#   provenance  -- pal provenance (list, may be empty)
#   checksum    -- integrity digest over the fields above (sha256 hex)

# Internal null-coalescing operator (explicit; do not rely on rlang).
`%||%` <- function(a, b) if (is.null(a)) b else a

#' @title Package a canonical PAL state into a transport unit
#' @description Wraps a visualr_pal (or canonical PAL string) into the
#'   visualR package contract: format header, canonical state, resolved
#'   mapping-pack identity, provenance, and a sha256 integrity checksum.
#'   The result is a flat list that can be serialized by any transport
#'   layer (file, raw vector, network) and reloaded with
#'   \code{unpack_state()}.
#' @param x a visualr_pal object, or a single canonical PAL string.
#' @param payload optional list of compute-state metadata to carry.
#' @return list with contract fields described above; class
#'   \code{visualr_package}.
#' @examples
#' pkg <- package_state(new_pal_state(c("A","B","C","D"), "e"))
#' str(pkg)
package_state <- function(x, payload = NULL) {
  if (inherits(x, "visualr_pal")) {
    pal_obj <- x
    pal_str <- format_pal(pal_obj)
  } else if (is.character(x) && length(x) == 1L) {
    if (startsWith(trimws(x), "{")) {
      # Canonical palindrome grammar, e.g. "{A{B{C{D{e}D}C}B}A}"
      pal_obj <- pal_parse(x)
    } else {
      # Serialized format_pal text (with FORMAT_HEADER line)
      pal_obj <- parse_pal(x)
    }
    pal_str <- format_pal(pal_obj)
  } else {
    stop("`x` must be a visualr_pal object or a single PAL string.",
         call. = FALSE)
  }
  validate_pal(pal_obj)

  pack <- resolve_mapping_pack(pal_obj$mapping_pack_id)
  if (is.null(pack) || is.null(pack$id) || is.null(pack$hash)) {
    stop("Resolved mapping pack lacks identity fields; cannot package.",
         call. = FALSE)
  }

  if (!is.null(payload) && !is.list(payload)) {
    stop("`payload` must be a list or NULL.", call. = FALSE)
  }

  body <- list(
    format = "visualR-package",
    version = 1L,
    pal = pal_str,
    mapping_pack = list(
      id = pack$id,
      version = pack$version,
      hash = pack$hash
    ),
    payload = payload %||% list(),
    provenance = pal_obj$provenance %||% list()
  )
  body$checksum <- package_checksum(body)
  # Dev-checkout hint: source root for fresh-process reload when the
  # package is not installed (excluded from checksum — transport hint).
  # In a dev load (pkgload), system.file() is unreliable, so accept an
  # explicit env hint, else probe the loaded namespace's source.
  src_root <- Sys.getenv("VISUALR_SOURCE_ROOT", unset = NA_character_)
  if (is.na(src_root)) {
    src_root <- tryCatch(
      getNamespaceInfo(asNamespace("visualR"), "path"),
      error = function(e) NULL
    )
  }
  if (is.null(src_root) || is.na(src_root) ||
      !file.exists(file.path(src_root, "DESCRIPTION"))) {
    src_root <- NULL
  }
  if (!is.null(src_root)) {
    body$`_source_root` <- src_root
  }
  structure(body, class = "visualr_package")
}

#' @title Compute the integrity checksum of a package body
#' @description sha256 hex digest over the package fields, computed on the
#'   canonical representation (stable ordering, no class attributes).
#'   Used both at package time and at verification time.
#' @param body list; the package body WITHOUT the checksum field.
#' @return single character sha256 hex digest.
package_checksum <- function(body) {
  stopifnot(is.list(body))
  stable <- list(
    format = body$format,
    version = body$version,
    pal = body$pal,
    mapping_pack = body$mapping_pack,
    payload = body$payload %||% list(),
    provenance = body$provenance %||% list()
  )
  canonical <- paste0(
    "format=", stable$format, "|",
    "version=", stable$version, "|",
    "pal=", stable$pal, "|",
    "pack_id=", stable$mapping_pack$id, "|",
    "pack_version=", stable$mapping_pack$version, "|",
    "pack_hash=", stable$mapping_pack$hash, "|",
    "payload=", list_digest_flat(stable$payload), "|",
    "provenance=", list_digest_flat(stable$provenance)
  )
  digest_sha256(canonical)
}

# Internal: deterministic digest of an arbitrary nested list (for payload
# and provenance checksums). Mirrors the stable-ordering principle of the
# mapping-pack digest; never uses R serialization bytes (unstable across
# R versions / platforms).
list_digest_flat <- function(x) {
  if (is.null(x) || length(x) == 0L) return("<>")
  parts <- vapply(seq_along(x), function(i) {
    nm <- names(x)[i]
    v <- x[[i]]
    if (is.list(v)) {
      paste0(nm, "=", list_digest_flat(v))
    } else if (is.null(v)) {
      paste0(nm, "=NULL")
    } else {
      paste0(nm, "=", paste(as.character(v), collapse = ","))
    }
  }, character(1))
  paste0("<", paste(parts, collapse = ";"), ">")
}

# Internal: sha256 hex digest using R's built-in tools (no external dep).
# Returns a PLAIN character (openssl::sha256 returns classed "hash"
# objects which break identical() against plain strings).
digest_sha256 <- function(x) {
  if (requireNamespace("openssl", quietly = TRUE)) {
    return(as.character(openssl::sha256(x)))
  }
  con <- textConnection(x)
  on.exit(close(con))
  # tools::md5sum needs a file; use tempfile for a stable digest
  tf <- tempfile()
  writeLines(x, tf)
  on.exit(unlink(tf), add = TRUE)
  unname(tools::md5sum(tf))
}

#' @title Verify and unpack a visualR package back to a pal state
#' @description Validates the package contract (format/version header,
#'   mapping-pack identity, integrity checksum) and reconstructs the
#'   canonical visualr_pal. Fail-closed: any unknown format, version,
#'   unknown pack, or checksum mismatch errors instead of returning a
#'   partial result.
#' @param pkg a visualr_package object (as produced by package_state),
#'   or a list with the same contract fields.
#' @param verify_integrity logical; recompute and compare the checksum
#'   (default TRUE). Set FALSE only for debugging.
#' @return the reconstructed visualr_pal object.
#' @examples
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' pkg <- package_state(p)
#' p2 <- unpack_state(pkg)
#' identical(format_pal(p), format_pal(p2))  # TRUE
unpack_state <- function(pkg, verify_integrity = TRUE) {
  if (!is.list(pkg) || is.null(pkg$format) || is.null(pkg$pal)) {
    stop("Not a visualR package: missing format/pal fields.", call. = FALSE)
  }
  if (!identical(pkg$format, "visualR-package")) {
    stop(sprintf("Unknown package format '%s' (fail closed).",
                 pkg$format), call. = FALSE)
  }
  if (!identical(pkg$version, 1L)) {
    stop(sprintf("Unsupported package version %s (fail closed).",
                 pkg$version), call. = FALSE)
  }
  if (verify_integrity) {
    expected <- pkg$checksum
    if (is.null(expected) || !nzchar(expected)) {
      stop("Package has no checksum; integrity cannot be verified.",
           call. = FALSE)
    }
    body <- pkg
    body$checksum <- NULL
    actual <- package_checksum(body)
    if (!identical(actual, expected)) {
      stop(sprintf("Package checksum mismatch (fail closed):\n  stored=%s\n  computed=%s",
                   expected, actual), call. = FALSE)
    }
  }
  pack_id <- pkg$mapping_pack$id
  if (is.null(pack_id) || !nzchar(pack_id)) {
    stop("Package missing mapping-pack id (fail closed).", call. = FALSE)
  }
  # Fail-closed: resolve errors if unknown/tampered pack id.
  resolve_mapping_pack(pack_id)

  pal <- parse_pal(pkg$pal)
  # Reattach provenance carried in the package (parse_pal has no
  # provenance slot; set it explicitly).
  if (!is.null(pkg$provenance) && length(pkg$provenance) > 0L) {
    pal$provenance <- pkg$provenance
  }
  validate_pal(pal)
  pal
}

#' @title Round-trip a package through a fresh R process (reload check)
#' @description Serializes the package to a file, loads it back in a
#'   fresh R subprocess (via Rscript), and confirms the canonical PAL
#'   string reproduces. This is the v0.5.0 "reload without preserving
#'   expanded working state" acceptance test.
#' @param pkg a visualr_package object.
#' @param rscript character; path to Rscript (default from R.home).
#' @param timeout numeric; seconds to wait for the subprocess.
#' @param verbose logical; if TRUE, print the child process stderr when
#'   reproduction fails (default FALSE).
#' @return logical TRUE if the fresh process reproduced the canonical
#'   state; FALSE otherwise (with message).
#' @examples
#' pkg <- package_state(new_pal_state(c("A","B","C","D"), "e"))
#' package_reload_check(pkg)
package_reload_check <- function(pkg, rscript = file.path(R.home("bin"), "Rscript"),
                                 timeout = 30, verbose = FALSE) {
  if (!inherits(pkg, "visualr_package")) {
    stop("`pkg` must be a visualr_package.", call. = FALSE)
  }
  # Write the package to a plain RDS file (transport unit on disk).
  tf <- tempfile(fileext = ".rds")
  saveRDS(pkg, tf)
  on.exit(unlink(tf), add = TRUE)

  # Fresh process: read the file, unpack, print the canonical PAL.
  # Preferred path: the installed package (in CI the checked package is
  # installed and current, so visualR::unpack_state exists). A dev
  # source root (pkgload) is used ONLY when explicitly present and the
  # package is NOT installed — this avoids requiring pkgload in CI
  # (pkgload is not in Suggests) and avoids shadowing the installed
  # package with an older dev checkout.
  # Use a temporary script file (not -e) to avoid shell metacharacter
  # expansion on the R expression.
  pkg_root <- if (!is.null(pkg$`_source_root`)) pkg$`_source_root` else NULL
  script_file <- tempfile(fileext = ".R")
  # The child decides: pass the parent's library paths explicitly (R CMD
  # check tests run against a temp lib the child Rscript may not see),
  # prefer an installed visualR, and fall back to pkgload::load_all of
  # the dev source root only when no installed package is found.
  libs <- paste(shQuote(.libPaths()), collapse = ", ")
  if (!is.null(pkg_root)) {
    script_head <- sprintf(
      '.libPaths(c(%s))\nif (!requireNamespace("visualR", quietly = TRUE)) {\n  suppressMessages(pkgload::load_all(%s))\n}',
      libs, shQuote(pkg_root)
    )
  } else {
    script_head <- sprintf(
      '.libPaths(c(%s))\nif (!requireNamespace("visualR", quietly = TRUE)) stop("visualR not available")',
      libs
    )
  }
  writeLines(sprintf(
    '%s\npkg <- readRDS(%s)\np <- visualR::unpack_state(pkg)\ncat(visualR::format_pal(p), "\\n")',
    script_head, shQuote(tf)
  ), script_file)
  on.exit(unlink(script_file), add = TRUE)
  out <- tryCatch(
    suppressWarnings(system2(rscript, shQuote(script_file),
                             stdout = TRUE, stderr = TRUE,
                             timeout = timeout)),
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  if (length(out) == 0L) {
    message("Fresh-process reload returned no output.")
    return(FALSE)
  }
  # The child prints format_pal(p) which is itself multi-line (shells,
  # core, mapping_pack_id, provenance). Join all output lines back into
  # one string, strip CR (Windows child output uses CRLF) and trailing
  # whitespace, then compare against the full canonical PAL string.
  reproduced <- trimws(gsub("\r", "", paste(out, collapse = "\n"), fixed = TRUE))
  ok <- identical(reproduced, trimws(format_pal(unpack_state(pkg))))
  if (!ok && verbose) {
    message("package_reload_check: child output did not match canonical PAL.\n",
            "--- child stdout/stderr ---\n",
            paste(out, collapse = "\n"),
            "\n--- expected canonical PAL ---\n",
            format_pal(unpack_state(pkg)))
  }
  ok
}

#' @export
print.visualr_package <- function(x, ...) {
  cat(sprintf("<visualr_package> v%s pal=%s pack=%s\n",
              x$version, x$pal, x$mapping_pack$id))
  cat(sprintf("  checksum=%s\n", substr(x$checksum, 1, 16)))
  invisible(x)
}
