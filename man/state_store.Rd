\name{state_store}
\alias{state_store}
\alias{state_store_close}
\alias{state_store_write}
\alias{state_store_read}
\alias{state_store_event}
\alias{state_store_events}
\alias{state_store_list}
\title{Versioned state store with append-only event log (SQLite)}
\usage{
state_store(path, auto_connect = TRUE)

state_store_close(store)

state_store_write(store, pal, version = 1L, payload = NULL,
                  overwrite = FALSE)

state_store_read(store, pal, version = 1L, check = TRUE)

state_store_event(store, kind, state_id = NULL, detail = NULL)

state_store_events(store, kind = NULL, limit = 1000L)

state_store_list(store)
}
\arguments{
  \item{path}{Single character; filesystem path to the SQLite store file
    (parent directory must exist).}
  \item{auto_connect}{Logical; if TRUE (default) the DBI connection is
    opened immediately.}
  \item{store}{A \code{visualr_state_store} object.}
  \item{pal}{A \code{visualr_pal} object, or a single canonical PAL
    string (palindrome grammar or serialized text).}
  \item{version}{Integer; the record version (default 1L).}
  \item{payload}{Optional list; carried as canonical text in the state
    record (informational provenance).}
  \item{overwrite}{Logical; allow replacing an existing version
    (default FALSE; duplicates fail closed).}
  \item{check}{Logical; verify the checksum on read (default TRUE).}
  \item{kind}{Single character; event kind for
    \code{state_store_event} / filter for \code{state_store_events}.}
  \item{state_id}{Optional single character; related state id for an
    event.}
  \item{detail}{Optional single character; free-form event detail.}
  \item{limit}{Integer; max rows returned by \code{state_store_events}
    (default 1000).}
}
\value{
  \code{state_store} returns a \code{visualr_state_store} object (path,
  con). \code{state_store_close} returns invisible TRUE.
  \code{state_store_write} returns the state checksum (invisible).
  \code{state_store_read} returns the reconstructed \code{visualr_pal}.
  \code{state_store_event} returns the event sequence number.
  \code{state_store_events} returns a data.frame (seq, ts, kind,
  state_id, detail). \code{state_store_list} returns a data.frame
  (state_id, max_version).
}
\description{
  SQLite-backed versioned storage for canonical PAL states with an
  append-only event log (v0.5.0 C-branch engineering foundation; the
  reference semantics for the future Java port). Every write records a
  state_write event; every read records a state_read event and verifies
  the state checksum (fail-closed on tamper/mismatch). State id is the
  canonical PAL text; versions are monotone per state id. Requires
  RSQLite and DBI (Suggests); fails closed if unavailable.
}
\examples{
st <- state_store(tempfile(fileext = ".sqlite"))
p <- new_pal_state(c("A", "B", "C", "D"), "e")
state_store_write(st, p)
p2 <- state_store_read(st, p)
identical(format_pal(p), format_pal(p2))  # TRUE
state_store_event(st, "note", detail = "hello")
state_store_events(st)
state_store_close(st)
}
