\name{new_recursion}
\alias{new_recursion}
\alias{recursion_depth}
\alias{simple_recurse}
\alias{simple_unrecurse}
\alias{freeze_layer}
\alias{complex_recurse}
\alias{interactive_step_up}
\alias{interactive_step_down}
\alias{nested_recurse}
\alias{recursion_stack}
\title{Recursive re-typing: four recursion families (B branch)}
\usage{
new_recursion(pals)

recursion_depth(rc)

simple_recurse(pal, r = 1L)

simple_unrecurse(rc)

freeze_layer(rc, at_depth = NULL)

complex_recurse(pal)

interactive_step_up(rc, op = "identity")

interactive_step_down(rc)

nested_recurse(rc, r = 1L)

recursion_stack(rc)
}
\arguments{
  \item{pals}{List of \code{visualr_pal} objects, base layer first.}
  \item{rc}{A \code{visualr_recursion} object.}
  \item{pal}{A \code{visualr_pal} object (base state, layer 0).}
  \item{r}{Integer; number of re-typing repetitions (>= 0).}
  \item{at_depth}{Integer; which layer to freeze (default: top).}
  \item{op}{Single character, operator name (reserved; default
    "identity").}
}
\value{
  \code{new_recursion} returns a \code{visualr_recursion} object
  (layers, depth). \code{recursion_depth} returns integer depth.
  \code{simple_recurse} / \code{complex_recurse} /
  \code{nested_recurse} return a \code{visualr_recursion}.
  \code{simple_unrecurse} returns a \code{visualr_recursion} with depth
  reduced by one. \code{freeze_layer} returns canonical PAL text.
  \code{interactive_step_up} / \code{interactive_step_down} return a
  trace list with the new recursion. \code{recursion_stack} returns a
  character vector of canonical PAL texts, base first.
}
\description{
  Recursive re-typing implementing the frozen definition
  \code{R: S4^[r] -> S0^[r+1]<S4^[r]>}: each re-type wraps the inner
  topology as an atomic whole (a deterministic sha256 digest token, so
  the identity is verifiable and token-domain safe). Four families are
  provided and tested in separate files:

  \enumerate{
    \item \strong{simple} — same-operator re-typing repeated r times
      (\code{simple_recurse} / \code{simple_unrecurse} /
      \code{freeze_layer}).
    \item \strong{complex} — mixed re-typing over a peel chain, every
      level's topology preserved (\code{complex_recurse}).
    \item \strong{interactive} — user-driven step up/down with trace
      (\code{interactive_step_up} / \code{interactive_step_down}).
    \item \strong{nested} — recursion inside recursion, depth query
      (\code{nested_recurse} / \code{recursion_stack}).
  }

  Java interface note (user decision 2026-08-08): this R file is the
  reference semantics for the future Java port. Function names and
  argument contracts here are the stable ABI the Java layer must
  mirror.
}
\examples{
p <- new_pal_state(c("A", "B", "C", "D"), "e")
rc <- simple_recurse(p, 2L)
recursion_depth(rc)      # 3
recursion_stack(rc)
freeze_layer(rc, 0L)     # canonical PAL of base layer
}
