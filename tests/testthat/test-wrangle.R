library(covidcast)
library(dplyr)

test_that("aggregated signals have times shifted correctly", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = "a",
    value = 1:5,
    time_value = seq.Date(as.Date("2020-01-01"), as.Date("2020-01-05"), "day"),
    issue = as.Date("2020-01-06"),
    stderr = 0.1,
    sample_size = 10,
    lag = 1),
    class = c("covidcast_signal", "data.frame"),
    metadata = list(geo_type = "state"))

  agg <- aggregate_signals(foo, dt = c(-1, 1, 2))

  expect_equal(arrange(agg, time_value),
               structure(data.frame(
                 geo_value = "a",
                 time_value = foo$time_value,
                 "value-1:foo_foo" = c(NA, 1:4),
                 "value+1:foo_foo" = c(2:5, NA),
                 "value+2:foo_foo" = c(3:5, NA, NA),
                 check.names = FALSE),
                 class = c("covidcast_signal_wide", "data.frame"),
                 metadata = data.frame(geo_type = "state")))
})

test_that("list of aggregated signals have times shifted correctly", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = "a",
    value = 1:5,
    time_value = seq.Date(as.Date("2020-01-01"), as.Date("2020-01-05"), "day"),
    issue = as.Date("2020-01-06"),
    stderr = 0.1,
    sample_size = 10,
    lag = 1),
    class = c("covidcast_signal", "data.frame"),
    metadata = list(geo_type = "state"))

  bar <- structure(data.frame(
    data_source = "bar",
    signal = "bar",
    geo_value = "a",
    value = 6:10,
    time_value = seq.Date(as.Date("2020-01-01"), as.Date("2020-01-05"), "day"),
    issue = as.Date("2020-01-06"),
    stderr = 0.1,
    sample_size = 10,
    lag = 1),
    class = c("covidcast_signal", "data.frame"),
    metadata = list(geo_type = "state"))

  # list of lags for each input signal
  agg <- aggregate_signals(list(foo, bar), dt = list(0, c(-1, 1, 2)))

  expect_equal(arrange(agg, time_value),
               structure(data.frame(
                 geo_value = "a",
                 time_value = foo$time_value,
                 "value+0:foo_foo" = c(1:5),
                 "value-1:bar_bar" = c(NA, 6:9),
                 "value+1:bar_bar" = c(7:10, NA),
                 "value+2:bar_bar" = c(8:10, NA, NA),
                 check.names = FALSE),
                 class = c("covidcast_signal_wide", "data.frame"),
                 metadata = data.frame(geo_type = rep("state", 2))))

  # single vector of lags for all input signals
  agg <- aggregate_signals(list(foo, bar), dt = c(-1, 1, 2))

  expect_equal(arrange(agg, time_value),
               structure(data.frame(
                 geo_value = "a",
                 time_value = foo$time_value,
                 "value-1:foo_foo" = c(NA, 1:4),
                 "value+1:foo_foo" = c(2:5, NA),
                 "value+2:foo_foo" = c(3:5, NA, NA),
                 "value-1:bar_bar" = c(NA, 6:9),
                 "value+1:bar_bar" = c(7:10, NA),
                 "value+2:bar_bar" = c(8:10, NA, NA),
                 check.names = FALSE),
                 class = c("covidcast_signal_wide", "data.frame"),
                 metadata = data.frame(geo_type = rep("state", 2))))
})

test_that("signals are joined with full join", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = "a",
    value = 1:5,
    time_value = seq.Date(as.Date("2020-01-01"), as.Date("2020-01-05"), "day"),
    issue = as.Date("2020-01-06"),
    stderr = 0.1,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "foo", signal = "foo",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  bar <- structure(data.frame(
    data_source = "bar",
    signal = "bar",
    geo_value = "a",
    value = 6:10,
    time_value = seq.Date(as.Date("2020-01-03"), as.Date("2020-01-07"), "day"),
    issue = as.Date("2020-01-06"),
    stderr = 0.1,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "bar", signal = "bar",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  agg <- aggregate_signals(list(foo, bar))

  expect_equal(arrange(agg, time_value),
               structure(data.frame(
                 geo_value = "a",
                 time_value = seq.Date(as.Date("2020-01-01"),
                                       as.Date("2020-01-07"), "day"),
                 "value+0:foo_foo" = c(1:5, NA, NA),
                 "value+0:bar_bar" = c(NA, NA, 6:10),
                 check.names = FALSE),
                 metadata = data.frame(data_source = c("foo", "bar"),
                                       signal = c("foo", "bar"),
                                       geo_type = "state"),
                 class = c("covidcast_signal_wide", "data.frame")))
})

test_that("aggregated data can be made longer", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = c("pa", "tx", "ri"),
    value = 1:3,
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-01-02"),
    stderr = 0.5,
    lag = 1),
    metadata = data.frame(data_source = "foo", signal = "foo",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  bar <- structure(data.frame(
    data_source = "bar",
    signal = "bar",
    geo_value = c("pa", "tx", "ri"),
    value = 4:6,
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-01-02"),
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "bar", signal = "bar",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  agg_wide <- aggregate_signals(list(foo, bar), format = "wide")

  expect_equal(arrange(agg_wide, geo_value),
               structure(data.frame(
                 geo_value = c("pa", "ri", "tx"),
                 time_value = as.Date("2020-01-01"),
                 "value+0:foo_foo" = c(1, 3, 2),
                 "value+0:bar_bar" = c(4, 6, 5),
                 check.names = FALSE),
                 metadata = data.frame(
                     data_source = c("foo", "bar"),
                     signal = c("foo", "bar"),
                     geo_type = "state"),
                 class = c("covidcast_signal_wide", "data.frame")))

  long <- covidcast_longer(agg_wide)

  expect_equal(arrange(long, data_source, geo_value),
               structure(data.frame(
                 data_source = c(rep("bar", 3), rep("foo", 3)),
                 signal = c(rep("bar", 3), rep("foo", 3)),
                 geo_value = rep(c("pa", "ri", "tx"), 2),
                 time_value = as.Date("2020-01-01"),
                 dt = 0,
                 value = c(4, 6, 5, 1, 3, 2)),
                 metadata = data.frame(
                     data_source = c("foo", "bar"),
                     signal = c("foo", "bar"),
                     geo_type = "state"),
                 class = c("covidcast_signal_long", "data.frame")))

  # Now try it long in the first place. TODO Currently fails because wide format
  # does not preserve issue, stderr, sample_size, or lag. Support should be
  # added for these columns.
  ## agg_long <- aggregate_signals(list(foo, bar), format = "long")
  ## expect_equal(long, agg_long)
})

test_that("aggregated data can be made wider", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = c("pa", "tx", "ri"),
    value = 1:3,
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-01-02"),
    stderr = 0.5,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "foo", signal = "foo",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  bar <- structure(data.frame(
    data_source = "bar",
    signal = "bar",
    geo_value = c("pa", "tx", "ri"),
    value = 4:6,
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-01-02"),
    stderr = 0.5,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "bar", signal = "bar",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  agg_long <- aggregate_signals(list(foo, bar), format = "long")

  expect_equal(arrange(agg_long, data_source, geo_value),
               structure(data.frame(
                 data_source = c(rep("bar", 3), rep("foo", 3)),
                 signal = c(rep("bar", 3), rep("foo", 3)),
                 geo_value = rep(c("pa", "ri", "tx"), 2),
                 time_value = as.Date("2020-01-01"),
                 issue = as.Date("2020-01-02"),
                 stderr = 0.5,
                 sample_size = 10,
                 lag = 1,
                 dt = 0,
                 value = c(4, 6, 5, 1, 3, 2)),
                 metadata = data.frame(
                     data_source = c("foo", "bar"),
                     signal = c("foo", "bar"),
                     geo_type = "state"),
                 class = c("covidcast_signal_long", "data.frame")))

  wide <- covidcast_wider(agg_long)

  expect_equal(arrange(wide, geo_value),
               structure(data.frame(
                 geo_value = c("pa", "ri", "tx"),
                 time_value = as.Date("2020-01-01"),
                 "value+0:foo_foo" = c(1, 3, 2),
                 "value+0:bar_bar" = c(4, 6, 5),
                 check.names = FALSE),
                 metadata = data.frame(
                     data_source = c("foo", "bar"),
                     signal = c("foo", "bar"),
                     geo_type = "state"),
                 class = c("covidcast_signal_wide", "data.frame")))
})

test_that("can aggregate signals with different metadata", {
  # signals from as.covidcast_signal() may have less metadata available than
  # those from covidcast_signal()

  foo <- as.covidcast_signal(
    data.frame(
      geo_value = "01000",
      time_value = as.Date("2020-01-01"),
      value = 1
    ),
    signal = "foo"
  )

  baz <- foo
  attributes(baz)$metadata <- data.frame(
    geo_type = "county",
    num_locations = 100
  )

  expect_silent(aggregate_signals(list(foo, baz)))
})

test_that("aggregated df doesn't clobber data_source or signal", {
  foo <- structure(data.frame(
    data_source = "foo",
    signal = "foo",
    geo_value = c("pa", "tx", "ri", "ri"),
    value = 1:4,
    time_value = as.Date(c("2020-01-01", "2020-01-02", "2020-01-01", "2020-01-03")),
    issue = as.Date("2020-01-02"),
    stderr = 0.5,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "foo", signal = "foo",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

  bar <- structure(data.frame(
    data_source = "bar",
    signal = "bar",
    geo_value = c("pa", "tx", "ri"),
    value = 4:6,
    time_value = as.Date("2020-01-01"),
    issue = as.Date("2020-01-02"),
    stderr = 0.5,
    sample_size = 10,
    lag = 1),
    metadata = data.frame(data_source = "bar", signal = "bar",
                          geo_type = "state"),
    class = c("covidcast_signal", "data.frame"))

    agg_long <- aggregate_signals(list(foo, bar), format = "long")

    expect_false(any(is.na(agg_long$data_source)))
    expect_false(any(is.na(agg_long$signal)))


})
