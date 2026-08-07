\name{pal_compact}
\alias{pal_compact}
\title{Resident compact representation of a pal state}
\usage{
pal_compact(pal)
}
\arguments{
  \item{pal}{A \code{visualr_pal} object.}
}
\value{
Single character, the compact serialized form (identical to
\code{format_pal}).
}
\description{
Returns the compact serialized string for a \code{visualr_pal} — the
recommended RESIDENT form for memory / transport efficiency
(v0.4.x A1). The S3 pal object carries list+class overhead that makes
it larger than the materialized matrix; the compact string stays small
and can be restored on demand with \code{parse_pal}.

Recommended resident workflow: keep \code{pal_compact()} strings in
memory / transit; materialize to pal state (\code{parse_pal}) or matrix
(\code{materialize}) only when an operator needs a compute view
("store less / expand less / move less", DEVELOPMENT_PLAN G1/G2).
}
\examples{
pal_compact(new_pal_state(c("A","B","C","D"), "e"))
}