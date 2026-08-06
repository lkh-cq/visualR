# Test file: Gamma generator + peel chain
# gamma_field validated against ALL 4 frozen spec examples (README v0.2).
# peel chain: S_4 -> S_3 -> S_2 -> S_1 -> S_0 (center-block fusion).

# ── Gamma generator: exact spec examples ────────────────────────────

test_that("Γ(S_4) matches frozen spec", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_equal(gamma_field(pal),
               matrix(c("C", "D", "C", "D", "e", "D", "C", "D", "C"),
                      3, 3, byrow = TRUE))
})

test_that("Γ(S_3) matches frozen spec", {
  pal <- new_pal_state(c("A", "B", "C"), "D")
  expect_equal(gamma_field(pal),
               matrix(c("B", "C", "B", "C", "d", "C", "B", "C", "B"),
                      3, 3, byrow = TRUE))
})

test_that("Γ(S_2) matches frozen spec", {
  pal <- new_pal_state(c("A", "B"), "C")
  expect_equal(gamma_field(pal),
               matrix(c("A", "B", "A", "B", "c", "B", "A", "B", "A"),
                      3, 3, byrow = TRUE))
})

test_that("Γ(S_1) matches frozen spec", {
  pal <- new_pal_state(c("A"), "B")
  expect_equal(gamma_field(pal),
               matrix(c("A", "A", "A", "A", "b", "A", "A", "A", "A"),
                      3, 3, byrow = TRUE))
})

test_that("Γ(S_0) is rejected (no 3x3 neighborhood)", {
  pal <- new_pal_state(character(0), "A")
  expect_error(gamma_field(pal), "at least one shell")
})

test_that("Γ only global center keeps case (isotropic singularity)", {
  # S_4 center e stays lowercase-identical; stripped centers lowercase
  pal4 <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_equal(gamma_field(pal4)[2, 2], "e")  # global center: unchanged
  pal3 <- new_pal_state(c("A", "B", "C"), "D")
  expect_equal(gamma_field(pal3)[2, 2], "d")  # stripped: lowercased
})

# ── Peel chain ───────────────────────────────────────────────────────

test_that("peel S_4 -> S_3 (center-block fusion)", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  p3 <- peel(pal)
  expect_equal(p3$shells, c("A", "B", "C"))
  expect_equal(p3$core, "D")
})

test_that("peel chain reaches S_0", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  chain <- peel_chain(pal)
  expect_length(chain, 5)
  expect_equal(chain[[1]]$shells, c("A", "B", "C", "D"))
  expect_equal(chain[[5]]$shells, character(0))
  expect_equal(chain[[5]]$core, "A")
})

test_that("peel preserves metadata", {
  pal <- new_pal_state(c("A", "B"), "C",
                       mapping_pack_id = "custom-v0.2",
                       provenance = list(clock = 42L))
  p2 <- peel(pal)
  expect_equal(p2$mapping_pack_id, "custom-v0.2")
  expect_equal(p2$provenance, list(clock = 42L))
})

test_that("peel rejects S_0", {
  pal <- new_pal_state(character(0), "X")
  expect_error(peel(pal), "Cannot peel S_0")
})

test_that("promote is inverse of peel", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  p3 <- peel(pal)
  back <- promote(p3, "e")
  expect_equal(back$shells, pal$shells)
  expect_equal(back$core, pal$core)
})

test_that("promote validates new_core", {
  pal <- new_pal_state(c("A", "B"), "C")
  expect_error(promote(pal, c("X", "Y")), "single")
  expect_error(promote(pal, NA_character_), "non-NA")
})

test_that("peel + gamma consistent with frozen chain", {
  # Γ(δ(S_4)) = Γ(S_3) — completeness axiom: K_k = Γ(δ^{n-k}(S_n))
  pal4 <- new_pal_state(c("A", "B", "C", "D"), "e")
  pal3 <- peel(pal4)
  expect_equal(gamma_field(pal3),
               matrix(c("B", "C", "B", "C", "d", "C", "B", "C", "B"),
                      3, 3, byrow = TRUE))
})

test_that("unfold consistency: peel reduces unfold length by 2", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_equal(length(unfold_pal(pal)), 9L)
  expect_equal(length(unfold_pal(peel(pal))), 7L)
})
