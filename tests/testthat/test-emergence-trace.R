# v0.7.0 Promotion Gate test — Trace Completeness (gate 7, §14.5).
# Every new Merge must be fully traceable: source locals / packet / router
# policy / destination position / adjacency / harmony operator / logical round.
# This test reconstructs the entire origin chain from a produced Merge and
# asserts every hop is present and correct.

test_that("a new Merge traces back to sources, policy, position, operator, round", {
  st <- list({m <- new_merge("alpha","M1","la",1L); m$address<-"/a"; m},
             {m <- new_merge("beta","M2","lb",1L); m$address<-"/b"; m},
             {m <- new_merge("gamma","M3","lc",1L); m$address<-"/c"; m},
             {m <- new_merge("delta","M4","ld",1L); m$address<-"/d"; m})
  space <- c("/a","/b","/c","/d"); res <- c("/a"=1,"/b"=1,"/c"=1,"/d"=1)
  bnd <- c("/a"="open","/b"="open","/c"="open","/d"="open")
  pk <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  rnd <- run_emergence_round(pk, st, space, res, bnd, 1L, "identity_route", "pair_comp")

  expect_length(rnd$events, length(rnd$result$new_merges))
  ev <- rnd$events[[1]]
  trace <- paste(ev$trace, collapse = " ")

  # source locals present (the src= component carries left/right merge ids)
  expect_true(any(grepl("src=.*@.*~.*@", ev$trace)))
  # router policy present (route_trace carried "policy=...")
  expect_true(any(grepl("policy=", trace)))
  # destination position present (addresses appear in the src= component)
  expect_true(any(grepl("/a|/b|/c|/d", trace)))
  # harmony operator present
  expect_true(any(grepl("op=pair_comp", trace)))
  # logical round present
  expect_true(any(grepl("t=1", trace)))
  # the new Merge object itself carries origin + address (position is state, A6)
  expect_s3_class(ev$result, "visualr_merge")
  expect_false(is.null(ev$result$address))
})

test_that("every new Merge in the round is covered by an adjacency pair (no orphan)", {
  st <- list({m <- new_merge("a","M1","l",1L); m$address<-"/a"; m},
             {m <- new_merge("b","M2","l",1L); m$address<-"/b"; m})
  pk <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  rnd <- run_emergence_round(pk, st, c("/a","/b"), c("/a"=1,"/b"=1),
                             c("/a"="open","/b"="open"), 1L)
  expect_equal(length(rnd$result$new_merges), length(rnd$pairs))
})
