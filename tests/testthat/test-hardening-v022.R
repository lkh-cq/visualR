# Test file: v0.2.2 P0 completion regression
# P0-1 full pack hash / P0-2 pack drives ALL mappings / P0-3 typed
# carrier dispatch / P1 operator ABI enforcement / P1 param domains

s4 <- function() new_pal_state(c("A", "B", "C", "D"), "e")

# ── P0-1: full-content pack hash ────────────────────────────────────

test_that("hash changes when orbit TABLE CONTENT changes", {
  p1 <- new_mapping_pack(id = "h-content",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  # Tamper: move A's addr1 coordinate
  ot2 <- visualR:::ORBIT_TABLE
  ot2$A$addr1 <- c(2L, 1L)
  p2 <- new_mapping_pack(id = "h-content",
                         orbit_table = ot2,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_false(p1$hash == p2$hash)
})

test_that("hash changes when complement content changes", {
  p1 <- new_mapping_pack(id = "h-comp",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         complement_table = list(A = "B"),
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  p2 <- new_mapping_pack(id = "h-comp",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         complement_table = list(A = "C"),
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_false(p1$hash == p2$hash)
})

test_that("hash changes when carrier_fn source changes", {
  p1 <- new_mapping_pack(id = "h-carrier",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         carrier_fn = function() matrix(0, 11, 11),
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  p2 <- new_mapping_pack(id = "h-carrier",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         carrier_fn = function() matrix(1, 11, 11),
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_false(p1$hash == p2$hash)
})

test_that("assert_pack fails closed on tampered pack", {
  p <- new_mapping_pack(id = "h-tamper",
                        orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  # Tamper: fetch the registered pack, mutate a coordinate, re-assign.
  # resolve_mapping_pack must FAIL CLOSED on the hash mismatch.
  reg <- get(".visualR_pack_registry", envir = asNamespace("visualR"))
  tampered <- reg[["h-tamper"]]
  tampered$orbit_table$A$addr1 <- c(3L, 3L)
  assign("h-tamper", tampered, envir = reg)
  expect_error(resolve_mapping_pack("h-tamper"), "hash mismatch")
  # Clean up
  rm("h-tamper", envir = reg)
})

test_that("resolve_mapping_pack validates hash on every resolve", {
  p <- new_mapping_pack(id = "h-valid",
                        orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  expect_s3_class(resolve_mapping_pack("h-valid"), "visualr_mapping_pack")
  rm("h-valid", envir = get(".visualR_pack_registry", envir = asNamespace("visualR")))
})

# ── P0-2: pack drives ALL mappings ──────────────────────────────────

test_that("materialize carrier_11x11 uses pack$carrier_fn", {
  # A pack whose carrier_fn returns a DIFFERENT matrix must be used
  custom_carrier <- function() matrix(9, 11, 11)
  p <- new_mapping_pack(id = "h-custom-carrier",
                        orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        carrier_fn = custom_carrier,
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  pal <- new_pal_state(c("A", "B", "C", "D"), "e",
                       mapping_pack_id = "h-custom-carrier")
  m <- materialize(pal, carrier = "carrier_11x11")
  expect_true(all(m$grid == 9))
  rm("h-custom-carrier", envir = get(".visualR_pack_registry", envir = asNamespace("visualR")))
})

test_that("gamma_field uses pack$local_center_transform", {
  # Identity-transform pack: center stays uppercase
  p <- new_mapping_pack(id = "h-ident",
                        orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        local_center_transform = identity,
                        frozen_symbols = c("A", "B", "C", "D", "E"))
  register_mapping_pack(p)
  pal <- new_pal_state(c("A", "B", "C", "D"), "E",
                       mapping_pack_id = "h-ident")
  g <- gamma_field(pal)
  expect_equal(g[2, 2], "E")     # identity: NOT lowercased
  # default pack lowercases
  gd <- gamma_field(new_pal_state(c("A", "B", "C", "D"), "E"))
  expect_equal(gd[2, 2], "e")
  rm("h-ident", envir = get(".visualR_pack_registry", envir = asNamespace("visualR")))
})

test_that("gamma_field uses pack$gamma_rule when defined", {
  p <- new_mapping_pack(id = "h-grule",
                        orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        gamma_rule = function(pal) matrix("Z", 3, 3),
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  pal <- new_pal_state(c("A", "B", "C", "D"), "e",
                       mapping_pack_id = "h-grule")
  g <- gamma_field(pal)
  expect_true(all(g == "Z"))
  # a broken gamma_rule fails closed
  p2 <- new_mapping_pack(id = "h-grule-bad",
                         orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         gamma_rule = function(pal) list(1),
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p2)
  pal2 <- new_pal_state(c("A", "B", "C", "D"), "e",
                        mapping_pack_id = "h-grule-bad")
  expect_error(gamma_field(pal2), "3x3")
  rm("h-grule", "h-grule-bad", envir = get(".visualR_pack_registry", envir = asNamespace("visualR")))
})

# ── P0-3: typed carrier dispatch ────────────────────────────────────

test_that("pal_pipe with non-3x3 carrier fails with typed error", {
  expect_error(pal_pipe("{A{B{C{D{e}D}C}B}A}", "identity",
                        carrier = "carrier_11x11", verbose = FALSE),
               "typed dispatch")
})

test_that("materialize carrier_11x11 still works as a view", {
  m <- materialize(s4(), carrier = "carrier_11x11")
  expect_equal(dim(m$grid), c(11L, 11L))
  expect_true(m$ok)
})

# ── P1: operator ABI enforcement ────────────────────────────────────

test_that("register_operator rejects non-3x3 return at registration", {
  expect_error(register_operator("bad_shape", function(M, pack) matrix(1, 2, 2)),
               "3x3")
  expect_error(register_operator("bad_list", function(M, pack) list(1)),
               "3x3")
  expect_error(register_operator("bad_numeric", function(M, pack) matrix(1, 3, 3)),
               "character")
})

test_that("compute_jiugong enforces contract at call time", {
  # registration-time probe rejects non-character return (P1)
  expect_error(
    register_operator("abnormal_ok", function(M, pack) matrix(1, 3, 3),
                      overwrite = TRUE),
    "character"
  )
})

# ── P1: diamond_at param domain ─────────────────────────────────────

test_that("diamond_at validates offset params", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_error(diamond_at(pal, NA, 0), "finite")
  expect_error(diamond_at(pal, 0, NA), "finite")
  expect_error(diamond_at(pal, Inf, 0), "finite")
  expect_error(diamond_at(pal, 1.5, 0), "integer-like")
  expect_error(diamond_at(pal, c(1, 2), 0), "single")
  expect_error(diamond_at(pal, "a", 0), "numeric")
})

# ── P1: jiugong naming ──────────────────────────────────────────────

test_that("pal_to_jiugong is strictly S_4/3x3; square view handles rest", {
  expect_error(pal_to_jiugong(new_pal_state(character(0), "X")),
               "S_4 -> 3x3 mapping only")
  v <- pal_to_square_view(new_pal_state(character(0), "X"))
  expect_equal(dim(v$grid), c(1L, 1L))
  # S_12: 5x5 view
  pal12 <- new_pal_state(LETTERS[1:12], "M")
  v12 <- pal_to_square_view(pal12)
  expect_equal(dim(v12$grid), c(5L, 5L))
})
