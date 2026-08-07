# == pal_parse / pal_encode: Layer 1 palindrome grammar (interop layer) ==-
# Ported from mapping_pack.py parse_palindrome/encode_palindrome.
#
# These functions speak the FROZEN palindrome grammar G:
#   S_n = {x_0{x_1{...{x_{n-1}{x_n}x_{n-1}}...}x_1}x_0}
#   example: {A{B{C{D{e}D}C}B}A}  -> path ['A','B','C','D','e','D','C','B','A']
#
# Relationship to existing functions:
#   format_pal/parse_pal  = serialization (R-side object <-> string record)
#   pal_parse/pal_encode  = palindrome grammar (text S_n <-> visualr_pal)
# They are DIFFERENT: format_pal uses v0.2 length-prefixed records;
# pal_parse uses the frozen bracket grammar {A{B{...}}}.
# The grammar functions are the interoperability layer with the Python
# reference implementation (mapping_pack.py).

#' @title Parse palindrome grammar to visualr_pal
#' @description Parse the frozen palindrome storage form
#'   \code{{A{B{C{D{e}D}C}B}A}} into a \code{visualr_pal} object.
#'   The bracket-nested grammar is uniquely parseable (prefix matching),
#'   so parsing is the bijective inverse of encoding.
#' @param text single character, palindrome text like \code{"{A{B{C{D{e}D}C}B}A}"}
#' @param mapping_pack_id optional override, defaults to DEFAULT_MAPPING_PACK_ID
#' @param provenance optional list
#' @return visualr_pal object
#' @examples
#' pal_parse("{A{B{C{D{e}D}C}B}A}")
#' pal_parse("{A{B}A}")
pal_parse <- function(text, mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
                      provenance = list()) {
  if (!is.character(text) || length(text) != 1 || is.na(text)) {
    stop("`text` must be a single character.", call. = FALSE)
  }
  # Frozen grammar: must be wrapped in { }
  if (!startsWith(text, "{") || !endsWith(text, "}")) {
    stop("Palindrome must be wrapped in { }.", call. = FALSE)
  }

  chars <- strsplit(text, "", fixed = TRUE)[[1]]
  n <- length(chars)
  pos <- 1L

  parse_node <- function() {
    if (pos > n || chars[pos] != "{") {
      stop(sprintf("Position %d: expected '{'.", pos), call. = FALSE)
    }
    pos <<- pos + 1L
    # Read symbol until { or }
    start <- pos
    while (pos <= n && chars[pos] != "{" && chars[pos] != "}") {
      pos <<- pos + 1L
    }
    if (start == pos) {
      stop(sprintf("Position %d: empty node, missing symbol.", start),
           call. = FALSE)
    }
    sym <- paste(chars[start:(pos - 1L)], collapse = "")
    if (pos <= n && chars[pos] == "{") {
      inner <- parse_node()
      # Symmetry check: after inner, must be sym again (multi-char safe),
      # then }
      sym_len <- nchar(sym)
      if (pos + sym_len - 1L > n ||
          paste(chars[pos:(pos + sym_len - 1L)], collapse = "") != sym) {
        stop(sprintf("Position %d: expected symmetric symbol '%s'.",
                     pos, sym), call. = FALSE)
      }
      pos <<- pos + sym_len
      if (pos > n || chars[pos] != "}") {
        stop(sprintf("Position %d: expected '}' after symmetric symbol.", pos),
             call. = FALSE)
      }
      pos <<- pos + 1L
      return(c(sym, inner, sym))
    } else {
      if (pos <= n && chars[pos] == "}") {
        pos <<- pos + 1L
        return(sym)  # leaf: center singularity
      }
      stop(sprintf("Position %d: illegal structure.", pos), call. = FALSE)
    }
  }

  path <- parse_node()
  if (pos != n + 1L) {
    stop(sprintf("Position %d: unconsumed characters.", pos), call. = FALSE)
  }

  # path: [x_0 ... x_n ... x_0], core = middle element
  len <- length(path)
  mid <- (len + 1L) %/% 2L
  new_pal_state(
    shells = if (mid == 1L) character(0) else path[1:(mid - 1L)],
    core = path[mid],
    mapping_pack_id = mapping_pack_id,
    provenance = provenance
  )
}

#' @title Encode visualr_pal to palindrome grammar text
#' @description The inverse of \code{pal_parse}: build the frozen
#'   palindrome storage form \code{{A{B{C{D{e}D}C}B}A}} from a
#'   \code{visualr_pal}.  Bijective: \code{pal_parse(pal_encode(S)) == S}
#'   and \code{pal_encode(pal_parse(text)) == text} for canonical text.
#' @param pal a visualr_pal object
#' @return single character, palindrome text
#' @examples
#' pal_encode(new_pal_state(c("A","B","C","D"), "e"))
pal_encode <- function(pal) {
  validate_pal(pal)
  shells <- pal$shells
  core <- pal$core
  n <- length(shells)
  # Build center-outward: start from core, wrap outward
  out <- paste0("{", core, "}")
  if (n > 0L) {
    for (k in n:1L) {
      out <- paste0("{", shells[k], out, shells[k], "}")
    }
  }
  out
}
