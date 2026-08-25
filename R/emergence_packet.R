# == Phase 1 — Emergence Packet ABI (pack / unpack) =================
# Status: NEW (v0.7.0 Phase 1). Builds ONLY against the frozen shared
#   constructors + validators in R/router_contract.R (single-writer
#   ownership matrix, inst/ROUTER_CONTRACT_v070.md §2). This file never
#   redefines Merge / RoutingEnvelope / EmergencePacket.
# Types (ROUTER_CONTRACT_v070.md §1.3 / §1.4):
#   EmergencePacket { envelope: RoutingEnvelope, payload: Merge }
#   RoutingEnvelope { packet_id, source_local, source_address, logical_time,
#                     boundary, transport, integrity }
# Semantics:
#   - pack_emergence():   local-side. Carries a Merge into a packet. The
#     opaque content stays in $payload; the envelope carries only
#     router-readable metadata (A2/P1). integrity is the content
#     tamper-detect hash (the envelope's ONLY dynamic field).
#   - unpack_for_local(): destination-side. Re-verifies envelope live
#     fields (packet_id / source_address) AND the payload integrity
#     against the content (fail closed on tamper), then hands the Merge
#     back so the local can rebuild its state. Content is still read
#     through merge_content() (local is an allowed consumer).

# -- internal: reproducible content hash ---------------------------
# Deterministic, base-R-only hash used to fill / verify envelope$integrity.
# Serializes the OPAQUE Merge content to bytes and md5sums them
# (tools::md5sum is base R). Same content => same hash => reproducible.
.emergence_content_hash <- function(merge_obj) {
  stopifnot(inherits(merge_obj, "visualr_merge"))
  # ascii=TRUE gives a byte-order-independent serialization so the integrity
  # hash is reproducible across endianness/architectures (port-reproducible,
  # D4 / contract "R<->C exact-equivalence" — a C/other reader can recompute it).
  bytes <- serialize(merge_content(merge_obj), NULL, ascii = TRUE, version = 2L)
  tf <- tempfile()
  on.exit(unlink(tf), add = TRUE)
  writeBin(charToRaw(paste(bytes, collapse = "")), tf)
  h <- unname(tools::md5sum(tf))
  if (length(h) != 1L || is.na(h)) {
    stop("Failed to compute content integrity hash (fail closed).", call. = FALSE)
  }
  h
}

# -- pack_emergence -------------------------------------------------
# Local-side: bundle a Merge into a router-readable EmergencePacket.
# @param merge_obj       visualr_merge (the opaque payload).
# @param source_address  character(1): address of the origin local.
# @param boundary        character(1): 'open' or 'closed' at emit time.
# @param transport       list: resource/traffic metadata.
# @param integrity       character: optional content hash; when empty or
#                        blank it is filled from the content (reproducible).
# @return visualr_emergence_packet.
pack_emergence <- function(merge_obj, source_address, boundary,
                           transport = list(), integrity = character(0L)) {
  if (!inherits(merge_obj, "visualr_merge")) {
    stop("`merge_obj` must be a visualr_merge.", call. = FALSE)
  }
  if (!is.character(source_address) || length(source_address) != 1L ||
      is.na(source_address) || !nzchar(source_address)) {
    stop("`source_address` must be one non-empty character.", call. = FALSE)
  }
  if (!is.character(boundary) || length(boundary) != 1L || is.na(boundary) ||
      !nzchar(boundary)) {
    stop("`boundary` must be one non-empty character ('open' or 'closed').",
         call. = FALSE)
  }
  if (!boundary %in% c("open", "closed")) {
    stop("`boundary` must be one of: 'open', 'closed' (fail closed).",
         call. = FALSE)
  }
  if (!is.list(transport)) {
    stop("`transport` must be a list.", call. = FALSE)
  }
  if (!is.character(integrity)) {
    stop("`integrity` must be a character vector.", call. = FALSE)
  }
  if (anyNA(integrity)) {
    stop("`integrity` must not contain NA values.", call. = FALSE)
  }

  # packet_id: auditable and 1:1 with the packet's merge id.
  packet_id <- paste0("P", merge_obj$merge_id)

  # integrity: auto-fill with the content hash when not supplied.
  if (length(integrity) == 0L ||
      (length(integrity) == 1L && !nzchar(integrity))) {
    integrity <- .emergence_content_hash(merge_obj)
  }

  envelope <- new_routing_envelope(
    packet_id      = packet_id,
    source_local   = merge_obj$origin_local,
    source_address = source_address,
    logical_time   = merge_obj$logical_time,
    boundary       = boundary,
    transport      = transport,
    integrity      = integrity
  )

  new_emergence_packet(envelope, merge_obj)
}

# -- unpack_for_local ----------------------------------------------
# Destination-side: unpack a packet, verifying it is well-formed (fail
# closed on missing packet_id / source_address via validate_emergence_packet)
# and that the payload content still matches the recorded integrity hash
# (fail closed on tamper). Returns the Merge so the local can rebuild
# its state; semantic content is read through merge_content().
# @param packet visualr_emergence_packet.
# @return the visualr_merge payload.
unpack_for_local <- function(packet) {
  if (!inherits(packet, "visualr_emergence_packet")) {
    stop("`packet` must be a visualr_emergence_packet.", call. = FALSE)
  }
  validate_emergence_packet(packet)  # fails closed on bad envelope live fields

  envl <- packet$envelope
  if (is.null(envl$integrity) || length(envl$integrity) == 0L ||
      (length(envl$integrity) == 1L && !nzchar(envl$integrity))) {
    stop("Packet has no integrity hash to verify (fail closed).", call. = FALSE)
  }

  expected <- .emergence_content_hash(packet$payload)
  if (!identical(expected, envl$integrity)) {
    stop("Packet integrity mismatch (tamper detected, fail closed).",
         call. = FALSE)
  }

  packet$payload   # the Merge; local reads content via merge_content()
}
