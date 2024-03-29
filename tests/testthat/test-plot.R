library(testthat)
library(vdiffr)
library(dplyr)

## Plotting tests.
# Since it is difficult to test specific output of plots, these tests instead
# use vdiffr to ensure that plots match a saved reference version. The tests
# below simple build simple graphs of each type, thus exercising the different
# plotting options and ensuring they all function.

test_that("simple line graph", {
  fake_data <- structure(data.frame(
    data_source = "foo",
    signal = "bar",
    value = 1:10,
    time_value = seq.Date(as.Date("2020-01-01"), as.Date("2020-01-10"),
                          by = "day"),
    issue = as.Date("2020-02-01"),
    geo_value = "pa",
    stderr = 0.5),
  class = c("covidcast_signal", "data.frame")
  )

  expect_doppelganger("simple line graph", plot(
    fake_data,
    plot_type = "line",
    range = c(-1, 11),
    title = "Penguins!",
    line_params = list(
      xlab = "Day",
      ylab = "Penguinocity",
      stderr_bands = TRUE,
      stderr_alpha = 0.3
    )
  ))
})

test_that("state line graphs", {
  fb_state <- readRDS(test_path("data/survey-data-state.rds"))

  expect_doppelganger("default state line graph",
                      plot(fb_state, plot_type = "line"))

  expect_doppelganger("state line graph with stderrs",
                      plot(filter(fb_state, geo_value %in% c("pa", "tx", "ny")),
                           plot_type = "line",
                           line_params = list(stderr_bands = TRUE)))

  expect_doppelganger("state line graph with range",
                      plot(fb_state, plot_type = "line",
                           range = c(0, 10)))
})

test_that("simple state choropleths", {
  fb_state <- readRDS(test_path("data/survey-data-state.rds"))

  expect_doppelganger("default state choropleth",
                      plot(fb_state, plot_type = "choro"))

  expect_doppelganger("default state choropleth with include",
                      plot(fb_state, plot_type = "choro",
                           include = c("pa", "OH", "in", "KY")))

  expect_doppelganger("default state choropleth with range",
                      plot(fb_state, plot_type = "choro",
                           range = c(0, 4)))

  fb_county <- readRDS(test_path("data/survey-data-county.rds"))
  expect_doppelganger("default county choropleth",
                      plot(fb_county, plot_type = "choro"))

  expect_doppelganger("default county choropleth with include",
                      plot(fb_county, plot_type = "choro",
                           include = c("pa", "OH", "in", "KY")))

  # Alaska has FIPS beginning with 02, which can confuse FIPS-based subsetting
  expect_doppelganger("default county choropleth with Alaska",
                      plot(fb_county, plot_type = "choro",
                           include = "ak"))

  # Work-in-progress signals may not have metadata, so we should preserve the
  # ability to plot them by manually specifying range
  attributes(fb_state)$metadata <- NULL
  attributes(fb_state)$metadata$geo_type <- "state"
  expect_doppelganger("state choropleth with no metadata",
                      plot(fb_state, plot_type = "choro",
                           range = c(0, 2)))

})

test_that("simple HRR choropleths", {
  fb_hrr <- readRDS(test_path("data/survey-data-hrr.rds"))

  expect_doppelganger("default HRR choropleth",
                      plot(fb_hrr, plot_type = "choro"))

  expect_doppelganger("default HRR choropleth with include",
                      plot(fb_hrr, plot_type = "choro",
                           include = c("tx", "CA")))
})

test_that("simple MSA choropleths", {
  fb_msa <- readRDS(test_path("data/survey-data-msa.rds"))

  expect_doppelganger("default MSA choropleth",
                      plot(fb_msa, plot_type = "choro"))

  expect_doppelganger("default MSA choropleth with include",
                      plot(fb_msa, plot_type = "choro",
                           include = c("tx", "CA")))
})

test_that("state bubble plot with both missing and 0 values", {
  fake_data <- structure(data.frame(
    data_source = "foo",
    signal = "bar",
    value = c(1, 2, 0, 3),
    geo_value = c("pa", "in", "tx", "wy"),
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-02-01"),
    stderr = 0.5),
    class = c("covidcast_signal", "data.frame"),
    metadata = list(geo_type = "state")
  )

  # we suppress the warning about missing data
  expect_doppelganger("bubble plot with 0 and missing",
                      suppressWarnings(
                        plot(fake_data, plot_type = "bubble",
                           range = c(0, 3))))
})

test_that("simple county bubble plot", {
  fb_county <- readRDS(test_path("data/survey-data-county.rds"))

  expect_doppelganger("simple county bubble plot",
                      suppressWarnings(
                        plot(fb_county, plot_type = "bubble")))
})


test_that("warn on incomplete metadata", {
  fake_data <- structure(data.frame(
    data_source = "foo",
    signal = "bar",
    value = c(1, 2, 0, 3),
    geo_value = c("pa", "in", "tx", "wy"),
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-02-01"),
    stderr = 0.5),
    class = c("covidcast_signal", "data.frame"),
    metadata = list(geo_type = "state", mean_value = 0, stdev_value = 1)
  )

  expect_warning(plot(fake_data), NA)
  attributes(fake_data)$metadata <- list(geo_type = "state", mean_value = 0)

  expect_warning(plot(fake_data),
                 class="covidcast_plot_meta_not_found")
})
