\name{benchmark_storage}
\alias{benchmark_storage}
\title{Benchmark compact vs expanded storage bytes}
\usage{
benchmark_storage()
}
\value{
Data.frame with columns: \code{dim} (S1..S5), \code{pal_bytes}
(compact PAL serialization content bytes), \code{matrix_bytes}
(serialized materialized matrix),
\code{cells} (grid cell count; NA for non-carrier states),
\code{reduction} (\code{matrix_bytes / pal_bytes}).
\code{reduction >= 1} means PAL is more compact than the matrix.
}
\description{
Reproducible measurement of stored/transport bytes for the compact PAL
representation vs the expanded materialized matrix across representative
dimensions S_1..S_5. This is the v0.4.x Efficiency-gate measurement
harness (DEVELOPMENT_PLAN_v0.5.0.md §10).

PAL serialization is the transport unit (G1 "store less / move less");
the matrix is an on-demand working view (\code{materialize}), not
resident. The high-dimension S_5 case uses the 11x11 carrier (121 cells)
where PAL's O(n) advantage over the O(n^2) matrix is most pronounced.

Note: this measures TRANSPORT/PERSISTENCE bytes. Reduction ratios are
the portable claim; absolute byte counts are R-version/platform-specific
(serialization header version). This does NOT claim an R object-memory
advantage -- the S3 pal object carries list+class overhead.
}
\examples{
benchmark_storage()
}