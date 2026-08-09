# == Gradient emergence: layered expansion, not matrix filling =======
# User direction (2026-08-09): expansion proceeds by gradient; each
# batch is one gradient layer — NOT filling a fixed matrix once. The
# matrix is only a local observation window of an infinite recursive
# expansion; the gradient stream is the working structure.
#
# Positions carry information (位置就是信息); the emergence weight is a
# structural weight (which positions deserve compute/verification), not
# a statistical frequency.
#
# This is stage-2 of the equation-core: the generative mechanism. It is
# deliberately NOT a traditional matrix generator.

#' @title Generate gradient layers as position batches
#' @description Returns the position stream of a gradient expansion:
#'   layer 0 is the center; layer k is the ring at gradient distance k
#'   (Manhattan ring). Each layer is one batch — the generator can
#'   consume batches incrementally instead of computing a whole matrix.
#' @param depth non-negative integer; number of gradient layers beyond
#'   the center.
#' @return A list of class \code{visualr_gradient_layers}; element
#'   \code{k+1} is a data frame with columns x, y (integer offsets from
#'   the center). Layer size for k>0 is 4k.
#' @examples
#' g <- gradient_layers(2L)
#' nrow(g[[1L]]); nrow(g[[2L]]); nrow(g[[3L]])
gradient_layers <- function(depth) {
  if (length(depth) != 1L || is.na(depth) || !is.numeric(depth) ||
      depth != as.integer(depth) || depth < 0L) {
    stop("`depth` must be one non-negative integer.", call. = FALSE)
  }
  depth <- as.integer(depth)
  mk_ring <- function(k) {
    pts <- list()
    for (x in (-k):k) {
      rem <- k - abs(x)
      if (rem == 0L) {
        pts[[length(pts) + 1L]] <- c(x, 0L)
      } else {
        pts[[length(pts) + 1L]] <- c(x, rem)
        pts[[length(pts) + 1L]] <- c(x, -rem)
      }
    }
    m <- do.call(rbind, lapply(pts, function(p) {
      data.frame(x = p[[1L]], y = p[[2L]], stringsAsFactors = FALSE)
    }))
    rownames(m) <- NULL
    m
  }
  layers <- vector("list", depth + 1L)
  layers[[1L]] <- data.frame(x = 0L, y = 0L, stringsAsFactors = FALSE)
  if (depth >= 1L) {
    for (k in seq_len(depth)) layers[[k + 1L]] <- mk_ring(k)
  }
  structure(layers, class = "visualr_gradient_layers")
}

#' @export
print.visualr_gradient_layers <- function(x, ...) {
  cat("<visualr_gradient_layers> layers=", length(x), "\n", sep = "")
  for (k in seq_along(x)) {
    cat(sprintf("  layer %d: %d positions (gradient %d)\n",
                k - 1L, nrow(x[[k]]), k - 1L))
  }
  invisible(x)
}

#' @title Emergence weight of a position
#' @description Structural weight of a position in the gradient stream:
#'   positions carry topological information (位置就是信息). The default
#'   weight model is candidate-only (NOT frozen): weight decays with
#'   layer depth (center carries highest structural density) and is
#'   scaled by ring size. This decides where compute/verification
#'   resources go; it is not a statistical estimate of a value.
#' @param layer_index integer; the gradient layer (0 = center).
#' @param ring_size integer; number of positions in that layer.
#' @param model character; weight model, default \code{"decay"}.
#' @return numeric weight in (0, 1].
#' @examples
#' emerge_weight(0L, 1L)
#' emerge_weight(2L, 8L)
emerge_weight <- function(layer_index, ring_size, model = "decay") {
  layer_index <- as.integer(layer_index)
  ring_size <- as.integer(ring_size)
  if (length(layer_index) != 1L || is.na(layer_index) || layer_index < 0L) {
    stop("`layer_index` must be one non-negative integer.", call. = FALSE)
  }
  if (length(ring_size) != 1L || is.na(ring_size) || ring_size < 1L) {
    stop("`ring_size` must be one positive integer.", call. = FALSE)
  }
  model <- match.arg(model, c("decay", "uniform"))
  if (model == "uniform") {
    return(1)
  }
  # decay: center = 1; each layer halves per layer index, scaled so the
  # total weight of a ring grows with its size.
  1 / (2^layer_index)
}

#' @title Consume gradient layers incrementally (batch assembly)
#' @description Builds the emergence structure layer by layer. Each
#'   batch is one gradient layer; the caller may stop after any batch
#'   (incremental construction, no fixed matrix is required). Depth 0..4
#'   map to symbols A,B,C,D,e; deeper layers are reported as requiring
#'   symbol extension (candidate, not fabricated).
#' @param depth non-negative integer; how many layers to consume.
#' @param symbols optional character vector; symbol table ordered from
#'   the CENTER outward (default e,D,C,B,A — the singularity is the
#'   first batch, matching the frozen definition that e is the center).
#' @return list with \code{layers} (position stream), \code{depth_map}
#'   (position -> gradient depth, as a data frame), \code{symbols},
#'   \code{needs_extension} logical and \code{extension_note}.
#' @examples
#' e <- emerge_by_layers(2L)
#' e$needs_extension
emerge_by_layers <- function(depth, symbols = c("e", "D", "C", "B", "A")) {
  depth <- as.integer(depth)
  if (length(depth) != 1L || is.na(depth) || depth < 0L) {
    stop("`depth` must be one non-negative integer.", call. = FALSE)
  }
  symbols <- as.character(symbols)
  if (length(symbols) < 1L || anyNA(symbols) || any(symbols == "")) {
    stop("`symbols` must be a non-empty character vector.", call. = FALSE)
  }
  g <- gradient_layers(depth)
  n_used <- length(g)
  needs_extension <- n_used > length(symbols)
  depth_map <- do.call(rbind, lapply(seq_along(g), function(k) {
    d <- data.frame(x = g[[k]]$x, y = g[[k]]$y, depth = k - 1L,
                    stringsAsFactors = FALSE)
    d$symbol <- if (k - 1L < length(symbols)) symbols[k] else NA_character_
    d
  }))
  rownames(depth_map) <- NULL
  list(
    layers = g,
    depth_map = depth_map,
    symbols = symbols,
    needs_extension = needs_extension,
    extension_note = if (needs_extension) {
      sprintf("gradient depth %d exceeds symbol table size %d; extension required",
              max(depth_map$depth), length(symbols))
    } else {
      NA_character_
    }
  )
}

#' @title Project a gradient stream onto a square window
#' @description Display-only projection: lays the gradient stream onto a
#'   (2*radius+1) x (2*radius+1) window with NA outside the diamond.
#'   The window is an observation slice, NOT the topology itself.
#' @param emergence result of \code{emerge_by_layers}.
#' @param radius integer; half-width of the window. Must be >= the
#'   maximum layer consumed.
#' @return character matrix (symbols) with NA in the four corners.
#' @examples
#' e <- emerge_by_layers(2L)
#' project_gradient_window(e, radius = 2L)
project_gradient_window <- function(emergence, radius) {
  radius <- as.integer(radius)
  if (length(radius) != 1L || is.na(radius) || radius < 0L) {
    stop("`radius` must be one non-negative integer.", call. = FALSE)
  }
  n <- 2L * radius + 1L
  m <- matrix(NA_character_, nrow = n, ncol = n)
  dm <- emergence$depth_map
  for (i in seq_len(nrow(dm))) {
    x <- dm$x[i]; y <- dm$y[i]
    if (abs(x) <= radius && abs(y) <= radius) {
      m[y + radius + 1L, x + radius + 1L] <- dm$symbol[i]
    }
  }
  m
}

#' @title Verify structural invariants of a gradient emergence
#' @description Checks the invariants that must hold for ANY layer of a
#'   gradient expansion: layer sizes are 4k (k>0), center is unique,
#'   central inversion symmetry (x,y) <-> (-x,-y), and gradient depth
#'   equals layer index. These are structural facts, not value guesses.
#' @param emergence result of \code{emerge_by_layers}.
#' @return list with named logical checks and an overall \code{ok}.
verify_gradient_emergence <- function(emergence) {
  g <- emergence$layers
  n_layers <- length(g)
  sizes <- vapply(g, nrow, integer(1L))
  size_ok <- sizes[[1L]] == 1L &&
    all(vapply(seq_len(n_layers - 1L), function(k) {
      sizes[[k + 1L]] == 4L * k
    }, logical(1L)))

  center_ok <- identical(g[[1L]]$x, 0L) && identical(g[[1L]]$y, 0L)

  # central inversion: every (x,y) in layer k has (-x,-y) in layer k
  inv_ok <- TRUE
  if (n_layers >= 1L) {
    for (k in seq_len(n_layers)) {
      lk <- g[[k]]
      keys <- paste(lk$x, lk$y, sep = ",")
      inv_keys <- paste(-lk$x, -lk$y, sep = ",")
      if (!setequal(keys, inv_keys)) {
        inv_ok <- FALSE
        break
      }
    }
  }

  # gradient depth == layer index
  dm <- emergence$depth_map
  depth_ok <- all(dm$depth == rep(seq_len(n_layers) - 1L,
                                  vapply(g, nrow, integer(1L))))

  list(
    layer_size_ok = size_ok,
    center_ok = center_ok,
    inversion_ok = inv_ok,
    depth_ok = depth_ok,
    ok = size_ok && center_ok && inv_ok && depth_ok
  )
}
