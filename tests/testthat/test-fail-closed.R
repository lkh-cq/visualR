# v0.7.0 Promotion Gate test — Fail-Closed (gate 12, §14 "all error paths fail
# closed"). Enumerates the v0.7 module error paths and asserts EACH one throws
# (never silently proceeds / returns a partial result).

test_that("pack_emergence fails closed on every invalid input", {
  m <- new_merge("x","M1","la",1L)
  expect_error(pack_emergence(1, "/a", "open"))                 # not a Merge
  expect_error(pack_emergence(m, NA_character_, "open"))        # missing address
  expect_error(pack_emergence(m, "", "open"))                   # empty address
  expect_error(pack_emergence(m, "/a", "banana"))               # bad boundary
  expect_error(pack_emergence(m, "/a", "open", transport = "not a list"))  # bad transport
  expect_error(pack_emergence(m, "/a", "open", integrity = NA_character_)) # NA integrity
})

test_that("unpack_for_local fails closed on tamper / malformed", {
  m <- new_merge("x","M1","la",1L)
  p <- pack_emergence(m, "/a", "open")
  p$envelope$integrity <- "deadbeef"
  expect_error(unpack_for_local(p), "mismatch|tamper")
  expect_error(unpack_for_local("not a packet"), "visualr_emergence_packet")
})

test_that("route_emergence fails closed on missing policy / bad snapshot", {
  pk <- list(pack_emergence(new_merge("a","M1","l",1L), "/a", "open"))
  expect_error(route_emergence(pk, "not snapshot", "identity_route"), "snapshot")
  expect_error(route_emergence(pk, new_router_snapshot(1L,list(),"/a",c("/a"=1),c("/a"="open")),
                               "nope_route"), "Unknown router policy")
})

test_that("materialize_adjacency fails closed on malformed plan / bad edges", {
  snp <- new_router_snapshot(1L, list(new_routing_envelope("P1","l","/a",1L,"open")),
                             "/a", c("/a"=1), c("/a"="open"))
  expect_error(materialize_adjacency("not a plan", snp, 1L), "visualr_routing_plan|A3")
  expect_error(materialize_adjacency(new_routing_plan(adjacencies = list(
    list(source_packet_id = "P1", dest_packet_id = "P1"))), snp, 1L), "self")
  expect_error(materialize_adjacency(new_routing_plan(adjacencies = list(
    list(source_packet_id = "P1", dest_packet_id = "P9"))), snp, 1L), "nonexistent")
})

test_that("harmony_step fails closed on non-adjacency / unknown operator", {
  m <- new_merge("a","M1","l",1L)
  expect_error(harmony_step("raw"), "visualr_adjacency_pair|A3")
  pr <- new_adjacency_pair(new_merge("a","M1","l",1L), new_merge("b","M2","l",1L),
                           "/a","/b","s","t",1L)
  expect_error(harmony_step(pr, "nope_op"), "Unknown harmony operator")
})

test_that("run_emergence_round fails closed on empty input", {
  expect_error(run_emergence_round(list(), list(), "/a", c("/a"=1), c("/a"="open"), 1L),
               "at least one packet")
})

test_that("merge_content fails closed on a packet_id string (seam hint, not a Merge)", {
  expect_error(merge_content("PM1"), "packet_id string|resolve|4.1")
  expect_error(merge_content(42), "visualr_merge")
})

test_that("register_harmony_operator fails closed on bad arity / CLI toggles", {
  expect_error(register_harmony_operator("bad", function(a) a), "accept")
  expect_error(register_harmony_operator(NA, function(a,b,c) 1), "single non-empty")
})
