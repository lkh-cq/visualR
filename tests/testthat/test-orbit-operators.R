# Test: Orbit operators — lane kernels for Topology Operator ABI v0.1
# Five kernels: identity / complement / mirror / rotate / gamma.
# Frozen-spec mapping: complement C^2=I, rotate cycles A->B->C->D->A,
# gamma lowers order A->B->C->D->e (clamped).

test_that("builtin lane kernels are registered", {
  .onLoad_lane_kernels()
  expect_setequal(lane_kernel_list(),
                  c("complement", "gamma", "identity", "mirror", "rotate"))
})

test_that("identity kernel returns orbit unchanged", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d <- execute_lanes_ops(snap, "identity")
  expect_identical(d$A$result, c("A", "A"))
  expect_identical(d$e$result, "e")
  expect_identical(d$A$action, "identity")
})

test_that("complement maps A<->D, B<->C, e->e", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d <- execute_lanes_ops(snap, "complement")
  expect_identical(d$A$result, c("D", "D"))
  expect_identical(d$D$result, c("A", "A"))
  expect_identical(d$B$result, c("C", "C"))
  expect_identical(d$C$result, c("B", "B"))
  expect_identical(d$e$result, "e")
  expect_identical(d$A$action, "complement")
})

test_that("complement is an involution C^2 = I", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d1 <- execute_lanes_ops(snap, "complement")
  # apply complement again on the transformed state
  p2 <- new_pal_state(unname(d1$A$result), d1$e$result)
  snap2 <- snapshot(new_topology_carrier(p2))
  d2 <- execute_lanes_ops(snap2, "complement")
  expect_identical(d2$A$result, c("A", "A"))
  expect_identical(d2$e$result, "e")
})

test_that("mirror swaps endpoints of a directional orbit", {
  # directional orbit (head != tail) to see the flip
  cell <- new_topology_cell("e", list(A = c("X", "Y"), B = c("B", "B"),
                                      C = c("C", "C"), D = c("D", "D")))
  # construct a snapshot-like lane call directly
  r <- kernel_mirror(c("X", "Y"), "idle", NULL)
  expect_identical(r$result, c("Y", "X"))
  expect_identical(r$action, "mirror")
  # canonical palindrome orbit is unchanged by mirror
  r2 <- kernel_mirror(c("A", "A"), "idle", NULL)
  expect_identical(r2$result, c("A", "A"))
  # singularity lane: mirror of center is itself
  r3 <- kernel_mirror("e", "idle", NULL)
  expect_identical(r3$result, "e")
})

test_that("rotate cycles A->B->C->D->A", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d <- execute_lanes_ops(snap, "rotate")
  expect_identical(d$A$result, c("B", "B"))
  expect_identical(d$B$result, c("C", "C"))
  expect_identical(d$C$result, c("D", "D"))
  expect_identical(d$D$result, c("A", "A"))
  expect_identical(d$e$result, "e")
  expect_identical(d$A$action, "rotate")
})

test_that("gamma lowers order A->B->C->D->e clamped at e", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d <- execute_lanes_ops(snap, "gamma")
  expect_identical(d$A$result, c("B", "B"))
  expect_identical(d$B$result, c("C", "C"))
  expect_identical(d$C$result, c("D", "D"))
  expect_identical(d$D$result, c("e", "e"))  # D steps to e
  expect_identical(d$e$result, "e")          # e is saturated
})

test_that("per-lane mixed kernels dispatch independently", {
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  snap <- snapshot(new_topology_carrier(p))
  d <- execute_lanes_ops(snap, list(A = "gamma", B = "complement",
                                    C = "rotate", D = "mirror",
                                    e = "identity"))
  expect_identical(d$A$result, c("B", "B"))    # gamma
  expect_identical(d$B$result, c("C", "C"))    # complement
  expect_identical(d$C$result, c("D", "D"))    # rotate
  expect_identical(d$D$result, c("D", "D"))    # mirror (palindrome)
  expect_identical(d$e$result, "e")            # identity
})

test_that("lane_kernels builds dispatch lists", {
  .onLoad_lane_kernels()
  k <- lane_kernels("rotate")
  expect_true(all(vapply(k, is.function, logical(1))))
  expect_identical(names(k), c("A", "B", "C", "D", "e"))
  k2 <- lane_kernels(list(A = "gamma", B = kernel_complement,
                          C = "rotate", D = "mirror", e = "identity"))
  expect_true(is.function(k2$B))
})

test_that("unknown lane kernel fails closed", {
  .onLoad_lane_kernels()
  expect_error(lane_kernel_get("nope"), "Unknown lane kernel")
  expect_error(lane_kernels(list(A = "nope", B = "identity",
                                 C = "identity", D = "identity",
                                 e = "identity")), "Unknown lane kernel")
})

test_that("builtin lane kernel cannot be silently overwritten", {
  .onLoad_lane_kernels()
  expect_error(lane_kernel_register("identity", function(o, p, k) NULL),
               "built-in")
  # but overwrite=TRUE works
  expect_true(lane_kernel_register("identity", kernel_identity, overwrite = TRUE))
})

test_that("lane kernel arity is enforced at registration", {
  expect_error(lane_kernel_register("bad", function(x) x),
               "at least \\(orbit, phase, pack\\)")
})

test_that("NA endpoints pass through kernels without error", {
  r <- kernel_gamma(c(NA_character_, NA_character_), "idle", NULL)
  expect_true(all(is.na(r$result)))
  r2 <- kernel_rotate(c(NA_character_, "A"), "idle", NULL)
  expect_true(is.na(r2$result[1]))
  expect_identical(r2$result[2], "B")
})
