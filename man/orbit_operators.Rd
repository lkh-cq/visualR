\name{lane_kernel_register}
\alias{lane_kernel_register}
\alias{lane_kernel_get}
\alias{lane_kernel_list}
\alias{kernel_identity}
\alias{kernel_complement}
\alias{kernel_mirror}
\alias{kernel_rotate}
\alias{kernel_gamma}
\alias{lane_kernels}
\alias{execute_lanes_ops}
\title{Orbit operators — lane kernels for the Topology Operator ABI}
\usage{
lane_kernel_register(name, fn, overwrite = FALSE)

lane_kernel_get(name)

lane_kernel_list()

kernel_identity(orbit, phase = "idle", pack = NULL)

kernel_complement(orbit, phase = "idle", pack = NULL)

kernel_mirror(orbit, phase = "idle", pack = NULL)

kernel_rotate(orbit, phase = "idle", pack = NULL)

kernel_gamma(orbit, phase = "idle", pack = NULL)

lane_kernels(spec)

execute_lanes_ops(snap, kernels = NULL, pack = NULL)
}
\arguments{
  \item{name}{Single character; lane kernel name.}
  \item{fn}{Function with signature \code{(orbit, phase, pack)}.}
  \item{overwrite}{Logical; allow replacing a built-in kernel.}
  \item{orbit}{Character vector of two endpoints (head, tail), or the
    singularity token for the singleton lane.}
  \item{phase}{Current phase label.}
  \item{pack}{Mapping pack (rules source; NULL allowed for builtins
    with frozen rules).}
  \item{spec}{Character (one kernel for all lanes) or named list with
    names A/B/C/D/e.}
  \item{snap}{A \code{visualr_snapshot} object.}
  \item{kernels}{Named list of kernel functions, or a kernel-name spec
    accepted by \code{lane_kernels()} (default: all identity).}
}
\value{
  \code{lane_kernel_register} returns TRUE; \code{lane_kernel_get}
  returns the kernel function; \code{lane_kernel_list} returns kernel
  names; each \code{kernel_*} returns \code{list(result, phase, action)};
  \code{lane_kernels} returns a named list of kernel functions;
  \code{execute_lanes_ops} returns the named list of lane results.
}
\description{
  Concrete lane kernels for the Topology Operator ABI v0.1, replacing
  the identity placeholder. Each kernel has signature
  \code{(orbit, phase, pack)} — orbit is the endpoint pair or the
  singularity token; pack carries the mapping-pack rules (P0-1: rules
  come from the pack, never globals).

  Frozen-spec mapping:
  \itemize{
    \item \strong{identity} — no change (baseline lane).
    \item \strong{complement} — self-mirror involution C^2 = I
      (A<->D, B<->C, e->e).
    \item \strong{mirror} — swap head<->tail endpoints (orientation
      flip; palindrome orbits unchanged).
    \item \strong{rotate} — orbit-table rotation A->B->C->D->A.
    \item \strong{gamma} — local field step: lower order
      A->B->C->D->e (clamped at e).
  }

  R is the operator language; these kernels are the reference
  semantics for the C/Java execution fabrics.
}
\examples{
p <- new_pal_state(c("A", "B", "C", "D"), "e")
snap <- snapshot(new_topology_carrier(p))
d <- execute_lanes_ops(snap, "complement")
d$A$result  # c("D", "D")
d2 <- execute_lanes_ops(snap, list(A = "gamma", B = "rotate",
                                   C = "mirror", D = "identity",
                                   e = "identity"))
}
