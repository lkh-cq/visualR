# Test: StateStore — versioned state storage + event log (C branch)
# v0.5.0 engineering foundation (SQLite via RSQLite/DBI, Suggests).
# All tests skip when RSQLite is unavailable.

skip_if_not_installed("RSQLite")
skip_if_not_installed("DBI")

new_store <- function() {
  state_store(tempfile(fileext = ".sqlite"))
}

test_that("state_store opens and reports empty schema", {
  st <- new_store()
  on.exit(state_store_close(st))
  expect_s3_class(st, "visualr_state_store")
  expect_true(DBI::dbIsValid(st$con))
  # print method should not error
  expect_output(print(st), "visualr_state_store")
})

test_that("state_store_write + read round-trips (S1..S5)", {
  st <- new_store()
  on.exit(state_store_close(st))
  for (d in list(
    list(shells = character(0), core = "A"),
    list(shells = "A", core = "b"),
    list(shells = c("A", "B"), core = "c"),
    list(shells = c("A", "B", "C", "D"), core = "e"),
    list(shells = c("A", "B", "C", "D", "E"), core = "f")
  )) {
    p <- new_pal_state(d$shells, d$core)
    state_store_write(st, p)
    p2 <- state_store_read(st, p)
    expect_identical(format_pal(p), format_pal(p2),
                     info = paste(d$shells, collapse = ","))
  }
})

test_that("state_store_write accepts PAL strings", {
  st <- new_store()
  on.exit(state_store_close(st))
  state_store_write(st, "{A{B{C{D{e}D}C}B}A}")
  p2 <- state_store_read(st, "{A{B{C{D{e}D}C}B}A}")
  expect_identical(format_pal(p2), format_pal(pal_parse("{A{B{C{D{e}D}C}B}A}")))
})

test_that("state_store versioning: multiple versions per state_id", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p, version = 1L)
  state_store_write(st, p, version = 2L, payload = list(round = 2))
  lst <- state_store_list(st)
  expect_equal(nrow(lst), 1L)
  expect_equal(lst$max_version[1], 2L)
})

test_that("state_store_write duplicate version fails closed", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p, version = 1L)
  expect_error(state_store_write(st, p, version = 1L), "already exists")
  # overwrite=TRUE succeeds
  state_store_write(st, p, version = 1L, overwrite = TRUE)
})

test_that("state_store_read fails closed on missing version", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p, version = 1L)
  expect_error(state_store_read(st, p, version = 9L), "No state found")
})

test_that("state_store tamper detection fails closed", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p)
  # Tamper: rewrite the stored pal text WITHOUT updating checksum.
  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = st$path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  DBI::dbExecute(con, "UPDATE states SET pal = ? WHERE version = 1",
                 params = list("{A{B{C{D{X}D}C}B}A}"))
  # Reading the ORIGINAL state_id now hits the tampered row: the row
  # exists but its checksum no longer matches the tampered pal text.
  expect_error(state_store_read(st, p), "checksum mismatch")
})

test_that("state_store_events records write/read and custom events", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p)
  state_store_read(st, p)
  state_store_event(st, "note", detail = "hello")
  ev <- state_store_events(st)
  expect_true(nrow(ev) >= 3L)
  expect_true(all(c("seq", "ts", "kind", "state_id", "detail") %in% names(ev)))
  kinds <- ev$kind
  expect_true("state_write" %in% kinds)
  expect_true("state_read" %in% kinds)
  expect_true("note" %in% kinds)
})

test_that("state_store_events filters by kind", {
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p)
  state_store_event(st, "note", detail = "x")
  writes <- state_store_events(st, kind = "state_write")
  notes <- state_store_events(st, kind = "note")
  expect_true(nrow(writes) >= 1L)
  expect_equal(nrow(notes), 1L)
})

test_that("state_store can be closed and re-opened from path", {
  tf <- tempfile(fileext = ".sqlite")
  st <- state_store(tf)
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p)
  state_store_close(st)
  expect_false(DBI::dbIsValid(st$con))
  # Re-open and read back
  st2 <- state_store(tf)
  on.exit(state_store_close(st2))
  p2 <- state_store_read(st2, p)
  expect_identical(format_pal(p), format_pal(p2))
})

test_that("state_store rejects bad input", {
  expect_error(state_store(""), "non-empty character")
  expect_error(state_store(NULL), "non-empty character")
  st <- new_store()
  on.exit(state_store_close(st))
  p <- new_pal_state(c("A", "B", "C", "D"), "e")
  state_store_write(st, p)
  expect_error(state_store_read(st, 42), "visualr_pal or PAL string")
  expect_error(state_store_event(st, ""), "non-empty character")
})
