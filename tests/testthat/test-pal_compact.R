# Test: pal_compact() — v0.4.x A1 resident compact representation

test_that("pal_compact equals format_pal", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_identical(pal_compact(p), format_pal(p))
})

test_that("pal_compact round-trips via parse_pal (resident workflow)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  s <- pal_compact(p)          # resident form
  r <- parse_pal(s)            # restore on demand
  expect_identical(r$shells, p$shells)
  expect_identical(r$core, p$core)
  expect_identical(r$mapping_pack_id, p$mapping_pack_id)
})

test_that("pal_compact string is smaller than S3 object (A1 memory claim)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  str_bytes <- nchar(pal_compact(p), type = "bytes")
  obj_bytes <- as.numeric(object.size(p))
  # the compact string content is far smaller than the S3 object header
  expect_lt(str_bytes, obj_bytes)
})

test_that("pal_compact validates input", {
  expect_error(pal_compact("not a pal"), "visualr_pal")
})