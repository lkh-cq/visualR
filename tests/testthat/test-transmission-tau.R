# v0.10 Transmission Signature tau = (d,b,r,phi,g) + psi embedding tests
# (Task 4). Covers phase wrapping, the numeric d/b/r fixture, the promotion
# gate that recursive-layer travel does NOT cancel, the leakage discipline of
# psi_embed_tau, and signature-humility (tau equality never implies path
# equality). `.onLoad_geometry_defaults()` is run once by helper-geometry.R.

test_that("wrap_phase: pi stays at pi, 3*pi normalizes to (-pi, pi]", {
  expect_equal(wrap_phase(pi), pi)
  expect_true(abs(wrap_phase(3 * pi)) <= pi)
  expect_equal(wrap_phase(3 * pi), pi)
  expect_true(wrap_phase(4 * pi) > -pi)        # still inside interval
})

test_that("wrap_phase: phase-difference symmetry (odd function)", {
  expect_equal(wrap_phase(2), -wrap_phase(-2))
  expect_equal(wrap_phase(3), -wrap_phase(-3))
})

test_that("transmission_tau: d/b/r/ph i numeric fixture", {
  # layer 0 -> 2 -> 0  : r = |2-0| + |0-2| = 4 (does NOT cancel to 0)
  # manhattan: coords 0 -> 1 -> 3 : d = 1 + 2 = 3 ; one boundary => b = 1
  p0 <- new_position_state("/a", c(0), "core",   layer = 0L)
  p1 <- new_position_state("/a", c(1), "periph", layer = 2L)
  p2 <- new_position_state("/a", c(3), "core",   layer = 0L)
  ev1 <- new_transmission_event("m", p0, list(p1), boundary_flags = FALSE,
                                logical_time = 1L)
  ev2 <- new_transmission_event("m", p1, list(p2), boundary_flags = TRUE,
                                logical_time = 2L)
  tau <- transmission_tau(list(ev1, ev2), list(p0, p1, p2), "manhattan",
                          final_phase = 0, regulation_summary = c(alpha = 1))
  expect_equal(tau$d, 3)
  expect_identical(tau$b, 1)
  expect_equal(tau$r, 4)
  expect_equal(tau$phi, 0)
})

test_that("r non-cancellation is a promotion gate (up-then-down != 0)", {
  p0 <- new_position_state("/a", 0, "core", layer = 0L)
  up <- new_position_state("/a", 1, "core", layer = 2L)
  p2 <- new_position_state("/a", 2, "core", layer = 0L)
  evs <- list(
    new_transmission_event("m", p0, list(up), logical_time = 1L),
    new_transmission_event("m", up, list(p2), logical_time = 2L)
  )
  tau <- transmission_tau(evs, list(p0, up, p2), "manhattan",
                          final_phase = 0, regulation_summary = numeric(0))
  expect_false(tau$r == 0)     # layer travel up-then-down must NOT cancel
  expect_equal(tau$r, 4)
})

test_that("psi_embed_tau: regulation present without center/scale fails closed", {
  p0 <- new_position_state("/a", 0, "core", layer = 0L)
  p1 <- new_position_state("/a", 2, "core", layer = 0L)
  ev <- new_transmission_event("m", p0, list(p1), logical_time = 1L)
  tau <- transmission_tau(list(ev), list(p0, p1), "manhattan",
                          final_phase = 0, regulation_summary = c(a = 1, b = 2))
  # leakage discipline: fitting on transformed input must not happen here
  expect_error(psi_embed_tau(tau), "reg_center/reg_scale")
})

test_that("psi_embed_tau: with scales, output = 5 + len(g), all named", {
  p0 <- new_position_state("/a", 0, "core", layer = 0L)
  p1 <- new_position_state("/a", 2, "core", layer = 0L)
  ev <- new_transmission_event("m", p0, list(p1), logical_time = 1L)
  tau <- transmission_tau(list(ev), list(p0, p1), "manhattan",
                          final_phase = pi / 2, regulation_summary = c(a = 1, b = 2))
  out <- psi_embed_tau(tau, reg_center = c(1, 2), reg_scale = c(1, 1))
  expect_length(out, 5L + 2L)
  expect_named(out)
  expect_true(all(nzchar(names(out))))
  # mismatch between reg_center/reg_scale and g length also fails closed
  expect_error(psi_embed_tau(tau, reg_center = c(1), reg_scale = c(1)),
               "must match regulation length")
})

test_that("signature humility: equal tau does NOT imply equal path", {
  pA0 <- new_position_state("/a", 0, "core", layer = 0L)
  pA1 <- new_position_state("/a", 1, "core", layer = 1L)
  pA2 <- new_position_state("/a", 3, "core", layer = 0L)
  pB0 <- new_position_state("/a", 0, "core", layer = 0L)
  pB1 <- new_position_state("/a", 2, "core", layer = 1L)
  pB2 <- new_position_state("/a", 3, "core", layer = 0L)

  evsA <- list(
    new_transmission_event("m", pA0, list(pA1), logical_time = 1L),
    new_transmission_event("m", pA1, list(pA2), logical_time = 2L)
  )
  evsB <- list(
    new_transmission_event("m", pB0, list(pB1), logical_time = 1L),
    new_transmission_event("m", pB1, list(pB2), logical_time = 2L)
  )
  # same d (3), b (0), r (2), phi (0), g -> identical tau
  tauA <- transmission_tau(evsA, list(pA0, pA1, pA2), "manhattan",
                           final_phase = 0, regulation_summary = c(x = 1))
  tauB <- transmission_tau(evsB, list(pB0, pB1, pB2), "manhattan",
                           final_phase = 0, regulation_summary = c(x = 1))
  expect_identical(tauA$d, tauB$d)
  expect_identical(tauA$r, tauB$r)
  psiA <- psi_embed_tau(tauA, reg_center = 1, reg_scale = 1)
  psiB <- psi_embed_tau(tauB, reg_center = 1, reg_scale = 1)
  expect_identical(psiA, psiB)
  # ...but the full path objects (different intermediate points) are NOT equal
  pathA <- append_transmission_step(
    append_transmission_step(new_transmission_path("m", pA0), pA0, pA1,
                             "T1", 1L), pA1, pA2, "T1", 2L)
  pathB <- append_transmission_step(
    append_transmission_step(new_transmission_path("m", pB0), pB0, pB1,
                             "T1", 1L), pB1, pB2, "T1", 2L)
  expect_false(paths_equal(pathA, pathB))
})