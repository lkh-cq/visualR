#include "visualr.h"

#include <R.h>
#include <limits.h>

#define VISUALR_MAX_SHELLS 64
#define VISUALR_MAX_LEVELS 30
#define VISUALR_MAX_CONVOLUTIONS 16
#define VISUALR_MAX_KERNEL_OFFSETS 31
#define VISUALR_MAX_COMPILED_TAPS 1000000

static int scalar_integer(SEXP x, const char *name) {
  if (TYPEOF(x) != INTSXP || XLENGTH(x) != 1 || INTEGER(x)[0] == NA_INTEGER) {
    error("`%s` must be one non-NA integer.", name);
  }
  return INTEGER(x)[0];
}

SEXP C_visualr_compile_taps(SEXP width_sexp, SEXP levels_sexp,
                           SEXP offsets_sexp, SEXP convolutions_sexp) {
  const int width = scalar_integer(width_sexp, "width");
  const int levels = scalar_integer(levels_sexp, "levels");
  const int convolutions = scalar_integer(convolutions_sexp,
                                          "convolutions_per_level");
  const R_xlen_t n_offsets = XLENGTH(offsets_sexp);

  if (width < 1 || width > 2 * VISUALR_MAX_SHELLS + 1 || width % 2 == 0) {
    error("`width` must be an odd integer in [1, 129].");
  }
  if (levels < 1 || levels > VISUALR_MAX_LEVELS) {
    error("`levels` must be an integer in [1, 30].");
  }
  if (convolutions < 1 || convolutions > VISUALR_MAX_CONVOLUTIONS) {
    error("`convolutions_per_level` must be an integer in [1, 16].");
  }
  if (TYPEOF(offsets_sexp) != INTSXP || n_offsets < 1 ||
      n_offsets > VISUALR_MAX_KERNEL_OFFSETS) {
    error("`kernel_offsets` must contain 1 to 31 integers.");
  }

  const int *offsets = INTEGER(offsets_sexp);
  for (R_xlen_t i = 0; i < n_offsets; ++i) {
    if (offsets[i] == NA_INTEGER || offsets[i] < -32768 ||
        offsets[i] > 32767) {
      error("`kernel_offsets` contains an invalid integer.");
    }
    for (R_xlen_t j = 0; j < i; ++j) {
      if (offsets[i] == offsets[j]) {
        error("`kernel_offsets` must be unique.");
      }
    }
  }

  const double row_count_double = (double) width * (double) levels *
    (double) convolutions * (double) n_offsets;
  if (row_count_double > VISUALR_MAX_COMPILED_TAPS) {
    error("Tap schedule exceeds VISUALR_MAX_COMPILED_TAPS.");
  }
  const int n_rows = (int) row_count_double;
  SEXP result = PROTECT(allocMatrix(INTSXP, n_rows, 9));
  int *out = INTEGER(result);
  int row = 0;
  int dilation = 1;

  for (int level = 1; level <= levels; ++level) {
    if (level > 1) {
      if (dilation > INT_MAX / 2) {
        UNPROTECT(1);
        error("Dilation exceeds the integer range.");
      }
      dilation *= 2;
    }
    for (int convolution = 1; convolution <= convolutions; ++convolution) {
      const int source_layer = (level - 1) * convolutions + convolution - 1;
      const int target_layer = source_layer + 1;
      for (int target_position = 1; target_position <= width;
           ++target_position) {
        for (R_xlen_t kernel = 0; kernel < n_offsets; ++kernel) {
          const long long source_long = (long long) target_position +
            (long long) offsets[kernel] * (long long) dilation;
          if (source_long < INT_MIN || source_long > INT_MAX) {
            UNPROTECT(1);
            error("Compiled source position exceeds the integer range.");
          }
          const int source_position = (int) source_long;
          const int scope = source_position < 1 ? -1 :
            (source_position > width ? 1 : 0);

          out[row + n_rows * 0] = level;
          out[row + n_rows * 1] = convolution;
          out[row + n_rows * 2] = source_layer;
          out[row + n_rows * 3] = target_layer;
          out[row + n_rows * 4] = dilation;
          out[row + n_rows * 5] = target_position;
          out[row + n_rows * 6] = offsets[kernel];
          out[row + n_rows * 7] = source_position;
          out[row + n_rows * 8] = scope;
          ++row;
        }
      }
    }
  }

  UNPROTECT(1);
  return result;
}
