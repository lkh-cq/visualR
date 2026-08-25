# ── Test fixtures for visualR ────────────────────────────────────────
# These fixtures call new_pal_state(), which does not exist yet (RED phase).
# This is intentional per TDD: write tests first, watch them fail.

# S_0: minimal palindrome — empty shells + core
pal_fixture_n0 <- function() {
  new_pal_state(shells = character(0), core = "X")
}

# S_1: 1 shell + core → unfold length 3
pal_fixture_n1 <- function() {
  new_pal_state(shells = c("A"), core = "B")
}

# S_2: 2 shells + core → unfold length 5 (non-perfect-square, valid per R1)
pal_fixture_n2 <- function() {
  new_pal_state(shells = c("A", "B"), core = "C")
}

# S_4: 4 shells + core → unfold length 9 = 3² (standard jiugong)
pal_fixture_n4 <- function() {
  new_pal_state(shells = c("A", "B", "C", "D"), core = "E")
}

# S_4 with custom metadata (for藏归分离 test U12)
pal_fixture_n4_custom <- function() {
  new_pal_state(
    shells = c("A", "B", "C", "D"), core = "E",
    mapping_pack_id = "custom-v0.2",
    provenance = list(clock = 42L, source = "test")
  )
}

# S_12: 12 shells + core → unfold length 25 = 5²
pal_fixture_n12 <- function() {
  new_pal_state(
    shells = c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"),
    core = "M"
  )
}

# Addressed open-window fixture shared by the v0.6.2 numeric tests.
.numeric_window_fixture <- function() {
  open_window_parse(
    "}{B{C{D}C}B}{",
    origin = 10L,
    outer_ref = list(left = "solution:L", right = "solution:R")
  )
}
