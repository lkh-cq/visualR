# Test file: complete/open PAL window state (v0.6.1 experimental)

test_that("deepen_solution installs only an explicit next core", {
  s1 <- pal_parse("{A{B}A}")
  s2 <- pal_parse("{A{B{C}B}A}")
  s3 <- pal_parse("{A{B{C{D}C}B}A}")

  expect_equal(pal_encode(deepen_solution(s1, "c")), "{A{B{c}B}A}")
  expect_equal(pal_encode(deepen_solution(s2, "d")),
               "{A{B{C{d}C}B}A}")
  expect_equal(pal_encode(deepen_solution(s3, "e")),
               "{A{B{C{D{e}D}C}B}A}")
  expect_equal(deepen_solution(s3, "e")$mapping_pack_id,
               s1$mapping_pack_id)
})

test_that("open-window syntax is a reversible boundary wrapper", {
  text <- "}{B{C{D}C}B}{"
  w <- open_window_parse(
    text,
    origin = 10L,
    outer_ref = list(left = "solution:left", right = "solution:right")
  )

  expect_s3_class(w, "visualr_pal_window")
  expect_equal(w$boundary, "open")
  expect_equal(open_window_encode(w), text)
  expect_equal(w$path, c("B", "C", "D", "C", "B"))
  expect_equal(w$addresses$local_offset, -2:2)
  expect_equal(w$addresses$global_address, 8:12)
  expect_equal(w$addresses$token, w$path)
})

test_that("fixed-radius open window shifts without inventing outer content", {
  w1 <- open_window_parse(
    "}{B{C{D}C}B}{",
    origin = 10L,
    outer_ref = list(left = "outer:L", right = "outer:R")
  )
  w2 <- shift_open_window(w1, "E")
  w3 <- shift_open_window(w2, "F")

  expect_equal(open_window_encode(w2), "}{C{D{E}D}C}{")
  expect_equal(open_window_encode(w3), "}{D{E{F}E}D}{")
  expect_equal(c(w1$origin, w2$origin, w3$origin), c(10L, 11L, 12L))
  expect_equal(w2$radius, w1$radius)
  expect_identical(w3$outer_ref, w1$outer_ref)
  expect_length(w3$trace, 2L)
  expect_equal(w2$trace[[1L]]$evicted_left, "B")
  expect_equal(w2$trace[[1L]]$introduced_core, "E")
  expect_equal(w2$trace[[1L]]$address_transition$relation,
               c("retained", "retained", "introduced",
                 "mirrored", "mirrored"))
  expect_equal(w2$trace[[1L]]$address_transition$source_global,
               c(9L, 10L, NA_integer_, 10L, 9L))
})

test_that("single-core open windows retain fixed width on shift", {
  w <- open_window_parse("}{D}{", origin = -2L)
  shifted <- shift_open_window(w, "E")

  expect_equal(open_window_encode(shifted), "}{E}{")
  expect_equal(shifted$width, 1L)
  expect_equal(shifted$origin, -1L)
})

test_that("closed and open boundary states fail closed on misuse", {
  p <- pal_parse("{A{B}A}")
  closed <- new_pal_window(p)

  expect_error(open_window_encode(closed), "boundary = 'open'")
  expect_error(shift_open_window(closed, "C"), "boundary = 'open'")
  expect_error(open_window_parse("{A{B}A}"), "Open-window syntax")
  expect_error(open_window_parse("}{A{B}C}{"), "symmetric symbol")
  expect_error(
    new_pal_window(
      p,
      boundary = "closed",
      outer_ref = list(left = "hidden", right = NA_character_)
    ),
    "closed window cannot bind"
  )
  expect_error(
    new_pal_window(p, boundary = "open", outer_ref = list(left = "x")),
    "exactly `left` and `right`"
  )
  expect_error(deepen_solution(p, "{illegal"), "reserved character")
})

test_that("PAL window print method is stable", {
  w <- open_window_parse("}{B{C{D}C}B}{")
  expect_invisible(print(w))
})
