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
\code{effective_mode} ("multicore" | "psock" | "serial").
}
\description{
Reports the effective concurrency mode for \code{batch_compute} on
the current platform (v0.4.x "explicit worker/fallback reporting"
companion, DEVELOPMENT_PLAN_v0.5.0.md §6):
\itemize{
  \item Unix + multiple cores: "multicore" (fork / mclapply).
  \item Windows + multiple cores: "psock" (PSOCK cluster, true
    parallelism -- added in v0.4.x; previously serial-only).
  \item Single core: "serial".
}
The requested engine is never silently degraded; the actual execution
path is always reported.
}
\examples{
concurrency_health()
}