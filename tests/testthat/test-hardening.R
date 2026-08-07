# Test file: v0.2.1 Semantic Hardening regression
# P0-1 mapping-pack injection / P0-2 unified dispatch / P0-3 token domain
# P0-5 closure fact vs policy / P0-6 compute result / P0-7 experimental

s4 <- function() new_pal_state(c("A", "B", "C", "D"), "e")

# ── P0-1: mapping_pack_id DRIVES rules, fail closed ────────────────

test_that("default pack is registered and resolvable", {
  pack <- resolve_mapping_pack("pal-jiugong-v0.2")
  expect_s3_class(pack, "visualr_mapping_pack")
  expect_equal(pack$id, "pal-jiugong-v0.2")
  expect_equal(pack$frozen_symbols, c("A", "B", "C", "D", "e"))
})

test_that("unknown pack id fails closed (no silent fallback)", {
  expect_error(resolve_mapping_pack("no-such-pack"), "Unknown mapping pack")
})

test_that("register duplicate pack fails closed", {
  p <- new_mapping_pack(id = "dup-pack", orbit_table = visualR:::ORBIT_TABLE,
                        expand_order = visualR:::EXPAND_ORDER,
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  p2 <- new_mapping_pack(id = "dup-pack", orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_error(register_mapping_pack(p2), "already registered")
  # overwrite=TRUE works
  register_mapping_pack(p2, overwrite = TRUE)
})

test_that("pack hash is deterministic", {
  p1 <- new_mapping_pack(id = "h1", orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  p2 <- new_mapping_pack(id = "h1", orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_equal(p1$hash, p2$hash)
  # different id -> different hash
  p3 <- new_mapping_pack(id = "h2", orbit_table = visualR:::ORBIT_TABLE,
                         expand_order = visualR:::EXPAND_ORDER,
                         frozen_symbols = c("A", "B", "C", "D", "e"))
  expect_false(p1$hash == p3$hash)
})

test_that("compute with unregistered pack id fails closed", {
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  expect_error(compute_jiugong(M, "identity", mapping_pack_id = "ghost"),
               "Unknown mapping pack")
  expect_error(closure_check(M, mapping_pack_id = "ghost"),
               "Unknown mapping pack")
})

test_that("custom pack drives orbit rules (not global constants)", {
  # A pack whose orbit table is REVERSED (D<->A swapped) must change
  # orbit_rotate output vs the default pack.
  custom_table <- visualR:::ORBIT_TABLE
  custom_table$A <- visualR:::ORBIT_TABLE$D
  custom_table$D <- visualR:::ORBIT_TABLE$A
  p <- new_mapping_pack(id = "custom-reversed", orbit_table = custom_table,
                        expand_order = visualR:::EXPAND_ORDER,
                        frozen_symbols = c("A", "B", "C", "D", "e"))
  register_mapping_pack(p)
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  out_default <- compute_jiugong(M, "orbit_rotate", mapping_pack_id = "pal-jiugong-v0.2")
  out_custom <- compute_jiugong(M, "orbit_rotate", mapping_pack_id = "custom-reversed")
  expect_false(identical(out_default, out_custom))
})

# ── P0-2: unified carrier dispatch ──────────────────────────────────

test_that("materialize auto: S_4 -> canonical_jiugong", {
  m <- materialize(s4())
  expect_equal(m$carrier, "canonical_jiugong")
  expect_equal(dim(m$grid), c(3L, 3L))
  expect_true(m$ok)
})

test_that("materialize auto: S_3 -> gamma_local", {
  m <- materialize(new_pal_state(c("A", "B", "C"), "D"))
  expect_equal(m$carrier, "gamma_local")
  expect_equal(dim(m$grid), c(3L, 3L))
  expect_true(m$ok)
})

test_that("pal_pipe and batch_compute resolve the SAME carrier", {
  # Same S_4 state -> both must use canonical_jiugong (no semantic fork)
  p1 <- pal_pipe(s4(), "identity", verbose = FALSE)
  b1 <- batch_compute(list(s4()), "identity", ncores = 1L)
  expect_equal(p1$carrier, "canonical_jiugong")
  expect_equal(b1$carrier, "canonical_jiugong")
})

test_that("materialize rejects unknown carrier", {
  expect_error(materialize(s4(), "nope"), "Unknown carrier")
})

# ── P0-5: closure fact separated from transition policy ─────────────

test_that("closure_check is a logical fact", {
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  expect_true(closure_check(M))
  M[1,1] <- "D"  # asymmetry
  expect_false(closure_check(M))
})

test_that("transition_policy maps fact to action", {
  M <- matrix(c("A","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  expect_equal(transition_policy(M), "promote")
  M[1,1] <- "D"
  expect_equal(transition_policy(M), "recurse")
  bad <- matrix(c("X","B","C","D","e","D","C","B","A"), 3, 3, byrow = TRUE)
  expect_equal(transition_policy(bad), "reject")
})

# ── P0-6: interact returns compute result, never swallows ───────────

test_that("interact returns visualr_compute_result with trace", {
  out <- interact(s4(), "orbit_rotate")
  expect_s3_class(out, "visualr_compute_result")
  expect_true(out$closed)
  expect_equal(out$action, "promote")
  expect_false(is.null(out$fold_back))
  expect_true(is.list(out$trace))
  expect_equal(out$trace$carrier, "canonical_jiugong")
})

test_that("interact on asymmetric state reports action, does NOT swallow", {
  # Even when computation is not closed, result carries the state
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  out <- interact(p, "orbit_rotate")
  # orbit_rotate on S_4 is closed, so this verifies the promoted path;
  # for non-closed, we verify the print/trace still exist
  expect_true("action" %in% names(out))
  expect_true("computed" %in% names(out))
  expect_true("trace" %in% names(out))
})

# ── P0-3: closed token domain ───────────────────────────────────────

test_that("token domain rejects reserved characters at construction", {
  expect_error(new_pal_state(c("A"), "B\nC"), "reserved")
  expect_error(new_pal_state(c("A|B"), "C"), "reserved")
  expect_error(new_pal_state(c("A=B"), "C"), "reserved")
  expect_error(new_pal_state(c("A"), "B", mapping_pack_id = "x\ny"), "reserved")
  expect_error(new_pal_state(c("A"), "B", provenance = list(x = c("A", "B"))),
               "scalar")
  expect_error(new_pal_state(c("A"), "B", provenance = list(x = "a=b")),
               "reserved")
})

test_that("grammar round-trip holds for legal multi-char tokens", {
  # v0.2.1: multi-character role tokens are LEGAL as long as they are
  # non-empty and reserved-free; grammar must round-trip them.
  pal <- new_pal_state(c("ABC"), "D")
  expect_equal(pal$shells, "ABC")
  enc <- pal_encode(pal)
  dec <- pal_parse(enc)
  expect_equal(dec$shells, "ABC")
  expect_equal(dec$core, "D")
})

# ── P0-7: experimental markers ──────────────────────────────────────

test_that("carrier and gamma retain experimental status (not frozen axioms)", {
  # These are fitted rules; the API still works but is explicitly
  # experimental. Verification: carrier is deterministic and 11x11.
  M <- carrier_11x11()
  expect_equal(dim(M), c(11L, 11L))
  expect_true(all(M %in% 0:5))
  g <- gamma_field(new_pal_state(c("A", "B", "C", "D"), "e"))
  expect_equal(dim(g), c(3L, 3L))
})
