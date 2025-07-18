#' Plot `covidcast_signal` object as choropleths, bubbles, or time series
#'
#' Several plot types are provided, including choropleth plots (maps), bubble
#' plots, and time series plots showing the change of signals over time, for a
#' data frame returned by `covidcast_signal()`. (Only the latest issue from the
#' data frame is used for plotting.) See `vignette("plotting-signals", package =
#' "covidcast")` for examples.
#'
#' @param x The `covidcast_signal` object to map or plot. If the object contains
#'   multiple issues of the same observation, only the most recent issue is
#'   mapped or plotted.
#' @param plot_type One of "choro", "bubble", "line" indicating whether to plot
#'   a choropleth map, bubble map, or line (time series) graph, respectively.
#'   The default is "choro".
#' @param time_value Date object (or string in the form "YYYY-MM-DD") specifying
#'   the day to map, for choropleth and bubble maps. If `NULL`, the default,
#'   then the last date in `x` is used for the maps. Time series plots always
#'   include all available time values in `x`.
#' @param include Vector of state abbreviations (case insensitive, so "pa" and
#'   "PA" both denote Pennsylvania) indicating which states to include in the
#'   choropleth and bubble maps. Default is `c()`, which is interpreted to mean
#'   all states.
#' @param range Vector of two values: min and max, in this order, to use when
#'   defining the color scale for choropleth maps and the size scale for bubble
#'   maps, or the range of the y-axis for the time series plot. If `NULL`, the
#'   default, then for the maps, the min and max are set to be the mean +/- 3
#'   standard deviations, where this mean and standard deviation are as provided
#'   in the metadata for the given data source and signal; and for the time
#'   series plot, they are set to be the observed min and max of the values over
#'   the given time period.
#' @param choro_col Vector of colors, as specified in hex code, to use for the
#'   choropleth color scale. Can be arbitrary in length. Default is similar to
#'   that from <https://delphi.cmu.edu/covidcast/>.
#' @param alpha Number between 0 and 1, indicating the transparency level to be
#'   used in the maps. For choropleth maps, this determines the transparency
#'   level for the mega counties. For bubble maps, this determines the
#'   transparency level for the bubbles. Default is 0.5.
#' @param bubble_col Bubble color for the bubble map. Default is "purple".
#' @param num_bins Number of bins for determining the bubble sizes for the
#'   bubble map (here and throughout, to be precise, by bubble size we mean
#'   bubble area). Default is 8. These bins are evenly-spaced in between the min
#'   and max as specified through the `range` parameter. Each bin is assigned
#'   the same bubble size. Also, values of zero special: it has its own separate
#'   (small) bin, and values mapped to the zero bin are not drawn.
#' @param title Title for the plot. If `NULL`, the default, then a simple title
#'   is used based on the given data source, signal, and time values.
#' @param choro_params,bubble_params,line_params Additional parameter lists for
#'   the different plot types, for further customization. See details below.
#' @param ... Additional arguments, for compatibility with `plot()`. Currently
#'   unused.
#' @return A `ggplot` object that can be customized and styled using standard
#'   ggplot2 functions.
#'
#' @details The following named arguments are supported through the lists
#'   `choro_params`, `bubble_params`, and `line_params`.
#'
#' For both choropleth and bubble maps:
#' \describe{
#' \item{`subtitle`}{Subtitle for the map.}
#' \item{`missing_col`}{Color assigned to missing or NA geo locations.}
#' \item{`border_col`}{Border color for geo locations.}
#' \item{`border_size`}{Border size for geo locations.}
#' \item{`legend_position`}{Position for legend; use "none" to hide legend.}
#' \item{`legend_height`, `legend_width`}{Height and width of the legend.}
#' \item{`breaks`}{Breaks for a custom (discrete) color or size scale.  Note
#'   that we must set `breaks` to be a vector of the same length as `choro_col`
#'   for choropleth maps. This works as follows: we assign the `i`th color for
#'   choropleth maps, or the `i`th size for bubble maps, if and only if the
#'   given value satisfies `breaks[i] <= value < breaks[i+1]`, where we take by
#'   convention `breaks[0] = -Inf` and `breaks[N+1] = Inf` for `N =
#'   length(breaks)`.}
#' \item{`legend_digits`}{Number of decimal places to show for the legend
#'   labels.}
#' }
#'
#' For choropleth maps only:
#' \describe{
#' \item{`legend_n`}{Number of values to label on the legend color bar. Ignored
#'   for discrete color scales (when `breaks` is set manually).}
#' }
#'
#' For bubble maps only:
#' \describe{
#' \item{`remove_zero`}{Should zeros be excluded from the size scale (hence
#'   effectively drawn as bubbles of zero size)?}
#' \item{`min_size`, `max_size`}{Min size for the size scale.}
#' }
#'
#' For line graphs:
#' \describe{
#' \item{`xlab`, `ylab`}{Labels for the x-axis and y-axis.}
#' \item{`stderr_bands`}{Should standard error bands be drawn?}
#' \item{`stderr_alpha`}{Transparency level for the standard error bands.}
#' }
#'
#' @method plot covidcast_signal
#' @importFrom stats sd
#' @importFrom rlang warn
#' @export
plot.covidcast_signal <- function(x,
                                  plot_type = c("choro", "bubble", "line"),
                                  time_value = NULL,
                                  include = c(),
                                  range = NULL,
                                  choro_col = c(
                                    "#FFFFCC", "#FD893C", "#800026"
                                  ),
                                  alpha = 0.5,
                                  bubble_col = "purple",
                                  num_bins = 8,
                                  title = NULL,
                                  choro_params = list(),
                                  bubble_params = list(),
                                  line_params = list(),
                                  ...) {
  plot_type <- match.arg(plot_type)
  x <- latest_issue(x)

  # For the maps, set range, if we need to (to mean +/- 3 standard deviations,
  # from metadata)
  if (is.null(range) && (plot_type == "choro" || plot_type == "bubble")) {
    if (is.null(attributes(x)$metadata$mean_value) ||
        is.null(attributes(x)$metadata$stdev_value)) {
      warn(paste("Metadata for signal mean and standard deviation not",
                 "available; defaulting to observed mean and standard",
                 "deviation to set plot range."),
           class = "covidcast_plot_meta_not_found")
      mean_value <- mean(x$value)
      stdev_value <- sd(x$value)
      if (stdev_value == 0) { stdev_value <- abs(mean_value) * 0.1 }
      if (stdev_value == 0) { stdev_value <- 0.001 }
    } else {
      mean_value <- attributes(x)$metadata$mean_value
      stdev_value <- attributes(x)$metadata$stdev_value
    }
    range <- c(mean_value - 3 * stdev_value, mean_value + 3 * stdev_value)
    range <- pmax(0, range)
    # TODO: figure out for which signals we need to clip the top of the range.
    # For example, for percentages, we need to clip it at 100
  }

  # For the maps, take the most recent time value if more than one is passed,
  # and check that the include arguments indeed contains state names
  if (plot_type == "choro" || plot_type == "bubble") {
    if (!is.null(include)) {
      include <- toupper(include)
      no_match <- which(!(include %in% c(datasets::state.abb, "DC")))

      if (length(no_match) > 0) {
        warn("'include' must only contain US state abbreviations or 'DC'.",
             not_match = include[no_match], class = "plot_include_no_match")
        include <- include[-no_match]
      }
    }
  }

  # Choropleth map
  if (plot_type == "choro") {
    plot_choro(x, time_value = time_value, include = include, range = range,
               col = choro_col, alpha = alpha, title = title,
               params = choro_params)
  }


  # Bubble map
  else if (plot_type == "bubble") {
    plot_bubble(x, time_value = time_value, include = include, range = range,
                col = bubble_col, alpha = alpha, num_bins = num_bins,
                title = title, params = bubble_params)
  }

  # Line (time series) plot
  else {
    plot_line(x, range = range, title = title, params = line_params)
  }
}

# Plot a choropleth map of a covidcast_signal object.
#' @importFrom stats approx
plot_choro <- function(x, time_value = NULL, include = c(), range,
                      col = c("#FFFFCC", "#FD893C", "#800026"),
                      alpha = 0.5, title = NULL, params = list()) {
  # Check that we're looking at either counties or states
  if (!(attributes(x)$metadata$geo_type %in%
        c("county", "state", "hrr", "msa"))) {
    stop("Only 'county', 'state', 'hrr' and 'msa' are supported
         for choropleth maps.")
  }

  # Set the time value, if we need to (last observed time value)
  if (is.null(time_value)) time_value <- max(x$time_value)

  # Set a title, if we need to (simple combo of data source, signal, time value)
  if (is.null(title)) title <- paste0(unique(x$data_source), ": ",
                                     unique(x$signal), ", ", time_value)

  # Set a subtitle, if there are specific states we're viewing
  subtitle <- params$subtitle
  if (length(include) != 0 && is.null(subtitle)) {
    subtitle <- paste("Viewing", paste(include, collapse=", "))
  }

  # Set other map parameters, if we need to
  missing_col <- params$missing_col
  border_col <- params$border_col
  border_size <- params$border_size
  legend_height <- params$legend_height
  legend_width <- params$legend_width
  legend_digits <- params$legend_digits
  if (is.null(missing_col)) missing_col <- "gray"
  if (is.null(border_col)) border_col <- "white"
  if (is.null(border_size)) border_size <- 0.1
  if (is.null(legend_height)) legend_height <- 0.5
  if (is.null(legend_width)) legend_width <- 15
  if (is.null(legend_digits)) legend_digits <- 2

  # Create a continuous color function, if we need to
  breaks <- params$breaks
  if (is.null(breaks)) {
    ramp_fun <- grDevices::colorRamp(col)
    col_fun <- function(val, alpha = 1) {
      val <- pmin(pmax(val, range[1]), range[2])
      val <- (val - range[1]) / (range[2] - range[1])
      rgb_mat <- ramp_fun(val)
      not_na <- rowSums(is.na(rgb_mat)) == 0
      col_out <- rep(missing_col, length(val))
      col_out[not_na] <- grDevices::rgb(
        rgb_mat[not_na,], alpha = alpha * 255, max = 255
      )
      return(col_out)
    }
  }

  # Create a discrete color function, if we need to
  else {
    if (length(breaks) != length(col)) {
      stop("`breaks` must have length equal to the number of colors.")
    }
    col_fun <- function(val, alpha = 1) {
      alpha_str <- substr(grDevices::rgb(0, 0, 0, alpha = alpha), 8, 9)
      not_na <- !is.na(val)
      col_out <- rep(missing_col, length(val))
      col_out[not_na] <- col[1]
      for (i in seq_along(breaks)) col_out[val >= breaks[i]] <- col[i]
      col_out[not_na] <- paste0(col_out[not_na], alpha_str)
      return(col_out)
    }
  }

  # Set some basic layers
  element_text <- ggplot2::element_text
  margin <- ggplot2::margin
  title_layer <- ggplot2::labs(title = title, subtitle = subtitle)
  theme_layer <- ggplot2::theme_void() +
    ggplot2::theme(plot.title = element_text(hjust = 0.5, size = 12),
                   plot.subtitle = element_text(hjust = 0.5, size = 10,
                                                margin = margin(t = 5)),
                   legend.position = "bottom")

  # Grab the values
  given_time_value <- time_value
  df <- x %>%
    dplyr::filter(time_value == given_time_value) %>%
    dplyr::select(val = "value", geo = "geo_value")
  val <- df$val
  geo <- df$geo
  names(val) <- geo

  # Make background layer for maps.  For states view this isn't
  # necessary but it just hides in the background
  map_df <- read_geojson_data("state")
  background_crs <- sf::st_crs(map_df)
  map_df$STATEFP <- as.character(map_df$STATEFP)
  map_df <- map_df %>% dplyr::mutate(
    is_alaska = .data$STATEFP == '02',
    is_hawaii = .data$STATEFP == '15',
    is_pr = .data$STATEFP == '72',
    is_state = as.numeric(.data$STATEFP) < 57)

  # Set megacounty colors here
  if (attributes(x)$metadata$geo_type == "county") {
    map_df <- map_df %>% dplyr::mutate(
      color = ifelse(paste0(.data$STATEFP, "000") %in% geo,
                     col_fun(val[paste0(.data$STATEFP, "000")], alpha = alpha),
                     missing_col))
  }
  # Else, just set background to missing color
  else {
     map_df <- map_df %>% dplyr::mutate(color = missing_col)
  }

  if (length(include) > 0) {
    map_df <- map_df %>% dplyr::filter(.data$STUSPS %in% include)
  }

  main_df <- shift_main(map_df)
  hawaii_df <- shift_hawaii(map_df)
  alaska_df <- shift_alaska(map_df)
  pr_df <- shift_pr(map_df)

  main_col <- main_df$color
  hawaii_col <- hawaii_df$color
  alaska_col <- alaska_df$color
  pr_col <- pr_df$color

  aes <- ggplot2::aes
  geom_args <- list()
  geom_args$color <- border_col
  geom_args$size <- border_size
  geom_args$mapping <- ggplot2::aes(geometry=.data$geometry)

  geom_args$fill <- main_col
  geom_args$data <- main_df
  back_main_layer <- if (nrow(main_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- pr_col
  geom_args$data <- pr_df
  back_pr_layer <- if (nrow(pr_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- hawaii_col
  geom_args$data <- hawaii_df
  back_hawaii_layer <- if (nrow(hawaii_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$data <- alaska_df
  geom_args$fill <- alaska_col
  back_alaska_layer <- if (nrow(alaska_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }

  # Create the choropleth colors for counties
  if (attributes(x)$metadata$geo_type == "county") {
    map_df <- read_geojson_data("county")

    map_df$STATEFP <- as.character(map_df$STATEFP)
    map_df$GEOID <- as.character(map_df$GEOID)
    # Get rid of unobserved counties and megacounties
    # Those are taken care of by background layer
    # Then set color for those observed counties
    map_df <- map_df %>% dplyr::filter((.data$GEOID %in% geo) &
                                       !(.data$COUNTYFP == "000")
      ) %>% dplyr::mutate(
        is_alaska = .data$STATEFP == '02',
        is_hawaii = .data$STATEFP == '15',
        is_pr = .data$STATEFP == '72',
        is_state = as.numeric(.data$STATEFP) < 57,
        color = col_fun(val[.data$GEOID]))

    if (length(include) > 0) {
      map_df <- map_df %>%
        dplyr::filter(fips_to_abbr(paste0(.data$STATEFP, "000")) %in% include)
    }
  }

  # Create the choropleth colors for states
  else if (attributes(x)$metadata$geo_type == "state") {
    map_df <- read_geojson_data("state")

    background_crs <- sf::st_crs(map_df)
    map_df$STATEFP <- as.character(map_df$STATEFP)
    map_df <- map_df %>% dplyr::mutate(
      is_alaska = .data$STATEFP == '02',
      is_hawaii = .data$STATEFP == '15',
      is_pr = .data$STATEFP == '72',
      is_state = as.numeric(.data$STATEFP) < 57,
      color = ifelse(tolower(.data$STUSPS) %in% geo,
                     col_fun(val[tolower(.data$STUSPS)]),
                     missing_col))
    if (length(include) > 0) {
      map_df <- map_df %>% dplyr::filter(.data$STUSPS %in% include)
    }
  }

  else if (attributes(x)$metadata$geo_type == "msa") {
    map_df <- read_geojson_data("msa")


    # only get metro and not micropolitan areas
    map_df <- map_df %>% dplyr::filter(map_df$LSAD == 'M1')
    if (length(include) > 0) {
      # Last two letters are state abbreviation
      map_df <- map_df %>% dplyr::filter(
        substr(.data$NAME, nchar(.data$NAME) - 1,
               nchar(.data$NAME)) %in% include)
    }
    map_df$NAME <- as.character(map_df$NAME)
    map_df <- map_df %>% dplyr::mutate(
      is_alaska = substr(
        .data$NAME, nchar(.data$NAME) - 1, nchar(.data$NAME)) == 'AK',
      is_hawaii = substr(
        .data$NAME, nchar(.data$NAME) - 1, nchar(.data$NAME)) == 'HI',
      is_pr = substr(
        .data$NAME, nchar(.data$NAME) - 1, nchar(.data$NAME)) == 'PR',
      color = ifelse(
        .data$GEOID %in% geo, col_fun(val[.data$GEOID]), missing_col)
    )
  }

  else if (attributes(x)$metadata$geo_type == "hrr") {
    map_df <- read_geojson_data("hrr")

    if (length(include) > 0) {
      # First two letters are state abbreviation
      map_df <- map_df %>% dplyr::filter(
        substr(.data$hrr_name, 1, 2) %in% include
      )
    }
    map_df <- sf::st_transform(map_df, background_crs)
    hrr_shift <- sf::st_geometry(map_df) + c(0, -0.185)
    map_df <- sf::st_set_geometry(map_df, hrr_shift)
    map_df <- sf::st_set_crs(map_df, background_crs)
    map_df$hrr_name <- as.character(map_df$hrr_name)
    map_df <- map_df %>% dplyr::mutate(
      is_alaska = substr(.data$hrr_name, 1, 2) == 'AK',
      is_hawaii = substr(.data$hrr_name, 1, 2) == 'HI',
      is_pr = substr(.data$hrr_name, 1, 2) == 'PR',
      # use the HRR numbers to index the named val vector -- but convert to
      # character, otherwise the indices will be positional, not using the
      # names.
      color = ifelse(
        .data$hrr_num %in% geo,
        col_fun(val[as.character(.data$hrr_num)]), missing_col
      )
    )
  }

  main_df <- shift_main(map_df)
  hawaii_df <- shift_hawaii(map_df)
  alaska_df <- shift_alaska(map_df)
  pr_df <- shift_pr(map_df)

  main_col <- main_df$color
  hawaii_col <- hawaii_df$color
  alaska_col <- alaska_df$color
  pr_col <- pr_df$color

  # Create the polygon layers
  aes <- ggplot2::aes
  geom_args <- list()
  geom_args$color <- border_col
  geom_args$size <- border_size
  geom_args$mapping <- ggplot2::aes(geometry=.data$geometry)
  coord_args <- list()

  geom_args$fill <- main_col
  geom_args$data <- main_df
  main_layer <- if (nrow(main_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- pr_col
  geom_args$data <- pr_df
  pr_layer <- if (nrow(pr_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- hawaii_col
  geom_args$data <- hawaii_df
  hawaii_layer <- if (nrow(hawaii_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- alaska_col
  geom_args$data <- alaska_df
  alaska_layer <- if (nrow(alaska_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  coord_layer <- do.call(ggplot2::coord_sf, coord_args)

  # For continuous color scale, create a legend layer
  if (is.null(breaks)) {
    # Create legend breaks and legend labels, if we need to
    n <- params$legend_n
    if (is.null(n)) { n <- 8 }
    legend_breaks <- seq(range[1], range[2], len = n)
    legend_labels <- round(legend_breaks, legend_digits)

    # Create a dense set of breaks, for the color gradient (especially
    # important if many colors were passed)
    d <- approx(x = 0:(n-1) / (n-1), y = legend_breaks, xout = 0:999 / 999)$y

    # Now the legend layer (hidden + scale)
    hidden_df <- data.frame(x = rep(Inf, n), z = legend_breaks)
    hidden_layer <- ggplot2::geom_point(ggplot2::aes(
      x = .data$x, y = .data$x, color = .data$z),
                                       data = hidden_df, alpha = 0)
    guide <- ggplot2::guide_colorbar(title = NULL, direction = "horizontal",
                                     barheight = legend_height,
                                     barwidth = legend_width)
    scale_layer <- ggplot2::scale_color_gradientn(colors = col_fun(d),
                                                 limits = range(d),
                                                 breaks = legend_breaks,
                                                 labels = legend_labels,
                                                 guide = guide)
  }

  # For discrete color scale, create a legend layer
  else {
    # Create legend breaks and legend labels
    n <- length(breaks)
    legend_breaks <- breaks
    legend_labels <- round(legend_breaks, legend_digits)

    # Now the legend layer (hidden + scale)
    hidden_df <- data.frame(x = rep(Inf, n), z = as.factor(legend_breaks))
    hidden_layer <- ggplot2::geom_polygon(
      ggplot2::aes(x = .data$x, y = .data$x, fill = .data$z),
      data = hidden_df, alpha = 0
    )
    guide <- ggplot2::guide_legend(title = NULL, direction = "horizontal", nrow = 1,
                                   keyheight = legend_height,
                                   keywidth = legend_width / n,
                                   label.position = "bottom", label.hjust = 0,
                                   override.aes = list(alpha = 1))
    scale_layer <- ggplot2::scale_fill_manual(values = col,
                                             breaks = legend_breaks,
                                             labels = legend_labels,
                                             guide = guide)
  }

  return(ggplot2::ggplot() +
        back_main_layer + back_pr_layer + back_hawaii_layer +
        back_alaska_layer + main_layer + pr_layer + alaska_layer +
        hawaii_layer + coord_layer + title_layer + hidden_layer + scale_layer +
        theme_layer)
}

# Plot a bubble map of a covidcast_signal object.

plot_bubble <- function(x, time_value = NULL, include = c(), range = NULL,
                       col = "purple", alpha = 0.5, num_bins = 8,
                       title = NULL, params = list()) {
  # Check that we're looking at either counties or states
  if (!(attributes(x)$metadata$geo_type == "county" ||
        attributes(x)$metadata$geo_type == "state")) {
    stop("Only 'county' and 'state' are supported for bubble maps.")
  }

  # Set the time value, if we need to (last observed time value)
  if (is.null(time_value)) time_value <- max(x$time_value)

  # Set a title, if we need to (simple combo of data source, signal, time value)
  if (is.null(title)) title <- paste0(unique(x$data_source), ": ",
                                     unique(x$signal), ", ", time_value)

  # Set a subtitle, if there are specific states we're viewing
  subtitle <- params$subtitle
  if (length(include) != 0 && is.null(subtitle)) {
    subtitle <- paste("Viewing", paste(include, collapse=", "))
  }

  # Set other map parameters, if we need to
  missing_col <- params$missing_col
  border_col <- params$border_col
  border_size <- params$border_size
  legend_height <- params$legend_height
  legend_width <- params$legend_width
  legend_digits <- params$legend_digits
  legend_pos <- params$legend_position
  if (is.null(missing_col)) missing_col <- "gray"
  if (is.null(border_col)) border_col <- "darkgray"
  if (is.null(border_size)) border_size <- 0.1
  if (is.null(legend_height)) legend_height <- 0.5
  if (is.null(legend_width)) legend_width <- 15
  if (is.null(legend_digits)) legend_digits <- 2
  if (is.null(legend_pos)) legend_pos <- "bottom"

  # Create breaks, if we need to
  breaks <- params$breaks
  if (!is.null(breaks)) num_bins <- length(breaks)
  else {
    # Set a lower bound if range[1] == 0 and we're removing zeros
    lower_bd <- range[1]
    if (!isFALSE(params$remove_zero) && range[1] == 0) {
      lower_bd <- min(0.1, range[2] / num_bins)
    }
    breaks <- seq(lower_bd, range[2], length = num_bins)
  }

  # Max and min bubble sizes
  min_size <- params$min_size
  max_size <- params$max_size
  if (is.null(min_size)) {
    min_size <- ifelse(attributes(x)$metadata$geo_type == "county", 0.1, 1)
  }
  if (is.null(max_size)) {
    max_size <- ifelse(attributes(x)$metadata$geo_type == "county", 4, 12)
  }

  # Bubble sizes. Important note the way we set sizes later, via
  # scale_size_manual(), this actually sets the *radius* not the *area*, so we
  # need to define these sizes to be evenly-spaced on the squared scale
  sizes <- sqrt(seq(min_size^2, max_size^2, length = num_bins))

  # Create discretization function
  dis_fun <- function(val) {
    val_out <- rep(NA, length(val))
    for (i in seq_along(breaks)) val_out[val >= breaks[i]] <- breaks[i]
    return(val_out)
  }

  # Set some basic layers
  element_text <- ggplot2::element_text
  margin <- ggplot2::margin
  title_layer <- ggplot2::labs(title = title, subtitle = subtitle)
  theme_layer <- ggplot2::theme_void() +
    ggplot2::theme(plot.title = element_text(hjust = 0.5, size = 12),
                   plot.subtitle = element_text(hjust = 0.5, size = 10,
                                                margin = margin(t = 5)),
                   legend.position = legend_pos)

  # Grab the values
  given_time_value <- time_value
  df <- x %>%
    dplyr::filter(.data$time_value == given_time_value) %>%
    dplyr::select(val = "value", geo = "geo_value")
  val <- df$val
  geo <- df$geo
  names(val) <- geo

  # Grap the map data frame for counties
  if (attributes(x)$metadata$geo_type == "county") {
    map_df <- read_geojson_data("county")

    map_df$STATEFP <- as.character(map_df$STATEFP)
    map_df$GEOID <- as.character(map_df$GEOID)
    # Get rid of megacounties
    # Set color for observed states as white, missing as missing_col
    # Set bubble size for all observed states
    map_df <- map_df %>%
      dplyr::filter(!(.data$COUNTYFP == "000")) %>%
      dplyr::mutate(
        is_alaska = .data$STATEFP == '02',
        is_hawaii = .data$STATEFP == '15',
        is_pr = .data$STATEFP == '72',
        is_state = as.numeric(.data$STATEFP) < 57,
        back_color = ifelse(.data$GEOID %in% geo, "white", missing_col),
        bubble_val = ifelse(.data$GEOID %in% geo,
                            dis_fun(val[.data$GEOID]),
                            0))

    if (length(include) > 0) {
      map_df <- map_df %>%
        dplyr::filter(fips_to_abbr(paste0(.data$STATEFP, "000")) %in% include)
    }
  }

  # Grap the map data frame for states
  else if (attributes(x)$metadata$geo_type == "state") {
    map_df <- read_geojson_data("state")

    map_geo <- tolower(map_df$STUSPS)
    background_crs <- sf::st_crs(map_df)
    map_df$STATEFP <- as.character(map_df$STATEFP)
    # Set color for observed states as white, missing as missing_col
    # Set bubble size for all observed states
    map_df <- map_df %>% dplyr::mutate(
      is_alaska = .data$STATEFP == '02',
      is_hawaii = .data$STATEFP == '15',
      is_pr = .data$STATEFP == '72',
      is_state = as.numeric(.data$STATEFP) < 57,
      back_color = ifelse(tolower(.data$STUSPS) %in% geo, "white", missing_col),
      bubble_val = ifelse(tolower(.data$STUSPS) %in% geo,
                          dis_fun(val[tolower(.data$STUSPS)]),
                          NA))

    if (length(include) > 0) {
      map_df <- map_df %>%
        dplyr::filter(.data$STUSPS %in% include)
    }
  }

  # Important: make into a factor and set the levels (for the legend)
  # Factor bubble values before splitting up into mainland and non-main layers
  map_df$bubble_val <- factor(map_df$bubble_val, levels = breaks)

  # Explicitly drop zeros (and from levels) unless we're asked not to
  if (!isFALSE(params$remove_zero)) {
    map_df$bubble_val[map_df$bubble_val == 0] <- NA
    levels(map_df$bubble_val)[levels(map_df$bubble_val) == 0] <- NA
  }

  # Warn if there's any missing locations
  if (any(map_df$back_color == missing_col)) {
    warning("Bubble maps can be hard to read when there is missing data; ",
            "the locations without data are filled in gray.")
  }

  # Adjust map data for non mainland
  main_df <- shift_main(map_df)
  hawaii_df <- shift_hawaii(map_df)
  alaska_df <- shift_alaska(map_df)
  pr_df <- shift_pr(map_df)

  # Create the polygon layers
  aes <- ggplot2::aes
  geom_args <- list()
  geom_args$color <- border_col
  geom_args$size <- border_size
  geom_args$mapping <- ggplot2::aes(geometry=.data$geometry)
  geom_args$fill <- main_df$back_color
  geom_args$data <- main_df
  main_layer <- if (nrow(main_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$fill <- pr_df$back_color
  geom_args$data <- pr_df
  pr_layer <- if (nrow(pr_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$data <- hawaii_df
  geom_args$fill <- hawaii_df$back_color
  hawaii_layer <- if (nrow(hawaii_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }
  geom_args$data <- alaska_df
  geom_args$fill <- alaska_df$back_color
  alaska_layer <- if (nrow(alaska_df) > 0) {
    do.call(ggplot2::geom_sf, geom_args)
  } else {
    ggplot2::geom_blank()
  }

  # Change geometry to centroids
  # Use centroid coordinates for plotting bubbles
  # Warnings say centroids don't give lat/long centroid for
  # map data, but since we have properly projected coordinates
  # it works fine.
  suppressWarnings({
    main_df$geometry <- sf::st_centroid(main_df$geometry)
    hawaii_df$geometry <- sf::st_centroid(hawaii_df$geometry)
    alaska_df$geometry <- sf::st_centroid(alaska_df$geometry)
    pr_df$geometry <- sf::st_centroid(pr_df$geometry)
  })

  # Create the bubble layers
  geom_args <- list()
  geom_args$mapping <- ggplot2::aes(
    geometry = .data$geometry, size = .data$bubble_val
  )
  geom_args$color <- col
  geom_args$alpha <- alpha
  geom_args$na.rm <- TRUE
  geom_args$show.legend <- "point"

  # If there is no bubble data (all values are missing), return blank layer
  bubble_blank_if_all_na <- function(geom_args, df) {
    geom_args$data <- df
    bubble_layer <- ggplot2::geom_blank()
    if (!all(is.na(df$bubble_val))) {
      bubble_layer <- do.call(ggplot2::geom_sf, geom_args)
    }
    return(bubble_layer)
  }

  main_bubble_layer <- bubble_blank_if_all_na(geom_args, main_df)
  hawaii_bubble_layer <- bubble_blank_if_all_na(geom_args, hawaii_df)
  pr_bubble_layer <- bubble_blank_if_all_na(geom_args, pr_df)
  alaska_bubble_layer <- bubble_blank_if_all_na(geom_args, alaska_df)

  # Create the scale layer
  labels <- round(breaks, legend_digits)
  guide <- ggplot2::guide_legend(title = NULL, direction = "horizontal", nrow = 1)
  scale_layer <- ggplot2::scale_size_manual(values = sizes, breaks = breaks,
                                            labels = labels, drop = FALSE,
                                            guide = guide)

  # Put it all together and return
  return(ggplot2::ggplot() + main_layer + pr_layer + alaska_layer +
           hawaii_layer + title_layer + main_bubble_layer +
           hawaii_bubble_layer + pr_bubble_layer + alaska_bubble_layer +
           scale_layer + theme_layer)
}

# Plot a line (time series) graph of a covidcast_signal object.
plot_line <- function(x, range = NULL, title = NULL, params = list()) {
  # Set a title, if we need to (simple combo of data source, signal)
  if (is.null(title)) title <- paste0(unique(x$data_source), ": ",
                                     unique(x$signal))

  # Set other plot parameters, if we need to
  xlab <- params$xlab
  ylab <- params$ylab
  stderr_bands <- params$stderr_bands
  stderr_alpha <- params$stderr_alpha
  if (is.null(xlab)) xlab <- "Date"
  if (is.null(ylab)) ylab <- "Value"
  if (is.null(stderr_bands)) stderr_bands <- FALSE
  if (is.null(stderr_alpha)) stderr_alpha <- 0.5

  # Grab the values
  df <- x %>% dplyr::select(
    "value", "time_value", "geo_value", "stderr"
  )

  # Set the range, if we need to
  if (is.null(range)) range <- base::range(df$value, na.rm = TRUE)

  # Create label and theme layers
  label_layer <- ggplot2::labs(title = title, x = xlab, y = ylab)
  theme_layer <- ggplot2::theme_bw() +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5)) +
    ggplot2::theme(legend.position = "bottom",
                   legend.title = ggplot2::element_blank())

  # Create lim, line, and ribbon layers
  aes <- ggplot2::aes
  lim_layer <- ggplot2::coord_cartesian(ylim = range)
  line_layer <- ggplot2::geom_line(ggplot2::aes(
    y = .data$value, color = .data$geo_value, group = .data$geo_value
  ))
  ribbon_layer <- NULL
  if (stderr_bands) {
    df$ymin <- df$value - df$stderr
    df$ymax <- df$value + df$stderr
    ribbon_layer <- ggplot2::geom_ribbon(ggplot2::aes(
      ymin = .data$ymin, ymax = .data$ymax, fill = .data$geo_value
    ), alpha = stderr_alpha)
  }

  # Put it all together and return
  return(ggplot2::ggplot(ggplot2::aes(x = .data$time_value), data = df) +
         line_layer + ribbon_layer + lim_layer + label_layer + theme_layer)
}



# Use the following CRS values
# final_crs is ESRI:102003, alaska_crs is ESRI:102006,
# hawaii_crs is ESRI:102007. There were errors using the integers, so these
# were copied from spatialreference.org

final_crs <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0
             +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs'
alaska_crs <- '+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0
              +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs'
hawaii_crs <- '+proj=aea +lat_1=8 +lat_2=18 +lat_0=13 +lon_0=-157 +x_0=0
              +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs'

# These functions move Hawaii, Puerto Rico and Alaska close to the mainland,
# and rotate/scale them for the plots.

shift_pr <- function(map_df) {
  pr_df <- map_df %>% dplyr::filter(.data$is_pr)
  pr_df <- sf::st_transform(pr_df, final_crs)
  pr_shift <- sf::st_geometry(pr_df) + c(-1.2e+6, 0.5e+6)
  pr_df <- sf::st_set_geometry(pr_df, pr_shift)

  # Pretend this was in final_crs all along
  suppressWarnings({
    sf::st_crs(pr_df) <- final_crs
  })
  return(pr_df)
}

shift_alaska <- function(map_df) {
  alaska_df <- map_df %>% dplyr::filter(.data$is_alaska)
  alaska_df <- sf::st_transform(alaska_df, alaska_crs)
  alaska_scale <- sf::st_geometry(alaska_df) * 0.35
  alaska_df <- sf::st_set_geometry(alaska_df, alaska_scale)
  alaska_shift <- sf::st_geometry(alaska_df) + c(-1.8e+6, -1.6e+6)
  alaska_df <- sf::st_set_geometry(alaska_df, alaska_shift)

  # Pretend this was in final_crs all along
  suppressWarnings({
    sf::st_crs(alaska_df) <- final_crs
  })
  return(alaska_df)
}

shift_hawaii <- function(map_df){
  hawaii_df <- map_df %>% dplyr::filter(.data$is_hawaii)
  hawaii_df <- sf::st_transform(hawaii_df, hawaii_crs)
  hawaii_shift <- sf::st_geometry(hawaii_df) + c(-1e+6, -2e+6)
  hawaii_df <- sf::st_set_geometry(hawaii_df, hawaii_shift)

  # Pretend this was in final_crs all along
  suppressWarnings({
    sf::st_crs(hawaii_df) <- final_crs
  })
  return(hawaii_df)
}

shift_main <- function(map_df){
  main_df <- map_df %>% dplyr::filter(
      !.data$is_alaska) %>% dplyr::filter(
        !.data$is_hawaii) %>% dplyr::filter(!.data$is_pr)
  # Remove other territories if that attribute is there
  if ("is_state" %in% colnames(main_df)) {
    main_df <- main_df %>% dplyr::filter(.data$is_state)
  }
  main_df <- sf::st_transform(main_df, final_crs)
  return(main_df)
}

read_geojson_data <- function(name) {
  fpath <- system.file(
    sprintf("shapefiles/%s.geojson.bz2", name), package = "covidcast"
  )
  geojson <- paste(readLines(fpath), collapse = "")
  map_df <- sf::st_read(dsn = geojson, quiet = TRUE)
  map_df
}
