# == StateStore: versioned state storage + event log (C branch) ======
# v0.5.0 engineering foundation (user decision 2026-08-08: branch C,
# SQLite StateStore; Java is the future implementation language, this R
# store is the reference semantics for that port).
#
# Design:
#   - SQLite via RSQLite/DBI (Suggests; fail-closed if unavailable).
#   - Two tables:
#       states   (state_id, version, pal TEXT, checksum TEXT,
#                 created_at TEXT, payload TEXT)  -- versioned records
#       events   (seq INTEGER PK AUTOINCREMENT, ts TEXT, kind TEXT,
#                 state_id TEXT, detail TEXT)     -- append-only log
#   - Every write records an event (event-sourced style). Every read
#     verifies the checksum (fail-closed on tamper/mismatch).
#   - state_id is the canonical PAL string; version is the record
#     version (monotone per state_id).
#   - All text is UTF-8; timestamps are ISO-8601 UTC.
#
# Contract (mirrors package_state): pal text is the canonical form,
# checksum is sha256 (openssl) with md5 fallback, provenance carried
# in payload.

#' @title Open (or create) a versioned state store
#' @description Opens a SQLite-backed StateStore at \code{path},
#'   creating the schema if the file does not exist. Fail-closed if
#'   RSQLite is unavailable.
#' @param path single character; filesystem path to the store file
#'   (must be writable; parent directory must exist).
#' @param auto_connect logical; if TRUE (default) the DBI connection is
#'   opened immediately and returned in the object.
#' @return an object of class \code{visualr_state_store} with fields:
#'   path, con (DBIConnection or NULL), dbname.
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' state_store_close(st)
state_store <- function(path, auto_connect = TRUE) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    stop("`path` must be a single non-empty character.", call. = FALSE)
  }
  if (!requireNamespace("RSQLite", quietly = TRUE)) {
    stop("StateStore requires RSQLite (Suggests). Install it or avoid ",
         "state-store functions.", call. = FALSE)
  }
  if (!requireNamespace("DBI", quietly = TRUE)) {
    stop("StateStore requires DBI (Suggests).", call. = FALSE)
  }
  dir <- dirname(path)
  if (dir != "." && !dir.exists(dir)) {
    stop(sprintf("Parent directory does not exist: %s", dir), call. = FALSE)
  }
  con <- NULL
  if (auto_connect) {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = path)
    schema_init(con)
  }
  structure(list(path = path, con = con, dbname = path),
            class = "visualr_state_store")
}

# Internal: create schema (idempotent).
schema_init <- function(con) {
  DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS states (
      state_id    TEXT NOT NULL,
      version     INTEGER NOT NULL,
      pal         TEXT NOT NULL,
      checksum    TEXT NOT NULL,
      created_at  TEXT NOT NULL,
      payload     TEXT,
      PRIMARY KEY (state_id, version)
    )")
  DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS events (
      seq       INTEGER PRIMARY KEY AUTOINCREMENT,
      ts        TEXT NOT NULL,
      kind      TEXT NOT NULL,
      state_id  TEXT,
      detail    TEXT
    )")
  invisible(con)
}

#' @title Close a state store connection
#' @description Closes the DBI connection if open. Idempotent.
#' @param store a \code{visualr_state_store} object.
#' @return invisible TRUE.
state_store_close <- function(store) {
  if (!inherits(store, "visualr_state_store")) {
    stop("`store` must be a visualr_state_store.", call. = FALSE)
  }
  if (!is.null(store$con) && DBI::dbIsValid(store$con)) {
    DBI::dbDisconnect(store$con)
    store$con <- NULL
  }
  invisible(TRUE)
}

# Internal: ensure an open connection; re-open from path if closed.
store_con <- function(store) {
  if (!is.null(store$con) && DBI::dbIsValid(store$con)) {
    return(store$con)
  }
  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = store$path)
  schema_init(con)
  store$con <- con
  con
}

#' @title Write a canonical state into the store (versioned)
#' @description Inserts a versioned record for the canonical state.
#'   Appends an event of kind "state_write". If the same
#'   (state_id, version) already exists, fail-closed unless
#'   \code{overwrite = TRUE}.
#' @param store a \code{visualr_state_store} object.
#' @param pal a \code{visualr_pal} object or canonical PAL string.
#' @param version integer; the record version (default 1L).
#' @param payload optional list; carried as JSON-ish text via
#'   \code{to_payload_text}.
#' @param overwrite logical; allow replacing an existing version
#'   (default FALSE).
#' @return the checksum of the written state (invisible).
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' state_store_write(st, new_pal_state(c("A","B","C","D"), "e"))
#' state_store_close(st)
state_store_write <- function(store, pal, version = 1L, payload = NULL,
                              overwrite = FALSE) {
  con <- store_con(store)
  if (inherits(pal, "visualr_pal")) {
    pal_obj <- pal
    pal_text <- format_pal(pal_obj)
  } else if (is.character(pal) && length(pal) == 1L) {
    pal_obj <- if (startsWith(trimws(pal), "{")) pal_parse(pal) else parse_pal(pal)
    pal_text <- format_pal(pal_obj)
  } else {
    stop("`pal` must be a visualr_pal object or a single PAL string.",
         call. = FALSE)
  }
  validate_pal(pal_obj)
  version <- as.integer(version)
  if (version < 1L) stop("`version` must be >= 1.", call. = FALSE)

  checksum <- checksum_of(pal_text, payload)
  payload_text <- to_payload_text(payload)
  now <- iso_now()

  exists <- DBI::dbGetQuery(
    con,
    "SELECT 1 FROM states WHERE state_id = ? AND version = ?",
    params = list(pal_text, version)
  )
  if (nrow(exists) > 0L && !overwrite) {
    stop(sprintf("state (version %d) already exists; pass overwrite=TRUE ",
                 version), call. = FALSE)
  }

  if (nrow(exists) > 0L && overwrite) {
    DBI::dbExecute(
      con,
      "UPDATE states SET pal = ?, checksum = ?, created_at = ?, payload = ?
       WHERE state_id = ? AND version = ?",
      params = list(pal_text, checksum, now, payload_text, pal_text, version)
    )
    DBI::dbExecute(
      con,
      "INSERT INTO events (ts, kind, state_id, detail) VALUES (?,?,?,?)",
      params = list(now, "state_overwrite", pal_text,
                    paste0("version=", version))
    )
  } else {
    DBI::dbExecute(
      con,
      "INSERT INTO states (state_id, version, pal, checksum, created_at, payload)
       VALUES (?,?,?,?,?,?)",
      params = list(pal_text, version, pal_text, checksum, now, payload_text)
    )
    DBI::dbExecute(
      con,
      "INSERT INTO events (ts, kind, state_id, detail) VALUES (?,?,?,?)",
      params = list(now, "state_write", pal_text,
                    paste0("version=", version))
    )
  }
  invisible(checksum)
}

# Internal: canonical checksum over pal text + payload TEXT.
# Uses the payload's canonical text form (to_payload_text), NOT the
# parsed list, so write/read are symmetric without needing a full
# payload round-trip parser.
checksum_of <- function(pal_text, payload = NULL) {
  checksum_of_text(pal_text, to_payload_text(payload))
}

# Internal: checksum over pal text + already-canonical payload text.
# Returns a PLAIN character (openssl::sha256 returns classed "hash"
# objects which break identical() against plain DB strings).
checksum_of_text <- function(pal_text, payload_text = "") {
  body <- list(format = "visualr-state",
               pal = pal_text,
               payload_text = payload_text %||% "")
  as.character(package_checksum(body))
}

# Internal: deterministic payload text (list -> "<k=v;...>").
to_payload_text <- function(payload) {
  if (is.null(payload) || length(payload) == 0L) return("")
  list_digest_flat(payload)
}

# Internal: ISO-8601 UTC timestamp.
iso_now <- function() {
  format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
}

#' @title Read a state version back from the store
#' @description Fetches the requested (state_id, version) record,
#'   verifies its checksum (fail-closed on mismatch), and returns the
#'   reconstructed \code{visualr_pal}. Appends a "state_read" event.
#' @param store a \code{visualr_state_store} object.
#' @param pal a \code{visualr_pal} object or canonical PAL string used
#'   to identify the state_id (its canonical PAL text).
#' @param version integer; version to read (default 1L).
#' @param check logical; verify checksum (default TRUE).
#' @return the \code{visualr_pal} object.
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' p <- new_pal_state(c("A","B","C","D"), "e")
#' state_store_write(st, p)
#' p2 <- state_store_read(st, p)
#' identical(format_pal(p), format_pal(p2))  # TRUE
state_store_read <- function(store, pal, version = 1L, check = TRUE) {
  con <- store_con(store)
  state_id <- if (inherits(pal, "visualr_pal")) format_pal(pal)
              else if (is.character(pal) && length(pal) == 1L) {
                # Normalize to canonical PAL text so `{...}` grammar and
                # serialized text both resolve to the same state_id.
                if (startsWith(trimws(pal), "{")) format_pal(pal_parse(pal))
                else pal
              }
              else stop("`pal` must be a visualr_pal or PAL string.",
                        call. = FALSE)
  version <- as.integer(version)
  row <- DBI::dbGetQuery(
    con,
    "SELECT pal, checksum, payload FROM states WHERE state_id = ? AND version = ?",
    params = list(state_id, version)
  )
  if (nrow(row) == 0L) {
    stop(sprintf("No state found for id=%s version=%d.", state_id, version),
         call. = FALSE)
  }
  if (check) {
    # Recompute over pal text + stored payload TEXT (symmetric with
    # write; no parsed round-trip needed).
    expected <- checksum_of_text(row$pal[1], row$payload[1])
    if (!identical(expected, row$checksum[1])) {
      stop(sprintf("State checksum mismatch (fail closed): stored=%s computed=%s",
                   row$checksum[1], expected), call. = FALSE)
    }
  }
  DBI::dbExecute(
    con,
    "INSERT INTO events (ts, kind, state_id, detail) VALUES (?,?,?,?)",
    params = list(iso_now(), "state_read", state_id,
                  paste0("version=", version))
  )
  pal_obj <- if (startsWith(trimws(row$pal[1]), "{")) pal_parse(row$pal[1])
             else parse_pal(row$pal[1])
  validate_pal(pal_obj)
  pal_obj
}

#' @title Append a custom event to the store log
#' @description Appends an event record to the append-only log.
#' @param store a \code{visualr_state_store} object.
#' @param kind single character; event kind (e.g. "note", "compute").
#' @param state_id optional single character; related state id.
#' @param detail optional single character; free-form detail.
#' @return the event sequence number (invisible).
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' state_store_event(st, "note", detail = "hello")
state_store_event <- function(store, kind, state_id = NULL, detail = NULL) {
  con <- store_con(store)
  if (!is.character(kind) || length(kind) != 1L || !nzchar(kind)) {
    stop("`kind` must be a single non-empty character.", call. = FALSE)
  }
  DBI::dbExecute(
    con,
    "INSERT INTO events (ts, kind, state_id, detail) VALUES (?,?,?,?)",
    params = list(iso_now(), kind,
                  if (is.null(state_id)) NA_character_ else state_id,
                  if (is.null(detail)) NA_character_ else detail)
  )
  seq <- DBI::dbGetQuery(con, "SELECT last_insert_rowid() AS s")$s[1]
  invisible(seq)
}

#' @title Read the event log
#' @description Returns the append-only event log, optionally filtered
#'   by kind. Ordered by sequence (insertion order).
#' @param store a \code{visualr_state_store} object.
#' @param kind optional single character; filter by event kind.
#' @param limit integer; max rows (default 1000).
#' @return data.frame with columns: seq, ts, kind, state_id, detail.
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' state_store_write(st, new_pal_state(c("A","B","C","D"), "e"))
#' state_store_events(st)
state_store_events <- function(store, kind = NULL, limit = 1000L) {
  con <- store_con(store)
  limit <- as.integer(limit)
  if (is.null(kind)) {
    DBI::dbGetQuery(con, "SELECT seq, ts, kind, state_id, detail
                          FROM events ORDER BY seq DESC LIMIT ?",
                    params = list(limit))
  } else {
    DBI::dbGetQuery(con, "SELECT seq, ts, kind, state_id, detail
                          FROM events WHERE kind = ? ORDER BY seq DESC LIMIT ?",
                    params = list(kind, limit))
  }
}

#' @title List distinct state ids in the store
#' @description Returns the distinct canonical state ids and their
#'   latest version.
#' @param store a \code{visualr_state_store} object.
#' @return data.frame with columns: state_id, max_version.
#' @examples
#' st <- state_store(tempfile(fileext = ".sqlite"))
#' state_store_write(st, new_pal_state(c("A","B","C","D"), "e"))
#' state_store_list(st)
state_store_list <- function(store) {
  con <- store_con(store)
  DBI::dbGetQuery(con,
    "SELECT state_id, MAX(version) AS max_version FROM states
     GROUP BY state_id ORDER BY state_id")
}

#' @export
print.visualr_state_store <- function(x, ...) {
  cat(sprintf("<visualr_state_store> %s\n", x$path))
  if (!is.null(x$con) && DBI::dbIsValid(x$con)) {
    n_states <- DBI::dbGetQuery(x$con, "SELECT COUNT(*) AS n FROM states")$n[1]
    n_events <- DBI::dbGetQuery(x$con, "SELECT COUNT(*) AS n FROM events")$n[1]
    cat(sprintf("  states=%d events=%d (open)\n", n_states, n_events))
  } else {
    cat("  (closed)\n")
  }
  invisible(x)
}
