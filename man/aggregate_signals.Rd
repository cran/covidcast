% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrangle.R
\name{aggregate_signals}
\alias{aggregate_signals}
\title{Aggregate \code{covidcast_signal} objects into one data frame}
\usage{
aggregate_signals(x, dt = NULL, format = c("wide", "long"))
}
\arguments{
\item{x}{Single \code{covidcast_signal} data frame, or a list of such data
frames, such as is returned by \code{covidcast_signals()}.}

\item{dt}{Vector of shifts to apply to the values in the data frame \code{x}.
Negative shifts translate into in a lag value and positive shifts into a
lead value; for example, if \code{dt = -1}, then the value on June 2 that gets
reported is the original value on June 1; if \code{dt = 0}, then the values are
left as is. When \code{x} is a list of data frames, \code{dt} can either be a single
vector of shifts or a list of vectors of shifts, this list having the same
length as \code{x} (in order to apply, respectively, the same shifts or a
different set of shifts to each data frame in \code{x}).}

\item{format}{One of either "wide" or "long". The default is "wide".}
}
\value{
Data frame of aggregated signals in "wide" or "long" form, depending
on \code{format}. In "long" form, an extra column \code{dt} is appended to indicate
the value of the time-shift. In "wide" form, only the latest issue of data
is retained; the returned data frame is formed via full joins of the input
data frames (on \code{geo_value} and \code{time_value} as the join key), and the
columns \code{data_source}, \code{signal}, \code{issue}, \code{lag}, \code{stderr}, \code{sample_size}
are all dropped from the output. Each unique signal---defined by a
combination of data source name, signal name, and time-shift---is given its
own column, whose name indicates its defining quantities. For example, the
column name "value+2:usa-facts_confirmed_incidence_num" corresponds to a
signal defined by \code{data_source = "usa-facts"}, \code{signal = "confirmed_incidence_num"}, and \code{dt = 2}.
}
\description{
Aggregates \code{covidcast_signal} objects into one data frame, in either "wide"
or "long" format. (In "wide" aggregation, only the latest issue from each
data frame is retained, and several columns, including \code{data_source} and
\code{signal} are dropped; see details below). See \code{vignette("multi-signals", package = "covidcast")} for examples.
}
\details{
This function can be thought of having three use cases. In all three
cases, the result will be a new data frame in either "wide" or "long"
format, depending on \code{format}.

The first use case is to apply time-shifts to the values in a given
\code{covidcast_signal} object. In this use case, \code{x} is a \code{covidcast_signal}
data frame and \code{dt} is a vector of shifts.

The second use case is to bind together, into one data frame, signals that
are returned by \code{covidcast_signals()}. In this use case, \code{x} is a list of
\code{covidcast_signal} data frames, and \code{dt} is \code{NULL}.

The third use case is a combination of the first two: to bind together
signals returned by \code{covidcast_signals()}, and simultaneously, apply
time-shifts to their values. In this use case, \code{x} is a list of
\code{covidcast_signal} data frames, and \code{dt} is either a vector of shifts---to
apply the same shifts for each signal in \code{x}, or a list of vector of
shifts---to apply different shifts for each signal in \code{x}.
}
\seealso{
\code{\link[=covidcast_wider]{covidcast_wider()}}, \code{\link[=covidcast_longer]{covidcast_longer()}}
}
