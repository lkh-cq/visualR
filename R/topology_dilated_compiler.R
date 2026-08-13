# == Dilated topology compiler ======================================
# STATUS: reference_experimental (v0.6.1)
#
# Engineering reference:
#   locuslab/TCN @ 2f8c2b817050206397458dfd1f5a25ce8a32fe65
#   TCN/tcn.py: fixed kernel, dilation 2^level, two convolutions per
#   TemporalBlock, shape-preserving residual identity.
#
# This is a structural migration, not a neural-network port.  Tokens,
# PAL addresses, open boundaries and residual paths stay symbolic.  R
# is the semantic authority; C99 may compile the integer tap schedule
# only, and must produce a byte-for-byte identical schedule.

MAX_COMPILED_TAPS <- 1000000L

.topology_integer_vector <- function(x, name, minimum, maximum,
                                     scalar = FALSE) {
  if (!(is.integer(x) || is.numeric(x)) || length(x) < 1L ||
      anyNA(x) || any(!is.finite(x)) || any(x != trunc(x)) ||
      any(x < minimum) || any(x > maximum)) {
    stop(sprintf("`%s` must contain finite integers in [%s, %s].",
                 name, minimum, maximum), call. = FALSE)
  }
  if (scalar && length(x) != 1L) {
    stop(sprintf("`%s` must be one integer.", name), call. = FALSE)
  }
  as.integer(x)
}

.normalize_compile_arguments <- function(width, levels, kernel_offsets,
                                         convolutions_per_level) {
  width <- .topology_integer_vector(width, "width", 1L,
                                    2L * MAX_SHELLS + 1L, scalar = TRUE)
  if (width %% 2L != 1L) {
    stop("`width` must be odd for a PAL path.", call. = FALSE)
  }
  levels <- .topology_integer_vector(levels, "levels", 1L, 30L,
                                     scalar = TRUE)
  convolutions_per_level <- .topology_integer_vector(
    convolutions_per_level, "convolutions_per_level", 1L, 16L,
    scalar = TRUE
  )
  kernel_offsets <- .topology_integer_vector(
    kernel_offsets, "kernel_offsets", -32768L, 32767L
  )
  if (length(kernel_offsets) > 31L) {
    stop("`kernel_offsets` may contain at most 31 addresses.",
         call. = FALSE)
  }
  if (anyDuplicated(kernel_offsets)) {
    stop("`kernel_offsets` must be unique; duplicate taps are ambiguous.",
         call. = FALSE)
  }

  max_dilation <- 2^(levels - 1L)
  max_one_hop <- max(abs(as.double(kernel_offsets))) * max_dilation
  if (max_one_hop + width > .Machine$integer.max) {
    stop("Compiled source addresses would exceed the integer range.",
         call. = FALSE)
  }

  tap_count <- as.double(width) * levels * convolutions_per_level *
    length(kernel_offsets)
  if (tap_count > MAX_COMPILED_TAPS) {
    stop(sprintf("Tap schedule exceeds MAX_COMPILED_TAPS=%d.",
                 MAX_COMPILED_TAPS), call. = FALSE)
  }

  list(
    width = width,
    levels = levels,
    kernel_offsets = kernel_offsets,
    convolutions_per_level = convolutions_per_level,
    tap_count = as.integer(tap_count)
  )
}

.tap_schedule_columns <- c(
  "level", "convolution", "source_layer", "target_layer", "dilation",
  "target_position", "kernel_offset", "source_position", "scope"
)

.compile_tap_schedule_r <- function(width, levels, kernel_offsets,
                                    convolutions_per_level, tap_count) {
  schedule <- matrix(0L, nrow = tap_count,
                     ncol = length(.tap_schedule_columns))
  colnames(schedule) <- .tap_schedule_columns
  row <- 0L

  for (level in seq_len(levels)) {
    dilation <- as.integer(2^(level - 1L))
    for (convolution in seq_len(convolutions_per_level)) {
      source_layer <- (level - 1L) * convolutions_per_level +
        convolution - 1L
      target_layer <- source_layer + 1L
      for (target_position in seq_len(width)) {
        for (kernel_offset in kernel_offsets) {
          row <- row + 1L
          source_position <- as.integer(
            target_position + as.double(kernel_offset) * dilation
          )
          scope <- if (source_position < 1L) {
            -1L
          } else if (source_position > width) {
            1L
          } else {
            0L
          }
          schedule[row, ] <- c(
            level, convolution, source_layer, target_layer, dilation,
            target_position, kernel_offset, source_position, scope
          )
        }
      }
    }
  }
  schedule
}

.compile_tap_schedule_c <- function(width, levels, kernel_offsets,
                                    convolutions_per_level) {
  if (!is.loaded("C_visualr_compile_taps", PACKAGE = "visualR")) {
    stop("The C99 tap compiler is not loaded; install visualR with compilation enabled.",
         call. = FALSE)
  }
  schedule <- .Call(
    "C_visualr_compile_taps",
    width,
    levels,
    kernel_offsets,
    convolutions_per_level,
    PACKAGE = "visualR"
  )
  colnames(schedule) <- .tap_schedule_columns
  schedule
}

.topology_node_id <- function(layer, global_address) {
  sprintf("L%03d:G%+011d", as.integer(layer), as.integer(global_address))
}

.make_topology_nodes <- function(window, schedule,
                                 convolutions_per_level, levels) {
  width <- window$width
  total_layers <- levels * convolutions_per_level
  layer <- rep(0:total_layers, each = width)
  position <- rep.int(seq_len(width), times = total_layers + 1L)
  global_address <- window$addresses$global_address[position]
  local_offset <- window$addresses$local_offset[position]
  token <- rep.int(NA_character_, length(layer))
  token[layer == 0L] <- window$path[position[layer == 0L]]
  node_kind <- ifelse(
    layer == 0L, "input",
    ifelse(layer == total_layers, "output", "intermediate")
  )

  internal <- data.frame(
    node_id = .topology_node_id(layer, global_address),
    layer = as.integer(layer),
    position = as.integer(position),
    local_offset = as.integer(local_offset),
    global_address = as.integer(global_address),
    token = token,
    node_kind = node_kind,
    side = window$addresses$side[position],
    outer_ref = rep.int(NA_character_, length(layer)),
    stringsAsFactors = FALSE
  )

  outside <- schedule[, "scope"] != 0L
  if (!any(outside)) {
    return(internal)
  }
  source_position <- schedule[outside, "source_position"]
  source_layer <- schedule[outside, "source_layer"]
  center_position <- window$radius + 1L
  global <- as.double(window$origin) + source_position - center_position
  if (any(global > .Machine$integer.max) ||
      any(global < -.Machine$integer.max)) {
    stop("Frontier addresses exceed the supported integer range.",
         call. = FALSE)
  }
  global <- as.integer(global)
  ids <- .topology_node_id(source_layer, global)
  keep <- !duplicated(ids)
  side <- ifelse(schedule[outside, "scope"] < 0L, "left", "right")
  refs <- ifelse(side == "left", window$outer_ref$left,
                 window$outer_ref$right)
  external <- data.frame(
    node_id = ids[keep],
    layer = as.integer(source_layer[keep]),
    position = rep.int(NA_integer_, sum(keep)),
    local_offset = as.integer(global[keep] - window$origin),
    global_address = global[keep],
    token = rep.int(NA_character_, sum(keep)),
    node_kind = rep.int(
      if (identical(window$boundary, "open")) "outer_reference"
      else "boundary_stop",
      sum(keep)
    ),
    side = side[keep],
    outer_ref = refs[keep],
    stringsAsFactors = FALSE
  )
  rbind(internal, external)
}

.make_tap_edges <- function(window, schedule) {
  width <- window$width
  center_position <- window$radius + 1L
  visible <- schedule[, "scope"] == 0L
  source_global <- as.double(window$origin) +
    schedule[, "source_position"] - center_position
  target_global <- as.double(window$origin) +
    schedule[, "target_position"] - center_position
  if (any(abs(c(source_global, target_global)) > .Machine$integer.max)) {
    stop("Compiled edge addresses exceed the supported integer range.",
         call. = FALSE)
  }
  source_global <- as.integer(source_global)
  target_global <- as.integer(target_global)
  side <- ifelse(visible, "visible",
                 ifelse(schedule[, "scope"] < 0L, "left", "right"))
  source_kind <- ifelse(
    visible,
    "visible",
    if (identical(window$boundary, "open")) "outer_reference"
    else "boundary_stop"
  )
  refs <- rep.int(NA_character_, nrow(schedule))
  refs[!visible & side == "left"] <- window$outer_ref$left
  refs[!visible & side == "right"] <- window$outer_ref$right

  data.frame(
    edge_id = sprintf("E%07d", seq_len(nrow(schedule))),
    edge_type = rep.int("dilated_tap", nrow(schedule)),
    level = schedule[, "level"],
    convolution = schedule[, "convolution"],
    dilation = schedule[, "dilation"],
    kernel_offset = schedule[, "kernel_offset"],
    from_node = .topology_node_id(schedule[, "source_layer"], source_global),
    to_node = .topology_node_id(schedule[, "target_layer"], target_global),
    source_layer = schedule[, "source_layer"],
    target_layer = schedule[, "target_layer"],
    source_position = schedule[, "source_position"],
    target_position = schedule[, "target_position"],
    source_global = source_global,
    target_global = target_global,
    source_kind = source_kind,
    side = side,
    outer_ref = refs,
    reference_bound = visible | (!is.na(refs) & source_kind == "outer_reference"),
    requires_resolution = !visible,
    stringsAsFactors = FALSE
  )
}

.make_residual_edges <- function(window, levels, convolutions_per_level,
                                 dilations, first_edge) {
  width <- window$width
  level <- rep(seq_len(levels), each = width)
  position <- rep.int(seq_len(width), times = levels)
  global_address <- window$addresses$global_address[position]
  source_layer <- (level - 1L) * convolutions_per_level
  target_layer <- level * convolutions_per_level
  n <- length(level)

  data.frame(
    edge_id = sprintf("E%07d", first_edge + seq_len(n) - 1L),
    edge_type = rep.int("residual_identity", n),
    level = as.integer(level),
    convolution = rep.int(NA_integer_, n),
    dilation = dilations[level],
    kernel_offset = rep.int(NA_integer_, n),
    from_node = .topology_node_id(source_layer, global_address),
    to_node = .topology_node_id(target_layer, global_address),
    source_layer = as.integer(source_layer),
    target_layer = as.integer(target_layer),
    source_position = as.integer(position),
    target_position = as.integer(position),
    source_global = as.integer(global_address),
    target_global = as.integer(global_address),
    source_kind = rep.int("residual_identity", n),
    side = rep.int("visible", n),
    outer_ref = rep.int(NA_character_, n),
    reference_bound = rep.int(TRUE, n),
    requires_resolution = rep.int(FALSE, n),
    stringsAsFactors = FALSE
  )
}

#' @title Compile a TCN-style dilated PAL topology
#' @description Compiles a complete PAL or addressed PAL window into an
#'   auditable graph. Each level uses dilation 2^(level-1), a fixed ordered
#'   kernel, a configurable number of convolution passes (two by default),
#'   and one shape-preserving residual identity per visible address.
#'
#'   The result is symbolic topology, not numerical convolution. An address
#'   outside an open window becomes an explicit outer-reference node. The same
#'   address outside a closed solution becomes an explicit boundary-stop node.
#'   Neither case silently inserts zero padding. R is authoritative; engine
#'   "c" accelerates only the integer tap schedule and is checked against the
#'   same graph contract.
#' @param x a visualr_pal or visualr_pal_window
#' @param levels integer number of residual levels
#' @param kernel_offsets ordered unique integer tap offsets
#' @param convolutions_per_level integer passes per level; default 2 mirrors
#'   the reference TemporalBlock
#' @param engine "r" (semantic reference) or "c" (C99 address compiler)
#' @return a visualr_dilated_plan
#' @examples
#' w <- open_window_parse("}{B{C{D}C}B}{")
#' compile_dilated_topology(w, levels = 2L)
compile_dilated_topology <- function(
    x,
    levels,
    kernel_offsets = c(-1L, 0L, 1L),
    convolutions_per_level = 2L,
    engine = c("r", "c")) {
  engine <- match.arg(engine)
  window <- if (inherits(x, "visualr_pal_window")) {
    .validate_pal_window(x)
    x
  } else {
    validate_pal(x)
    new_pal_window(x)
  }

  args <- .normalize_compile_arguments(
    window$width, levels, kernel_offsets, convolutions_per_level
  )
  schedule <- if (identical(engine, "r")) {
    .compile_tap_schedule_r(
      args$width, args$levels, args$kernel_offsets,
      args$convolutions_per_level, args$tap_count
    )
  } else {
    .compile_tap_schedule_c(
      args$width, args$levels, args$kernel_offsets,
      args$convolutions_per_level
    )
  }
  if (!identical(dim(schedule), c(args$tap_count, 9L))) {
    stop("Tap compiler returned an invalid schedule shape.", call. = FALSE)
  }

  dilations <- growth_sequence("dilation_power", args$levels - 1L)
  tap_edges <- .make_tap_edges(window, schedule)
  residual_edges <- .make_residual_edges(
    window, args$levels, args$convolutions_per_level, dilations,
    nrow(tap_edges) + 1L
  )
  edges <- rbind(tap_edges, residual_edges)
  nodes <- .make_topology_nodes(
    window, schedule, args$convolutions_per_level, args$levels
  )
  total_layers <- args$levels * args$convolutions_per_level
  blocks <- data.frame(
    level = seq_len(args$levels),
    dilation = dilations,
    source_layer = (seq_len(args$levels) - 1L) *
      args$convolutions_per_level,
    target_layer = seq_len(args$levels) * args$convolutions_per_level,
    convolutions = rep.int(args$convolutions_per_level, args$levels),
    kernel_offsets = rep.int(
      paste(args$kernel_offsets, collapse = ","), args$levels
    ),
    residual = rep.int(TRUE, args$levels),
    stringsAsFactors = FALSE
  )

  dilation_sum <- sum(as.double(dilations))
  tap_min_reach <- args$convolutions_per_level * dilation_sum *
    min(args$kernel_offsets)
  tap_max_reach <- args$convolutions_per_level * dilation_sum *
    max(args$kernel_offsets)
  min_reach <- min(0, tap_min_reach)
  max_reach <- max(0, tap_max_reach)
  unresolved <- edges[edges$requires_resolution, , drop = FALSE]
  plan <- structure(
    list(
      status = "reference_experimental",
      semantic_authority = "R",
      engine = engine,
      source_reference = list(
        repository = "https://github.com/locuslab/TCN",
        commit = "2f8c2b817050206397458dfd1f5a25ce8a32fe65",
        file = "TCN/tcn.py",
        migrated_pattern = paste(
          "fixed kernel; dilation 2^level; two-pass residual block;",
          "shape-preserving identity"
        )
      ),
      window = window,
      levels = args$levels,
      convolutions_per_level = args$convolutions_per_level,
      kernel_offsets = args$kernel_offsets,
      total_layers = as.integer(total_layers),
      shape = list(
        input_width = args$width,
        output_width = args$width,
        preserved = TRUE
      ),
      receptive_span = list(
        min_offset = min_reach,
        max_offset = max_reach,
        width = max_reach - min_reach + 1
      ),
      schedule = schedule,
      blocks = blocks,
      nodes = nodes,
      edges = edges,
      unresolved_edges = unresolved,
      numeric_fusion = FALSE
    ),
    class = "visualr_dilated_plan"
  )
  validate_dilated_plan(plan)
  plan
}

#' @title Validate a compiled dilated topology plan
#' @description Checks shape preservation, node/edge closure, exact edge
#'   counts, dilation sequence, and residual-address identity. It does not
#'   resolve open outer references or execute numeric operators.
#' @param plan a visualr_dilated_plan
#' @return invisible TRUE; fails closed on the first broken invariant
validate_dilated_plan <- function(plan) {
  if (!inherits(plan, "visualr_dilated_plan")) {
    stop("`plan` must be a visualr_dilated_plan.", call. = FALSE)
  }
  required <- c("status", "semantic_authority", "engine",
                "source_reference", "window", "levels",
                "convolutions_per_level", "kernel_offsets", "total_layers",
                "shape", "receptive_span", "schedule", "blocks", "nodes", "edges",
                "unresolved_edges", "numeric_fusion")
  missing <- setdiff(required, names(plan))
  if (length(missing) > 0L) {
    stop(sprintf("Dilated plan is missing: %s.",
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  if (!is.character(plan$engine) || length(plan$engine) != 1L ||
      is.na(plan$engine) || !plan$engine %in% c("r", "c")) {
    stop("Dilated plan has an invalid engine declaration.", call. = FALSE)
  }
  .validate_pal_window(plan$window)
  args <- .normalize_compile_arguments(
    plan$window$width, plan$levels, plan$kernel_offsets,
    plan$convolutions_per_level
  )
  width <- args$width
  expected_taps <- args$tap_count
  expected_residuals <- width * plan$levels
  taps <- plan$edges$edge_type == "dilated_tap"
  residuals <- plan$edges$edge_type == "residual_identity"

  if (nrow(plan$schedule) != expected_taps || sum(taps) != expected_taps ||
      sum(residuals) != expected_residuals) {
    stop("Dilated plan edge-count invariant failed.", call. = FALSE)
  }
  reference_schedule <- .compile_tap_schedule_r(
    args$width, args$levels, args$kernel_offsets,
    args$convolutions_per_level, args$tap_count
  )
  if (!identical(plan$schedule, reference_schedule)) {
    stop("Dilated plan schedule differs from the R authority.",
         call. = FALSE)
  }
  expected_total_layers <- as.integer(
    args$levels * args$convolutions_per_level
  )
  expected_shape <- list(
    input_width = args$width,
    output_width = args$width,
    preserved = TRUE
  )
  if (!identical(plan$total_layers, expected_total_layers) ||
      !identical(plan$shape, expected_shape)) {
    stop("Dilated plan must preserve visible width.", call. = FALSE)
  }
  dilations <- growth_sequence("dilation_power", args$levels - 1L)
  expected_blocks <- data.frame(
    level = seq_len(args$levels),
    dilation = dilations,
    source_layer = (seq_len(args$levels) - 1L) *
      args$convolutions_per_level,
    target_layer = seq_len(args$levels) * args$convolutions_per_level,
    convolutions = rep.int(args$convolutions_per_level, args$levels),
    kernel_offsets = rep.int(
      paste(args$kernel_offsets, collapse = ","), args$levels
    ),
    residual = rep.int(TRUE, args$levels),
    stringsAsFactors = FALSE
  )
  if (!identical(plan$blocks, expected_blocks)) {
    stop("Dilated plan growth-law invariant failed.", call. = FALSE)
  }
  dilation_sum <- sum(as.double(dilations))
  tap_min_reach <- args$convolutions_per_level * dilation_sum *
    min(args$kernel_offsets)
  tap_max_reach <- args$convolutions_per_level * dilation_sum *
    max(args$kernel_offsets)
  expected_span <- list(
    min_offset = min(0, tap_min_reach),
    max_offset = max(0, tap_max_reach),
    width = max(0, tap_max_reach) - min(0, tap_min_reach) + 1
  )
  if (!identical(plan$receptive_span, expected_span)) {
    stop("Dilated plan receptive-span invariant failed.", call. = FALSE)
  }
  if (anyDuplicated(plan$nodes$node_id) || anyDuplicated(plan$edges$edge_id)) {
    stop("Dilated plan contains duplicate node or edge identifiers.",
         call. = FALSE)
  }
  if (!all(plan$edges$from_node %in% plan$nodes$node_id) ||
      !all(plan$edges$to_node %in% plan$nodes$node_id)) {
    stop("Dilated plan contains an edge whose node is not declared.",
         call. = FALSE)
  }
  tap_edges <- plan$edges[taps, , drop = FALSE]
  center_position <- plan$window$radius + 1L
  expected_source_global <- as.integer(
    as.double(plan$window$origin) +
      plan$schedule[, "source_position"] - center_position
  )
  expected_target_global <- as.integer(
    as.double(plan$window$origin) +
      plan$schedule[, "target_position"] - center_position
  )
  visible <- plan$schedule[, "scope"] == 0L
  expected_side <- ifelse(
    visible, "visible",
    ifelse(plan$schedule[, "scope"] < 0L, "left", "right")
  )
  expected_kind <- ifelse(
    visible, "visible",
    if (identical(plan$window$boundary, "open")) "outer_reference"
    else "boundary_stop"
  )
  expected_refs <- rep.int(NA_character_, expected_taps)
  expected_refs[!visible & expected_side == "left"] <-
    plan$window$outer_ref$left
  expected_refs[!visible & expected_side == "right"] <-
    plan$window$outer_ref$right
  expected_from <- .topology_node_id(
    plan$schedule[, "source_layer"], expected_source_global
  )
  expected_to <- .topology_node_id(
    plan$schedule[, "target_layer"], expected_target_global
  )
  if (!identical(which(taps), seq_len(expected_taps)) ||
      !identical(tap_edges$level, plan$schedule[, "level"]) ||
      !identical(tap_edges$convolution,
                 plan$schedule[, "convolution"]) ||
      !identical(tap_edges$dilation, plan$schedule[, "dilation"]) ||
      !identical(tap_edges$kernel_offset,
                 plan$schedule[, "kernel_offset"]) ||
      !identical(tap_edges$source_layer,
                 plan$schedule[, "source_layer"]) ||
      !identical(tap_edges$target_layer,
                 plan$schedule[, "target_layer"]) ||
      !identical(tap_edges$source_position,
                 plan$schedule[, "source_position"]) ||
      !identical(tap_edges$target_position,
                 plan$schedule[, "target_position"]) ||
      !identical(tap_edges$source_global, expected_source_global) ||
      !identical(tap_edges$target_global, expected_target_global) ||
      !identical(tap_edges$from_node, expected_from) ||
      !identical(tap_edges$to_node, expected_to) ||
      !identical(tap_edges$source_kind, expected_kind) ||
      !identical(tap_edges$side, expected_side) ||
      !identical(tap_edges$outer_ref, expected_refs) ||
      !identical(tap_edges$reference_bound,
                 visible | (!is.na(expected_refs) &
                              expected_kind == "outer_reference")) ||
      !identical(tap_edges$requires_resolution, !visible)) {
    stop("Dilated tap edges differ from the compiled schedule.",
         call. = FALSE)
  }
  if (any(plan$edges$requires_resolution !=
          (plan$edges$source_kind %in% c("outer_reference", "boundary_stop")))) {
    stop("Dilated plan frontier-resolution invariant failed.", call. = FALSE)
  }
  if (any(plan$edges$source_position[residuals] !=
          plan$edges$target_position[residuals]) ||
      any(plan$edges$source_global[residuals] !=
          plan$edges$target_global[residuals])) {
    stop("Residual edges must preserve address identity.", call. = FALSE)
  }
  residual_edges <- plan$edges[residuals, , drop = FALSE]
  expected_residual_level <- rep(seq_len(args$levels), each = width)
  expected_residual_position <- rep.int(seq_len(width), times = args$levels)
  expected_residual_global <-
    plan$window$addresses$global_address[expected_residual_position]
  expected_residual_source <-
    (expected_residual_level - 1L) * args$convolutions_per_level
  expected_residual_target <-
    expected_residual_level * args$convolutions_per_level
  if (!identical(which(residuals),
                 expected_taps + seq_len(expected_residuals)) ||
      !identical(residual_edges$level, expected_residual_level) ||
      !identical(residual_edges$dilation,
                 dilations[expected_residual_level]) ||
      !identical(residual_edges$source_layer,
                 as.integer(expected_residual_source)) ||
      !identical(residual_edges$target_layer,
                 as.integer(expected_residual_target)) ||
      !identical(residual_edges$source_position,
                 as.integer(expected_residual_position)) ||
      !identical(residual_edges$source_global,
                 as.integer(expected_residual_global)) ||
      !all(residual_edges$source_kind == "residual_identity") ||
      any(residual_edges$requires_resolution)) {
    stop("Residual edges differ from the block ABI.", call. = FALSE)
  }
  internal_layer <- rep(0:expected_total_layers, each = width)
  internal_position <- rep.int(
    seq_len(width), times = expected_total_layers + 1L
  )
  internal_ids <- .topology_node_id(
    internal_layer,
    plan$window$addresses$global_address[internal_position]
  )
  external_ids <- unique(expected_from[!visible])
  if (!identical(plan$nodes$node_id, c(internal_ids, external_ids))) {
    stop("Dilated plan node declaration differs from its address graph.",
         call. = FALSE)
  }
  expected_unresolved <- plan$edges[
    plan$edges$requires_resolution, , drop = FALSE
  ]
  if (!identical(plan$unresolved_edges, expected_unresolved)) {
    stop("Dilated plan unresolved frontier table is stale.", call. = FALSE)
  }
  expected_reference <- list(
    repository = "https://github.com/locuslab/TCN",
    commit = "2f8c2b817050206397458dfd1f5a25ce8a32fe65",
    file = "TCN/tcn.py",
    migrated_pattern = paste(
      "fixed kernel; dilation 2^level; two-pass residual block;",
      "shape-preserving identity"
    )
  )
  if (!identical(plan$source_reference, expected_reference)) {
    stop("Dilated plan source-reference invariant failed.", call. = FALSE)
  }
  if (!identical(plan$status, "reference_experimental") ||
      !identical(plan$semantic_authority, "R") ||
      !identical(plan$numeric_fusion, FALSE)) {
    stop("Compiler authority/fusion contract failed.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
print.visualr_dilated_plan <- function(x, ...) {
  validate_dilated_plan(x)
  cat(sprintf(
    "<visualr_dilated_plan> levels=%d layers=%d width=%d engine=%s\n",
    x$levels, x$total_layers, x$shape$input_width, x$engine
  ))
  cat(sprintf(
    "  taps=%d residuals=%d frontier=%d boundary=%s status=%s\n",
    sum(x$edges$edge_type == "dilated_tap"),
    sum(x$edges$edge_type == "residual_identity"),
    nrow(x$unresolved_edges), x$window$boundary, x$status
  ))
  invisible(x)
}
