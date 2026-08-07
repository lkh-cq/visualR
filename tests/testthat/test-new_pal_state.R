# Test file: new_pal_state
# TDD RED phase — tests written before implementation

test_that("new_pal_state constructs empty-shell state (N1)", {
  pal <- new_pal_state(shells = character(0), core = "X")
  expect_s3_class(pal, "visualr_pal")
  expect_length(pal$shells, 0)
})

test_that("new_pal_state constructs S_4 standard state (N2)", {
  pal <- new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
  expect_s3_class(pal, "visualr_pal")
  expect_equal(pal$shells, c("A", "B", "C", "D"))
  expect_equal(pal$core, "E")
})

test_that("new_pal_state constructs arbitrary-length shells (N3)", {
  pal <- new_pal_state(shells = c("A", "B"), core = "C")
  expect_s3_class(pal, "visualr_pal")
  expect_length(pal$shells, 2)
})

test_that("new_pal_state has default mapping_pack_id (N4)", {
  pal <- new_pal_state(shells = c("A"), core = "B")
  expect_equal(pal$mapping_pack_id, "pal-jiugong-v0.2")
})

test_that("new_pal_state has default provenance (N5)", {
  pal <- new_pal_state(shells = c("A"), core = "B")
  expect_equal(pal$provenance, list())
})

test_that("new_pal_state rejects non-character shells (N6)", {
  expect_error(
    new_pal_state(shells = c(1, 2, 3), core = "E"),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects non-scalar core (N7)", {
  expect_error(
    new_pal_state(shells = c("A"), core = c("E", "F")),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects non-character core (N8)", {
  expect_error(
    new_pal_state(shells = c("A"), core = 42),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects NA core (N9)", {
  expect_error(
    new_pal_state(shells = c("A"), core = NA_character_),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects non-character mapping_pack_id (N10)", {
  expect_error(
    new_pal_state(shells = c("A"), core = "B", mapping_pack_id = 0L),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects non-list provenance (N11)", {
  expect_error(
    new_pal_state(shells = c("A"), core = "B", provenance = "x"),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects shells with NA (N12)", {
  expect_error(
    new_pal_state(shells = c("A", NA, "C"), core = "E"),
    class = "simpleError"
  )
})

test_that("new_pal_state rejects empty-string core (N13, v0.2.1 closed token domain)", {
  expect_error(new_pal_state(shells = c("A"), core = ""), "non-empty")
})

test_that("new_pal_state rejects empty strings in shells (N14, v0.2.1 closed token domain)", {
  expect_error(new_pal_state(shells = c("A", "", "C"), core = "E"), "non-empty")
})
