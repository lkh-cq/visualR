# Deterministic property matrix for v0.6.2 spectral observations.
# Shapes deliberately cover odd, even, rectangular, singleton and complex
# inputs. This is a finite contract matrix, not randomized proof.

.spectral_property_cases <- function() {
  list(
    odd_real = matrix(sin(seq_len(15L)) + seq_len(15L) / 10, 3L, 5L),
    even_real = matrix(cos(seq_len(8L)) - seq_len(8L) / 7, 2L, 4L),
    singleton = matrix(-3.25, 1L, 1L),
    row_singleton = matrix(c(2, -1, 4, 0), 1L, 4L),
    complex = matrix(seq_len(6L) + 1i * rev(seq_len(6L)), 3L, 2L)
  )
}

test_that("unitary carrier FFT properties hold across declared shapes", {
  for (case_name in names(.spectral_property_cases())) {
    x <- .spectral_property_cases()[[case_name]]
    field <- new_numeric_field(x, value_semantics = case_name,
                               boundary_state = "closed")
    plan <- compile_spectral_plan(field, "carrier", "finite_window")
    spectrum <- execute_spectral_plan(field, plan)
    reconstructed <- inverse_spectral(spectrum)

    expect_identical(plan$shape, as.integer(dim(x)), info = case_name)
    expect_equal(reconstructed$value, as.complex(as.vector(x)),
                 tolerance = 1e-11,
                 info = case_name)
    expect_equal(sum(spectrum$energy), sum(Mod(x)^2), tolerance = 1e-11,
                 info = case_name)
  }
})

test_that("finite-window path FFT round-trips without boundary invention", {
  field <- new_numeric_field(
    .numeric_window_fixture(),
    c(0.5, -1, 2.5, 4, -0.25),
    "open finite path"
  )
  plan <- compile_spectral_plan(field, "path", "finite_window")
  spectrum <- execute_spectral_plan(field, plan)
  reconstructed <- inverse_spectral(spectrum)

  expect_identical(plan$completeness, "window_only")
  expect_identical(plan$boundary_policy, "finite_window")
  expect_equal(reconstructed$value, as.complex(field$value),
               tolerance = 1e-11)
  expect_equal(sum(spectrum$energy), sum(field$value^2), tolerance = 1e-11)
})

test_that("closed periodic plan is explicit and remains reversible", {
  field <- new_numeric_field(matrix(seq_len(12L), 3L, 4L),
                             value_semantics = "periodic fixture",
                             boundary_state = "closed")
  plan <- compile_spectral_plan(field, "carrier", "periodic")
  reconstructed <- inverse_spectral(execute_spectral_plan(field, plan))

  expect_identical(plan$boundary_policy, "periodic")
  expect_equal(reconstructed$value, as.complex(field$value),
               tolerance = 1e-11)
})
