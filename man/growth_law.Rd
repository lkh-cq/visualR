\name{growth_law}
\alias{growth_law}
\alias{growth_sequence}
\alias{print.visualr_growth_law}
\title{Query the frozen growth-law constant table}
\usage{
growth_law(law_id, depth)

growth_sequence(law_id, depth_max)

\method{print}{visualr_growth_law}(x, ...)
}
\arguments{
\item{law_id}{character(1), one of \code{"dilation_power"},
\code{"gradient_batch"}, \code{"carrier_width"}, \code{"pal_path"}.}

\item{depth}{integer(1) >= 0, layer/depth index.}

\item{depth_max}{integer(1) >= 0, largest depth to include.}

\item{x}{a \code{visualr_growth_law} object.}

\item{...}{unused.}
}
\value{
\code{growth_law()} returns a list of class \code{visualr_growth_law}
with law_id, depth, value, formula, frozen and source.
\code{growth_sequence()} returns an integer vector of length
\code{depth_max + 1}.
}
\description{
Looks up a named growth law in the frozen constant table and returns
its value at the requested depth. Mirrors TCN's explicit dilation law
(base^depth). Candidate laws (carrier_width, pal_path) are exposed but
NOT frozen -- the table keeps them side by side with the frozen
references so future freeze decisions are made against one authority.
}
\examples{
growth_law("dilation_power", depth = 3L)   # 8  (2^3)
growth_law("pal_path", depth = 4L)         # 9  (candidate, not frozen)
growth_sequence("dilation_power", depth_max = 4L)  # 1 2 4 8 16
}
