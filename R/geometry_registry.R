# == v0.8 Registries — MetricLaw & TransportLaw =====================
# Math anchor: MetricLaw g/d answers "how far"; TransportLaw P_ij:E_i->E_j
#   answers "how states compare across positions". First transport is
#   identity (flat baseline); flat baseline cycles MUST return identity
#   (property test flat_transport_has_trivial_holonomy).

.geometries_env <- new.env(parent = emptyenv())
.geometries_env$metrics   <- list()
.geometries_env$transport <- list()

register_metric <- function(name, distance_fn) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(distance_fn)) {
    stop("`distance_fn` must be a function.", call. = FALSE)
  }
  .geometries_env$metrics[[name]] <- distance_fn
  invisible(name)
}

get_metric <- function(name) {
  fn <- .geometries_env$metrics[[name]]
  if (is.null(fn)) stop(sprintf("Unknown metric '%s' (fail closed).", name),
                        call. = FALSE)
  fn
}

has_metric <- function(name) !is.null(.geometries_env$metrics[[name]])

register_transport_law <- function(name, step_fn) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("`name` must be a single non-empty character.", call. = FALSE)
  }
  if (!is.function(step_fn)) {
    stop("`step_fn` must be a function(state, from, to, regulation).",
         call. = FALSE)
  }
  .geometries_env$transport[[name]] <- step_fn
  invisible(name)
}

get_transport_law <- function(name) {
  fn <- .geometries_env$transport[[name]]
  if (is.null(fn)) stop(sprintf("Unknown transport law '%s' (fail closed).", name),
                        call. = FALSE)
  fn
}

has_transport_law <- function(name) !is.null(.geometries_env$transport[[name]])

# -- built-in reference implementations (registered lazily) --------
.geometries_register_defaults <- function() {
  register_metric("manhattan", function(a, b) {
    sum(abs(a$coordinate - b$coordinate))
  })
  register_metric("euclidean", function(a, b) {
    sqrt(sum((a$coordinate - b$coordinate)^2))
  })
  register_transport_law("grid_identity", function(state, from, to,
                                                   regulation = NULL) {
    state  # identity connection: flat baseline, trivial holonomy
  })
  invisible(TRUE)
}
.onLoad_geometry_defaults <- function() .geometries_register_defaults()

# 注意: `.onLoad_geometry_defaults()` 不挂钩真 .onLoad（那是包级钩子，
# 改 NAMESPACE/包级 env 属于另一批）。改为在测试 helper 中显式调用一次。