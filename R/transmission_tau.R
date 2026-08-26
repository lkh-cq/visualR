# == v0.10 Transmission Signature tau = (d, b, r, phi, g) ============
# Report definition:
#   d = accumulated metric distance over the path
#   b = boundary load (count of boundary crossings; raw types stay in path)
#   r = recursive-layer travel measured as SUM |delta layer| (not net!)
#       -- so up-then-down does NOT cancel to zero
#   phi = wrapped net phase change in (-pi, pi]
#   g = prescribed regulation summary vector
#
# tau is ALWAYS a lossy audit/statistical summary; it never replaces the
# full path (holonomy warning inherited from v0.8 contract).
#
# psi(tau) is the statistical feature embedding: bounded transforms for
# d/b/r, CIRCULAR encoding sin/cos for phi (never raw angle into linear
# models), and caller-supplied robust scaling for g. Scale fitting MUST
# happen on training data only — this function refuses to fit anything.

wrap_phase <- function(x) atan2(sin(x), cos(x))

transmission_tau <- function(events, positions_path, metric_name,
                             final_phase, regulation_summary) {
  if (!is.list(events) || length(events) == 0L) {
    stop("`events` must be a non-empty list of transmission events.",
         call. = FALSE)
  }
  for (ev in events) validate_transmission_event(ev)
  d_fn <- get_metric(metric_name)

  d <- 0; b <- 0; r <- 0
  cur <- events[[1L]]$from
  for (ev in events) {
    for (st in ev$substeps) {
      d <- d + d_fn(cur, st$to)
      if (isTRUE(st$boundary)) b <- b + 1L
      r <- r + abs(st$to$layer - cur$layer)
      cur <- st$to
    }
  }

  list(
    d   = d,
    b   = b,
    r   = r,
    phi = wrap_phase(final_phase),
    g   = as.numeric(regulation_summary),
    g_names = names(regulation_summary)
  )
}

# psi feature embedding. `scales` and `reg_center`/`reg_scale` are
# CALLER-SUPPLIED constants (fitted on training data upstream). This
# function performs no data-driven estimation (leakage discipline).
psi_embed_tau <- function(tau, scales = c(d = 1, b = 1, r = 1),
                          reg_center = NULL, reg_scale = NULL) {
  if (!all(c("d","b","r") %in% names(scales))) {
    stop("`scales` must name d/b/r.", call. = FALSE)
  }
  f <- function(x, s) x / (x + s)
  out <- c(
    f_d = f(tau$d, scales[["d"]]),
    f_b = f(tau$b, scales[["b"]]),
    f_r = f(tau$r, scales[["r"]]),
    sin_phi = sin(tau$phi),
    cos_phi = cos(tau$phi)
  )
  g <- tau$g
  if (!is.null(g) && length(g)) {
    if (is.null(reg_center) || is.null(reg_scale)) {
      stop(paste("regulation present but reg_center/reg_scale missing;",
                 "fit them on TRAINING data only and pass them in",
                 "(leakage discipline)."), call. = FALSE)
    }
    if (length(reg_center) != length(g) ||
        length(reg_scale) != length(g)) {
      stop("reg_center/reg_scale must match regulation length.", call. = FALSE)
    }
    fg <- tanh((g - reg_center) / (1.4826 * reg_scale + 1e-12))
    out <- c(out, stats::setNames(as.numeric(fg),
                                  paste0("g_", tau$g_names)))
  }
  out
}