# == PAL solution/window state =======================================
# STATUS: reference_experimental (v0.6.1)
#
# The frozen grammar describes a complete palindrome.  A moving
# computation also needs to distinguish that complete solution from a
# visible window whose enclosing solution exists but is deliberately
# omitted.  This module makes that boundary state explicit:
#
#   closed: {A{B{C}B}A}
#   open:   }{B{C{D}C}B}{
#
# `}{` is boundary syntax only.  It is never admitted into the frozen
# PAL token domain and it never changes pal_parse()/pal_encode().

.window_integer_scalar <- function(x, name) {
  if (!(is.integer(x) || is.numeric(x)) || length(x) != 1L ||
      is.na(x) || !is.finite(x) || x != trunc(x) ||
      x > .Machine$integer.max || x < -.Machine$integer.max) {
    stop(sprintf("`%s` must be one finite integer.", name), call. = FALSE)
  }
  as.integer(x)
}

.normalize_outer_ref <- function(outer_ref, boundary) {
  if (!is.list(outer_ref) ||
      !identical(sort(names(outer_ref)), c("left", "right"))) {
    stop("`outer_ref` must be a list with exactly `left` and `right`.",
         call. = FALSE)
  }

  normalize_one <- function(x, side) {
    if (!is.character(x) || length(x) != 1L) {
      stop(sprintf("`outer_ref$%s` must be one character value or NA.", side),
           call. = FALSE)
    }
    if (!is.na(x) && (nchar(x) == 0L || grepl("\n|\r", x))) {
      stop(sprintf("`outer_ref$%s` must be non-empty and single-line.", side),
           call. = FALSE)
    }
    x
  }

  refs <- list(
    left = normalize_one(outer_ref$left, "left"),
    right = normalize_one(outer_ref$right, "right")
  )
  if (identical(boundary, "closed") &&
      (!is.na(refs$left) || !is.na(refs$right))) {
    stop("A closed window cannot bind `outer_ref`; use boundary = 'open'.",
         call. = FALSE)
  }
  refs
}

.validate_pal_window <- function(window) {
  if (!inherits(window, "visualr_pal_window")) {
    stop("`window` must be a visualr_pal_window object.", call. = FALSE)
  }
  required <- c("pal", "boundary", "origin", "radius", "width",
                "path", "addresses", "outer_ref", "trace")
  missing <- setdiff(required, names(window))
  if (length(missing) > 0L) {
    stop(sprintf("PAL window is missing: %s.", paste(missing, collapse = ", ")),
         call. = FALSE)
  }
  validate_pal(window$pal)
  if (!is.character(window$boundary) || length(window$boundary) != 1L ||
      is.na(window$boundary) || !window$boundary %in% c("closed", "open")) {
    stop("PAL window has an invalid boundary state.", call. = FALSE)
  }
  origin <- .window_integer_scalar(window$origin, "window$origin")
  refs <- .normalize_outer_ref(window$outer_ref, window$boundary)
  if (!identical(refs, window$outer_ref)) {
    stop("PAL window outer-reference invariant failed.", call. = FALSE)
  }
  expected_radius <- as.integer(length(window$pal$shells))
  if (!identical(window$radius, expected_radius)) {
    stop("PAL window radius does not match its PAL state.", call. = FALSE)
  }
  if (!identical(window$path, unname(unfold_pal(window$pal)))) {
    stop("PAL window path does not match its PAL state.", call. = FALSE)
  }
  if (!identical(window$width, as.integer(length(window$path))) ||
      window$width != 2L * window$radius + 1L) {
    stop("PAL window width/radius invariant failed.", call. = FALSE)
  }
  if (!is.data.frame(window$addresses) ||
      nrow(window$addresses) != window$width) {
    stop("PAL window address table is invalid.", call. = FALSE)
  }
  required_address <- c("position", "local_offset", "global_address",
                        "token", "role", "side")
  if (!identical(names(window$addresses), required_address)) {
    stop("PAL window address table has invalid columns.", call. = FALSE)
  }
  expected_offset <- seq.int(-expected_radius, expected_radius)
  expected_global <- as.double(origin) + expected_offset
  if (any(expected_global > .Machine$integer.max) ||
      any(expected_global < -.Machine$integer.max) ||
      !identical(window$addresses$position, seq_len(window$width)) ||
      !identical(window$addresses$local_offset, expected_offset) ||
      !identical(window$addresses$global_address, as.integer(expected_global)) ||
      !identical(window$addresses$token, window$path) ||
      !identical(window$addresses$role,
                 ifelse(expected_offset == 0L, "core", "shell")) ||
      !identical(window$addresses$side,
                 ifelse(expected_offset < 0L, "left",
                        ifelse(expected_offset > 0L, "right", "core")))) {
    stop("PAL window address invariant failed.", call. = FALSE)
  }
  if (!is.list(window$trace)) {
    stop("PAL window trace must be a list.", call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Construct an addressed PAL window
#' @description Wraps a frozen \code{visualr_pal} in an explicit closed or
#'   open boundary. \code{origin} is the global address of the visible core;
#'   visible addresses are \code{origin + (-radius:radius)}. An open window
#'   may bind opaque left/right outer-solution references. Missing references
#'   remain explicit \code{NA} values; they are never replaced by padding.
#' @param pal a \code{visualr_pal} object
#' @param boundary \code{"closed"} or \code{"open"}
#' @param origin integer global address of the visible core
#' @param outer_ref list with exactly \code{left} and \code{right}; each value
#'   is an opaque character reference or \code{NA_character_}
#' @return a \code{visualr_pal_window}
#' @examples
#' new_pal_window(pal_parse("{A{B}A}"))
#' new_pal_window(pal_parse("{B{C{D}C}B}"), boundary = "open")
new_pal_window <- function(
    pal,
    boundary = c("closed", "open"),
    origin = 0L,
    outer_ref = list(left = NA_character_, right = NA_character_)) {
  validate_pal(pal)
  boundary <- match.arg(boundary)
  origin <- .window_integer_scalar(origin, "origin")
  refs <- .normalize_outer_ref(outer_ref, boundary)

  path <- unname(unfold_pal(pal))
  radius <- as.integer(length(pal$shells))
  local_offset <- seq.int(-radius, radius)
  global_address <- as.double(origin) + local_offset
  if (any(global_address > .Machine$integer.max) ||
      any(global_address < -.Machine$integer.max)) {
    stop("Visible addresses exceed the supported integer range.",
         call. = FALSE)
  }

  addresses <- data.frame(
    position = seq_along(path),
    local_offset = local_offset,
    global_address = as.integer(global_address),
    token = path,
    role = ifelse(local_offset == 0L, "core", "shell"),
    side = ifelse(local_offset < 0L, "left",
                  ifelse(local_offset > 0L, "right", "core")),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      pal = pal,
      boundary = boundary,
      origin = origin,
      radius = radius,
      width = as.integer(length(path)),
      path = path,
      addresses = addresses,
      outer_ref = refs,
      trace = list()
    ),
    class = "visualr_pal_window"
  )
}

#' @title Parse explicit open-window PAL syntax
#' @description Parses \code{"}{B{C{D}C}B}{"} by stripping only the two
#'   boundary markers and delegating the enclosed complete palindrome to the
#'   frozen \code{pal_parse()} grammar. This keeps boundary state separate from
#'   the token grammar.
#' @param text single open-window string
#' @param origin integer global address of the visible core
#' @param outer_ref opaque left/right outer-solution references
#' @param mapping_pack_id optional mapping pack identifier
#' @param provenance optional PAL provenance list
#' @return a \code{visualr_pal_window} with \code{boundary = "open"}
#' @examples
#' open_window_parse("}{B{C{D}C}B}{")
open_window_parse <- function(
    text,
    origin = 0L,
    outer_ref = list(left = NA_character_, right = NA_character_),
    mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
    provenance = list()) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) {
    stop("`text` must be one non-NA character value.", call. = FALSE)
  }
  n <- nchar(text, type = "chars")
  if (n < 5L || !startsWith(text, "}{") || !endsWith(text, "}{")) {
    stop("Open-window syntax must be `}` + closed PAL + `{`.",
         call. = FALSE)
  }
  inner <- substr(text, 2L, n - 1L)
  pal <- pal_parse(inner, mapping_pack_id = mapping_pack_id,
                   provenance = provenance)
  new_pal_window(pal, boundary = "open", origin = origin,
                 outer_ref = outer_ref)
}

#' @title Encode explicit open-window PAL syntax
#' @param window an open \code{visualr_pal_window}
#' @return single string in \code{"}" + closed PAL + "{"} form
open_window_encode <- function(window) {
  .validate_pal_window(window)
  if (!identical(window$boundary, "open")) {
    stop("`open_window_encode()` requires boundary = 'open'.",
         call. = FALSE)
  }
  paste0("}", pal_encode(window$pal), "{")
}

#' @title Deepen a complete PAL solution
#' @description Moves the current core into the innermost shell and installs
#'   the caller-supplied \code{next_core}. No token is inferred. For example,
#'   \code{{A{B}A}} plus \code{"c"} becomes \code{{A{B{c}B}A}}.
#' @param pal a complete \code{visualr_pal}
#' @param next_core explicit next core token
#' @return a new \code{visualr_pal}
deepen_solution <- function(pal, next_core) {
  validate_pal(pal)
  new_pal_state(
    shells = c(pal$shells, pal$core),
    core = next_core,
    mapping_pack_id = pal$mapping_pack_id,
    provenance = pal$provenance
  )
}

#' @title Shift a fixed-radius open PAL window
#' @description Advances the focus by one global address. The outermost shell
#'   is evicted, all remaining left-side addresses move outward by one local
#'   slot, the old core becomes the innermost shell, and the explicit
#'   \code{next_core} becomes the new focus. Outer references are preserved as
#'   opaque references; the function never fabricates the omitted solution.
#' @param window an open \code{visualr_pal_window}
#' @param next_core explicit next core token
#' @return a shifted \code{visualr_pal_window} with one trace entry appended
#' @examples
#' w <- open_window_parse("}{B{C{D}C}B}{")
#' open_window_encode(shift_open_window(w, "E"))
shift_open_window <- function(window, next_core) {
  .validate_pal_window(window)
  if (!identical(window$boundary, "open")) {
    stop("`shift_open_window()` requires boundary = 'open'.",
         call. = FALSE)
  }
  if (window$origin == .Machine$integer.max) {
    stop("Cannot shift: `origin` would exceed the integer range.",
         call. = FALSE)
  }

  old <- window$pal
  new_shells <- if (length(old$shells) == 0L) {
    character(0)
  } else {
    c(old$shells[-1L], old$core)
  }
  shifted_pal <- new_pal_state(
    shells = new_shells,
    core = next_core,
    mapping_pack_id = old$mapping_pack_id,
    provenance = old$provenance
  )
  shifted <- new_pal_window(
    shifted_pal,
    boundary = "open",
    origin = window$origin + 1L,
    outer_ref = window$outer_ref
  )
  retained <- if (shifted$radius == 0L) {
    integer(0)
  } else {
    seq_len(shifted$radius)
  }
  mirrored <- if (shifted$radius == 0L) {
    integer(0)
  } else {
    (shifted$radius + 2L):shifted$width
  }
  source_position <- rep.int(NA_integer_, shifted$width)
  source_global <- rep.int(NA_integer_, shifted$width)
  source_state <- rep.int("explicit", shifted$width)
  relation <- rep.int("introduced", shifted$width)
  if (length(retained) > 0L) {
    source_position[retained] <- retained + 1L
    source_global[retained] <- window$addresses$global_address[retained + 1L]
    source_state[retained] <- "previous"
    relation[retained] <- "retained"
  }
  if (length(mirrored) > 0L) {
    source_position[mirrored] <- shifted$width - mirrored + 1L
    source_global[mirrored] <-
      shifted$addresses$global_address[source_position[mirrored]]
    source_state[mirrored] <- "new_window"
    relation[mirrored] <- "mirrored"
  }
  address_transition <- data.frame(
    new_position = shifted$addresses$position,
    new_global = shifted$addresses$global_address,
    token = shifted$path,
    relation = relation,
    source_state = source_state,
    source_position = source_position,
    source_global = source_global,
    stringsAsFactors = FALSE
  )
  shifted$trace <- c(
    window$trace,
    list(list(
      operation = "shift_open_window",
      from_origin = window$origin,
      to_origin = shifted$origin,
      evicted_left = window$path[1L],
      evicted_right = window$path[window$width],
      introduced_core = shifted$pal$core,
      address_transition = address_transition,
      from = open_window_encode(window),
      to = open_window_encode(shifted)
    ))
  )
  shifted
}

#' @export
print.visualr_pal_window <- function(x, ...) {
  .validate_pal_window(x)
  encoded <- if (identical(x$boundary, "open")) {
    open_window_encode(x)
  } else {
    pal_encode(x$pal)
  }
  cat(sprintf("<visualr_pal_window> boundary=%s origin=%d radius=%d\n",
              x$boundary, x$origin, x$radius))
  cat(sprintf("  %s\n", encoded))
  if (identical(x$boundary, "open")) {
    left <- if (is.na(x$outer_ref$left)) "unbound" else x$outer_ref$left
    right <- if (is.na(x$outer_ref$right)) "unbound" else x$outer_ref$right
    cat(sprintf("  outer_ref: left=%s right=%s\n", left, right))
  }
  invisible(x)
}
