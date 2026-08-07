\name{concurrency_health}
\alias{concurrency_health}
\title{Concurrency health check (fork availability)}
\usage{
concurrency_health()
}
\value{
List with fields: \code{platform} (OS type), \code{fork_supported}
(logical), \code{detect_cores} (total cores),
\code{recommended_cores} (cores batch_compute should use),
\code{effective_mode} ("multicore" | "serial").
}
\description{
Reports whether the current platform supports true multi-core
execution via fork (mclapply), or must fall back to serial. This is
the v0.4.x "explicit worker/fallback reporting" companion to
\code{batch_compute} (DEVELOPMENT_PLAN_v0.5.0.md §6).

On Windows, fork is unavailable, so \code{batch_compute} silently
falls back to serial (reported via its \code{fallback} field); this
function surfaces that decision up front.
}
\examples{
concurrency_health()
}