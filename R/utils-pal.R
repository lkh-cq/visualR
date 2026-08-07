# == Internal utilities (pal_ prefix, not exported) ==================-
# Zero external deps; all base R.

# Unit separator used in serialization. Chosen because it cannot appear
# in normal text and R strsplit handles it predictably.
PAL_SEP <- "\x1f"

#' Split a string on a fixed separator, KEEPING empty strings.
#' Unlike strsplit(), which drops trailing empty strings (strsplit("a|b|","|")
#' -> c("a","b")), this preserves all fields -- required for lossless
#' round-trip of empty-string shells/provenance values.
#' @param s single character string
#' @param sep single-character separator
#' @return character vector (length 0 only if input is "")
pal_split_fixed <- function(s, sep) {
  if (identical(s, "")) return(character(0))
  pos <- gregexpr(sep, s, fixed = TRUE)[[1]]
  if (length(pos) == 1L && pos == -1L) {
    return(s)
  }
  starts <- c(1L, pos + 1L)
  ends <- c(pos - 1L, nchar(s))
  substring(s, starts, ends)
}

#' Join with separator (length-prefixed encoding helper)
#' @param x character vector
#' @return single string
pal_join <- function(x) {
  if (length(x) == 0L) return("")
  paste(x, collapse = PAL_SEP)
}

#' Guard: fail loudly if a value would break the serialization format.
#' Better to error at format time than to silently corrupt on parse.
pal_assert_no_sep <- function(x, what) {
  if (any(grepl(PAL_SEP, x, fixed = TRUE))) {
    stop(sprintf("`%s` values must not contain the unit separator (\\x1f).", what),
         call. = FALSE)
  }
}
