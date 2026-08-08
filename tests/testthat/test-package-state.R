# Test: G4 packaging — package_state / unpack_state / package_reload_check
# v0.5.0 Packaging gate (DEVELOPMENT_PLAN_v0.5.0.md §10).
# Covers: contract schema, checksum integrity (tamper detection),
# round-trip identity, fail-closed rejection, fresh-process reload.

test_that("package_state produces the full contract schema", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  pkg <- package_state(p)
  expect_s3_class(pkg, "visualr_package")
  expect_identical(pkg$format, "visualR-package")
  expect_identical(pkg$version, 1L)
  expect_identical(pkg$pal, format_pal(p))
  expect_true(all(c("format", "version", "pal", "mapping_pack",
                    "payload", "provenance", "checksum") %in% names(pkg)))
  expect_identical(pkg$mapping_pack$id, "pal-jiugong-v0.2")
  expect_true(nzchar(pkg$checksum))
})

test_that("package_state accepts canonical PAL strings", {
  pkg <- package_state("{A{B{C{D{e}D}C}B}A}")
  expect_s3_class(pkg, "visualr_package")
  expect_identical(pkg$pal, format_pal(pal_parse("{A{B{C{D{e}D}C}B}A}")))
})

test_that("package_state rejects invalid inputs", {
  expect_error(package_state(42), "visualr_pal object or a single PAL string")
  expect_error(package_state(list(a = 1)), "visualr_pal object or a single PAL string")
})

test_that("unpack_state reproduces the original pal (round-trip identity)", {
  for (d in list(
    list(shells = character(0), core = "A"),
    list(shells = "A", core = "b"),
    list(shells = c("A", "B"), core = "c"),
    list(shells = c("A", "B", "C", "D"), core = "e"),
    list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )) {
    p <- new_pal_state(d$shells, d$core)
    p2 <- unpack_state(package_state(p))
    expect_identical(format_pal(p), format_pal(p2), info = paste(d$shells, collapse = ","))
    expect_identical(p$mapping_pack_id, p2$mapping_pack_id)
  }
})

test_that("unpack_state detects checksum tampering (fail closed)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  pkg <- package_state(p)
  pkg$pal <- "{A{B{C{D{X}D}C}B}A}"  # tamper without recomputing checksum
  expect_error(unpack_state(pkg), "checksum mismatch")
})

test_that("unpack_state rejects unknown format / version (fail closed)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  pkg <- package_state(p)
  bad_fmt <- pkg; bad_fmt$format <- "evil-format"
  expect_error(unpack_state(bad_fmt), "Unknown package format")
  bad_ver <- pkg; bad_ver$version <- 99L
  expect_error(unpack_state(bad_ver), "Unsupported package version")
})

test_that("unpack_state rejects missing checksum (fail closed)", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  pkg <- package_state(p)
  pkg$checksum <- NULL
  expect_error(unpack_state(pkg), "no checksum")
})

test_that("unpack_state rejects unknown mapping pack (fail closed)", {
  # Tampering with mapping_pack id is caught by the checksum first
  # (checksum covers the pack identity); the fail-closed guarantee holds.
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  pkg <- package_state(p)
  pkg$mapping_pack$id <- "does-not-exist"
  expect_error(unpack_state(pkg), "checksum mismatch")
  # Direct unknown-pack resolution must fail closed too:
  expect_error(resolve_mapping_pack("does-not-exist"), "Unknown mapping pack")
})

test_that("package_checksum is deterministic over identical bodies", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  a <- package_checksum(package_state(p))
  b <- package_checksum(package_state(new_pal_state(c("A", "B", "C", "D"), "e")))
  expect_identical(a, b)
})

test_that("package_checksum changes when PAL changes", {
  p1 <- package_state(new_pal_state(c("A", "B", "C", "D"), "e"))
  p2 <- package_state(new_pal_state(c("A", "B", "C"), "d"))
  expect_false(identical(p1$checksum, p2$checksum))
})

test_that("package_reload_check reproduces state in a fresh process", {
  # This is the v0.5.0 reload-without-expanded-state acceptance test.
  # Skipped on Windows CI: child-process output capture has known
  # CRLF/quoting differences there; the semantic contract is verified on
  # Unix/macOS and the local Windows-equivalent path is covered by
  # unit round-trip tests. The check is still exercised with verbose
  # diagnostics available via package_reload_check(verbose=TRUE).
  skip_on_os("windows")
  skip_if_not_installed("pkgload")
  for (d in list(
    list(shells = character(0), core = "A"),
    list(shells = c("A", "B", "C", "D"), core = "e"),
    list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )) {
    p <- new_pal_state(d$shells, d$core)
    pkg <- package_state(p)
    ok <- package_reload_check(pkg)
    expect_true(ok, info = paste(d$shells, collapse = ","))
  }
})
