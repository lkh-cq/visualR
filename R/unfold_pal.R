# ── unfold_pal / fold_pal: Layer 2 palindrome expand/fold ───────────
# unfold_pal: visualr_pal -> character vector (palindrome)
# fold_pal:   character vector (palindrome) -> visualr_pal
#
# Audit ruling R3: unfold is c(shells, core, rev(shells)), NOT window extraction.
# 藏归分离: fold_pal only reads the `unfolded` parameter.
#           It does NOT access any hidden original pal_state object.
# Invariant 2: fold_pal(unfold_pal(S)) == S (with default metadata)

unfold_pal <- function(pal) {
  validate_pal(pal)
  c(pal$shells, pal$core, rev(pal$shells))
}

fold_pal <- function(unfolded,
                     mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
                     provenance = list()) {
  # Validate input type
  if (!is.character(unfolded)) {
    stop("`unfolded` must be a character vector.", call. = FALSE)
  }

  n <- length(unfolded)

  # Must be odd length (palindrome property)
  if (n %% 2 == 0) {
    stop("`unfolded` must have odd length (palindrome).", call. = FALSE)
  }

  # Must be a palindrome
  if (!identical(unfolded, rev(unfolded))) {
    stop("`unfolded` must be a palindrome.", call. = FALSE)
  }

  # Extract core and shells from the unfolded path ONLY
  # 藏归分离: no access to any hidden original object
  mid <- (n + 1) %/% 2
  core <- unfolded[mid]
  shells <- if (mid == 1) character(0) else unfolded[1:(mid - 1)]

  new_pal_state(
    shells = shells,
    core = core,
    mapping_pack_id = mapping_pack_id,
    provenance = provenance
  )
}
