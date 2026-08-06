# Test file: format_pal / parse_pal
# TDD RED phase — tests written before implementation

test_that("format_pal produces a single character string (F1)", {
  pal <- pal_fixture_n4()
  result <- format_pal(pal)
  expect_type(result, "character")
  expect_length(result, 1)
})

test_that("format_pal includes shells (F2)", {
  pal <- pal_fixture_n4()
  result <- format_pal(pal)
  # length-prefixed + \x1f format: shells:4\x1fA\x1fB\x1fC\x1fD
  expect_true(grepl("shells:4\x1fA\x1fB\x1fC\x1fD", result, fixed = TRUE))
})

test_that("format_pal includes core (F3)", {
  pal <- pal_fixture_n4()
  result <- format_pal(pal)
  expect_true(grepl("core:E", result, fixed = TRUE))
})

test_that("format_pal includes mapping_pack_id (F4)", {
  pal <- pal_fixture_n4()
  result <- format_pal(pal)
  expect_true(grepl("pal-jiugong-v0.1", result, fixed = TRUE))
})

test_that("format_pal handles empty shells (F5)", {
  pal <- pal_fixture_n0()
  result <- format_pal(pal)
  expect_true(grepl("shells:", result, fixed = TRUE))
  # length-prefixed format: shells:0
  shells_line <- grep("shells:", strsplit(result, "\n")[[1]], value = TRUE)
  expect_equal(sub("shells:", "", shells_line), "0")
})

test_that("parse_pal(format_pal(S_0)) round-trips (F6)", {
  pal <- pal_fixture_n0()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
})

test_that("parse_pal(format_pal(S_4)) round-trips (F7)", {
  pal <- pal_fixture_n4()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
})

test_that("parse_pal(format_pal(custom)) round-trips with provenance (F8)", {
  pal <- pal_fixture_n4_custom()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
  expect_equal(result$provenance, pal$provenance)
})

test_that("parse_pal(format_pal(S_12)) round-trips (F9)", {
  pal <- pal_fixture_n12()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("parse_pal rejects wrong format header (F10)", {
  expect_error(
    parse_pal("wrong/v9.9\ncore:E"),
    class = "simpleError"
  )
})
