# v0.7.0 Phase 4: Adjacency Materialization + Adjacency Gate tests.
# Covers A3 ("no adjacency, no computation"), type gate (harmony must reject
# non-AdjacencyPair), and fail-closed on malformed edges.

make_snapshot <- function() {
  envelopes <- list(
    new_routing_envelope("P1", "la", "/a", 1L, "open", integrity = "h1"),
    new_routing_envelope("P2", "lb", "/b", 1L, "open", integrity = "h2"),
    new_routing_envelope("P3", "lc", "/c", 1L, "open", integrity = "h3"),
    new_routing_envelope("P4", "ld", "/d", 1L, "open", integrity = "h4")
  )
  new_router_snapshot(1L, envelopes, c("/a","/b","/c","/d"),
                      c("/a"=1,"/b"=1,"/c"=1,"/d"=1),
                      c("/a"="open","/b"="open","/c"="open","/d"="open"))
}

test_that("materialize_adjacency turns adopted edges into AdjacencyPairs", {
  plan <- new_routing_plan(
    adjacencies = list(
      list(source_packet_id = "P1", dest_packet_id = "P2"),
      list(source_packet_id = "P3", dest_packet_id = "P4")
    ),
    route_trace = "trace-1"
  )
  pairs <- materialize_adjacency(plan, make_snapshot(), 1L)
  expect_length(pairs, 2L)
  expect_s3_class(pairs[[1]], "visualr_adjacency_pair")
  expect_true(validate_adjacency_pair(pairs[[1]]))
})

test_that("self-referential edge fails closed (A6)", {
  plan <- new_routing_plan(
    adjacencies = list(list(source_packet_id = "P1", dest_packet_id = "P1")),
    route_trace = "t"
  )
  expect_error(materialize_adjacency(plan, make_snapshot(), 1L), "self|fail closed")
})

test_that("nonexistent packet edge fails closed", {
  plan <- new_routing_plan(
    adjacencies = list(list(source_packet_id = "P1", dest_packet_id = "P99")),
    route_trace = "t"
  )
  expect_error(materialize_adjacency(plan, make_snapshot(), 1L), "nonexistent|fail closed")
})

test_that("Adjacency Gate (A3): harmony rejects a raw packet", {
  m <- new_merge("x", "M1", "la", 1L)
  p <- pack_emergence(m, "/a", "open")
  expect_error(harmony_step(p), "visualr_adjacency_pair|A3|only these")
})

test_that("Adjacency Gate (A3): harmony accepts a legal AdjacencyPair", {
  a <- new_merge("aa", "M1", "la", 1L)
  b <- new_merge("bb", "M2", "lb", 1L)
  pr <- new_adjacency_pair(a, b, "/a", "/b", "space", "tr", 1L)
  ev <- harmony_step(pr, operator = "pair_comp")
  expect_s3_class(ev, "visualr_harmony_event")
  expect_s3_class(ev$result, "visualr_merge")
})

test_that("empty adjacency list is legal (nothing to compute, A3-consistent)", {
  plan <- new_routing_plan(adjacencies = list())
  expect_true(validate_adjacency(plan))
  expect_length(materialize_adjacency(plan, make_snapshot(), 1L), 0L)
})
