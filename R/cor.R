#' Compute correlations between two `covidcast_signal` data frames
#'
#' Computes correlations between two `covidcast_signal` data frames, allowing
#' for slicing by geo location, or by time. (Only the latest issue from each
#' data frame is used for correlations.) See the correlations vignette
#' for examples: `vignette("correlation-utils", package = "covidcast")`.
#'
#' @param x,y The `covidcast_signal` data frames to correlate.
#' @param dt_x,dt_y Time shifts (in days) to consider for `x` and `y`,
#'   respectively, before computing correlations. Default is 0. Negative shifts
#'   translate into in a lag value and positive shifts into a lead value; for
#'   example, setting `dt_y = 2` results in values of `y` being shifted earlier
#'   (leading) by 2 days before correlation, so values of `x` are correlated
#'   with values of `y` from two days later.
#' @param by If "geo_value", then correlations are computed for each geo
#'   location, over all time. Each correlation is measured between two time
#'   series at the same location. If "time_value", then correlations are
#'   computed for each time, over all geo locations. Each correlation is
#'   measured between all locations at one time. Default is "geo_value".
#' @param use,method Arguments to pass to `cor()`, with "na.or.complete" the
#'   default for `use` (different than `cor()`) and "pearson" the default for
#'   `method` (same as `cor()`).
#'
#' @return A data frame with first column `geo_value` or `time_value` (matching
#'   `by`), and second column `value`, which gives the correlation.
#'
#' @examples
#' \dontrun{
#' # For all these examples, let x and y be two signals measured at the county
#' # level over several months.
#'
#' ## `by = "geo_value"`
#' # Correlate each county's time series together, returning one correlation per
#' # county:
#' covidcast_cor(x, y, by = "geo_value")
#'
#' # Correlate x in each county with values of y 14 days later
#' covidcast_cor(x, y, dt_y = 14, by = "geo_value")
#'
#' # Equivalently, x can be shifted -14 days:
#' covidcast_cor(x, y, dt_x = -14, by = "geo_value")
#'
#' ## `by = "time_value"`
#' # For each date, correlate x's values in every county against y's values in
#' # the same counties. Returns one correlation per date:
#' covidcast_cor(x, y, by = "time_value")
#'
#' # Correlate x values across counties against y values 7 days later
#' covidcast_cor(x, y, dt_y = 7, by = "time_value")
#' }
#'
#' @importFrom stats cor
#' @export
covidcast_cor <- function(x, y, dt_x = 0, dt_y = 0,
                         by = c("geo_value", "time_value"),
                         use = "na.or.complete",
                         method = c("pearson", "kendall", "spearman")) {
  x <- latest_issue(x)
  y <- latest_issue(y)
  by <- match.arg(by)
  method <- match.arg(method)

  # Join the two data frames together by pairs of geo_value and time_value
  z <- dplyr::full_join(x, y, by = c("geo_value", "time_value"))

  # Make sure that we have a complete record of dates for each geo_value (fill
  # with NAs as necessary)
  z_all <- dplyr::group_by(z, .data$geo_value)
  z_all <- dplyr::reframe(z_all,
                          time_value = seq.Date(
                            as.Date(min(.data$time_value)),
                            as.Date(max(.data$time_value)),
                            by = "day")
                          )

  z <- dplyr::full_join(z, z_all, by = c("geo_value", "time_value"))

  # Perform time shifts, then compute appropriate correlations and return
  z <- dplyr::group_by(z, .data$geo_value)
  z <- dplyr::arrange(z, .data$time_value)
  z <- dplyr::mutate(z, value.x = shift(.data$value.x, n = dt_x),
                     value.y = shift(.data$value.y, n = dt_y))
  z <- dplyr::ungroup(z)
  z <- dplyr::group_by(z, dplyr::across(dplyr::all_of(by)))
  z <- dplyr::summarize(z, value = cor(
    x = .data$value.x, y = .data$value.y, use = use, method = method
  ))

  return(z)
}

# Function to perform time shifts, lag or lead
shift <- function(value, n) {
  if (n < 0) return(dplyr::lag(value, -n))
  else return(dplyr::lead(value, n))
}
