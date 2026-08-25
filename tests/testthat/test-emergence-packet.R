# v0.7.0 Phase 1: Emergence Packet ABI + Semantic Isolation tests.
# Covers contract 1.3/1.4 (two-layer packet), P1 (envelope-identical =>
# router output identical regardless of payload), and fail-closed paths.

test_that("pack_emergence builds a valid two-layer packet", {
  m <- new_merge("content-x", "M1", "locA", 1L)
  p <- pack_emergence(m, "/a", "open")
  expect_s3_class(p, "visualr_emergence_packet")
  expect_s3_class(p$envelope, "visualr_routing_envelope")
  # envelope is router-readable metadata only
  expect_equal(p$envelope$packet_id, "PM1")
  expect_equal(p$envelope$source_address, "/a")
  expect_equal(p$envelope$boundary, "open")
  # integrity auto-filled with a content hash
  expect_true(nzchar(p$envelope$integrity))
})

test_that("unpack_for_local returns the Merge and verifies integrity", {
  m <- new_merge("content-x", "M1", "locA", 1L)
  p <- pack_emergence(m, "/a", "open")
  got <- unpack_for_local(p)
  expect_s3_class(got, "visualr_merge")
  expect_equal(merge_content(got), "content-x")
})

test_that("unpack detects tampering (fail closed)", {
  m <- new_merge("content-x", "M1", "locA", 1L)
  p <- pack_emergence(m, "/a", "open")
  p$envelope$integrity <- "deadbeef"   # tamper the recorded hash
  expect_error(unpack_for_local(p), "integrity mismatch|tamper")
})

test_that("pack fails closed on invalid boundary", {
  m <- new_merge("content-x", "M1", "locA", 1L)
  expect_error(pack_emergence(m, "/a", "banana"), "boundary")
})

test_that("Semantic Isolation: router_envelope returns envelope ONLY", {
  m <- new_merge("SECRET", "M1", "locA", 1L)
  p <- pack_emergence(m, "/a", "open")
  # the router-visible surface must NOT equal the payload (content stays opaque)
  expect_false(identical(router_envelope(p), p$payload))
  expect_s3_class(router_envelope(p), "visualr_routing_envelope")
  # exchange of content cannot leak through envelope
  expect_false(any(grepl("SECRET", paste(unlist(p$envelope), collapse = ","))))
})

test_that("P1: identical envelopes => router output identical, payload differs", {
  # build two packets with identical envelopes but different payload content
  m1 <- new_merge("AAA", "M1", "locA", 1L)
  m2 <- new_merge("BBB", "M2", "locA", 1L)
  e1 <- new_routing_envelope("PX", "locA", "/a", 1L, "open", integrity = "h1")
  e2 <- new_routing_envelope("PX", "locA", "/a", 1L, "open", integrity = "h1")
  p1 <- new_emergence_packet(e1, m1)
  p2 <- new_emergence_packet(e2, m2)
  # envelope-identical
  expect_identical(router_envelope(p1), router_envelope(p2))
  # but payloads differ
  expect_false(identical(p1$payload, p2$payload))
})
