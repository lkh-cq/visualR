\name{demo_full_loop}
\alias{demo_full_loop}
\title{Run the full closed-loop demo (benchmark prototype)}
\usage{
demo_full_loop(state = NULL, op = "identity")
}
\arguments{
  \item{state}{List with \code{shells} and \code{core} (default S4).
    Pass NULL to run the canonical S4 example.}
  \item{op}{Single character, operator name passed to
    \code{compute_jiugong} (default "identity").}
}
\value{
  Invisible named list with fields: pal, matrix, verdict, folded, pkg,
  reload_ok. All reproducible.
}
\description{
  One-command proof of the complete visualR loop: canonical PAL state ->
  materialize -> compute -> closure decision -> fold back -> package ->
  reload in a fresh process -> reproduce the same canonical state.
  Prints every step. This is the benchmark-prototype entry point
  (user decision 2026-08-08: R-only baseline; Java is the future
  implementation language).
}
\examples{
demo_full_loop()
}
