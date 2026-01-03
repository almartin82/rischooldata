# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Convert to numeric, handling suppression markers
#'
#' RIDE uses various markers for suppressed data (*, <10, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "n/a", "#N/A")] <- NA_character_

  # Handle patterns like "<10"
  x[grepl("^<\\d+$", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get available years for Rhode Island enrollment data
#'
#' Returns the range of years available from RIDE. The RIDE Data Center
#' provides October 1st enrollment headcounts with data going back to 2010-11.
#'
#' Data Eras:
#' - Era 1 (2011-2014): Historical data with potentially different format
#' - Era 2 (2015-present): Current RIDE Data Center format
#'
#' @return Integer vector of available end years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # RIDE Data Center has data from 2010-11 to present
  # As of late 2025, data is available through 2025-26 (end_year 2026)
  2011:2026
}
