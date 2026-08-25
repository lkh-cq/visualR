\name{pack_emergence}
\alias{pack_emergence}
\alias{unpack_for_local}
\title{v0.7.0 Phase 1: Emergence Packet ABI (pack / unpack)}
\description{
Local-side carry of a Merge into a router-readable packet, and destination-side
unpack. The packet has two layers (envelope: router-readable metadata; payload:
opaque Merge). The router must only ever touch the envelope (A2/P1).
}
\usage{
pack_emergence(merge_obj, source_address, boundary,
               transport = list(), integrity = character(0L))
unpack_for_local(packet)
}
\arguments{
\item{merge_obj}{a \code{visualr_merge}; its content becomes the opaque payload.}
\item{source_address}{single non-empty character; origin address (A6).}
\item{boundary}{single character, one of \code{"open"}, \code{"closed"}.}
\item{transport}{list of resource/traffic metadata.}
\item{integrity}{optional content hash; when empty it is filled reproducibly
from the Merge content.}
\item{packet}{a \code{visualr_emergence_packet}.}
}
\value{
\code{pack_emergence} returns a \code{visualr_emergence_packet}.
\code{unpack_for_local} returns the \code{visualr_merge} payload, failing closed
on tamper (content hash mismatch) or malformed envelope.
}
