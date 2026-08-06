# Test file: palindrome grammar (pal_parse / pal_encode)
# Ported from mapping_pack.py parse_palindrome / encode_palindrome.
# Cross-verified against Python reference output.

test_that("pal_parse parses S_4 grammar", {
  pal <- pal_parse("{A{B{C{D{e}D}C}B}A}")
  expect_equal(pal$shells, c("A", "B", "C", "D"))
  expect_equal(pal$core, "e")
})

test_that("pal_parse S_0 (single center)", {
  pal <- pal_parse("{X}")
  expect_equal(pal$shells, character(0))
  expect_equal(pal$core, "X")
})

test_that("pal_parse S_1", {
  pal <- pal_parse("{A{B}A}")
  expect_equal(pal$shells, "A")
  expect_equal(pal$core, "B")
})

test_that("pal_parse rejects text without braces", {
  expect_error(pal_parse("A{B{C{D{e}D}C}B}A"), "wrapped in")
})

test_that("pal_parse rejects asymmetric grammar", {
  # {A{B}C} — C does not match A's symmetry
  expect_error(pal_parse("{A{B}C}"))
})

test_that("pal_parse rejects empty node", {
  expect_error(pal_parse("{{}A}"))
})

test_that("pal_encode S_4 round-trips", {
  pal <- new_pal_state(c("A", "B", "C", "D"), "e")
  expect_equal(pal_encode(pal), "{A{B{C{D{e}D}C}B}A}")
})

test_that("pal_encode S_0", {
  pal <- new_pal_state(character(0), "X")
  expect_equal(pal_encode(pal), "{X}")
})

test_that("pal_encode S_1", {
  pal <- new_pal_state("A", "B")
  expect_equal(pal_encode(pal), "{A{B}A}")
})

test_that("grammar bijection: parse(encode(S)) == S", {
  for (pal in list(
    new_pal_state(character(0), "X"),
    new_pal_state("A", "B"),
    new_pal_state(c("A", "B"), "C"),
    new_pal_state(c("A", "B", "C", "D"), "e")
  )) {
    text <- pal_encode(pal)
    back <- pal_parse(text)
    expect_equal(back$shells, pal$shells)
    expect_equal(back$core, pal$core)
  }
})

test_that("grammar bijection: encode(parse(text)) == text (canonical)", {
  texts <- c("{X}", "{A{B}A}", "{A{B{C}B}A}", "{A{B{C{D{e}D}C}B}A}")
  for (t in texts) {
    pal <- pal_parse(t)
    expect_equal(pal_encode(pal), t)
  }
})

test_that("grammar preserves metadata", {
  pal <- pal_parse("{A{B{C{D{e}D}C}B}A}",
                   mapping_pack_id = "custom-v0.2",
                   provenance = list(clock = 42L))
  expect_equal(pal$mapping_pack_id, "custom-v0.2")
  expect_equal(pal$provenance, list(clock = 42L))
})

test_that("grammar cross-verified with Python output", {
  # Python: parse("{A{B{C{D{e}D}C}B}A}") -> ['A','B','C','D','e','D','C','B','A']
  pal <- pal_parse("{A{B{C{D{e}D}C}B}A}")
  expect_equal(c(pal$shells, pal$core, rev(pal$shells)),
               c("A", "B", "C", "D", "e", "D", "C", "B", "A"))
})

test_that("grammar is compatible with fold/unfold", {
  # pal_parse(text) should equal fold_pal(parse_palindrome(text))
  text <- "{A{B{C{D{e}D}C}B}A}"
  from_grammar <- pal_parse(text)
  from_unfold <- fold_pal(c("A", "B", "C", "D", "e", "D", "C", "B", "A"))
  expect_equal(from_grammar$shells, from_unfold$shells)
  expect_equal(from_grammar$core, from_unfold$core)
})
