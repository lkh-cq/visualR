# v0.7.0 Promotion Gate tests — Router Semantic Blindness (attack-style).
# These are ADVERSARIAL tests: they attempt to make the Router read Merge
# payload semantics and assert it CANNOT. A passing suite here is what proves
# gate 2 (Router cannot read Merge internal semantics) and §14.1 (semantic
# isolation), not merely that the happy path works.

make_packets <- function() {
  list(
    pack_emergence(new_merge("SECRET-alpha", "M1", "la", 1L), "/a", "open"),
    pack_emergence(new_merge("SECRET-beta",  "M2", "lb", 1L), "/b", "open"),
    pack_emergence(new_merge("SECRET-gamma", "M3", "lc", 1L), "/c", "open")
  )
}
make_snapshot <- function(pk) {
  new_router_snapshot(1L, lapply(pk, function(p) p$envelope),
                      c("/a","/b","/c"), c("/a"=1,"/b"=1,"/c"=1),
                      c("/a"="open","/b"="open","/c"="open"))
}

test_that("a policy receives envelopes ONLY — never the packet or its payload", {
  # Register a policy that tries (in every way) to reach semantic content.
  # If it can't, semantic isolation holds; if it can, this test catches the leak.
  new_router_policy("malicious_read", function(envelopes, snapshot) {
    # Attack 1: with only envelopes, there is NO payload field to read.
    if (any(vapply(envelopes, function(e) "payload" %in% names(e), logical(1L)))) {
      stop("LEAK: an envelope carried a payload field")
    }
    # Attack 2: envelopes must be the routing surface, not Merge objects.
    if (any(vapply(envelopes, function(e) inherits(e, "visualr_merge"), logical(1L)))) {
      stop("LEAK: policy received a raw Merge")
    }
    # Attack 3: no subclass of a Merge should be reachable from an envelope.
    payload_field_present <- any(unlist(lapply(envelopes, function(e) {
      grepl("content", paste(names(e), collapse = ","))
    })))
    if (payload_field_present) stop("LEAK: name 'content' present on envelope")
    # benign identity result (build edges directly; do not reach into internals)
    pids <- vapply(envelopes, function(e) as.character(e$packet_id), character(1L))
    edges <- if (length(pids) >= 2L) {
      list(list(source_packet_id = pids[[1]], dest_packet_id = pids[[2]]))
    } else list()
    list(placements = Map(function(e) list(packet_id = e$packet_id, address = e$source_address),
                          envelopes),
         adjacencies = edges,
         policy_evidence = list(policy = "malicious_read"))
  }, overwrite = TRUE)

  pk <- make_packets()
  plan <- route_emergence(pk, make_snapshot(pk), "malicious_read")
  expect_s3_class(plan, "visualr_routing_plan")
  # the policy could NOT see content: validate_router_plan agrees, no semantic leak
  expect_true(validate_router_plan(plan))
})

test_that("router_envelope returns a routing surface, never Merge/payload (direct access)", {
  pk <- make_packets()
  e <- router_envelope(pk[[1]])
  expect_s3_class(e, "visualr_routing_envelope")
  expect_false(inherits(e, "visualr_merge"))
  expect_false("payload" %in% names(e))
  expect_false(any(grepl("SECRET", paste(unlist(e), collapse = ","))))
})

test_that("hidden semantic tokens cannot be smuggled into a plan (gate 9/10/11)", {
  pk <- make_packets()
  plan <- route_emergence(pk, make_snapshot(pk), "identity_route")
  # attack: inject a semantic score deep inside a placement (A4 recursive scan)
  plan$placements[1] <- list(list(packet_id = plan$placements[[1]]$packet_id,
                                  address = plan$placements[[1]]$address,
                                  score = 0.99))   # <- nested semantic field
  expect_error(validate_router_plan(plan), "A4|semantic")
  plan2 <- route_emergence(pk, make_snapshot(pk), "identity_route")
  plan2$policy_evidence[1] <- list(list(policy = "x", meaning = "prediction"))
  expect_error(validate_router_plan(plan2), "A4|semantic")
})

test_that("no silent padding / no hidden aggregation on the round result", {
  st <- list({m <- new_merge("a","M1","l",1L); m$address<-"/a"; m},
             {m <- new_merge("b","M2","l",1L); m$address<-"/b"; m})
  pk <- lapply(st, function(m) pack_emergence(m, as.character(m$address), "open"))
  rnd <- run_emergence_round(pk, st, c("/a","/b"), c("/a"=1,"/b"=1),
                             c("/a"="open","/b"="open"), 1L,
                             "identity_route", "pair_comp")
  # gate 11: no hidden aggregation — every new merge is accounted in adjacency_used
  expect_equal(length(rnd$result$new_merges),
               length(rnd$result$adjacency_used))
  # gate 10: no silent padding — resource_left is the real snapshot resource, not padded
  expect_equal(unname(rnd$result$resource_left), unname(c("/a"=1,"/b"=1)))
})
