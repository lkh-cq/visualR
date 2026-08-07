# == gamma_field / peel: Layer 2 Gamma generator + peel chain ========
# STATUS: FROZEN (B-promotion 2026-08-07)
#   gamma_field center-lowercasing is now a pack-level decision
#   (local_center_transform = tolower in default pack). Custom packs
#   can override via gamma_rule or local_center_transform. The
#   lowercasing is no longer experimental: it is the default pack's
#   frozen choice, verified against all 4 spec examples + custom pack
#   override tests.
#
# Implemented from frozen spec (README v0.2, 2026-08-05):
#   Gamma(S_k) = meta-jiugong K_k: cross -1 order, diagonal -2 order
#   Verified against all 4 spec examples (0 mismatches):
#     Gamma(S_4)=[C D C; D e D; C D C]    Gamma(S_3)=[B C B; C d C; B C B]
#     Gamma(S_2)=[A B A; B c B; A B A]    Gamma(S_1)=[A A A; A b A; A A A]
#   peel chain: S_4 -delta-> S_3 -delta-> S_2 -delta-> S_1 -delta-> S_0 (center-block fusion)
#
# NOTE: Python mapping_pack.py does NOT yet implement peel/gamma_field
# (README lists them as "v0.2 code pending"). This R implementation is
# the FIRST executable realization of the frozen spec, validated against
# the 4 example matrices given in README.

#' @title Gamma generator: S_k -> meta-jiugong K_k
#' @description Build the 3x3 meta-jiugong (local density field neighborhood)
#'   from a pal state. Cross cells drop 1 order, diagonal cells drop 2
#'   orders (frozen Gamma rule). Center cell is the core symbol lowercased --
#'   the stripped marker (local center, NOT the globally isotropic
#'   singularity; only the global center e keeps its case).
#' @param pal a visualr_pal object
#' @return a 3x3 character matrix (K_k)
#' @examples
#' gamma_field(new_pal_state(c("A","B","C","D"), "e"))
gamma_field <- function(pal) {
  validate_pal(pal)
  pack <- pal_resolve_pack(pal)   # v0.2.2 (P0-2): authority = resolved pack

  # If the pack defines a custom gamma_rule, the pack is the sole
  # authority for Gamma materialization.
  if (!is.null(pack$gamma_rule)) {
    G <- pack$gamma_rule(pal)
    if (!is.matrix(G) || nrow(G) != 3L || ncol(G) != 3L) {
      stop("pack$gamma_rule must return a 3x3 matrix (fail closed).",
           call. = FALSE)
    }
    return(G)
  }

  shells <- pal$shells
  n <- length(shells)
  if (n == 0L) {
    stop("Gamma field requires at least one shell (S_1+); S_0 has no 3x3 neighborhood.",
         call. = FALSE)
  }
  path <- c(shells, pal$core)  # path[1..n+1]; path[n+1] = center

  G <- matrix(NA_character_, nrow = 3L, ncol = 3L)
  for (i in 1:3) {
    for (j in 1:3) {
      d <- abs(i - 2L) + abs(j - 2L)        # Manhattan distance to center
      depth <- max(n + 1L - d, 1L)          # order, floor at outermost shell
      if (depth == n + 1L) {
        # center transform comes FROM the pack (v0.2.2 P0-2):
        #   default = identity; a custom local_center_transform is the
        #   pack's choice (lowercasing is the default pack's frozen
        #   transform, B-promotion 2026-08-07).
        tf <- pack$local_center_transform
        G[i, j] <- if (is.null(tf)) pal$core else tf(pal$core)
      } else {
        G[i, j] <- path[depth]
      }
    }
  }
  G
}

#' @title Peel chain: S_n -delta-> S_{n-1}
#' @description Strip one order from a pal state: the innermost shell
#'   becomes the new core (center-block fusion). Chain:
#'   S_4 -delta-> S_3 -delta-> S_2 -delta-> S_1 -delta-> S_0.
#'   Inversely, promote() rebuilds by wrapping core back into a shell.
#' @param pal a visualr_pal object
#' @return a new visualr_pal with one fewer shell
#' @examples
#' peel(new_pal_state(c("A","B","C","D"), "e"))
peel <- function(pal) {
  validate_pal(pal)
  shells <- pal$shells
  n <- length(shells)
  if (n == 0L) {
    stop("Cannot peel S_0 (no shells remain).", call. = FALSE)
  }
  new_pal_state(
    shells = if (n == 1L) character(0) else shells[1:(n - 1L)],
    core = shells[n],
    mapping_pack_id = pal$mapping_pack_id,
    provenance = pal$provenance
  )
}

#' @title Promote: S_{n-1} -promote-> S_n (inverse of peel)
#' @description Wrap the current core as the innermost shell and promote
#'   a new core symbol. Inverse of \code{peel}: \code{promote(peel(S)) == S}
#'   when the new core equals the original innermost shell's outer symbol.
#' @param pal a visualr_pal object
#' @param new_core single character, the new center singularity
#' @return a new visualr_pal with one more shell
#' @examples
#' promote(new_pal_state(c("A","B","C"), "D"), "e")
promote <- function(pal, new_core) {
  validate_pal(pal)
  if (!is.character(new_core) || length(new_core) != 1L || is.na(new_core)) {
    stop("`new_core` must be a single non-NA character.", call. = FALSE)
  }
  new_pal_state(
    shells = c(pal$shells, pal$core),
    core = new_core,
    mapping_pack_id = pal$mapping_pack_id,
    provenance = pal$provenance
  )
}

#' @title Full peel chain from a pal state
#' @description Peel down to S_0, returning the whole chain as a list of
#'   pal states (S_n, S_{n-1}, ..., S_0).
#' @param pal a visualr_pal object
#' @return list of visualr_pal objects, longest first
#' @examples
#' peel_chain(new_pal_state(c("A","B","C","D"), "e"))
peel_chain <- function(pal) {
  validate_pal(pal)
  out <- list(pal)
  cur <- pal
  while (length(cur$shells) > 0L) {
    cur <- peel(cur)
    out <- c(out, list(cur))
  }
  out
}
