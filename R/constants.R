# ── visualR frozen constants ─────────────────────────────────────────
# These constants define the v0.1 data contract.
# All values are frozen per audit ruling (2026-08-06).

# Default mapping pack identifier (R7: versioned string, not integer)
DEFAULT_MAPPING_PACK_ID <- "pal-jiugong-v0.1"

# Serialization format header
# v0.1 = deprecated eval(parse()) format (RCE vulnerable)
# v0.2 = length-prefixed records, pure string parser (2026-08-06)
FORMAT_HEADER <- "visualr_pal/v0.2"

# S3 class names
CLASS_PAL <- "visualr_pal"
CLASS_JIUGONG <- "visualr_jiugong"
CLASS_DIAMOND <- "visualr_diamond"

# Architecture note: rho+theta=1 is NOT verified in v0.1.
# It exists only as a conceptual mapping in inst/REFERENCES.md.
# v0.2 will introduce visualr_runtime_state with phase/singularity fields.
