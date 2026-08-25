# Test file: explicit multi-timescale signal envelope (v0.6.2 experimental)

test_that("signal envelope keeps routing metadata separate from payload", {
  env <- new_signal_envelope(
    source_kind = "cnn_feature",
    timescale = "fast",
    density = "dense",
    update_interval = 1L,
    spatial_scope = "local",
    persistence = "transient",
    provenance = "fixture:cnn",
    uncertainty = 0.1
  )

  expect_s3_class(env, "visualr_signal_envelope")
  expect_equal(env$timescale, "fast")
  expect_equal(env$density, "dense")
  expect_false("value" %in% names(env))
})

test_that("signal schedule activates fields without mixing their values", {
  fast <- new_numeric_field(
    matrix(1:4, 2L), value_semantics = "fast_feature",
    boundary_state = "closed",
    signal = new_signal_envelope(
      "cnn_feature", "fast", "dense", 1L,
      "local", "transient", "fixture:fast", 0.1
    )
  )
  slow <- new_numeric_field(
    matrix(5:8, 2L), value_semantics = "slow_feature",
    boundary_state = "closed",
    signal = new_signal_envelope(
      "metabolic_state", "slow", "sparse", 2L,
      "global", "persistent", "fixture:slow", 0.2
    )
  )

  tick1 <- compile_signal_schedule(list(fast = fast, slow = slow), tick = 1L)
  tick2 <- compile_signal_schedule(list(fast = fast, slow = slow), tick = 2L)

  expect_s3_class(tick1, "visualr_signal_schedule")
  expect_identical(tick1$active$field_id, "fast")
  expect_setequal(tick2$active$field_id, c("fast", "slow"))
  expect_identical(tick2$active$route_class,
                   c("fast_dense", "slow_sparse"))
  expect_equal(fast$value, 1:4)
  expect_equal(slow$value, 5:8)
})

test_that("signal routing rejects unregistered semantic shortcuts", {
  expect_error(
    new_signal_envelope("x", "neural", "dense", 1L,
                        "local", "transient", "fixture", 0),
    "timescale"
  )
  expect_error(
    new_signal_envelope("x", "fast", "dense", 0L,
                        "local", "transient", "fixture", 0),
    "update_interval"
  )
  expect_error(
    new_signal_envelope("x", "fast", "dense", 1L,
                        "local", "transient", "fixture", 1.1),
    "uncertainty"
  )
})
