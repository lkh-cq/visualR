# Distributed residual reservoir runtime

reservoir_fixture <- function() {
  new_reservoir(
    signal = c(2, -1, 4, 3, 7, 5),
    position = cbind(x = c(0, 0.15, 0.35, 0.6, 0.82, 1),
                     y = c(0.1, 0.7, 0.25, 0.9, 0.4, 0.05)),
    supply = c(1, 1, 0, 1, 1, 1),
    capacity = rep(0.5, 6),
    node_id = paste0("node-", 1:6)
  )
}

pipe_fixture <- function() {
  list(
    new_reservoir_pipe("local-a", budget = 0.8, phase = 0.0,
                       phase_step = sqrt(2) - 1, bandwidth = 0.22),
    new_reservoir_pipe("local-b", budget = 0.7, phase = 0.45,
                       phase_step = (sqrt(5) - 1) / 2, bandwidth = 0.22),
    new_reservoir_pipe("local-c", budget = 0.6, phase = 0.8,
                       phase_step = pi - 3, bandwidth = 0.22)
  )
}

test_that("reservoir separates signal, residual supply, and draw capacity", {
  field <- reservoir_fixture()
  expect_s3_class(field, "visualr_reservoir")
  expect_identical(length(field$signal), 6L)
  expect_identical(field$supply[3], 0)
  expect_identical(field$capacity, rep(0.5, 6))
  expect_identical(field$tick, 0L)

  expect_error(new_reservoir(1:2, matrix(1:3, ncol = 1)),
               "one row per node")
  expect_error(new_reservoir(1:2, supply = c(1, -1)), "non-negative")
  expect_error(new_reservoir(1:2, node_id = c("x", "x")), "unique")
})

test_that("modular phase sequence is finite, bounded, and deterministic", {
  x <- phase_sequence(8, seed = 0.1, step = sqrt(2) - 1)
  expect_length(x, 8L)
  expect_true(all(x >= 0 & x < 1))
  expect_equal(x, phase_sequence(8, seed = 0.1, step = sqrt(2) - 1))
  expect_identical(phase_sequence(0), numeric(0))
  expect_error(phase_sequence(-1), "non-negative integer")
})

test_that("routing is distributed and excludes unavailable nodes", {
  field <- reservoir_fixture()
  pipes <- pipe_fixture()
  preference <- route_pipes(field, pipes, k = 3)

  expect_identical(dim(preference), c(3L, 6L))
  expect_identical(rownames(preference),
                   c("local-a", "local-b", "local-c"))
  expect_identical(colnames(preference), paste0("node-", 1:6))
  expect_identical(unname(preference[, 3]), rep(0, 3))
  expect_identical(unname(rowSums(preference > 0)), rep(3, 3))
})

test_that("joint allocation obeys both pipe budgets and node draw limits", {
  field <- reservoir_fixture()
  pipes <- pipe_fixture()
  allocation <- allocate_pipes(field, pipes, route_pipes(field, pipes))

  expect_s3_class(allocation, "visualr_allocation")
  expect_true(all(allocation$budget_used <= allocation$pipe_budget + 1e-10))
  expect_true(all(allocation$supply_used <= allocation$node_available + 1e-10))
  expect_identical(unname(allocation$supply_used[3]), 0)
  expect_true(allocation$constraint_ok)
})

test_that("oversubscribed nodes scale concurrent requests symmetrically", {
  field <- new_reservoir(signal = c(10, 20), supply = c(1, 1),
                         capacity = c(0.6, 0.6))
  pipes <- list(new_reservoir_pipe("a", 0.6),
                new_reservoir_pipe("b", 0.6))
  preference <- matrix(c(1, 0, 1, 0), nrow = 2, byrow = TRUE,
                       dimnames = list(c("a", "b"), c("n1", "n2")))
  allocation <- allocate_pipes(field, pipes, preference)

  expect_equal(allocation$matrix[, "n1"], c(a = 0.3, b = 0.3))
  expect_equal(allocation$matrix[, "n2"], c(a = 0, b = 0))
  expect_equal(sum(allocation$matrix), 0.6)
})

test_that("pipe ordering does not change id-addressed allocation", {
  field <- reservoir_fixture()
  pipes <- pipe_fixture()
  preference <- route_pipes(field, pipes)
  a <- allocate_pipes(field, pipes, preference)$matrix

  reversed <- rev(pipes)
  b <- allocate_pipes(field, reversed,
                      preference[rev(rownames(preference)), , drop = FALSE])$matrix
  b <- b[rownames(a), , drop = FALSE]
  expect_equal(a, b, tolerance = 1e-12)
})

test_that("one step atomically conserves residual supply", {
  field <- reservoir_fixture()
  pipes <- pipe_fixture()
  result <- reservoir_step(field, pipes, k = 4)

  expect_s3_class(result, "visualr_reservoir_step")
  expect_true(result$conservation$ok)
  expect_equal(result$conservation$input,
               result$conservation$extracted + result$conservation$remaining,
               tolerance = 1e-10)
  expect_identical(field$supply, c(1, 1, 0, 1, 1, 1))
  expect_true(all(result$reservoir_out$supply <= field$supply + 1e-10))
  expect_identical(result$reservoir_out$tick, 1L)
  expect_length(result$reservoir_out$trace, 1L)
})

test_that("pipe outputs retain address geometry as topology", {
  field <- new_reservoir(
    signal = c(1, 2, 3),
    position = cbind(x = c(0, 1, 0), y = c(0, 0, 1)),
    supply = rep(1, 3), capacity = rep(1, 3)
  )
  pipes <- list(new_reservoir_pipe("a", 1),
                new_reservoir_pipe("b", 1))
  preference <- matrix(c(1, 1, 0,
                         0, 1, 1), nrow = 2, byrow = TRUE,
                       dimnames = list(c("a", "b"), c("n1", "n2", "n3")))
  result <- reservoir_step(field, pipes, preference)

  expect_true(all(c("node_id", "extraction", "x", "y") %in%
                    names(result$topology$nodes)))
  expect_true(all(c("from", "to", "distance", "relation",
                    "shared_pipes", "delta_x", "delta_y") %in%
                    names(result$topology$edges)))
  expect_true(nrow(result$topology$pipe_support) >= 2L)
  expect_true(all(c("centroid_x", "centroid_y") %in% names(result$outputs)))
})

test_that("phase advancement is explicit and leaves local metadata intact", {
  pipes <- pipe_fixture()
  advanced <- advance_pipes(pipes, 2L)
  expect_equal(advanced[[1]]$phase,
               (pipes[[1]]$phase + 2 * pipes[[1]]$phase_step) %% 1)
  expect_identical(advanced[[1]]$id, pipes[[1]]$id)
  expect_identical(advanced[[1]]$budget, pipes[[1]]$budget)
  expect_error(advance_pipes(pipes, -1), "non-negative integer")
})

test_that("invalid routing and allocation inputs fail closed", {
  field <- reservoir_fixture()
  pipes <- pipe_fixture()
  expect_error(new_reservoir_pipe("x", 0), "positive")
  expect_error(route_pipes(field, list()), "must contain")
  expect_error(route_pipes(field, pipes, k = 0), "positive integer")
  expect_error(allocate_pipes(field, pipes, matrix(-1, 3, 6)),
               "non-negative")
  duplicate <- c(pipes, pipes[1])
  expect_error(route_pipes(field, duplicate), "unique")
})
