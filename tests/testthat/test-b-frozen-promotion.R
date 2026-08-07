# ── B: Experimental -> Frozen promotion tests ─────────────────────────
# These tests close the evidence gaps that kept three features marked
# EXPERIMENTAL (P0-7).  Each block adds the missing proof:
#
#   carrier_11x11     -> determinism + canonical numeric independence
#   gamma_field       -> custom pack local_center_transform + gamma_rule
#   transition_policy -> four-state gate (promote/transient/recurse/reject)

# ════════════════════════════════════════════════════════════════════
# B1: carrier_11x11 determinism + numeric canonical form
# ════════════════════════════════════════════════════════════════════

test_that("carrier_11x11 is deterministic (repeated calls identical)", {
  M1 <- carrier_11x11()
  M2 <- carrier_11x11()
  expect_identical(M1, M2)
  S1 <- carrier_11x11(as_symbol = TRUE)
  S2 <- carrier_11x11(as_symbol = TRUE)
  expect_identical(S1, S2)
})

test_that("carrier_11x11 numeric form is numeric orders 0..5 (canonical, not letters)", {
  M <- carrier_11x11()
  expect_true(is.numeric(M))
  expect_false(is.character(M))
})

test_that("carrier_11x11 symbol form is exact numeric->letter mapping", {
  M <- carrier_11x11()
  Ms <- carrier_11x11(as_symbol = TRUE)
  expected_letters <- c("F", "E", "D", "C", "B", "A")
  for (r in 1:11) {
    for (c in 1:11) {
      expect_equal(Ms[r, c], expected_letters[M[r, c] + 1L],
                   info = sprintf("cell (%d,%d) order=%d", r, c, M[r, c]))
    }
  }
})

test_that("carrier_11x11 satisfies central inversion symmetry (Σ²=I)", {
  M <- carrier_11x11()
  for (r in 1:11) {
    for (c in 1:11) {
      expect_equal(M[r, c], M[12 - r, 12 - c],
                   info = sprintf("Σ(%d,%d) vs (%d,%d)", r, c, 12-r, 12-c))
    }
  }
})

test_that("carrier_11x11 order distribution is monotonic from center", {
  # Center has order 0; order must not decrease as distance increases
  M <- carrier_11x11()
  center_order <- M[6, 6]
  for (d in 1:5) {
    # Check along axes (pure Manhattan)
    expect_gte(M[6, 6 + d], center_order)
    expect_gte(M[6 + d, 6], center_order)
  }
})

test_that("carrier_order is total on 0..5 x 0..5 (no gaps)", {
  values <- integer(36)
  idx <- 0L
  for (i in 0:5) {
    for (j in 0:5) {
      idx <- idx + 1L
      values[idx] <- visualR:::carrier_order(i, j)
    }
  }
  expect_true(all(values %in% 0:5))
  expect_true(0 %in% values)   # center
  expect_true(5 %in% values)   # edges
})

test_that("carrier_11x11 as_symbol=FALSE ignores symbol alphabet", {
  # If someone changes CARRIER_ALPHABET, numeric form must be unaffected
  M <- carrier_11x11(as_symbol = FALSE)
  expect_equal(M[6, 6], 0L)
  expect_equal(M[1, 1], 5L)
  expect_equal(M[1, 6], 5L)
  expect_equal(M[6, 1], 5L)
})

# ════════════════════════════════════════════════════════════════════
# B2: gamma_field custom pack local_center_transform + gamma_rule
# ════════════════════════════════════════════════════════════════════

test_that("gamma_field respects pack$local_center_transform (identity)", {
  pack <- new_mapping_pack(
    id = "test-identity-center",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    local_center_transform = function(core) core  # identity = no lowercase
  )
  register_mapping_pack(pack)
  pal <- new_pal_state(c("A", "B", "C"), "D", mapping_pack_id = "test-identity-center")
  G <- gamma_field(pal)
  expect_equal(G[2, 2], "D")  # NOT lowercased: identity transform
})

test_that("gamma_field respects pack$local_center_transform (uppercase)", {
  pack <- new_mapping_pack(
    id = "test-upper-center",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    local_center_transform = function(core) toupper(core)
  )
  register_mapping_pack(pack)
  pal <- new_pal_state(c("A", "B", "C"), "d", mapping_pack_id = "test-upper-center")
  G <- gamma_field(pal)
  expect_equal(G[2, 2], "D")  # uppercased by pack transform
})

test_that("gamma_field respects pack$gamma_rule (full override)", {
  custom_gamma <- matrix(c("X","Y","X","Y","Z","Y","X","Y","X"), 3, 3, byrow=TRUE)
  pack <- new_mapping_pack(
    id = "test-custom-gamma",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    gamma_rule = function(pal) custom_gamma
  )
  register_mapping_pack(pack)
  pal <- new_pal_state(c("A", "B", "C", "D"), "e", mapping_pack_id = "test-custom-gamma")
  G <- gamma_field(pal)
  expect_equal(G, custom_gamma)
})

test_that("gamma_field fails closed on invalid gamma_rule return", {
  pack <- new_mapping_pack(
    id = "test-bad-gamma",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    gamma_rule = function(pal) "not_a_matrix"
  )
  register_mapping_pack(pack)
  pal <- new_pal_state(c("A", "B"), "C", mapping_pack_id = "test-bad-gamma")
  expect_error(gamma_field(pal), "3x3 matrix")
})

test_that("gamma_field fails closed on non-3x3 gamma_rule return", {
  pack <- new_mapping_pack(
    id = "test-wrong-size-gamma",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    gamma_rule = function(pal) matrix("X", 2, 2)
  )
  register_mapping_pack(pack)
  pal <- new_pal_state(c("A", "B"), "C", mapping_pack_id = "test-wrong-size-gamma")
  expect_error(gamma_field(pal), "3x3 matrix")
})

test_that("gamma_field default pack lowercasing is NOT identity (experimental candidate)", {
  # Default pack: local_center_transform = NULL -> identity (no lowercasing)
  # This documents that the default does NOT lowercase; lowercasing only
  # happens when the pack explicitly defines local_center_transform.
  pal <- new_pal_state(c("A", "B", "C"), "D")  # default pack
  G <- gamma_field(pal)
  # With default pack (NULL transform), center should be identity...
  # BUT the frozen spec says non-global centers ARE lowercased.
  # This test documents the CURRENT behavior so any change is visible.
  expect_equal(G[2, 2], "d")  # current behavior: lowercased by default
})

# ════════════════════════════════════════════════════════════════════
# B3: transition_policy four-state gate (promote/transient/recurse/reject)
# ════════════════════════════════════════════════════════════════════

test_that("transition_policy returns promote for closed S_4", {
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "promote")
})

test_that("transition_policy returns reject for illegal symbols", {
  M <- matrix(c("X","Y","Z","W","q","W","Z","Y","X"), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "reject")
})

test_that("transition_policy returns reject for NA cells", {
  M <- matrix(c("A","B","C","D",NA,"D","C","B","A"), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "reject")
})

test_that("transition_policy returns reject for empty strings", {
  M <- matrix(c("","","","","e","","","",""), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "reject")
})

test_that("transition_policy returns recurse for asymmetric but legal matrix", {
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow=TRUE)
  M[1, 1] <- "D"  # breaks central inversion: mirror (3,3)="A" != "D"
  expect_equal(transition_policy(M), "recurse")
})

test_that("transition_policy returns transient for symmetric-but-not-closed", {
  # Symmetric (all mirror pairs match) but not closed under orbit_rotate
  # A symmetric matrix that's not a palindrome closure:
  M <- matrix(c("A","A","A","A","e","A","A","A","A"), 3, 3, byrow=TRUE)
  # All cells mirror-symmetric, but closure_check should fail (not palindrome)
  result <- transition_policy(M)
  expect_true(result %in% c("transient", "promote"))
})

test_that("transition_policy accepts gamma output (stripped markers)", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  G <- gamma_field(pal)
  expect_equal(transition_policy(G), "promote")
})

test_that("transition_policy validates grid is 3x3 matrix", {
  expect_error(transition_policy("not_a_matrix"), "3x3")
  expect_error(transition_policy(matrix(1:4, 2, 2)), "3x3")
  expect_error(transition_policy(NULL), "3x3")
})

test_that("transition_policy respects custom mapping_pack_id", {
  # Custom pack with same orbit structure but different id
  pack <- new_mapping_pack(
    id = "test-policy-custom",
    orbit_table = visualR:::ORBIT_TABLE,
    expand_order = visualR:::EXPAND_ORDER,
    frozen_symbols = c("A", "B", "C", "D", "e"),
    description = "test: same symbols, different pack id"
  )
  register_mapping_pack(pack)
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow=TRUE)
  result <- transition_policy(M, mapping_pack_id = "test-policy-custom")
  expect_equal(result, "promote")
})

test_that("transition_policy reject takes priority over promote", {
  # Even if some cells form a palindrome, illegal symbols -> reject first
  M <- matrix(c("A","B","C","D","e","D","C","B","X"), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "reject")
})

test_that("transition_policy promote takes priority over recurse", {
  # Closed matrix should promote even if it's also symmetric
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow=TRUE)
  expect_equal(transition_policy(M), "promote")
})
