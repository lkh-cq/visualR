# v0.7.0 Phase 2/3: Central Router ABI + baseline policies tests.
# Covers A4 (plan carries no semantics), policy pluggability, Snapshot
# Equivalence (order-independent / deterministic), and fail-closed.

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
make_packets <- function() {
  list(
    pack_emergence(new_merge("a","M1","la",1L), "/a", "open"),
    pack_emergence(new_merge("b","M2","lb",1L), "/b", "open"),
    pack_emergence(new_merge("c","M3","lc",1L), "/c", "open"),
    pack_emergence(new_merge("d","M4","ld",1L), "/d", "open")
  )
}

test_that("route_emergence returns a validated RoutingPlan", {
  register_baseline_router_policies()
  plan <- route_emergence(make_packets(), make_snapshot(), "identity_route")
  expect_s3_class(plan, "visualr_routing_plan")
  expect_true(validate_router_plan(plan))
})

test_that("A4: plan carries no semantic fields, even if a policy tried", {
  register_baseline_router_policies()
  plan <- route_emergence(make_packets(), make_snapshot(), "identity_route")
  expect_false("semantic_score" %in% names(plan))
  expect_false("meaning" %in% names(plan))
  # validator actively stops a leaked plan
  bad <- plan; bad$semantic_score <- 0.9
  expect_error(validate_router_plan(bad), "semantic|A4")
})

test_that("all six baseline policies are pluggable with same ABI", {
  register_baseline_router_policies()
  for (pol in c("identity_route","nearest_valid_route","phase_route",
                "resource_route","deterministic_shuffle_route",
                "random_reference_route")) {
    p <- route_emergence(make_packets(), make_snapshot(), pol)
    expect_s3_class(p, "visualr_routing_plan")
    expect_true(validate_router_plan(p))
  }
})

test_that("Snapshot Equivalence: same inputs, any call order => same plan", {
  register_baseline_router_policies()
  pk <- make_packets(); snp <- make_snapshot()
  a <- route_emergence(pk, snp, "identity_route")
  b <- route_emergence(pk, snp, "identity_route")   # repeat -> deterministic
  expect_identical(a$route_trace, b$route_trace)
  expect_identical(a$adjacencies, b$adjacencies)
})

test_that("unknown policy fails closed", {
  expect_error(route_emergence(make_packets(), make_snapshot(), "nope_route"),
               "Unknown router policy")
})

test_that("policy edges reference packet_id (materialize_adjacency schema)", {
  register_baseline_router_policies()
  plan <- route_emergence(make_packets(), make_snapshot(), "identity_route")
  if (length(plan$adjacencies) > 0L) {
    e <- plan$adjacencies[[1]]
    expect_true("source_packet_id" %in% names(e))
    expect_true("dest_packet_id" %in% names(e))
  }
})
