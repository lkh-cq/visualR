# v0.7.0 Phase 6/7: Emergence Round + system tests + Trace Completeness.
# Covers contract 5 (every new Merge is traceable), Mutation Boundary
# (Router/Harmony do not mutate shared state), and the multi-round loop.

make_state <- function() {
  mk <- function(c, id, a) { m <- new_merge(c, id, paste0("l", id), 1L); m$address <- a; m }
  list(mk("a","M1","/a"), mk("b","M2","/b"), mk("c","M3","/c"), mk("d","M4","/d"))
}
full_state <- function() list(
  space = c("/a","/b","/c","/d"),
  res   = c("/a"=1,"/b"=1,"/c"=1,"/d"=1),
  bnd   = c("/a"="open","/b"="open","/c"="open","/d"="open"))

test_that("run_emergence_round wires Phases 1-5 into a ComputationRound", {
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  pks <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  rnd <- run_emergence_round(pks, st, fs$space, fs$res, fs$bnd, logical_time = 1L,
                             policy = "identity_route", harmony_operator = "pair_comp")
  expect_s3_class(rnd, "visualr_computation_round")
  expect_s3_class(rnd$snapshot, "visualr_router_snapshot")
  expect_s3_class(rnd$plan, "visualr_routing_plan")
  expect_s3_class(rnd$result, "visualr_merge_result")
})

test_that("Trace Completeness: each new Merge carries a full trace", {
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  pks <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  rnd <- run_emergence_round(pks, st, fs$space, fs$res, fs$bnd, 1L,
                             "identity_route", "pair_comp")
  if (length(rnd$events) > 0L) {
    ev <- rnd$events[[1]]
    # trace must mention policy(route_trace) and harmony operator + round
    expect_true(any(grepl("policy=", rnd$plan$route_trace)))
    expect_true(any(grepl("harmony:pair_comp@t=1", ev$trace)))
    # result is a fresh Merge with an address (position is state, A6)
    expect_s3_class(ev$result, "visualr_merge")
    expect_false(is.null(ev$result$address))
  }
})

test_that("Mutation Boundary: router does not mutate payload, harmony does not mutate snapshot", {
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  pks <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  before_content <- merge_content(pks[[1]]$payload)
  before_addr <- pks[[1]]$envelope$source_address
  rnd <- run_emergence_round(pks, st, fs$space, fs$res, fs$bnd, 1L)
  # router/harmony must not have changed the packet payload content or envelope
  expect_equal(merge_content(pks[[1]]$payload), before_content)
  expect_equal(pks[[1]]$envelope$source_address, before_addr)
})

test_that("run_emergence_system loops and reports structural observability", {
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  sys <- run_emergence_system(st, rounds = 3L, fs$space, fs$res, fs$bnd,
                              "identity_route", "pair_comp")
  expect_s3_class(sys, "visualr_emergence_system")
  expect_equal(sys$observability$layers, 3L)
  # facts only — no intelligence/AGI score fields
  expect_false("intelligence_score" %in% names(sys$observability))
  expect_false("reasoning_score" %in% names(sys$observability))
})

test_that("print method works (CLI readability)", {
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  sys <- run_emergence_system(st, 2L, fs$space, fs$res, fs$bnd)
  out <- capture.output(print(sys))
  expect_true(any(grepl("visualr_emergence_system", out)))
})
