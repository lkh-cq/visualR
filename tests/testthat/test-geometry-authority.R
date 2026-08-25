# v0.9 D1 — Geometric Adjacency Authority tests (Task 2).
# Covers the adapter layering: Router-plan pairs are candidates that enter
# Harmony only after passing the geometric predicate (fail-closed, never a
# silent drop), strict-gate behaviour, position-resolution fail-closure, and
# equivalence with detect_adjacency under the same predicate + input.
# helpers: new_routing_envelope / new_router_snapshot come from the frozen
#   v0.7 contract (R/router_contract.R); default_adjacency_predicate from
#   R/geometry_adjacency.R; manhattan metric defaults from helper-geometry.R.

# local factory: build a snapshot + positions from address/coordinate pairs
.build_fixture <- function(tab) {
  # tab: list(packet_id = address, ...) and coords named by address
  envs <- lapply(names(tab$ids), function(id) {
    addr <- tab$ids[[id]]
    new_routing_envelope(packet_id = id, source_local = paste0("l-", id),
                         source_address = addr, logical_time = 1L,
                         boundary = "open")
  })
  positions <- lapply(names(tab$ids), function(id) {
    addr <- tab$ids[[id]]
    new_position_state(addr, tab$coords[[addr]], "grid")
  })
  names(positions) <- names(tab$ids)
  snap <- new_router_snapshot(round = 1L, packets = envs, space = "grid",
                              resources = list(), boundaries = list())
  list(snapshot = snap, positions = positions, ids = tab$ids)
}

test_that("happy path: every plan edge passes the manhattan<=1 predicate", {
  # three collinear points at 0,1,2 -> pairwise distance 1 between neighbours
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b", P3 = "/c"),
                            coords = c("/a" = 0, "/b" = 1, "/c" = 2)))
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = 1L),
    list(source_packet_id = "P2", dest_packet_id = "P3", logical_time = 1L)
  )
  out <- filter_plan_through_predicate(plan_pairs, fx$snapshot, fx$positions,
                                       default_adjacency_predicate(max_distance = 1))
  expect_s3_class(out, "visualr_geometry_filtered_plan")
  expect_length(out$passed, 2L)
  expect_length(out$rejected, 0L)
  expect_true(all(vapply(out$passed, `[[`, logical(1), "geometrically_adjacent")))
})

test_that("filter: one adjacent + one far edge -> passed=1 rejected=1 with ids+positions", {
  # 0,1,10 -> P1-P2 adjacent (d1), P2-P3 far (d9)
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b", P3 = "/c"),
                            coords = c("/a" = 0, "/b" = 1, "/c" = 10)))
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = 1L),
    list(source_packet_id = "P2", dest_packet_id = "P3", logical_time = 1L)
  )
  out <- filter_plan_through_predicate(plan_pairs, fx$snapshot, fx$positions,
                                       default_adjacency_predicate(max_distance = 1))
  expect_length(out$passed, 1L)
  expect_length(out$rejected, 1L)
  # the accepted pair is the physically adjacent one
  expect_identical(out$passed[[1]]$source_packet_id, "P1")
  expect_identical(out$passed[[1]]$dest_packet_id, "P2")
  # the rejection carries both packet ids and their positions
  rej <- out$rejected[[1]]
  expect_identical(rej$source_packet_id, "P2")
  expect_identical(rej$dest_packet_id, "P3")
  expect_s3_class(rej$left_pos, "visualr_position_state")
  expect_s3_class(rej$right_pos, "visualr_position_state")
  expect_identical(rej$left_pos$address, "/b")
  expect_identical(rej$right_pos$address, "/c")
  expect_false(rej$geometrically_adjacent)
})

test_that("strict gate: assert_no_rejected_edges stops and flags no geometric adjacency", {
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b", P3 = "/c"),
                            coords = c("/a" = 0, "/b" = 1, "/c" = 10)))
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = 1L),
    list(source_packet_id = "P2", dest_packet_id = "P3", logical_time = 1L)
  )
  out <- filter_plan_through_predicate(plan_pairs, fx$snapshot, fx$positions,
                                       default_adjacency_predicate(max_distance = 1))
  expect_error(assert_no_rejected_edges(out), "no geometric adjacency")
  # a fully-passing plan passes the strict gate
  ok <- filter_plan_through_predicate(plan_pairs[1], fx$snapshot, fx$positions,
                                      default_adjacency_predicate(max_distance = 1))
  expect_true(assert_no_rejected_edges(ok))
})

test_that("fail-closed: missing PositionState for a plan edge's endpoint -> stop", {
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b", P3 = "/c"),
                            coords = c("/a" = 0, "/b" = 1, "/c" = 10)))
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = 1L),
    list(source_packet_id = "P2", dest_packet_id = "P3", logical_time = 1L)
  )
  # drop P3's mapping: edge P2->P3 cannot be located -> fail closed
  positions <- fx$positions[setdiff(names(fx$positions), "P3")]
  expect_error(
    filter_plan_through_predicate(plan_pairs, fx$snapshot, positions,
                                  default_adjacency_predicate(max_distance = 1)),
    "cannot verify"
  )
})

test_that("fail-closed: packet_id absent from the router snapshot -> stop", {
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b"),
                            coords = c("/a" = 0, "/b" = 1)))
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P99", logical_time = 1L)
  )
  expect_error(
    filter_plan_through_predicate(plan_pairs, fx$snapshot, fx$positions,
                                  default_adjacency_predicate()),
    "not in snapshot"
  )
})

test_that("semantic blindness: predicate sees only PositionState objects", {
  fx <- .build_fixture(list(ids = list(P1 = "/a", P2 = "/b"),
                            coords = c("/a" = 0, "/b" = 1)))
  seen <- list()
  spy <- function(pi_, pj_, logical_time) {
    if (!inherits(pi_, "visualr_position_state") ||
        !inherits(pj_, "visualr_position_state")) {
      stop("predicate must receive only PositionState objects", call. = FALSE)
    }
    seen[[length(seen) + 1L]] <<- list(pi_ = pi_, pj_ = pj_)
    TRUE
  }
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = 1L)
  )
  out <- filter_plan_through_predicate(plan_pairs, fx$snapshot, fx$positions, spy)
  expect_length(out$passed, 1L)
  expect_identical(length(seen), 1L)
  # the spy was handed the PositionStates, not merges / envelopes / ids
  expect_s3_class(seen[[1]]$pi_, "visualr_position_state")
  expect_s3_class(seen[[1]]$pj_, "visualr_position_state")
  expect_identical(seen[[1]]$pi_$address, "/a")
  expect_identical(seen[[1]]$pj_$address, "/b")
})

test_that("equivalence: filter-passed pair set matches detect_adjacency pair set", {
  # same four points as input to both paths, same predicate, same logical time
  fx <- .build_fixture(list(
    ids = list(P1 = "/a", P2 = "/b", P3 = "/c", P4 = "/d"),
    coords = c("/a" = 0, "/b" = 1, "/c" = 10, "/d" = 11)
  ))
  pred <- default_adjacency_predicate(max_distance = 1)
  lt <- 1L
  plan_pairs <- list(
    list(source_packet_id = "P1", dest_packet_id = "P2", logical_time = lt),
    list(source_packet_id = "P2", dest_packet_id = "P3", logical_time = lt),
    list(source_packet_id = "P3", dest_packet_id = "P4", logical_time = lt),
    list(source_packet_id = "P1", dest_packet_id = "P4", logical_time = lt)
  )
  filtered <- filter_plan_through_predicate(plan_pairs, fx$snapshot,
                                            fx$positions, pred)
  detected <- detect_adjacency(fx$positions, pred, lt)

  pair_key <- function(l, r) paste(sort(c(paste(l$address, collapse = "/"),
                                          paste(r$address, collapse = "/"))),
                                   collapse = "<->")
  filtered_keys <- vapply(filtered$passed, function(p) pair_key(p$left_pos, p$right_pos),
                          character(1))
  detected_keys <- vapply(detected$pairs, function(p) pair_key(p$left_pos, p$right_pos),
                          character(1))
  # same cardinality and the same address-pair set
  expect_identical(length(filtered$passed), length(detected$pairs))
  expect_setequal(filtered_keys, detected_keys)
})