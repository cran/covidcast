% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/covidcast.R
\name{print.covidcast_signal}
\alias{print.covidcast_signal}
\title{Print \code{covidcast_signal} object}
\usage{
\method{print}{covidcast_signal}(x, ...)
}
\arguments{
\item{x}{The \code{covidcast_signal} object.}

\item{...}{Additional arguments passed to \code{print.data.frame()} to print the
data.}
}
\value{
The \code{covidcast_signal} object, unchanged.
}
\description{
Prints a brief summary of the data source, signal, and geographic level, and
then prints the underlying data frame, for an object returned by
\code{covidcast_signal()}.
}
