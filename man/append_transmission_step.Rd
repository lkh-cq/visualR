\name{append_transmission_step}
\alias{append_transmission_step}
\title{Append a graded step to a TransmissionPath}
\usage{
append_transmission_step(path, from, to, grade, logical_time,
                         boundary_event = NULL, regulation_event = NULL)
}
\arguments{
  \item{path}{A \code{visualr_transmission_path}.}
  \item{from}{A \code{visualr_position_state}: must equal the current path
    head.}
  \item{to}{A \code{visualr_position_state}: the step destination.}
  \item{grade}{Single character, one of \code{T1}/\code{T2}/\code{T3}/
    \code{T4}.}
  \item{logical_time}{Single non-negative integer round tag.}
  \item{boundary_event}{Optional annotation; defaults to NULL.}
  \item{regulation_event}{Optional regulation annotation; defaults to NULL.}
}
\value{
  A new \code{visualr_transmission_path} with the appended step. The input
  \code{path} is never mutated.
}
\description{
  \code{append_transmission_step} extends an immutable path by one graded
  hop. It validates the \code{from}/\code{to} positions and the grade flag,
  and refuses the append if \code{from} is not the current head. The result
  is a fresh path; the original object is untouched.
}
\details{
  Grades T1-T4 mark hop classes. A step is a named list with \code{from},
  \code{to}, \code{grade}, \code{logical_time} and optional boundary and
  regulation events. History is preserved by construction: positions and
  steps are copied, never overwritten.
}
\examples{
p0 <- new_position_state(c("/a", "/ab"), c(0,0), "grid")
p1 <- new_position_state(c("/b", "/bb"), c(1,0), "grid")
path <- new_transmission_path("m1", p0)
path <- append_transmission_step(path, p0, p1, "T1", 1L)
path_length_steps(path)
}