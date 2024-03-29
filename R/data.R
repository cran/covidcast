#' County census population data
#'
#' Data set on county populations, from the 2019 US Census.
#'
#' @format A data frame with 3193 rows, one for each county (along with the 50
#'   states and DC). Columns include:
#'
#' \describe{
#'   \item{SUMLEV}{Geographic summary level. Either 40 (state) or 50 (county).}
#'   \item{REGION}{Census Region code}
#'   \item{DIVISION}{Census Division code}
#'   \item{STATE}{State FIPS code.}
#'   \item{COUNTY}{County FIPS}
#'   \item{STNAME}{Name of the state in which this county belongs.}
#'   \item{CTYNAME}{County name, to help find counties by name.}
#'   \item{POPESTIMATE2019}{Estimate of the county's resident population as of
#'   July 1, 2019.}
#'   \item{FIPS}{Five-digit county FIPS codes. These are unique identifiers
#'   used, for example, as the `geo_values` argument to `covidcast_signal()` to
#'   request data from a specific county.}
#' }
#'
#' @references Census Bureau documentation of all columns and their meaning:
#'   \url{https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.pdf},
#'   \url{https://www.census.gov/data/tables/time-series/demo/popest/2010s-total-puerto-rico-municipios.html},
#'   and \url{https://www.census.gov/data/tables/2010/dec/2010-island-areas.html}
#'
#' @source United States Census Bureau, at
#'   \url{https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv}
#'
#' @seealso [county_fips_to_name()], [name_to_fips()]
"county_census"

#' Metro area population data
#'
#' Data set on metropolitan area populations, from the 2019 US Census. This
#' includes metropolitan and micropolitan statistical areas, although the
#' COVIDcast API only supports fetching data from metropolitan statistical
#' areas.
#'
#' @format A data frame with 2797 rows, each representing one core-based
#'   statistical area (including metropolitan and micropolitan statistical
#'   areas, county or county equivalents, and metropolitan divisions). There are
#'   many columns. The most crucial are:
#'
#' \describe{
#'   \item{CBSA}{Core Based Statistical Area code. These are unique identifiers
#'   used, for example, as the `geo_values` argument to `covidcast_signal()`
#'   when requesting data from specific metro areas (with `geo_type = 'msa'`).}
#'   \item{MDIV}{Metropolitan Division code}
#'   \item{STCOU}{State and county code}
#'   \item{NAME}{Name or title of the area.}
#'   \item{LSAD}{Legal/Statistical Area Description, identifying if this is a
#'   metropolitan or micropolitan area, a metropolitan division, or a county.}
#'   \item{STATE}{State FIPS code.}
#'   \item{POPESTIMATE2019}{Estimate of the area's resident population as of
#' July 1, 2019.}
#' }
#'
#' @references Census Bureau documentation of all columns and their meaning:
#'   \url{https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/metro/totals/cbsa-est2019-alldata.pdf}
#'
#' @source United States Census Bureau, at
#'   \url{https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/metro/totals/cbsa-est2019-alldata.csv}
#'
#' @seealso [cbsa_to_name()], [name_to_cbsa()]
"msa_census"

#' State population data
#'
#' Data set on state populations, from the 2019 US Census.
#'
#' @format Data frame with 53 rows (including one for the United States as a
#'   whole, plus the District of Columbia and the Puerto Rico Commonwealth).
#'   Important columns:
#'
#' \describe{
#'   \item{SUMLEV}{Geographic summary level.}
#'   \item{REGION}{Census Region code}
#'   \item{DIVISION}{Census Division code}
#'   \item{STATE}{State FIPS code}
#'   \item{NAME}{Name of the state}
#'   \item{POPESTIMATE2019}{Estimate of the state's resident population in
#'      2019.}
#'   \item{POPEST18PLUS2019}{Estimate of the state's resident population in
#'      2019 that is over 18 years old.}
#'   \item{PCNT_POPEST18PLUS}{Estimate of the percent of a state's resident
#'      population in 2019 that is over 18.}
#'   \item{ABBR}{Postal abbreviation of the state}
#' }
#'
#' @source United States Census Bureau, at
#'   \url{https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.pdf},
#'   \url{https://www.census.gov/data/tables/time-series/demo/popest/2010s-total-puerto-rico-municipios.html},
#'   and \url{https://www.census.gov/data/tables/2010/dec/2010-island-areas.html}
#'
#' @seealso [abbr_to_name()], [name_to_abbr()], [abbr_to_fips()], [fips_to_abbr()]
"state_census"
