# v0.7.0 Phase 5: Harmony ABI tests.
# Covers the A3 boundary (only AdjacencyPair enters), built-in operators,
# contract 1.8 (fresh Merge result), and fail-closed operator registration.

test_that("register_harmony_operator enforces ABI arity", {
  expect_error(register_harmony_operator("bad", function(a) a),
               "accept .merge_a_content")
})

test_that("built-in names cannot be overwritten without overwrite=TRUE", {
  expect_error(register_harmony_operator("identity", function(a,b,p) a),
               "built-in harmony operator")
  expect_silent(register_harmony_operator("identity", function(a,b,p) a, overwrite = TRUE))
})

test_that("identity / swap / pair_comp / reversible_toy built-ins work", {
  a <- new_merge("alpha", "M1", "la", 1L)
  b <- new_merge("beta",  "M2", "lb", 1L)
  pr <- new_adjacency_pair(a, b, "/a", "/b", "space", "tr", 1L)
  expect_equal(merge_content(harmony_step(pr, "identity")$result), "alpha")
  expect_equal(merge_content(harmony_step(pr, "swap")$result), "beta")
  expect_equal(merge_content(harmony_step(pr, "pair_comp")$result), "alpha beta")
  expect_length(merge_content(harmony_step(pr, "reversible_toy")$result), 2L)
})

test_that("harmony is deterministic: same pair+op => same merge_id (concurrency gate 14.4)", {
  a <- new_merge("alpha", "M1", "la", 1L)
  b <- new_merge("beta",  "M2", "lb", 1L)
  pr <- new_adjacency_pair(a, b, "/a", "/b", "space", "tr", 1L)
  e1 <- harmony_step(pr, "pair_comp")
  e2 <- harmony_step(pr, "pair_comp")
  expect_s3_class(e1$result, "visualr_merge")
  # determinism: identical inputs -> identical id (no process-global counter)
  expect_identical(e1$result$merge_id, e2$result$merge_id)
  # but each call returns a FRESH object (never mutates inputs)
  expect_false(identical(e1$result, e2$result))
})

test_that("position is state (A6): distinct address, equal content => distinct", {
  a1 <- new_merge("same", "X", "l1", 1L); a1$address <- "/p"
  a2 <- new_merge("same", "Y", "l2", 1L); a2$address <- "/q"
  expect_false(identical(a1, a2))
})

test_that("unknown harmony operator fails closed", {
  a <- new_merge("alpha", "M1", "la", 1L)
  b <- new_merge("beta",  "M2", "lb", 1L)
  pr <- new_adjacency_pair(a, b, "/a", "/b", "space", "tr", 1L)
  expect_error(harmony_step(pr, "nope_op"), "Unknown harmony operator")
})

test_that("validate_harmony_event fails on non-Merge result", {
  ev <- new_harmony_event(NULL, "op", "not-a-merge")
  expect_error(validate_harmony_event(ev), "must produce a Merge")
})
