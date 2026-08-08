\name{package_state}
\alias{package_state}
\alias{unpack_state}
\alias{package_checksum}
\alias{package_reload_check}
\title{Package a canonical PAL state into a transport unit (G4)}
\usage{
package_state(x, payload = NULL)

unpack_state(pkg, verify_integrity = TRUE)

package_checksum(body)

package_reload_check(pkg, rscript = file.path(R.home("bin"), "Rscript"),
                     timeout = 30)
}
\arguments{
  \item{x}{A \code{visualr_pal} object, or a single canonical PAL string
    (either palindrome grammar such as \code{{A{B{C{D{e}D}C}B}A}} or the
    serialized \code{format_pal} text).}
  \item{payload}{Optional list of compute-state metadata to carry.}
  \item{pkg}{A \code{visualr_package} object (as produced by
    \code{package_state}), or a list with the same contract fields.}
  \item{verify_integrity}{Logical; recompute and compare the checksum
    (default TRUE). Set FALSE only for debugging.}
  \item{body}{List; the package body WITHOUT the checksum field.}
  \item{rscript}{Character; path to Rscript (default from \code{R.home}).}
  \item{timeout}{Numeric; seconds to wait for the subprocess.}
}
\value{
  \code{package_state} returns a \code{visualr_package} list with fields
  format, version, pal, mapping_pack (id/version/hash), payload,
  provenance, checksum, and optionally \verb{_source_root} (dev hint).

  \code{unpack_state} returns the reconstructed \code{visualr_pal}.

  \code{package_checksum} returns a single character sha256 hex digest
  (md5 fallback when openssl is unavailable).

  \code{package_reload_check} returns TRUE if a fresh R process
  reproduced the canonical PAL state, FALSE otherwise.
}
\description{
  v0.5.0 closed-loop packaging (DEVELOPMENT_PLAN section 7 / packaging
  gate). \code{package_state} wraps a canonical PAL state into the
  visualR package contract: format header, canonical state, resolved
  mapping-pack identity, provenance, payload, and an integrity checksum.
  \code{unpack_state} verifies the contract (fail-closed on unknown
  format/version/checksum/pack) and reconstructs the pal.
  \code{package_reload_check} serializes the package, reloads it in a
  fresh R subprocess, and confirms the canonical PAL string reproduces —
  the "reload without preserving expanded working state" acceptance
  test.
}
\examples{
p <- new_pal_state(c("A", "B", "C", "D"), "e")
pkg <- package_state(p)
p2 <- unpack_state(pkg)
identical(format_pal(p), format_pal(p2))  # TRUE
}
