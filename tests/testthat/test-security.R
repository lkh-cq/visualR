# Test file: RCE regression tests
# v0.1.0 format used eval(parse(text=...)) — arbitrary code execution.
# Fixed in v0.1.1: pure string parser, no eval, no parse(text=).
# These tests MUST fail on the vulnerable implementation.

test_that("parse_pal rejects code injection in shells (RCE regression)", {
  # The exact payload that succeeded against v0.1.0:
  #   shells:c(system("echo FULL_PWN > /tmp/pwned2.txt", intern=TRUE))
  malicious <- paste(
    "visualr_pal/v0.1",
    "shells:c(system(\"echo FULL_PWN > /tmp/pwned2.txt\", intern=TRUE))",
    "core:E",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:list()",
    sep = "\n"
  )
  expect_error(parse_pal(malicious))
})

test_that("parse_pal does not execute code (no side effect)", {
  marker <- tempfile("rce_test")
  malicious <- paste(
    "visualr_pal/v0.1",
    sprintf("shells:c(system(\"touch %s\", intern=TRUE))", marker),
    "core:E",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:list()",
    sep = "\n"
  )
  # Should either error or return without executing; MUST NOT create file
  try(parse_pal(malicious), silent = TRUE)
  expect_false(file.exists(marker))
})

test_that("parse_pal rejects provenance code injection", {
  malicious <- paste(
    "visualr_pal/v0.1",
    "shells:4|A|B|C|D",
    "core:E",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:list(evil=system(\"echo PWN > /tmp/x\"))",
    sep = "\n"
  )
  expect_error(parse_pal(malicious))
})

test_that("old v0.1 format header is rejected", {
  # v0.1 header was "visualr_pal/v0.1"; new format is v0.2
  old_format <- paste(
    "visualr_pal/v0.1",
    "shells:0",
    "core:X",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:0|",
    sep = "\n"
  )
  expect_error(parse_pal(old_format), "Invalid format header")
})

test_that("parse_pal rejects malformed shells count", {
  bad <- paste(
    "visualr_pal/v0.2",
    "shells:3\x1fA\x1fB",  # claims 3, gives 2
    "core:X",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:0|",
    sep = "\n"
  )
  expect_error(parse_pal(bad), "count mismatch")
})

test_that("parse_pal rejects negative shells count", {
  bad <- paste(
    "visualr_pal/v0.2",
    "shells:-1",
    "core:X",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:0|",
    sep = "\n"
  )
  expect_error(parse_pal(bad), "bad count")
})

test_that("v0.2 format with code in shells count is not executable", {
  # Even a malicious count field cannot execute code: parser uses as.integer()
  marker <- tempfile("rce_count")
  bad <- paste(
    "visualr_pal/v0.2",
    sprintf("shells:system(\"touch %s\")", marker),
    "core:X",
    "mapping_pack_id:pal-jiugong-v0.1",
    "provenance:0|",
    sep = "\n"
  )
  try(parse_pal(bad), silent = TRUE)
  expect_false(file.exists(marker))
})

test_that("v0.2 format with code in provenance value is not executable", {
  marker <- tempfile("rce_prov")
  bad <- paste(
    "visualr_pal/v0.2",
    "shells:0",
    "core:X",
    "mapping_pack_id:pal-jiugong-v0.1",
    sprintf("provenance:1|evil=c:system(\"touch %s\")", marker),
    sep = "\n"
  )
  # provenance with c: prefix is treated as plain string, not executed
  res <- tryCatch(parse_pal(bad), error = function(e) e)
  if (!inherits(res, "error")) {
    # stored as literal string starting with "system("
    expect_true(grepl("^system\\(", res$provenance$evil))
  }
  expect_false(file.exists(marker))
})
