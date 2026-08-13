\name{new_pal_window}
\alias{new_pal_window}
\alias{open_window_parse}
\alias{open_window_encode}
\alias{deepen_solution}
\alias{shift_open_window}
\alias{print.visualr_pal_window}
\title{Complete and open PAL window states}
\usage{
new_pal_window(
  pal,
  boundary = c("closed", "open"),
  origin = 0L,
  outer_ref = list(left = NA_character_, right = NA_character_)
)

open_window_parse(
  text,
  origin = 0L,
  outer_ref = list(left = NA_character_, right = NA_character_),
  mapping_pack_id = DEFAULT_MAPPING_PACK_ID,
  provenance = list()
)

open_window_encode(window)

deepen_solution(pal, next_core)

shift_open_window(window, next_core)

\method{print}{visualr_pal_window}(x, ...)
}
\arguments{
\item{pal}{A complete \code{visualr_pal} object.}

\item{boundary}{Either \code{"closed"} or \code{"open"}.}

\item{origin}{Integer global address of the visible core.}

\item{outer_ref}{A list with exactly \code{left} and \code{right}; each
value is an opaque character reference or \code{NA_character_}.}

\item{text}{One open-window string: a closed PAL with an outer closing
brace prepended and an outer opening brace appended.}

\item{mapping_pack_id}{Optional mapping pack identifier.}

\item{provenance}{Optional PAL provenance list.}

\item{window}{An open \code{visualr_pal_window}.}

\item{next_core}{Explicit next core token. No value is inferred.}

\item{x}{A \code{visualr_pal_window}.}

\item{...}{Unused.}
}
\value{
\code{new_pal_window()}, \code{open_window_parse()}, and
\code{shift_open_window()} return a \code{visualr_pal_window}.
\code{open_window_encode()} returns one character string.
\code{deepen_solution()} returns a new \code{visualr_pal}.
}
\description{
Adds an addressed boundary state around the frozen PAL grammar without
changing that grammar. A closed window is a complete solution. An open
window says that an outer solution exists but is omitted; missing outer
references remain explicit and are never converted to padding.
}
\details{
The open form is \code{\}\{B\{C\{D\}C\}B\}\{} for the visible PAL
\code{\{B\{C\{D\}C\}B\}}. The first closing brace and final opening
brace are boundary syntax, not tokens.

\code{deepen_solution()} moves the current core into the innermost shell.
\code{shift_open_window()} keeps radius fixed, advances \code{origin} by
one, evicts the old outermost shell, and records the transition in
\code{trace}. The trace classifies every new address as retained,
introduced, or mirrored and records its source address when applicable.
}
\examples{
p <- pal_parse("{A{B}A}")
pal_encode(deepen_solution(p, "c"))

open_text <- paste0("}", "{B{C{D}C}B}", "{")
w <- open_window_parse(open_text, origin = 10L)
open_window_encode(shift_open_window(w, "E"))
}
