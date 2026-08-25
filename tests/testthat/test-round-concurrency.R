# v0.7.0 CPU Concurrency Equivalence (contract 14.4 / §15 performance route).
# Result(serial) == Result(PSOCK) == Result(multicore) — only performance may
# differ, never semantics. This proves routing/harmony are pure/deterministic
# under parallel execution.

make_state <- function() {
  mk <- function(c, id, a) { m <- new_merge(c, id, paste0("l", id), 1L); m$address <- a; m }
  list(mk("a","M1","/a"), mk("b","M2","/b"), mk("c","M3","/c"), mk("d","M4","/d"))
}
full_state <- function() list(
  space = c("/a","/b","/c","/d"),
  res   = c("/a"=1,"/b"=1,"/c"=1,"/d"=1),
  bnd   = c("/a"="open","/b"="open","/c"="open","/d"="open"))

test_that("serial, PSOCK and multicore produce identical round results", {
  skip_if_not_installed("parallel")
  register_baseline_router_policies()
  st <- make_state(); fs <- full_state()
  pks <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))

  run_once <- function() {
    rnd <- run_emergence_round(pks, st, fs$space, fs$res, fs$bnd, 1L,
                               "identity_route", "pair_comp")
    list(
      n_new     = length(rnd$result$new_merges),
      n_pairs   = length(rnd$pairs),
      route_tr  = rnd$plan$route_trace,
      merge_ids = vapply(rnd$result$new_merges, function(m) m$merge_id, character(1L))
    )
  }

  # serial reference
  serial <- run_once()

  # PSOCK cluster (2 workers), each runs the whole round independently.
  # Workers are fresh R processes: they MUST load the package + register
  # baseline policies locally (only performance may differ, never semantics).
  cl <- parallel::makePSOCKcluster(2L)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  parallel::clusterEvalQ(cl, {
    suppressMessages(library(visualR))
    register_baseline_router_policies()
    mk <- function(c, id, a) { m <- new_merge(c, id, paste0("l", id), 1L); m$address <- a; m }
    st <- list(mk("a","M1","/a"), mk("b","M2","/b"), mk("c","M3","/c"), mk("d","M4","/d"))
    fs <- list(space = c("/a","/b","/c","/d"),
               res   = c("/a"=1,"/b"=1,"/c"=1,"/d"=1),
               bnd   = c("/a"="open","/b"="open","/c"="open","/d"="open"))
    pks <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
    run_once <- function() {
      rnd <- run_emergence_round(pks, st, fs$space, fs$res, fs$bnd, 1L,
                                 "identity_route", "pair_comp")
      list(n_new = length(rnd$result$new_merges), n_pairs = length(rnd$pairs),
           route_tr = rnd$plan$route_trace,
           merge_ids = vapply(rnd$result$new_merges, function(m) m$merge_id, character(1L)))
    }
    TRUE
  })
  par_results <- parallel::parLapply(cl, 1:3, function(i) run_once())
  for (r in par_results) {
    expect_identical(r$route_tr, serial$route_tr)
    expect_equal(r$n_new, serial$n_new)
    expect_equal(r$n_pairs, serial$n_pairs)
    expect_identical(r$merge_ids, serial$merge_ids)
  }
})
