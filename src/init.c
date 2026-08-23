#include "visualr.h"

#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

static const R_CallMethodDef call_methods[] = {
  {"C_visualr_compile_taps", (DL_FUNC) &C_visualr_compile_taps, 4},
  {NULL, NULL, 0}
};

void attribute_visible R_init_visualR(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, FALSE);
}
