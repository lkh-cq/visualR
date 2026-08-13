# Test file: TCN-pattern dilated address compiler (v0.6.1 experimental)

.compiler_window <- function() {
  open_window_parse(
    "}{B{C{D}C}B}{",
    origin = 10L,
    outer_ref = list(left = "solution:L", right = "solution:R")
  )
}

test_that("compiler realizes dilation, two passes, and residual ABI", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 2L)

  expect_s3_class(plan, "visualr_dilated_plan")
  expect_equal(plan$status, "reference_experimental")
  expect_equal(plan$semantic_authority, "R")
  expect_false(plan$numeric_fusion)
  expect_equal(plan$blocks$dilation, c(1L, 2L))
  expect_equal(plan$total_layers, 4L)
  expect_identical(plan$shape,
                   list(input_width = 5L, output_width = 5L,
                        preserved = TRUE))
  expect_equal(sum(plan$edges$edge_type == "dilated_tap"), 60L)
  expect_equal(sum(plan$edges$edge_type == "residual_identity"), 10L)
  expect_equal(nrow(plan$unresolved_edges), 12L)
  expect_true(validate_dilated_plan(plan))
})

test_that("fixed kernel taps compile to exact dilated addresses", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 2L)
  s <- plan$schedule

  level1_center <- s[s[, "level"] == 1L &
                     s[, "convolution"] == 1L &
                     s[, "target_position"] == 3L, , drop = FALSE]
  level2_center <- s[s[, "level"] == 2L &
                     s[, "convolution"] == 1L &
                     s[, "target_position"] == 3L, , drop = FALSE]

  expect_equal(level1_center[, "kernel_offset"], c(-1L, 0L, 1L))
  expect_equal(level1_center[, "source_position"], c(2L, 3L, 4L))
  expect_equal(level2_center[, "dilation"], rep(2L, 3L))
  expect_equal(level2_center[, "source_position"], c(1L, 3L, 5L))
  expect_identical(plan$receptive_span,
                   list(min_offset = -6, max_offset = 6, width = 13))
})

test_that("open frontier is explicit and outer references stay opaque", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 2L)
  frontier <- plan$unresolved_edges

  expect_true(all(frontier$source_kind == "outer_reference"))
  expect_true(all(frontier$side %in% c("left", "right")))
  expect_true(all(frontier$reference_bound))
  expect_setequal(unique(frontier$outer_ref), c("solution:L", "solution:R"))
  expect_true(any(plan$nodes$node_kind == "outer_reference"))
  expect_true(all(frontier$from_node %in% plan$nodes$node_id))
})

test_that("closed solution compiles boundary stops, never implicit padding", {
  pal <- pal_parse("{B{C{D}C}B}")
  plan <- compile_dilated_topology(pal, levels = 1L)
  frontier <- plan$unresolved_edges

  expect_equal(plan$window$boundary, "closed")
  expect_true(nrow(frontier) > 0L)
  expect_true(all(frontier$source_kind == "boundary_stop"))
  expect_true(all(is.na(frontier$outer_ref)))
  expect_false(any(frontier$reference_bound))
  expect_false(any(plan$edges$source_kind == "zero_padding"))
})

test_that("residual edges preserve global address identity", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 2L)
  residual <- plan$edges[plan$edges$edge_type == "residual_identity", ]

  expect_true(all(residual$source_position == residual$target_position))
  expect_true(all(residual$source_global == residual$target_global))
  expect_equal(unique(residual$source_layer), c(0L, 2L))
  expect_equal(unique(residual$target_layer), c(2L, 4L))
})

test_that("receptive span includes the residual identity address", {
  plan <- compile_dilated_topology(
    .compiler_window(), levels = 1L, kernel_offsets = 1L
  )
  expect_identical(plan$receptive_span,
                   list(min_offset = 0, max_offset = 2, width = 3))
})

test_that("equal labels at distinct addresses are never collapsed", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 1L)
  input <- plan$nodes[plan$nodes$layer == 0L &
                      plan$nodes$node_kind == "input", ]

  expect_equal(input$token, c("B", "C", "D", "C", "B"))
  expect_equal(length(unique(input$node_id)), 5L)
  expect_false(input$node_id[1L] == input$node_id[5L])
})

test_that("C99 tap compiler is exactly equivalent to R authority", {
  window <- .compiler_window()
  plan_r <- compile_dilated_topology(
    window, levels = 3L, kernel_offsets = c(-2L, 0L, 1L), engine = "r"
  )
  plan_c <- compile_dilated_topology(
    window, levels = 3L, kernel_offsets = c(-2L, 0L, 1L), engine = "c"
  )

  expect_identical(plan_c$schedule, plan_r$schedule)
  expect_identical(plan_c$blocks, plan_r$blocks)
  expect_identical(plan_c$nodes, plan_r$nodes)
  expect_identical(plan_c$edges, plan_r$edges)
  expect_identical(plan_c$unresolved_edges, plan_r$unresolved_edges)
})

test_that("C99 tap compiler independently fails closed", {
  native <- function(width, levels, offsets, convolutions) {
    .Call(
      "C_visualr_compile_taps",
      width,
      levels,
      offsets,
      convolutions,
      PACKAGE = "visualR"
    )
  }

  expect_error(native(4L, 1L, c(-1L, 0L), 2L), "width")
  expect_error(native(5L, 1, c(-1L, 0L), 2L), "non-NA integer")
  expect_error(native(5L, 1L, c(0L, 0L), 2L), "must be unique")
  expect_error(native(5L, 30L, 32767L, 2L), "integer range")
  expect_error(native(129L, 30L, -15L:15L, 16L),
               "MAX_COMPILED_TAPS")
})

test_that("compiler rejects ambiguous or unsafe plans", {
  window <- .compiler_window()

  expect_error(compile_dilated_topology(window, levels = 0L), "levels")
  expect_error(compile_dilated_topology(window, levels = 1.5), "finite integers")
  expect_error(
    compile_dilated_topology(window, 1L, kernel_offsets = c(0L, 0L)),
    "must be unique"
  )
  expect_error(
    compile_dilated_topology(window, 30L, kernel_offsets = 32767L),
    "integer range"
  )
  expect_error(compile_dilated_topology(list(), levels = 1L),
               "visualr_pal")
})

test_that("validator detects graph tampering", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 1L)
  bad_node <- plan
  bad_node$edges$to_node[1L] <- "missing-node"
  expect_error(validate_dilated_plan(bad_node), "node is not declared")

  bad_schedule <- plan
  bad_schedule$schedule[1L, "scope"] <- 1L
  expect_error(validate_dilated_plan(bad_schedule), "R authority")

  stale_frontier <- plan
  stale_frontier$unresolved_edges <- stale_frontier$unresolved_edges[-1L, ]
  expect_error(validate_dilated_plan(stale_frontier), "frontier table is stale")
})

test_that("dilated plan print method is stable", {
  plan <- compile_dilated_topology(.compiler_window(), levels = 1L)
  expect_invisible(print(plan))
})
