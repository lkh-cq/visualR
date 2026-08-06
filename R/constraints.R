validate_visualr <- function(x) {
  validate_pal(x)

  list(
    pal_valid = TRUE,
    unfolded_length = length(unfold_pal(x)),
    jiugong_valid = length(unfold_pal(x)) == 9L
  )
}
