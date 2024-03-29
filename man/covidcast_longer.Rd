% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrangle.R
\name{covidcast_longer}
\alias{covidcast_longer}
\alias{covidcast_wider}
\title{Pivot aggregated signals between "wide" and "long" formats}
\usage{
covidcast_longer(x)

covidcast_wider(x)
}
\arguments{
\item{x}{A \code{covidcast_signal_wide} or \code{covidcast_signal_long} object, as
returned from \code{aggregate_signals()} with the respective \code{format} argument.}
}
\value{
The object pivoted into the opposite form, i.e. as if
\code{aggregate_signals()} had been called in the first place with that
\code{format} argument.
}
\description{
These functions take signals returned from \code{aggregate_signals()} and convert
between formats. \code{covidcast_longer()} takes the output of
\code{aggregate_signals(..., format = "wide")} and converts it to "long" format,
while \code{covidcast_wider()} takes the output of \code{aggregate_signals(..., format = "long")} and converts it to "wide" format.
}
\seealso{
\code{\link[=covidcast_signals]{covidcast_signals()}}
}
