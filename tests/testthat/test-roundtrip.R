# Test file: property tests / round-trip invariants
# Tests the three core invariants across various inputs.

# ── Invariant 1: parse_pal(format_pal(S)) == S ─────────────────────

test_that("Inv1: parse(format(S_0)) == S_0 (R1)", {
  pal <- pal_fixture_n0()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
  expect_equal(result$provenance, pal$provenance)
})

test_that("Inv1: parse(format(S_4)) == S_4 (R2)", {
  pal <- pal_fixture_n4()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
})

test_that("Inv1: parse(format(custom)) preserves all metadata (R3)", {
  pal <- pal_fixture_n4_custom()
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  expect_equal(result$mapping_pack_id, pal$mapping_pack_id)
  expect_equal(result$provenance, pal$provenance)
})

test_that("Inv1: format is idempotent (R4)", {
  pal <- pal_fixture_n4()
  s1 <- format_pal(pal)
  s2 <- format_pal(parse_pal(s1))
  expect_equal(s1, s2)
})

# ── Invariant 2: fold_pal(unfold_pal(S)) == S ──────────────────────

test_that("Inv2: fold(unfold(S_0)) == S_0 (R5)", {
  pal <- pal_fixture_n0()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv2: fold(unfold(S_4)) == S_4 (R6)", {
  pal <- pal_fixture_n4()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv2: fold(unfold(S_12)) == S_12 (R7)", {
  pal <- pal_fixture_n12()
  result <- fold_pal(unfold_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv2: unfold is idempotent under fold (R8)", {
  pal <- pal_fixture_n4()
  u1 <- unfold_pal(pal)
  pal2 <- fold_pal(u1)
  u2 <- unfold_pal(pal2)
  expect_equal(u1, u2)
})

# ── Invariant 3: jiugong_to_pal(pal_to_jiugong(S)) == S ────────────

test_that("Inv3: jiugong_to_pal(pal_to_jiugong(S_4)) == S_4 (R9)", {
  pal <- pal_fixture_n4()
  result <- jiugong_to_pal(pal_to_jiugong(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv3: square view round-trips S_0 (R10, v0.2.2)", {
  pal <- pal_fixture_n0()
  v <- pal_to_square_view(pal)
  result <- fold_pal(as.vector(t(v$grid)), mapping_pack_id = pal$mapping_pack_id)
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv3: square view round-trips S_12 (R11, v0.2.2)", {
  pal <- pal_fixture_n12()
  v <- pal_to_square_view(pal)
  result <- fold_pal(as.vector(t(v$grid)), mapping_pack_id = pal$mapping_pack_id)
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
})

test_that("Inv3: jiugong is idempotent under pal round-trip (R12)", {
  pal <- pal_fixture_n4()
  jg1 <- pal_to_jiugong(pal)
  pal2 <- jiugong_to_pal(jg1)
  jg2 <- pal_to_jiugong(pal2)
  expect_equal(jg1$grid, jg2$grid)
})

# ── Unicode and special character tests ────────────────────────────

test_that("Unicode tokens in shells (R13)", {
  pal <- new_pal_state(
    shells = c("\u4e00", "\u4e8c", "\u4e09", "\u56db"),
    core = "\u4e94"
  )
  # format/parse round-trip
  result <- parse_pal(format_pal(pal))
  expect_equal(result$shells, pal$shells)
  expect_equal(result$core, pal$core)
  # unfold/fold round-trip
  result2 <- fold_pal(unfold_pal(pal))
  expect_equal(result2$shells, pal$shells)
  expect_equal(result2$core, pal$core)
})

test_that("Empty string tokens rejected (R14, v0.2.1 closed token domain)", {
  # v0.2.1: empty tokens violate the closed token domain -> rejected
  expect_error(new_pal_state(shells = c("", "A", ""), core = "e"),
               "non-empty")
  expect_error(new_pal_state(shells = c("A"), core = ""),
               "non-empty")
})

test_that("Special characters rejected (R15, v0.2.1 closed token domain)", {
  # v0.2.1: newline/separators break serialization framing -> rejected
  expect_error(new_pal_state(shells = c("A\nB"), core = "e"),
               "reserved")
  expect_error(new_pal_state(shells = c("A"), core = "X\ncore:evil"),
               "reserved")
  expect_error(new_pal_state(shells = c("A|B"), core = "e"),
               "reserved")
  expect_error(new_pal_state(shells = c("A=B"), core = "e"),
               "reserved")
  expect_error(new_pal_state(shells = c("{A"), core = "e"),
               "reserved")
})

# ── Cross-layer consistency ────────────────────────────────────────

test_that("Unfold length is always odd (R16)", {
  for (n in 0:12) {
    shells <- LETTERS[seq_len(n)]
    if (n == 0) shells <- character(0)
    pal <- new_pal_state(shells = shells, core = "Z")
    unfolded <- unfold_pal(pal)
    expect_true(length(unfolded) %% 2 == 1,
                info = paste("n =", n))
  }
})

test_that("Unfold is always a palindrome (R17)", {
  for (n in 0:12) {
    shells <- LETTERS[seq_len(n)]
    if (n == 0) shells <- character(0)
    pal <- new_pal_state(shells = shells, core = "Z")
    unfolded <- unfold_pal(pal)
    expect_equal(unfolded, rev(unfolded),
                 info = paste("n =", n))
  }
})

test_that("Diamond center always equals n (R18)", {
  for (n in 0:6) {
    shells <- LETTERS[seq_len(n)]
    if (n == 0) shells <- character(0)
    pal <- new_pal_state(shells = shells, core = "Z")
    dm <- diamond_field(pal)
    c <- n + 1
    expect_equal(dm$matrix[c, c], n,
                 info = paste("n =", n))
  }
})

test_that("Diamond area formula holds for all n 0..6 (R19)", {
  for (n in 0:6) {
    shells <- LETTERS[seq_len(n)]
    if (n == 0) shells <- character(0)
    pal <- new_pal_state(shells = shells, core = "Z")
    dm <- diamond_field(pal)
    expected_area <- 1 + 2 * n * (n + 1)
    actual_area <- sum(!is.na(dm$matrix))
    expect_equal(actual_area, expected_area,
                 info = paste("n =", n))
  }
})

test_that("Jiugong only works for perfect-square unfold lengths (R20)", {
  # n=0: 1 (1^2) -> ok
  # n=1: 3 -> not square
  # n=2: 5 -> not square
  # n=3: 7 -> not square
  # n=4: 9 (3^2) -> ok
  # n=5: 11 -> not square
  # n=12: 25 (5^2) -> ok
  square_ns <- c(0, 4, 12)
  non_square_ns <- c(1, 2, 3, 5)

  # v0.2.2 (P1): jiugong is strictly S_4 -> 3x3; only n=4 succeeds.
  # Other perfect-square lengths use pal_to_square_view.
  for (n in c(0, 4, 12)) {
    shells <- LETTERS[seq_len(n)]
    if (n == 0) shells <- character(0)
    pal <- new_pal_state(shells = shells, core = "Z")
    if (n == 4) {
      expect_true(inherits(pal_to_jiugong(pal), "visualr_jiugong"),
                  info = paste("n =", n, "should work"))
    } else {
      expect_error(pal_to_jiugong(pal),
                   info = paste("n =", n, "should fail (not S_4)"))
      expect_true(is.list(pal_to_square_view(pal)),
                  info = paste("n =", n, "square view should work"))
    }
  }

  for (n in non_square_ns) {
    shells <- LETTERS[seq_len(n)]
    pal <- new_pal_state(shells = shells, core = "Z")
    expect_error(pal_to_jiugong(pal),
                 info = paste("n =", n, "should fail"))
  }
})
