#ifndef VISUALR_H
#define VISUALR_H

#include <Rinternals.h>

SEXP C_visualr_compile_taps(SEXP width, SEXP levels, SEXP kernel_offsets,
                           SEXP convolutions_per_level);

#endif
